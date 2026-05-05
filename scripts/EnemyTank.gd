extends EnemyBasic
class_name EnemyTank

@export var spread_angle_degrees: float = 14.0


func _fire_forward() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var spread_radians: float = deg_to_rad(spread_angle_degrees)
	var dirs: Array[Vector2] = [
		Vector2.DOWN,
		Vector2.DOWN.rotated(spread_radians),
		Vector2.DOWN.rotated(-spread_radians),
	]

	for d in dirs:
		var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
		if b == null:
			continue
		bullet_parent.add_child(b)
		b.global_position = global_position
		b.velocity = d * bullet_speed
		b.damage = maxi(1, bullet_damage)

	if shot_sfx_id != "":
		AudioManager.play_sfx(shot_sfx_id)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.8, 0.35, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 5.0), Color(0.15, 0.25, 0.1, 1.0))
