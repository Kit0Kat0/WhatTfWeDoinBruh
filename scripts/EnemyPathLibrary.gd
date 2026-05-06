extends RefCounted
class_name EnemyPathLibrary

const PREFIX_ENEMY: String = "Path_Enemy_"
const PREFIX_BOSS: String = "Path_Boss_"
const PREFIX_SPLIT: String = "Path_SplitSet"

static func _variant_to_int(v: Variant, fallback: int = 0) -> int:
	match typeof(v):
		TYPE_INT:
			return v as int
		TYPE_FLOAT:
			return int(v as float)
		TYPE_BOOL:
			return 1 if (v as bool) else 0
		_:
			return fallback


static func configure_paths(enemy_root: Node2D, boss_root: Node2D, rect: Rect2) -> void:
	if enemy_root != null:
		var idx_enemy: int = 0
		var idx_split: Dictionary = {}
		for c: Node in enemy_root.get_children():
			var p: Path2D = c as Path2D
			if p == null:
				continue
			if p.name.begins_with(PREFIX_ENEMY):
				p.curve = _build_enemy_path(rect, idx_enemy)
				idx_enemy += 1
			elif p.name.begins_with(PREFIX_SPLIT):
				var gk: String = _split_group_key(str(p.name))
				if gk.is_empty():
					continue
				var raw_v: Variant = idx_split.get(gk, 0)
				var v: int = _variant_to_int(raw_v, 0)
				p.curve = _build_split_path(rect, gk, v)
				idx_split[gk] = v + 1
	if boss_root != null:
		var bidx: int = 0
		for c: Node in boss_root.get_children():
			var p: Path2D = c as Path2D
			if p == null:
				continue
			if p.name.begins_with(PREFIX_BOSS):
				p.curve = _build_boss_path(rect, bidx)
				bidx += 1


static func list_enemy_paths(enemy_root: Node2D) -> Array[Path2D]:
	var out: Array[Path2D] = []
	if enemy_root == null:
		return out
	for c: Node in enemy_root.get_children():
		var p: Path2D = c as Path2D
		if p == null:
			continue
		if str(p.name).begins_with(PREFIX_ENEMY):
			out.append(p)
	return out


static func list_boss_paths(boss_root: Node2D) -> Array[Path2D]:
	var out: Array[Path2D] = []
	if boss_root == null:
		return out
	for c: Node in boss_root.get_children():
		var p: Path2D = c as Path2D
		if p == null:
			continue
		if str(p.name).begins_with(PREFIX_BOSS):
			out.append(p)
	return out


static func collect_split_sets(enemy_root: Node2D) -> Dictionary:
	# group_key -> Array[Path2D] sorted by numeric suffix
	var buckets: Dictionary = {}
	if enemy_root == null:
		return buckets
	for c: Node in enemy_root.get_children():
		var p: Path2D = c as Path2D
		if p == null:
			continue
		if not str(p.name).begins_with(PREFIX_SPLIT):
			continue
		var gk: String = _split_group_key(str(p.name))
		if gk.is_empty():
			continue
		if not buckets.has(gk):
			buckets[gk] = [] as Array
		(buckets[gk] as Array).append(p)
	for k_raw: Variant in buckets.keys():
		var k: String = str(k_raw)
		var arr: Array = buckets.get(k, []) as Array
		arr.sort_custom(func(a: Node, b: Node) -> bool:
			return _split_suffix_num(str(a.name)) < _split_suffix_num(str(b.name))
		)
	return buckets


static func pick_random_enemy_path(enemy_root: Node2D, rng: RandomNumberGenerator) -> Path2D:
	var paths: Array[Path2D] = list_enemy_paths(enemy_root)
	if paths.is_empty():
		return null
	return paths[rng.randi_range(0, paths.size() - 1)]


static func pick_random_boss_path(boss_root: Node2D, rng: RandomNumberGenerator) -> Path2D:
	var paths: Array[Path2D] = list_boss_paths(boss_root)
	if paths.is_empty():
		return null
	return paths[rng.randi_range(0, paths.size() - 1)]


static func pick_random_split_set(enemy_root: Node2D, rng: RandomNumberGenerator) -> Array[Path2D]:
	var empty: Array[Path2D] = []
	var sets: Dictionary = collect_split_sets(enemy_root)
	if sets.is_empty():
		return empty
	var keys: Array = sets.keys()
	var gk: String = str(keys[rng.randi_range(0, keys.size() - 1)])
	var raw: Variant = sets.get(gk, [])
	if raw is Array:
		var out: Array[Path2D] = []
		for x: Variant in raw as Array:
			var pp: Path2D = x as Path2D
			if pp != null:
				out.append(pp)
		return out
	return empty


static func has_split_sets(enemy_root: Node2D) -> bool:
	return not collect_split_sets(enemy_root).is_empty()


static func _split_group_key(path_name: String) -> String:
	var i: int = path_name.rfind("_")
	if i <= 0:
		return ""
	var suf: String = path_name.substr(i + 1)
	if not suf.is_valid_int():
		return ""
	return path_name.substr(0, i)


static func _split_suffix_num(path_name: String) -> int:
	var i: int = path_name.rfind("_")
	if i <= 0:
		return 0
	var suf: String = path_name.substr(i + 1)
	if suf.is_valid_int():
		return int(suf)
	return 0


static func _build_enemy_path(rect: Rect2, variant: int) -> Curve2D:
	var c: Curve2D = Curve2D.new()
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var m: float = 72.0
	match variant % 6:
		0:
			_add_bezier_chain(c, [
				Vector2(ox + w * 0.15, oy - m * 1.25),
				Vector2(ox + w * 0.35, oy + h * 0.22),
				Vector2(ox + w * 0.72, oy + h * 0.45),
				Vector2(ox + w * 0.55, oy + h + m * 0.85),
				Vector2(ox + w * 0.2, oy + h * 0.55),
				Vector2(ox + w * 0.12, oy - m * 1.05),
			])
		1:
			_add_bezier_chain(c, [
				Vector2(ox + w + m * 0.6, oy - m * 1.25),
				Vector2(ox + w * 0.78, oy + h * 0.18),
				Vector2(ox + w * 0.42, oy + h * 0.38),
				Vector2(ox + w * 0.18, oy + h * 0.62),
				Vector2(ox - m * 0.5, oy + h * 0.35),
				Vector2(ox + w * 0.88, oy - m * 1.05),
			])
		2:
			_add_bezier_chain(c, [
				Vector2(ox - m * 0.55, oy - m * 1.25),
				Vector2(ox + w * 0.28, oy + h * 0.12),
				Vector2(ox + w * 0.62, oy + h * 0.28),
				Vector2(ox + w * 0.5, oy + h * 0.72),
				Vector2(ox + w * 0.22, oy + h + m),
				Vector2(ox + w * 0.08, oy - m * 1.05),
			])
		3:
			_add_bezier_chain(c, [
				Vector2(ox + w * 0.5, oy - m * 1.35),
				Vector2(ox + w * 0.62, oy + h * 0.2),
				Vector2(ox + w * 0.22, oy + h * 0.35),
				Vector2(ox + w * 0.78, oy + h * 0.58),
				Vector2(ox + w * 0.35, oy + h * 0.88),
				Vector2(ox + w * 0.48, oy - m * 1.05),
			])
		4:
			_add_bezier_chain(c, [
				Vector2(ox + w * 0.82, oy - m * 1.25),
				Vector2(ox + w * 0.35, oy + h * 0.25),
				Vector2(ox + w * 0.15, oy + h * 0.5),
				Vector2(ox + w * 0.65, oy + h * 0.68),
				Vector2(ox + w + m * 0.35, oy + h * 0.42),
				Vector2(ox + w * 0.72, oy - m * 1.05),
			])
		_:
			_add_bezier_chain(c, [
				Vector2(ox + w * 0.25, oy - m * 1.25),
				Vector2(ox + w * 0.7, oy + h * 0.15),
				Vector2(ox + w * 0.55, oy + h * 0.42),
				Vector2(ox + w * 0.18, oy + h * 0.65),
				Vector2(ox - m * 0.35, oy + h * 0.78),
				Vector2(ox + w * 0.4, oy - m * 1.05),
			])
	return c


static func _build_split_path(rect: Rect2, _group_key: String, index_in_group: int) -> Curve2D:
	var c: Curve2D = Curve2D.new()
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var m: float = 64.0
	match index_in_group % 3:
		0:
			_add_bezier_chain(c, [
				Vector2(ox - m * 0.45, oy - m * 1.2),
				Vector2(ox + w * 0.22, oy + h * 0.2),
				Vector2(ox + w * 0.38, oy + h * 0.55),
				Vector2(ox + w * 0.12, oy + h + m * 0.7),
				Vector2(ox + w * 0.55, oy + h * 0.35),
				Vector2(ox + w * 0.08, oy - m * 1.05),
			])
		1:
			_add_bezier_chain(c, [
				Vector2(ox + w * 0.5, oy - m * 1.3),
				Vector2(ox + w * 0.45, oy + h * 0.28),
				Vector2(ox + w * 0.52, oy + h * 0.62),
				Vector2(ox + w * 0.48, oy + h + m * 0.9),
				Vector2(ox + w * 0.5, oy + h * 0.18),
				Vector2(ox + w * 0.5, oy - m * 1.05),
			])
		_:
			_add_bezier_chain(c, [
				Vector2(ox + w + m * 0.5, oy - m * 1.2),
				Vector2(ox + w * 0.78, oy + h * 0.22),
				Vector2(ox + w * 0.62, oy + h * 0.52),
				Vector2(ox + w * 0.88, oy + h + m * 0.65),
				Vector2(ox + w * 0.42, oy + h * 0.4),
				Vector2(ox + w * 0.92, oy - m * 1.05),
			])
	return c


static func _build_boss_path(rect: Rect2, variant: int) -> Curve2D:
	var c: Curve2D = Curve2D.new()
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var margin: float = 100.0
	var cx: float = ox + w * 0.5
	var cy: float = oy + h * (0.27 if variant % 2 == 0 else 0.33)
	var rx: float = maxf(80.0, (w - margin * 2.0) * 0.31)
	var ry: float = maxf(48.0, (h - margin * 2.0) * 0.15)
	var entry: Vector2 = Vector2(cx, oy + margin * 0.55)
	# Oval loop; phase shift per variant so two boss paths feel different.
	var phase: float = 0.0 if variant % 2 == 0 else PI * 0.35
	var steps: int = 36
	var first_loop: Vector2 = Vector2(cx + cos(-PI * 0.5 + phase) * rx, cy + sin(-PI * 0.5 + phase) * ry)
	c.add_point(entry, Vector2.ZERO, Vector2(0.0, 90.0))
	c.add_point(first_loop, Vector2(0.0, -ry * 0.45), Vector2(-rx * 0.4, 0.0))
	for i in range(1, steps + 1):
		var t: float = TAU * float(i) / float(steps)
		var lp: Vector2 = Vector2(cx + cos(t - PI * 0.5 + phase) * rx, cy + sin(t - PI * 0.5 + phase) * ry)
		c.add_point(lp, Vector2.ZERO, Vector2.ZERO)
	c.add_point(first_loop, Vector2.ZERO, Vector2(0.0, -ry * 0.35))
	c.add_point(entry, Vector2.ZERO, Vector2.ZERO)
	return c


static func _add_bezier_chain(c: Curve2D, pts: Array) -> void:
	if pts.is_empty():
		return
	c.clear_points()
	for i in range(pts.size()):
		var p: Vector2 = pts[i] as Vector2
		var cin: Vector2 = Vector2.ZERO
		var cout: Vector2 = Vector2.ZERO
		if i > 0:
			var prev: Vector2 = pts[i - 1] as Vector2
			cout = (p - prev) * 0.42
		if i < pts.size() - 1:
			var nxt: Vector2 = pts[i + 1] as Vector2
			cin = (p - nxt) * 0.42
		c.add_point(p, cin, cout)
