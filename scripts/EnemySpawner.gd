extends Node
class_name EnemySpawner

@export var spawn_interval: float = 1.1

var playfield_rect: Rect2
var enemy_scene: PackedScene
var enemy_parent: Node
var enemy_bullet_scene: PackedScene
var enemy_bullet_parent: Node

var _t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_t = 0.35


func _process(delta: float) -> void:
	_t += delta
	if _t < spawn_interval:
		return
	_t = 0.0
	_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null or enemy_parent == null:
		return

	var e: EnemyBasic = enemy_scene.instantiate() as EnemyBasic
	if e == null:
		return
	enemy_parent.add_child(e)

	var x: float = _rng.randf_range(playfield_rect.position.x + 40.0, playfield_rect.end.x - 40.0)
	e.global_position = Vector2(x, playfield_rect.position.y - 30.0)

	e.playfield_rect = playfield_rect
	e.bullet_scene = enemy_bullet_scene
	e.bullet_parent = enemy_bullet_parent

