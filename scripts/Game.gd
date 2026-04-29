extends Node2D

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/EnemyBasic.tscn")
@export var tank_enemy_scene: PackedScene = preload("res://scenes/EnemyTank.tscn")
@export var speedster_enemy_scene: PackedScene = preload("res://scenes/EnemySpeedster.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/EnemyBoss.tscn")
@export var player_bullet_scene: PackedScene = preload("res://scenes/BulletPlayer.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/BulletEnemy.tscn")
@export var spawner_scene: PackedScene = preload("res://scenes/EnemySpawner.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/HUD.tscn")
@export var respawn_lives: int = 3
@export var respawn_immunity: float = 2.0

var playfield_rect: Rect2

var _player: Player
var _enemies: Node2D
var _player_bullets: Node2D
var _enemy_bullets: Node2D
var _hud: HUD
var _spawner: EnemySpawner
var _player_spawn_position: Vector2
var _lives_remaining: int = 0


func _ready() -> void:
	playfield_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	_lives_remaining = maxi(0, respawn_lives)
	_bootstrap_nodes()


func _bootstrap_nodes() -> void:
	_hud = hud_scene.instantiate() as HUD
	if _hud != null:
		add_child(_hud)
		_hud.set_lives(_lives_remaining)

	_enemies = Node2D.new()
	_enemies.name = "Enemies"
	add_child(_enemies)

	_player_bullets = Node2D.new()
	_player_bullets.name = "PlayerBullets"
	add_child(_player_bullets)

	_enemy_bullets = Node2D.new()
	_enemy_bullets.name = "EnemyBullets"
	add_child(_enemy_bullets)

	_player_spawn_position = Vector2(playfield_rect.size.x * 0.5, playfield_rect.size.y * 0.82)
	_spawn_player(false)

	_spawner = spawner_scene.instantiate() as EnemySpawner
	if _spawner == null:
		push_error("Failed to instantiate EnemySpawner from spawner_scene.")
		return
	add_child(_spawner)
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
	queue_redraw()


func _draw() -> void:
	var r: Rect2 = playfield_rect.grow(-8.0)
	draw_rect(r, Color(0.05, 0.05, 0.07, 1.0), true)
	draw_rect(r, Color(0.25, 0.25, 0.3, 1.0), false, 2.0)


func _on_player_died() -> void:
	if _lives_remaining <= 0:
		if _hud != null:
			_hud.set_lives(0)
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
