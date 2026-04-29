extends Area2D
class_name BulletEnemy

@export var ttl: float = 6.0
@export var radius: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY_BULLET)
	queue_redraw()


func _process(delta: float) -> void:
	global_position += velocity * delta
	_t += delta
	if _t >= ttl:
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if not view.grow(120.0).has_point(global_position):
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.55, 0.2, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 2.0), Color(0.95, 0.2, 0.35, 1.0))

