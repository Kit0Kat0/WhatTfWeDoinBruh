extends RefCounted
class_name EnemyPathMotion

## Advances an enemy along a Path2D's Curve2D by arc length; loops at curve end.

var path_node: Path2D
var _distance: float = 0.0
var _along_offset: float = 0.0


func setup(p: Path2D, start_distance: float = 0.0, along_offset: float = 0.0) -> void:
	path_node = p
	_distance = start_distance
	_along_offset = along_offset


func get_baked_length() -> float:
	if path_node == null or path_node.curve == null:
		return 0.0
	return path_node.curve.get_baked_length()


func advance(delta: float, speed: float) -> void:
	var L: float = get_baked_length()
	if L <= 0.0:
		return
	_distance += speed * delta
	while _distance >= L:
		_distance -= L


## Adds arc length without wrapping (used by one-shot path traces). Position sampling still wraps via `apply_to`.
func advance_no_wrap(delta: float, speed: float) -> void:
	if get_baked_length() <= 0.0:
		return
	_distance += speed * delta


func apply_to(enemy: Node2D, follow_rotation: bool) -> void:
	if path_node == null or path_node.curve == null:
		return
	var L: float = path_node.curve.get_baked_length()
	if L <= 0.0:
		return
	var d: float = fposmod(_distance + _along_offset, L)
	var local_pos: Vector2 = path_node.curve.sample_baked(d)
	enemy.global_position = path_node.to_global(local_pos)
	if follow_rotation:
		var d2: float = minf(d + 2.0, L)
		var local2: Vector2 = path_node.curve.sample_baked(d2)
		var tangent: Vector2 = path_node.to_global(local2) - enemy.global_position
		if tangent.length_squared() > 0.0001:
			enemy.rotation = tangent.angle()
