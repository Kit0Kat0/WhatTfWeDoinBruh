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
		b.damage = maxf(1.0, bullet_damage)

	if shot_sfx_id != "":
		AudioManager.play_sfx(shot_sfx_id)
