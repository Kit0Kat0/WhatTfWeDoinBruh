extends Node2D

const MAIN_MENU_SCENE_PATH: String = "res://scenes/Main.tscn"

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
var _perk_choice_active: bool = false


func _ready() -> void:
	add_to_group("game_controller")
	process_mode = Node.PROCESS_MODE_ALWAYS
	playfield_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	_lives_remaining = maxi(0, respawn_lives)
	_bootstrap_nodes()
	AudioManager.play_music("gameplay")


func _bootstrap_nodes() -> void:
	_hud = hud_scene.instantiate() as HUD
	if _hud != null:
		add_child(_hud)
		_hud.process_mode = Node.PROCESS_MODE_ALWAYS
		_hud.set_lives(_lives_remaining)
		_hud.hide_game_over()
		_hud.hide_pause()
		_hud.hide_perk_choice()
		_hud.pause_quit_requested.connect(_on_pause_quit_requested)
		_hud.perk_keep_refresh_requested.connect(_on_perk_keep_refresh)
		_hud.perk_switch_requested.connect(_on_perk_switch)

	_enemies = Node2D.new()
	_enemies.name = "Enemies"
	_enemies.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_enemies)

	_player_bullets = Node2D.new()
	_player_bullets.name = "PlayerBullets"
	_player_bullets.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_player_bullets)

	_enemy_bullets = Node2D.new()
	_enemy_bullets.name = "EnemyBullets"
	_enemy_bullets.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_enemy_bullets)

	_pickups = Node2D.new()
	_pickups.name = "Pickups"
	_pickups.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_pickups)

	_player_spawn_position = Vector2(playfield_rect.size.x * 0.5, playfield_rect.size.y * 0.82)
	_spawn_player(false)

	_spawner = spawner_scene.instantiate() as EnemySpawner
	if _spawner == null:
		push_error("Failed to instantiate EnemySpawner from spawner_scene.")
		return
	add_child(_spawner)
	_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawner.playfield_rect = playfield_rect
	_spawner.enemy_scene = enemy_scene
	_spawner.tank_enemy_scene = tank_enemy_scene
	_spawner.speedster_enemy_scene = speedster_enemy_scene
	_spawner.boss_scene = boss_scene
	_spawner.enemy_parent = _enemies
	_spawner.enemy_bullet_scene = enemy_bullet_scene
	_spawner.enemy_bullet_parent = _enemy_bullets
	_spawner.wave_started.connect(_on_wave_started)
	if _hud != null:
		_hud.set_wave(_spawner.get_current_wave())


func _process(_delta: float) -> void:
	if _is_game_over and Input.is_action_just_pressed("shoot"):
		AudioManager.play_sfx("state_restart")
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pause_toggle"):
		_handle_pause_toggle()
		return
	queue_redraw()


func _draw() -> void:
	var r: Rect2 = playfield_rect.grow(-8.0)
	draw_rect(r, Color(0.05, 0.05, 0.07, 1.0), true)
	draw_rect(r, Color(0.25, 0.25, 0.3, 1.0), false, 2.0)


func _on_player_died() -> void:
	if _lives_remaining <= 0:
		if _hud != null:
			_hud.set_lives(0)
		_game_over()
		return
	_lives_remaining -= 1
	if _hud != null:
		_hud.set_lives(_lives_remaining)
	_spawn_player(true)


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
	if apply_respawn_immunity:
		_player.reset_for_respawn(respawn_immunity)
	if _hud != null:
		_player.health_changed.connect(_hud.set_hp)
		_hud.set_hp(_player.hp, _player.max_hp)


func _on_wave_started(wave_number: int, _enemy_target: int, is_boss_wave: bool) -> void:
	if _hud != null:
		_hud.set_wave(wave_number)
		if is_boss_wave:
			_hud.show_boss_banner()
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
	if _perk_choice_active:
		_perk_choice_active = false
		get_tree().paused = false
		if _hud != null:
			_hud.hide_perk_choice()
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
	if not _player.has_active_weapon_perk():
		_player.apply_weapon_pickup(offered)
		return
	call_deferred("_deferred_open_perk_choice")


func _deferred_open_perk_choice() -> void:
	if _is_game_over or _player == null or _perk_choice_active:
		return
	if not _player.has_active_weapon_perk():
		return
	_perk_choice_active = true
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().paused = true
	if _hud != null:
		_hud.hide_pause()
		_hud.show_perk_choice(_player.get_weapon_perk_kind())


func _close_perk_choice_and_resume() -> void:
	if not _perk_choice_active:
		return
	_perk_choice_active = false
	get_tree().paused = false
	if _hud != null:
		_hud.hide_perk_choice()


func _on_perk_keep_refresh() -> void:
	if _player != null:
		_player.refresh_weapon_perk_timer()
	_close_perk_choice_and_resume()


func _on_perk_switch(kind: WeaponPickup.PerkKind) -> void:
	if _player != null:
		_player.apply_weapon_pickup(kind)
	_close_perk_choice_and_resume()


func _handle_pause_toggle() -> void:
	if _perk_choice_active:
		return
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
	var pk: WeaponPickup = weapon_pickup_scene.instantiate() as WeaponPickup
	if pk == null:
		return
	var kind: WeaponPickup.PerkKind
	match randi() % 3:
		0:
			kind = WeaponPickup.PerkKind.DOUBLE_STRAIGHT
		1:
			kind = WeaponPickup.PerkKind.TRIPLE_STRAIGHT
		_:
			kind = WeaponPickup.PerkKind.BEAM
	pk.setup(kind, playfield_rect)
	pk.global_position = at
	_pickups.add_child(pk)


func _on_pause_quit_requested() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().paused = false
	_is_paused = false
	_is_resume_countdown_running = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
