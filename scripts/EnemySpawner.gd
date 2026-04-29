extends Node

@export var spawn_interval := 1.1

var playfield_rect: Rect2
var enemy_scene: PackedScene
var enemy_parent: Node
var enemy_bullet_scene: PackedScene
var enemy_bullet_parent: Node

var _t := 0.0
var _rng := RandomNumberGenerator.new()


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

	var e := enemy_scene.instantiate()
	enemy_parent.add_child(e)

	var x := _rng.randf_range(playfield_rect.position.x + 40.0, playfield_rect.end.x - 40.0)
	e.global_position = Vector2(x, playfield_rect.position.y - 30.0)

	if e.has_method("set"):
		e.set("playfield_rect", playfield_rect)
		e.set("bullet_scene", enemy_bullet_scene)
		e.set("bullet_parent", enemy_bullet_parent)

