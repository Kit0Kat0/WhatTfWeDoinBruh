extends Area2D
class_name BulletPlayer

@export var ttl: float = 3.0
@export var radius: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER_BULLET)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += velocity * delta
	_t += delta
	if _t >= ttl:
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if global_position.y < view.position.y - 40.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_ENEMY):
		queue_free()

