extends Node2D

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
@export var player_bullet_scene: PackedScene = preload("res://scenes/BulletPlayer.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/BulletEnemy.tscn")
@export var spawner_scene: PackedScene = preload("res://scenes/EnemySpawner.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/HUD.tscn")
@export var weapon_pickup_scene: PackedScene = preload("res://scenes/WeaponPickup.tscn")
@export var path_trace_scene: PackedScene = preload("res://scenes/PathTrace.tscn")
@export var weapon_pickup_chance_normal: float = 0.11
@export var weapon_pickup_chance_boss: float = 0.48
@export var respawn_lives: int = 3
@export var respawn_immunity: float = 2.0

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

var _playfield_backdrop: PlayfieldBackdrop
var _playfield_frame: PlayfieldFrame
var _camera: Camera2D
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength_px: float = 0.0
var _last_player_hp: float = -1.0


func _ready() -> void:
	add_to_group("game_controller")
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_spawner.enemy_parent = _enemies
	_spawner.enemy_bullet_scene = enemy_bullet_scene
	_spawner.enemy_bullet_parent = _enemy_bullets
	_spawner.path_trace_scene = path_trace_scene
	_spawner.path_trace_parent = path_traces
	_spawner.wave_started.connect(_on_wave_started)
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


func _on_player_died() -> void:
	if _lives_remaining <= 0:
		if _hud != null:
			_hud.set_lives(0)
		_game_over()
		return
	_lives_remaining -= 1
	if _hud != null:
		_hud.set_lives(_lives_remaining)
	# Defer respawn so we don't toggle Area2D monitoring while physics is flushing overlap queries.
	call_deferred("_spawn_player", true)


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
	if _hud != null:
		_player.health_changed.connect(_hud.set_hp)
		_hud.set_hp(_player.hp, _player.max_hp)
	_last_player_hp = _player.hp


func _on_player_health_changed(current_hp: float, _max_hp: float) -> void:
	if _last_player_hp < 0.0:
		_last_player_hp = current_hp
		return
	if current_hp < _last_player_hp:
		var dmg: float = _last_player_hp - current_hp
		# Small, snappy shake. Scale modestly with damage but clamp hard.
		_shake(2.5 + minf(6.0, dmg * 0.05), 0.14)
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
			_hud.show_boss_banner()
			_hud.hide_boss_hp_bar()
		else:
			_hud.hide_boss_hp_bar()
	if is_boss_wave:
		AudioManager.play_stinger("boss_intro")
		AudioManager.play_music("boss", 0.7)
	else:
		AudioManager.play_sfx("state_wave_start")
		AudioManager.play_music("gameplay", 0.7)


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
		_hud.show_game_over()
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
	if _is_game_over or _is_resume_countdown_running:
		return
	if not _is_paused:
		_is_paused = true
		get_tree().paused = true
		if _hud != null:
			_hud.show_paused()
		AudioManager.play_sfx("state_pause")
		AudioManager.pause_music_dip()
		return
	_start_resume_countdown()


func _start_resume_countdown() -> void:
	_is_resume_countdown_running = true
	for i in range(3, 0, -1):
		if _hud != null:
			_hud.show_resume_countdown(i)
		AudioManager.play_resume_tick(i)
		await get_tree().create_timer(1.0, true).timeout
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().paused = false
	if _hud != null:
		_hud.hide_pause()
	AudioManager.resume_music_restore()


func try_spawn_weapon_pickup(at: Vector2, from_boss: bool = false) -> void:
	if weapon_pickup_scene == null or _is_game_over:
		return
	var chance: float = weapon_pickup_chance_boss if from_boss else weapon_pickup_chance_normal
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
	pk.global_position = at
	_pickups.add_child(pk)


func _on_pause_quit_requested() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().paused = false
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
