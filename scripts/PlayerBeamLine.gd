extends Node2D
class_name PlayerBeamLine

const MAX_ARC_LENGTH_PX: float = 250.0
const DPS: float = 100.0
const SCROLL_SPEED: float = 900.0
const BEAM_HALF_WIDTH: float = 8.0
const OFFSCREEN_MARGIN: float = 64.0

var _player_wr: WeakRef
## Combined offset from player origin to muzzle (same frame as `Player._spawn_player_bullet`).
var _muzzle_offset_from_player: Vector2 = Vector2.ZERO

var _points: PackedVector2Array = PackedVector2Array()
var _done_extending: bool = false

@onready var _line: Line2D = $Line2D
@onready var _damage_area: Area2D = $DamageArea
@onready var _collision_poly: CollisionPolygon2D = $DamageArea/CollisionPolygon2D


func setup(player: Player, muzzle_offset_from_player: Vector2) -> void:
	_player_wr = weakref(player)
	_muzzle_offset_from_player = muzzle_offset_from_player


func _physics_process(delta: float) -> void:
	var scroll: Vector2 = Vector2(0.0, -SCROLL_SPEED) * delta
	var n: int = _points.size()
	for i in n:
		_points[i] += scroll

	var p: Player = _player_wr.get_ref() as Player
	if p != null and not _done_extending:
		var gun_global: Vector2 = p.global_position + _muzzle_offset_from_player
		_points.append(gun_global)
		# IMPORTANT: stop growing once we hit 100px; do NOT keep appending+trimming,
		# or the beam will keep "sticking" to the player.
		if _polyline_length(_points) >= MAX_ARC_LENGTH_PX - 0.001:
			_done_extending = true
	elif not _done_extending:
		_done_extending = true

	_sync_line_and_hitbox()
	_apply_dps(delta)
	if _is_completely_off_screen():
		queue_free()


func _polyline_length(pts: PackedVector2Array) -> float:
	var L: float = 0.0
	for i in range(pts.size() - 1):
		L += pts[i].distance_to(pts[i + 1])
	return L


func _sync_line_and_hitbox() -> void:
	if _line != null:
		var lp: PackedVector2Array = PackedVector2Array()
		lp.resize(_points.size())
		for i in range(_points.size()):
			lp[i] = _line.to_local(_points[i])
		_line.points = lp

	if _collision_poly == null:
		return

	if _points.size() < 2:
		if _points.size() == 1:
			var c: Vector2 = _damage_area.to_local(_points[0])
			var r: float = BEAM_HALF_WIDTH
			_collision_poly.polygon = PackedVector2Array([
				c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r),
			])
		else:
			_collision_poly.polygon = PackedVector2Array()
		return

	var local_pts: PackedVector2Array = PackedVector2Array()
	local_pts.resize(_points.size())
	for i in range(_points.size()):
		local_pts[i] = _damage_area.to_local(_points[i])

	_collision_poly.polygon = _build_thick_polyline_polygon(local_pts, BEAM_HALF_WIDTH)


func _build_thick_polyline_polygon(pts: PackedVector2Array, half_width: float) -> PackedVector2Array:
	# Builds a simple non-rounded thick polyline polygon:
	# left side forward + right side backward.
	if pts.size() < 2:
		return PackedVector2Array()

	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	left.resize(pts.size())
	right.resize(pts.size())

	for i in range(pts.size()):
		var prev: Vector2 = pts[maxi(0, i - 1)]
		var cur: Vector2 = pts[i]
		var next: Vector2 = pts[mini(pts.size() - 1, i + 1)]

		var dir: Vector2 = next - prev
		if dir.length_squared() < 0.0001:
			dir = (next - cur)
		if dir.length_squared() < 0.0001:
			dir = (cur - prev)
		if dir.length_squared() < 0.0001:
			dir = Vector2.UP

		var n: Vector2 = Vector2(-dir.y, dir.x).normalized() * half_width
		left[i] = cur + n
		right[i] = cur - n

	var poly: PackedVector2Array = PackedVector2Array()
	poly.resize(left.size() + right.size())
	for i in range(left.size()):
		poly[i] = left[i]
	for i in range(right.size()):
		poly[left.size() + i] = right[right.size() - 1 - i]
	return poly


func _apply_dps(delta: float) -> void:
	if _damage_area == null:
		return
	_damage_area.force_update_transform()
	var overlapping: Array[Area2D] = _damage_area.get_overlapping_areas()
	for area in overlapping:
		if not area.is_in_group(Defs.GROUP_ENEMY):
			continue
		if not is_instance_valid(area):
			continue
		_apply_damage(area, DPS * delta)


func _apply_damage(area: Area2D, amount: float) -> void:
	if amount <= 0.0:
		return
	if area is EnemyBoss:
		(area as EnemyBoss).apply_beam_damage(amount)
	elif area is EnemyBasic:
		(area as EnemyBasic).apply_beam_damage(amount)


func _is_completely_off_screen() -> bool:
	if _points.is_empty():
		return false
	var r: Rect2 = get_viewport_rect().grow(OFFSCREEN_MARGIN)
	var aabb: Rect2 = _points_aabb().grow(maxf(2.0, BEAM_HALF_WIDTH))
	return not r.intersects(aabb)


func _points_aabb() -> Rect2:
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	for p in _points:
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x)
		max_y = maxf(max_y, p.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
