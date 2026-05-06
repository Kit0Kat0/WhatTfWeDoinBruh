extends EnemyBasic
class_name EnemySpeedster


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _with_hit_flash(Color(0.9, 0.5, 1.0, 1.0)))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 3.0), _with_hit_flash(Color(0.28, 0.1, 0.32, 1.0)))
