extends Node2D
class_name VirusHunterGame

const MAIN_MENU_SCENE_PATH: String = "res://scenes/Main.tscn"
## Bullets render above the playfield fill but below ships (see BACKDROP_Z_INDEX).
const BULLETS_Z_INDEX: int = -10
const BACKDROP_Z_INDEX: int = -50
## Playfield border drawn above all world Node2D nodes (HUD remains on `CanvasLayer` above).
const PLAYFIELD_FRAME_Z_INDEX: int = 100

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/EnemyBasic.tscn")
@export var tank_enemy_scene: PackedScene = preload("res://scenes/EnemyTank.tscn")
@export var speedster_enemy_scene: PackedScene = preload("res://scenes/EnemySpeedster.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/EnemyBoss.tscn")
@export var siege_boss_scene: PackedScene = preload("res://scenes/EnemySiegeBoss.tscn")
@export var player_bullet_scene: PackedScene = preload("res://scenes/BulletPlayer.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/BulletEnemy.tscn")
@export var spawner_scene: PackedScene = preload("res://scenes/EnemySpawner.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/HUD.tscn")
@export var weapon_pickup_scene: PackedScene = preload("res://scenes/WeaponPickup.tscn")
@export var path_trace_scene: PackedScene = preload("res://scenes/PathTrace.tscn")
@export var weapon_pickup_chance_normal: float = 0.11
@export var weapon_pickup_chance_boss: float = 0.48
@export var health_pickup_scene: PackedScene = preload("res://scenes/HealthPickup.tscn")
@export var health_pickup_chance_normal: float = 0.075
@export var health_pickup_chance_boss: float = 0.34
@export var respawn_lives: int = 2
@export var respawn_immunity: float = 2.0
@export var respawn_delay_sec: float = 0.8
@export var reverse_chain_radius_px: float = 140.0

var playfield_rect: Rect2

var _player: Player
var _enemies: Node2D
var _player_bullets: Node2D
var _enemy_bullets: Node2D
var _pickups: Node2D
var _hud: HUD
var _spawner: EnemySpawner
var _player_spawn_position: Vector2
var _lives_remaining: int = 0
var _is_game_over: bool = false
var _is_paused: bool = false
var _is_resume_countdown_running: bool = false
var _pause_locked_for_levelup_delay: bool = false

var _time_scale_ramp_active: bool = false
var _time_scale_ramp_start_ms: int = 0
var _time_scale_ramp_duration_ms: int = 0

var _playfield_backdrop: PlayfieldBackdrop
var _playfield_frame: PlayfieldFrame
var _camera: Camera2D
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength_px: float = 0.0
var _last_player_hp: float = -1.0

var _meta: MetaProgression
var _meta_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _score: int = 0


static func find_game(tree: SceneTree) -> VirusHunterGame:
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("game_controller"):
		var g: VirusHunterGame = n as VirusHunterGame
		if g != null:
			return g
	return null


static func jammer_blocks_enemy_volley(tree: SceneTree, is_boss: bool, rng: RandomNumberGenerator) -> bool:
	var g: VirusHunterGame = find_game(tree)
	if g == null or rng == null:
		return false
	var p: float = g.get_jammer_attack_fail_chance(is_boss)
	return p > 0.0001 and rng.randf() < p


func get_jammer_attack_fail_chance(is_boss: bool) -> float:
	if _meta == null:
		return 0.0
	return _meta.get_jammer_attack_fail_chance(is_boss)


func _ready() -> void:
	add_to_group("game_controller")
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0
	playfield_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	_lives_remaining = maxi(0, respawn_lives)
	_shake_rng.randomize()
	_bootstrap_nodes()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	AudioManager.play_music("gameplay")


func _on_viewport_size_changed() -> void:
	playfield_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	if _playfield_backdrop != null:
		_playfield_backdrop.set_playfield_rect(playfield_rect)
	if _playfield_frame != null:
		_playfield_frame.set_playfield_rect(playfield_rect)
	if _camera != null:
		_camera.global_position = playfield_rect.size * 0.5
	if _player != null:
		_player.playfield_rect = playfield_rect
	if _spawner != null:
		_spawner.playfield_rect = playfield_rect
	var er: Node2D = get_node_or_null(^"EnemyPaths") as Node2D
	var br: Node2D = get_node_or_null(^"BossPaths") as Node2D
	if er != null and br != null:
		EnemyPathLibrary.configure_paths(er, br, playfield_rect)
	_player_spawn_position = Vector2(playfield_rect.size.x * 0.5, playfield_rect.size.y * 0.82)


func _bootstrap_nodes() -> void:
	_meta = MetaProgression.new()
	_meta.reset()
	_meta_rng.randomize()

	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	_camera.global_position = playfield_rect.size * 0.5
	add_child(_camera)
	_camera.make_current()

	_playfield_backdrop = PlayfieldBackdrop.new()
	_playfield_backdrop.z_index = BACKDROP_Z_INDEX
	_playfield_backdrop.set_playfield_rect(playfield_rect)
	add_child(_playfield_backdrop)

	_hud = hud_scene.instantiate() as HUD
	if _hud != null:
		add_child(_hud)
		_hud.process_mode = Node.PROCESS_MODE_ALWAYS
		_hud.set_lives(_lives_remaining)
		_hud.hide_game_over()
		_hud.hide_pause()
		_hud.set_score(0)
		_hud.set_player_level(_meta.player_level)
		_hud.set_heat_map_enabled(_meta.heat_map_unlocked)
		_hud.set_pause_perk_history(_meta.pick_history)
		_hud.pause_quit_requested.connect(_on_pause_quit_requested)

	_enemies = Node2D.new()
	_enemies.name = "Enemies"
	_enemies.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_enemies)

	_player_bullets = Node2D.new()
	_player_bullets.name = "PlayerBullets"
	_player_bullets.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player_bullets.z_index = BULLETS_Z_INDEX
	add_child(_player_bullets)

	_enemy_bullets = Node2D.new()
	_enemy_bullets.name = "EnemyBullets"
	_enemy_bullets.process_mode = Node.PROCESS_MODE_PAUSABLE
	_enemy_bullets.z_index = BULLETS_Z_INDEX
	add_child(_enemy_bullets)

	_pickups = Node2D.new()
	_pickups.name = "Pickups"
	_pickups.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_pickups)

	var path_traces: Node2D = Node2D.new()
	path_traces.name = "PathTraces"
	path_traces.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(path_traces)

	var enemy_paths_root: Node2D = get_node_or_null(^"EnemyPaths") as Node2D
	var boss_paths_root: Node2D = get_node_or_null(^"BossPaths") as Node2D
	EnemyPathLibrary.configure_paths(enemy_paths_root, boss_paths_root, playfield_rect)

	_player_spawn_position = Vector2(playfield_rect.size.x * 0.5, playfield_rect.size.y * 0.82)
	_spawn_player(false)

	_spawner = spawner_scene.instantiate() as EnemySpawner
	if _spawner == null:
		push_error("Failed to instantiate EnemySpawner from spawner_scene.")
		return
	# Configure before adding to the tree so _ready() can build wave plan safely.
	_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawner.playfield_rect = playfield_rect
	_spawner.enemy_paths_root = enemy_paths_root
	_spawner.boss_paths_root = boss_paths_root
	_spawner.enemy_scene = enemy_scene
	_spawner.tank_enemy_scene = tank_enemy_scene
	_spawner.speedster_enemy_scene = speedster_enemy_scene
	_spawner.boss_scene = boss_scene
	_spawner.siege_boss_scene = siege_boss_scene
	_spawner.enemy_parent = _enemies
	_spawner.enemy_bullet_scene = enemy_bullet_scene
	_spawner.enemy_bullet_parent = _enemy_bullets
	_spawner.path_trace_scene = path_trace_scene
	_spawner.path_trace_parent = path_traces
	_spawner.wave_started.connect(_on_wave_started)
	_spawner.wave_completed.connect(_on_wave_completed)
	_spawner.boss_spawned.connect(_on_boss_spawned)
	add_child(_spawner)
	if _hud != null:
		_hud.set_wave(_spawner.get_current_wave())

	_playfield_frame = PlayfieldFrame.new()
	_playfield_frame.name = "PlayfieldFrame"
	_playfield_frame.z_index = PLAYFIELD_FRAME_Z_INDEX
	_playfield_frame.set_playfield_rect(playfield_rect)
	add_child(_playfield_frame)


func _process(_delta: float) -> void:
	_tick_time_scale_ramp()
	_update_screen_shake(_delta)
	if _is_game_over and Input.is_action_just_pressed("shoot"):
		AudioManager.play_sfx("state_restart")
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pause_toggle"):
		_handle_pause_toggle()
		return
	if _hud != null and _player != null:
		if _player.has_active_weapon_perk():
			_hud.set_perk_timer(_player.get_weapon_perk_kind(), _player.get_weapon_perk_time_ratio())
		else:
			_hud.hide_perk_timer()


func _begin_time_scale_ramp(duration_sec: float) -> void:
	_time_scale_ramp_active = true
	_time_scale_ramp_start_ms = int(Time.get_ticks_msec())
	_time_scale_ramp_duration_ms = maxi(1, int(roundf(maxf(0.01, duration_sec) * 1000.0)))
	Engine.time_scale = 0.0


func _tick_time_scale_ramp() -> void:
	if not _time_scale_ramp_active:
		return
	var now_ms: int = int(Time.get_ticks_msec())
	var t_ms: int = now_ms - _time_scale_ramp_start_ms
	var u: float = 1.0
	if _time_scale_ramp_duration_ms > 0:
		u = clampf(float(t_ms) / float(_time_scale_ramp_duration_ms), 0.0, 1.0)
	# Smooth-ish ease (fast start, soft end).
	var eased: float = 1.0 - pow(1.0 - u, 2.0)
	Engine.time_scale = eased
	if u >= 0.999:
		Engine.time_scale = 1.0
		_time_scale_ramp_active = false


func _on_player_died(at: Vector2) -> void:
	_spawn_player_death_vfx(at)
	if _lives_remaining <= 0:
		if _hud != null:
			_hud.set_lives(0, false)
		_game_over()
		return
	_lives_remaining -= 1
	if _hud != null:
		_hud.set_lives(_lives_remaining)
	if _playfield_frame != null:
		_playfield_frame.set_player_dead(true)
	# Delay respawn so death reads clearly.
	await get_tree().create_timer(maxf(0.05, respawn_delay_sec), true).timeout
	if _is_game_over:
		return
	# Defer respawn so we don't toggle Area2D monitoring while physics is flushing overlap queries.
	call_deferred("_spawn_player", true)


func _spawn_player_death_vfx(at: Vector2) -> void:
	var scn: PackedScene = preload("res://scenes/VFX/PlayerExplosion.tscn")
	var fx: Node2D = scn.instantiate() as Node2D
	if fx == null:
		return
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx)
	fx.global_position = at


func _spawn_player(apply_respawn_immunity: bool) -> void:
	_player = player_scene.instantiate() as Player
	if _player == null:
		push_error("Failed to instantiate Player from player_scene.")
		return
	add_child(_player)
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.global_position = _player_spawn_position
	_player.playfield_rect = playfield_rect
	_player.bullet_scene = player_bullet_scene
	_player.bullet_parent = _player_bullets
	_player.died.connect(_on_player_died)
	if not _player.health_changed.is_connected(_on_player_health_changed):
		_player.health_changed.connect(_on_player_health_changed)
	if apply_respawn_immunity:
		_player.reset_for_respawn(respawn_immunity)
		if _playfield_frame != null:
			_playfield_frame.set_player_dead(false)
			_playfield_frame.set_respawn_immunity(respawn_immunity)
	else:
		if _playfield_frame != null:
			_playfield_frame.set_player_dead(false)
	if _hud != null:
		_player.health_changed.connect(_hud.set_hp)
		_player.apply_meta_progression(_meta)
		_hud.set_hp(_player.hp, _player.max_hp)
		_hud.set_meta_xp(_meta.xp, _meta.xp_to_next_level)
	_last_player_hp = _player.hp


func _on_player_health_changed(current_hp: float, _max_hp: float) -> void:
	if _last_player_hp < 0.0:
		_last_player_hp = current_hp
		return
	if current_hp < _last_player_hp:
		var dmg: float = _last_player_hp - current_hp
		# Small, snappy shake. Scale modestly with damage but clamp hard.
		_shake(2.5 + minf(6.0, dmg * 0.05), 0.14)
		if _playfield_frame != null:
			_playfield_frame.flash_damage()
	_last_player_hp = current_hp


func _shake(strength_px: float, duration_sec: float) -> void:
	if duration_sec <= 0.0 or strength_px <= 0.0:
		return
	_shake_strength_px = maxf(_shake_strength_px, strength_px)
	_shake_duration = maxf(_shake_duration, duration_sec)
	_shake_time_left = maxf(_shake_time_left, duration_sec)


func _update_screen_shake(delta: float) -> void:
	if _camera == null:
		return
	if get_tree().paused:
		_camera.offset = Vector2.ZERO
		return
	if _shake_time_left <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_shake_time_left = maxf(0.0, _shake_time_left - delta)
	var t: float = 1.0
	if _shake_duration > 0.0:
		t = clampf(_shake_time_left / _shake_duration, 0.0, 1.0)
	# Ease out quickly so it feels snappy.
	var strength: float = _shake_strength_px * (t * t)
	_camera.offset = Vector2(
		_shake_rng.randf_range(-strength, strength),
		_shake_rng.randf_range(-strength, strength)
	)
	if _shake_time_left <= 0.0:
		_shake_strength_px = 0.0
		_shake_duration = 0.0


func _on_boss_spawned(boss: EnemyBoss) -> void:
	if _hud == null or boss == null:
		return
	if not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)
	if not boss.tree_exited.is_connected(_on_boss_tree_exited):
		boss.tree_exited.connect(_on_boss_tree_exited, CONNECT_ONE_SHOT)


func _on_boss_health_changed(current_hp: float, maximum_hp: float) -> void:
	if _hud != null:
		_hud.set_boss_hp(current_hp, maximum_hp)


func _on_boss_tree_exited() -> void:
	if _hud != null:
		_hud.hide_boss_hp_bar()


func _on_wave_started(wave_number: int, _enemy_target: int, is_boss_wave: bool) -> void:
	if _hud != null:
		_hud.set_wave(wave_number)
		if is_boss_wave:
			_hud.show_boss_banner(2.0, wave_number)
			_hud.hide_boss_hp_bar()
		else:
			_hud.show_wave_center(wave_number)
			_hud.hide_boss_hp_bar()
	if is_boss_wave:
		AudioManager.play_stinger("boss_intro")
		AudioManager.play_music("boss", 0.7)
	else:
		AudioManager.play_sfx("state_wave_start")
		AudioManager.play_music("gameplay", 0.7)
	if _playfield_backdrop != null:
		_playfield_backdrop.set_boss_wave_active(is_boss_wave)


func on_enemy_defeated(enemy: Node, from_chain_explosion: bool) -> void:
	if _is_game_over:
		return
	var xp_add: float = _xp_value_for_enemy(enemy)
	_score += _score_value_for_enemy(enemy)
	if _hud != null:
		_hud.set_score(_score)
	_meta.add_xp(xp_add)
	_sync_meta_xp_hud()
	_try_staller_extend_powerup()
	if not from_chain_explosion:
		var p_chain: float = _meta.get_chain_explosion_chance()
		if p_chain > 0.0001 and _meta_rng.randf() < p_chain:
			_trigger_reverse_engineering_chain(enemy as Node2D)


func _try_staller_extend_powerup() -> void:
	if _meta == null or _player == null:
		return
	var p: float = _meta.staller_extend_chance
	if p <= 0.0001:
		return
	if not _player.has_active_weapon_perk():
		return
	if _meta_rng.randf() >= clampf(p, 0.0, 1.0):
		return
	_player.add_weapon_perk_time(1.0)


func _xp_value_for_enemy(enemy: Node) -> float:
	if enemy is EnemyBoss:
		return 140.0
	var eb: EnemyBasic = enemy as EnemyBasic
	if eb != null:
		return clampf(eb.get_max_hp_snapshot() * 0.12, 7.0, 48.0)
	return 10.0


func _score_value_for_enemy(enemy: Node) -> int:
	if enemy is EnemyBoss:
		return 2800
	var eb: EnemyBasic = enemy as EnemyBasic
	if eb != null:
		return int(roundi(clampf(eb.get_max_hp_snapshot() * 10.0, 120.0, 950.0)))
	return 150


func _trigger_reverse_engineering_chain(dead: Node2D) -> void:
	if dead == null:
		return
	var pos: Vector2 = dead.global_position
	var dead_max: float = 1.0
	if dead is EnemyBoss:
		dead_max = (dead as EnemyBoss).get_max_hp_snapshot()
	elif dead is EnemyBasic:
		dead_max = (dead as EnemyBasic).get_max_hp_snapshot()
	var dmg: float = dead_max * 0.25
	var r2: float = reverse_chain_radius_px * reverse_chain_radius_px
	for n in get_tree().get_nodes_in_group(Defs.GROUP_ENEMY):
		if n == dead or not is_instance_valid(n):
			continue
		var nd: Node2D = n as Node2D
		if nd == null:
			continue
		if nd.global_position.distance_squared_to(pos) > r2:
			continue
		var eb: EnemyBasic = n as EnemyBasic
		if eb != null:
			eb.apply_chain_explosion_damage(dmg)
			continue
		var boss: EnemyBoss = n as EnemyBoss
		if boss != null:
			boss.apply_chain_explosion_damage(dmg)


func _sync_meta_xp_hud(reset_colored_after_level: bool = false) -> void:
	if _hud == null:
		return
	_hud.set_meta_xp(_meta.xp, _meta.xp_to_next_level, reset_colored_after_level)


func _on_wave_completed(_wave_number: int) -> void:
	if _is_game_over:
		return
	# Small breather before showing the level-up UI.
	_pause_locked_for_levelup_delay = true
	await get_tree().create_timer(0.75, true).timeout
	_pause_locked_for_levelup_delay = false
	if _is_game_over:
		_pause_locked_for_levelup_delay = false
		return
	await _drain_pending_meta_levelups()


func _drain_pending_meta_levelups() -> void:
	while not _is_game_over and _meta.can_level_up() and _hud != null:
		var offers: Array[Dictionary] = _meta.roll_three_offers(_meta_rng)
		if offers.is_empty():
			break
		get_tree().paused = true
		var queued: int = _meta.queued_meta_level_up_count()
		var idx: int = await _hud.request_meta_perk_choice(offers, queued)
		get_tree().paused = false
		if idx < 0 or idx >= offers.size():
			break
		_meta.apply_offer(offers[idx])
		_meta.consume_level_up()
		if _player != null:
			_player.apply_meta_progression(_meta)
		if _hud != null:
			_hud.set_player_level(_meta.player_level)
			_hud.set_heat_map_enabled(_meta.heat_map_unlocked)
			_hud.set_pause_perk_history(_meta.pick_history)
		_sync_meta_xp_hud(true)
	_sync_meta_xp_hud()


func _game_over() -> void:
	if _is_game_over:
		return
	_is_game_over = true
	if _spawner != null:
		_spawner.set_process(false)
	_clear_node_children(_enemies)
	_clear_node_children(_enemy_bullets)
	_clear_node_children(_player_bullets)
	_clear_node_children(_pickups)
	if _hud != null:
		# Ensure the game over screen shows the last wave reached.
		if _spawner != null:
			_hud.set_wave(_spawner.get_current_wave())
		_hud.show_game_over(_meta.pick_history, _score, _meta.player_level)
		_hud.hide_pause()
	AudioManager.stop_music(1.0)
	AudioManager.play_stinger("game_over")


func _clear_node_children(root: Node) -> void:
	if root == null:
		return
	for c in root.get_children():
		c.queue_free()


func offer_weapon_perk_pickup(offered: WeaponPickup.PerkKind) -> void:
	if _is_game_over or _player == null:
		return
	# Auto-apply pickups (no perk-choice pause screen).
	_player.apply_weapon_pickup(offered)


func _handle_pause_toggle() -> void:
	if _hud != null and _hud.is_meta_level_pick_open():
		return
	if _pause_locked_for_levelup_delay:
		return
	if _is_game_over or _is_resume_countdown_running:
		return
	if not _is_paused:
		_is_paused = true
		get_tree().paused = true
		if _hud != null:
			_hud.set_pause_perk_history(_meta.pick_history)
			_hud.show_paused()
		AudioManager.play_sfx("state_pause")
		AudioManager.pause_music_dip()
		return
	_start_resume_countdown()


func _start_resume_countdown() -> void:
	_is_resume_countdown_running = true
	var total: float = GameSettings.get_unpause_delay_seconds()
	if total <= 0.001:
		# No countdown; resume immediately but keep the post-resume time-scale ramp.
		_is_paused = false
		_is_resume_countdown_running = false
		get_tree().paused = false
		_begin_time_scale_ramp(0.5)
		if _hud != null:
			_hud.hide_pause()
		AudioManager.resume_music_restore()
		return

	if _hud != null:
		_hud.start_resume_countdown(total)
		_hud.show_resume_countdown(1)
	AudioManager.play_resume_tick(1)
	await get_tree().create_timer(total, true).timeout
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().paused = false
	_begin_time_scale_ramp(0.5)
	if _hud != null:
		_hud.hide_pause()
	AudioManager.resume_music_restore()


func try_spawn_weapon_pickup(at: Vector2, from_boss: bool = false) -> void:
	if weapon_pickup_scene == null or _is_game_over:
		return
	var chance: float = weapon_pickup_chance_boss if from_boss else weapon_pickup_chance_normal
	chance = clampf(chance + _meta.total_weapon_pickup_chance_bonus, 0.0, 1.0)
	if randf() > chance:
		return
	var kind: WeaponPickup.PerkKind
	match randi() % 4:
		0:
			kind = WeaponPickup.PerkKind.DOUBLE_STRAIGHT
		1:
			kind = WeaponPickup.PerkKind.TRIPLE_STRAIGHT
		2:
			kind = WeaponPickup.PerkKind.BEAM
		_:
			kind = WeaponPickup.PerkKind.CROSS_FIRE
	# Instantiating/adding Area2D during area_entered runs in a physics flush; defer add_child.
	call_deferred("_spawn_weapon_pickup_deferred", kind, at)


func _spawn_weapon_pickup_deferred(kind: WeaponPickup.PerkKind, at: Vector2) -> void:
	if weapon_pickup_scene == null or _is_game_over or _pickups == null:
		return
	var pk: WeaponPickup = weapon_pickup_scene.instantiate() as WeaponPickup
	if pk == null:
		return
	pk.setup(kind, playfield_rect)
	pk.fall_speed *= _meta.get_pickup_fall_speed_scale()
	pk.global_position = at
	pk.configure_zero_day_routing(_meta.zero_day_catcher_unlocked)
	_pickups.add_child(pk)


func try_spawn_health_pickup(at: Vector2, from_boss: bool = false) -> void:
	if health_pickup_scene == null or _is_game_over:
		return
	var chance: float = health_pickup_chance_boss if from_boss else health_pickup_chance_normal
	if randf() > chance:
		return
	call_deferred("_spawn_health_pickup_deferred", at)


func _spawn_health_pickup_deferred(at: Vector2) -> void:
	if health_pickup_scene == null or _is_game_over or _pickups == null:
		return
	var hk: HealthPickup = health_pickup_scene.instantiate() as HealthPickup
	if hk == null:
		return
	hk.setup(playfield_rect)
	hk.fall_speed *= _meta.get_pickup_fall_speed_scale()
	hk.global_position = at
	hk.configure_zero_day_routing(_meta.zero_day_catcher_unlocked)
	_pickups.add_child(hk)


func _on_pause_quit_requested() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().paused = false
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
