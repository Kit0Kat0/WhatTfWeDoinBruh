extends Area2D

@export var hp := 8
@export var speed := 110.0
@export var radius := 14.0

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var _shot_t := 0.0
var _shot_interval := 0.85
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	_rng.randomize()
	_shot_t = _rng.randf_range(0.0, _shot_interval)
	queue_redraw()


func _process(delta: float) -> void:
	global_position.y += speed * delta
	_shot_t += delta

	if _shot_t >= _shot_interval:
		_shot_t = 0.0
		_fire_ring()

	if playfield_rect.size != Vector2.ZERO and global_position.y > playfield_rect.end.y + 60.0:
		queue_free()


func _fire_ring() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var count := 12
	var base_angle := _rng.randf_range(0.0, TAU)
	for i in count:
		var a := base_angle + (TAU * float(i) / float(count))
		var v := Vector2.RIGHT.rotated(a) * 220.0
		var b := bullet_scene.instantiate()
		bullet_parent.add_child(b)
		b.global_position = global_position
		b.set("velocity", v)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.95, 0.3, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 4.0), Color(0.2, 0.2, 0.25, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		hp -= 1
		if hp <= 0:
			queue_free()

