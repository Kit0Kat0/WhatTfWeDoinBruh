extends Control
class_name HudHeatMapIndicators

@export var enabled: bool = false
@export var inset_px: float = 22.0
@export var arrow_len_px: float = 22.0
@export var arrow_w_px: float = 14.0
@export var max_indicators: int = 18

@export var enemy_arrow_color: Color = Color(1.0, 0.35, 0.2, 0.95)
@export var boss_arrow_color: Color = Color(1.0, 0.9, 0.25, 0.98)


func _process(_delta: float) -> void:
	# Indicators depend on moving world positions.
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vr: Rect2 = vp.get_visible_rect()
	if vr.size == Vector2.ZERO:
		return

	var inset: float = maxf(0.0, inset_px)
	var inner: Rect2 = vr.grow(-inset)
	if inner.size.x <= 4.0 or inner.size.y <= 4.0:
		return

	var enemies: Array[Node] = get_tree().get_nodes_in_group(Defs.GROUP_ENEMY)
	if enemies.is_empty():
		return

	var cam_xf: Transform2D = vp.get_canvas_transform()
	var center: Vector2 = inner.get_center()

	var drawn: int = 0
	for n in enemies:
		if drawn >= maxi(1, max_indicators):
			break
		var e2: Node2D = n as Node2D
		if e2 == null:
			continue
		# World -> screen-space
		var sp: Vector2 = cam_xf * e2.global_position
		if inner.has_point(sp):
			continue

		var d: Vector2 = sp - center
		if d.length_squared() < 0.001:
			continue
		d = d.normalized()

		# Place exactly where the center→enemy ray intersects the inner rectangle perimeter.
		var edge_pos: Vector2 = _ray_rect_intersection(center, d, inner)

		var is_boss: bool = e2 is EnemyBoss
		var col: Color = boss_arrow_color if is_boss else enemy_arrow_color

		_draw_arrow(edge_pos, d.angle(), col)
		drawn += 1


func _draw_arrow(pos: Vector2, angle: float, col: Color) -> void:
	var L: float = maxf(6.0, arrow_len_px)
	var W: float = maxf(4.0, arrow_w_px)
	var dir: Vector2 = Vector2.RIGHT.rotated(angle)
	var right: Vector2 = dir.rotated(PI * 0.5)

	var tip: Vector2 = pos + dir * L
	var base: Vector2 = pos - dir * (L * 0.55)
	var a: Vector2 = base + right * (W * 0.5)
	var b: Vector2 = base - right * (W * 0.5)

	draw_colored_polygon(PackedVector2Array([tip, a, b]), col)


func _ray_rect_intersection(origin: Vector2, dir_norm: Vector2, rect: Rect2) -> Vector2:
	# Assumes dir_norm is normalized and rect has positive size.
	# Finds the first positive intersection of origin + t*dir with the rectangle perimeter.
	var best_t: float = INF
	var best_p: Vector2 = origin

	# Vertical sides.
	if absf(dir_norm.x) > 0.000001:
		var t_left: float = (rect.position.x - origin.x) / dir_norm.x
		if t_left > 0.0:
			var y_left: float = origin.y + dir_norm.y * t_left
			if y_left >= rect.position.y - 0.001 and y_left <= rect.end.y + 0.001 and t_left < best_t:
				best_t = t_left
				best_p = Vector2(rect.position.x, clampf(y_left, rect.position.y, rect.end.y))

		var t_right: float = (rect.end.x - origin.x) / dir_norm.x
		if t_right > 0.0:
			var y_right: float = origin.y + dir_norm.y * t_right
			if y_right >= rect.position.y - 0.001 and y_right <= rect.end.y + 0.001 and t_right < best_t:
				best_t = t_right
				best_p = Vector2(rect.end.x, clampf(y_right, rect.position.y, rect.end.y))

	# Horizontal sides.
	if absf(dir_norm.y) > 0.000001:
		var t_top: float = (rect.position.y - origin.y) / dir_norm.y
		if t_top > 0.0:
			var x_top: float = origin.x + dir_norm.x * t_top
			if x_top >= rect.position.x - 0.001 and x_top <= rect.end.x + 0.001 and t_top < best_t:
				best_t = t_top
				best_p = Vector2(clampf(x_top, rect.position.x, rect.end.x), rect.position.y)

		var t_bottom: float = (rect.end.y - origin.y) / dir_norm.y
		if t_bottom > 0.0:
			var x_bottom: float = origin.x + dir_norm.x * t_bottom
			if x_bottom >= rect.position.x - 0.001 and x_bottom <= rect.end.x + 0.001 and t_bottom < best_t:
				best_t = t_bottom
				best_p = Vector2(clampf(x_bottom, rect.position.x, rect.end.x), rect.end.y)

	return best_p

