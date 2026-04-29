extends Area2D

@export var ttl := 3.0
@export var radius := 4.0

var velocity := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER_BULLET)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _process(delta: float) -> void:
	global_position += velocity * delta
	_t += delta
	if _t >= ttl:
		queue_free()
		return

	var view := get_viewport_rect()
	if global_position.y < view.position.y - 40.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.8, 1.0, 0.9, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_ENEMY):
		queue_free()

