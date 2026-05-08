extends Node2D
class_name EnemyBossLaserLine

## Bendy hazard beam: samples the boss muzzle each physics tick (like `PlayerBeamLine`), then the whole polyline drifts downward.
## Collision uses convex segment rectangles (no single self-intersecting polygon).
const SCROLL_SPEED: float = 260.0
const MAX_ARC_LENGTH_PX: float = 300.0
const MAX_POINTS: int = 180
const HALF_WIDTH: float = 28.0
const OFFSCREEN_MARGIN: float = 120.0
const MIN_SEGMENT_LEN_PX: float = 0.75

var damage_per_tick: float = 11.0
var damage_tick_interval: float = 0.16

var _boss_wr: WeakRef
var _muzzle_local: Vector2 = Vector2(0.0, 56.0)

var _points: PackedVector2Array = PackedVector2Array()
var _done_extending: bool = false
var _dmg_cd: float = 0.0
var _sfx_cd: float = 0.0

@onready var _line: Line2D = $Line2D
@onready var _damage_area: Area2D = $DamageArea


func setup(boss: Node2D, muzzle_local_from_boss: Vector2, dmg_tick: float, tick_ivl: float) -> void:
	_boss_wr = weakref(boss)
	_muzzle_local = muzzle_local_from_boss
	damage_per_tick = dmg_tick
	damage_tick_interval = tick_ivl


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -5
	_clear_damage_collision_children()


func _clear_damage_collision_children() -> void:
	if _damage_area == null:
		return
	var existing: Array[Node] = _damage_area.get_children()
	for ch in existing:
		ch.free()


func _physics_process(delta: float) -> void:
	if _damage_area == null:
		queue_free()
		return

	var scroll: Vector2 = Vector2(0.0, SCROLL_SPEED * delta)
	var n_sz: int = _points.size()
	for i in n_sz:
		_points[i] += scroll

	var boss_node: Node2D = _boss_wr.get_ref() as Node2D
	if boss_node != null and not _done_extending:
		var muzzle_global: Vector2 = boss_node.to_global(_muzzle_local)
		_points.append(muzzle_global)
		if _polyline_length(_points) >= MAX_ARC_LENGTH_PX - 0.001:
			_done_extending = true
		elif _points.size() >= MAX_POINTS:
			_done_extending = true
	elif not _done_extending:
		_done_extending = true

	_damage_overlap_ticks(delta)
	_sync_line_and_hitbox()

	if _is_completely_off_screen():
		queue_free()


func _polyline_length(pts: PackedVector2Array) -> float:
	var L: float = 0.0
	for i in range(pts.size() - 1):
		L += pts[i].distance_to(pts[i + 1])
	return L


func _damage_overlap_ticks(delta: float) -> void:
	_dmg_cd = maxf(0.0, _dmg_cd - delta)
	_sfx_cd = maxf(0.0, _sfx_cd - delta)
	if _dmg_cd > 0.001:
		return
	if _points.is_empty():
		return

	_damage_area.force_update_transform()
	var overlapping: Array[Area2D] = _damage_area.get_overlapping_areas()
	for area in overlapping:
		if not area.is_in_group(Defs.GROUP_PLAYER):
			continue
		var pl: Player = area as Player
		if pl == null:
			continue
		pl.receive_hazard_damage(damage_per_tick)
		_dmg_cd = damage_tick_interval
		if _sfx_cd <= 0.001:
			AudioManager.play_sfx("enemy_hit")
			_sfx_cd = 0.35
		break


func _is_completely_off_screen() -> bool:
	if _points.is_empty():
		return false
	var r: Rect2 = get_viewport_rect().grow(OFFSCREEN_MARGIN)
	var aabb: Rect2 = _points_aabb().grow(maxf(2.0, HALF_WIDTH))
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


func _sync_line_and_hitbox() -> void:
	if _line != null:
		var lp: PackedVector2Array = PackedVector2Array()
		lp.resize(_points.size())
		for i in range(_points.size()):
			lp[i] = _line.to_local(_points[i])
		_line.points = lp

	if _damage_area == null:
		return

	_clear_damage_collision_children()

	if _points.is_empty():
		return

	if _points.size() == 1:
		var cs: CollisionShape2D = CollisionShape2D.new()
		var circ: CircleShape2D = CircleShape2D.new()
		circ.radius = HALF_WIDTH
		cs.shape = circ
		cs.position = _damage_area.to_local(_points[0])
		_damage_area.add_child(cs)
		return

	var local_pts: PackedVector2Array = PackedVector2Array()
	local_pts.resize(_points.size())
	for i in range(_points.size()):
		local_pts[i] = _damage_area.to_local(_points[i])

	for i in range(local_pts.size() - 1):
		var a: Vector2 = local_pts[i]
		var b: Vector2 = local_pts[i + 1]
		var seg: Vector2 = b - a
		var seg_len: float = seg.length()
		if seg_len < MIN_SEGMENT_LEN_PX:
			continue
		var mid: Vector2 = (a + b) * 0.5
		var cs_rect: CollisionShape2D = CollisionShape2D.new()
		var rect_shape: RectangleShape2D = RectangleShape2D.new()
		rect_shape.size = Vector2(seg_len, HALF_WIDTH * 2.0)
		cs_rect.shape = rect_shape
		cs_rect.position = mid
		cs_rect.rotation = seg.angle()
		_damage_area.add_child(cs_rect)
