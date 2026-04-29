extends Node2D

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/EnemyBasic.tscn")
@export var player_bullet_scene: PackedScene = preload("res://scenes/BulletPlayer.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/BulletEnemy.tscn")
@export var spawner_scene: PackedScene = preload("res://scenes/EnemySpawner.tscn")

var playfield_rect: Rect2

var _player: Node2D
var _enemies: Node2D
var _player_bullets: Node2D
var _enemy_bullets: Node2D


func _ready() -> void:
	playfield_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	_bootstrap_nodes()


func _bootstrap_nodes() -> void:
	_enemies = Node2D.new()
	_enemies.name = "Enemies"
	add_child(_enemies)

	_player_bullets = Node2D.new()
	_player_bullets.name = "PlayerBullets"
	add_child(_player_bullets)

	_enemy_bullets = Node2D.new()
	_enemy_bullets.name = "EnemyBullets"
	add_child(_enemy_bullets)

	_player = player_scene.instantiate()
	add_child(_player)
	_player.global_position = Vector2(playfield_rect.size.x * 0.5, playfield_rect.size.y * 0.82)
	_player.set("playfield_rect", playfield_rect)
	_player.set("bullet_scene", player_bullet_scene)
	_player.set("bullet_parent", _player_bullets)

	var spawner := spawner_scene.instantiate()
	add_child(spawner)
	spawner.set("playfield_rect", playfield_rect)
	spawner.set("enemy_scene", enemy_scene)
	spawner.set("enemy_parent", _enemies)
	spawner.set("enemy_bullet_scene", enemy_bullet_scene)
	spawner.set("enemy_bullet_parent", _enemy_bullets)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := playfield_rect.grow(-8.0)
	draw_rect(r, Color(0.05, 0.05, 0.07, 1.0), true)
	draw_rect(r, Color(0.25, 0.25, 0.3, 1.0), false, 2.0)

