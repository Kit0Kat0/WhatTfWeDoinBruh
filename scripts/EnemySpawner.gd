extends Node
class_name EnemySpawner

@export var base_enemies_per_wave: int = 6
@export var enemies_per_wave_growth: int = 2
@export var inter_wave_delay: float = 2.0
@export var boss_every_n_waves: int = 7
@export_range(0.0, 1.0) var boss_enemy_amount: float = 0.35

@export var tank_spawn_chance: float = 0.22
@export var speedster_spawn_chance: float = 0.3

@export var split_group_chance: float = 0.22
@export var group_size_min: int = 3
@export var group_size_max: int = 5
@export var group_gap_min: float = 0.65
@export var group_gap_max: float = 1.35
@export var per_enemy_stagger_min: float = 0.12
@export var per_enemy_stagger_max: float = 0.22
@export var along_path_separation: float = 64.0
## Path trace VFX (once per enemy group) when archetype `EnemyBasic.speed` exceeds this; trace moves at 3× that speed.
@export var path_trace_speed_threshold: float = 300.0

signal wave_started(wave_number: int, enemy_target: int, is_boss_wave: bool)
signal boss_spawned(boss: EnemyBoss)

var playfield_rect: Rect2
var enemy_scene: PackedScene
var tank_enemy_scene: PackedScene
var speedster_enemy_scene: PackedScene
var boss_scene: PackedScene
var enemy_parent: Node
var enemy_bullet_scene: PackedScene
var enemy_bullet_parent: Node

var enemy_paths_root: Node2D
var boss_paths_root: Node2D

var path_trace_scene: PackedScene
var path_trace_parent: Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_wave: int = 0
var _spawned_this_wave: int = 0
var _alive_this_wave: int = 0
var _wave_in_progress: bool = false
var _inter_wave_t: float = 0.0

var _wave_time: float = 0.0
var _spawn_events: Array[Dictionary] = []
var _event_idx: int = 0
var _enemy_scene_speed_cache: Dictionary = {}


func _variant_to_float(v: Variant, fallback: float = 0.0) -> float:
	match typeof(v):
		TYPE_FLOAT:
			return v as float
		TYPE_INT:
			return float(v as int)
		TYPE_BOOL:
			return 1.0 if (v as bool) else 0.0
		_:
			return fallback


func _variant_to_bool(v: Variant, fallback: bool = false) -> bool:
	if typeof(v) == TYPE_BOOL:
		return v as bool
	return fallback


func _get_scene_base_speed(scene_packed: PackedScene) -> float:
	if scene_packed == null:
		return 0.0
	var key: String = scene_packed.resource_path
	if _enemy_scene_speed_cache.has(key):
		return _variant_to_float(_enemy_scene_speed_cache[key], 0.0)
	var inst: EnemyBasic = scene_packed.instantiate() as EnemyBasic
	if inst == null:
		return 0.0
	var sp: float = inst.speed
	inst.queue_free()
	_enemy_scene_speed_cache[key] = sp
	return sp


func _ready() -> void:
	_rng.randomize()
	_start_next_wave()


func _process(delta: float) -> void:
	if not _wave_in_progress:
		_inter_wave_t += delta
		if _inter_wave_t >= inter_wave_delay:
			_start_next_wave()
		return

	_wave_time += delta
	while _event_idx < _spawn_events.size():
		var ev: Dictionary = _spawn_events[_event_idx]
		var t_ev: float = _variant_to_float(ev.get("t", 0.0), 0.0)
		if t_ev > _wave_time:
			break
		_execute_spawn_event(ev)
		_event_idx += 1

	if _spawned_this_wave >= _wave_enemy_target() and _alive_this_wave <= 0:
		_wave_in_progress = false
		_inter_wave_t = 0.0


func _start_next_wave() -> void:
	_current_wave += 1
	_spawned_this_wave = 0
	_alive_this_wave = 0
	_inter_wave_t = 0.0
	_wave_time = 0.0
	_event_idx = 0
	_spawn_events.clear()
	_enemy_scene_speed_cache.clear()
	_wave_in_progress = true
	_build_wave_spawn_plan()
	wave_started.emit(_current_wave, _wave_enemy_target(), _is_boss_wave())


func _non_boss_enemy_count_for_wave(wave: int) -> int:
	return maxi(1, base_enemies_per_wave + enemies_per_wave_growth * (wave - 1))


func _boss_wave_add_count() -> int:
	# Special case: first boss wave has no extra enemies.
	if _is_boss_wave() and _current_wave == boss_every_n_waves:
		return 0
	var normal_target: int = _non_boss_enemy_count_for_wave(_current_wave)
	var amount: float = clampf(boss_enemy_amount, 0.0, 1.0)
	return maxi(0, roundi(amount * float(normal_target)))


func _wave_enemy_target() -> int:
	if _is_boss_wave():
		return 1 + _boss_wave_add_count()
	return _non_boss_enemy_count_for_wave(_current_wave)


func _on_enemy_exited() -> void:
	_alive_this_wave = maxi(0, _alive_this_wave - 1)


func get_current_wave() -> int:
	return _current_wave


func get_wave_enemy_target() -> int:
	return _wave_enemy_target()


func _is_boss_wave() -> bool:
	if boss_every_n_waves <= 0:
		return false
	return _current_wave > 0 and _current_wave % boss_every_n_waves == 0


func _roll_archetype_scene() -> PackedScene:
	var roll: float = _rng.randf()
	var tank_threshold: float = clampf(tank_spawn_chance, 0.0, 1.0)
	var speedster_threshold: float = clampf(tank_spawn_chance + speedster_spawn_chance, 0.0, 1.0)
	if roll < tank_threshold and tank_enemy_scene != null:
		return tank_enemy_scene
	if roll < speedster_threshold and speedster_enemy_scene != null:
		return speedster_enemy_scene
	if enemy_scene != null:
		return enemy_scene
	return null


func _build_wave_spawn_plan() -> void:
	if _is_boss_wave():
		_spawn_events.append({"t": 0.35, "kind": "boss"})
		var adds: int = _boss_wave_add_count()
		if adds > 0:
			if enemy_paths_root == null:
				push_warning("EnemySpawner: boss wave add spawns requested but enemy_paths_root is not set.")
			else:
				_append_grunt_spawn_events(adds, 0.1)
		_sort_spawn_events()
		return

	var target: int = _wave_enemy_target()
	if enemy_paths_root == null:
		push_error("EnemySpawner: enemy_paths_root is not set.")
		return

	_append_grunt_spawn_events(target, 0.25)
	_sort_spawn_events()


func _append_grunt_spawn_events(remaining: int, first_group_t: float) -> void:
	var next_group_t: float = first_group_t
	var gs_min: int = maxi(1, group_size_min)
	var gs_max: int = maxi(gs_min, group_size_max)

	while remaining > 0:
		var scene_for_group: PackedScene = _roll_archetype_scene()
		if scene_for_group == null:
			push_error("EnemySpawner: no enemy scene assigned.")
			return

		var used_split: bool = false
		if _rng.randf() < split_group_chance and EnemyPathLibrary.has_split_sets(enemy_paths_root):
			var set_paths: Array[Path2D] = EnemyPathLibrary.pick_random_split_set(enemy_paths_root, _rng)
			if not set_paths.is_empty():
				var k: int = mini(set_paths.size(), remaining)
				k = maxi(1, k)
				var split_group_base_speed: float = _get_scene_base_speed(scene_for_group)
				var trace_split_group: bool = split_group_base_speed > path_trace_speed_threshold
				for j in range(k):
					var pth: Path2D = set_paths[j]
					var along: float = 0.0
					var start_d: float = _compute_group_start_distance(pth)
					_spawn_events.append({
						"t": next_group_t,
						"kind": "enemy",
						"scene": scene_for_group,
						"path": pth,
						"along": along,
						"start_d": start_d,
						# For split groups, create a trace for each path when the archetype is fast.
						"emit_path_trace": trace_split_group,
					})
				remaining -= k
				used_split = true
				next_group_t += _rng.randf_range(group_gap_min, group_gap_max)

		if used_split:
			continue

		var path: Path2D = EnemyPathLibrary.pick_random_enemy_path(enemy_paths_root, _rng)
		if path == null:
			push_error("EnemySpawner: no Path_Enemy_* Path2D nodes found under enemy_paths_root.")
			return

		var gs: int = mini(_rng.randi_range(gs_min, gs_max), remaining)
		gs = maxi(1, gs)
		var stagger: float = _rng.randf_range(per_enemy_stagger_min, per_enemy_stagger_max)
		var group_start_d: float = _compute_group_start_distance(path)
		var group_base_speed: float = _get_scene_base_speed(scene_for_group)
		var trace_group: bool = group_base_speed > path_trace_speed_threshold
		for j in range(gs):
			var t_spawn: float = next_group_t + float(j) * stagger
			var along: float = float(gs - 1 - j) * along_path_separation
			_spawn_events.append({
				"t": t_spawn,
				"kind": "enemy",
				"scene": scene_for_group,
				"path": path,
				"along": along,
				"start_d": group_start_d,
				"emit_path_trace": trace_group and j == 0,
			})
		remaining -= gs
		next_group_t += _rng.randf_range(group_gap_min, group_gap_max) + float(maxi(0, gs - 1)) * stagger


func _sort_spawn_events() -> void:
	_spawn_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _variant_to_float(a.get("t", 0.0), 0.0) < _variant_to_float(b.get("t", 0.0), 0.0)
	)


func _execute_spawn_event(ev: Dictionary) -> void:
	var kind: String = str(ev.get("kind", ""))
	if kind == "boss":
		_spawn_boss_with_path()
		return
	if kind == "enemy":
		var sc: PackedScene = ev.get("scene") as PackedScene
		var pth: Path2D = ev.get("path") as Path2D
		var along: float = _variant_to_float(ev.get("along", 0.0), 0.0)
		var start_d: float = _variant_to_float(ev.get("start_d", 0.0), 0.0)
		if sc != null and pth != null:
			var emit_trace: bool = _variant_to_bool(ev.get("emit_path_trace", false), false)
			_spawn_enemy_on_path(sc, pth, along, start_d, emit_trace)


func _spawn_enemy_on_path(scene_packed: PackedScene, path: Path2D, along_offset: float, start_distance: float, emit_path_trace: bool = false) -> void:
	if enemy_parent == null or scene_packed == null or path == null:
		return
	var e: EnemyBasic = scene_packed.instantiate() as EnemyBasic
	if e == null:
		return
	enemy_parent.add_child(e)
	e.tree_exited.connect(_on_enemy_exited)
	_spawned_this_wave += 1
	_alive_this_wave += 1

	e.playfield_rect = playfield_rect
	e.bullet_scene = enemy_bullet_scene
	e.bullet_parent = enemy_bullet_parent

	var motion: EnemyPathMotion = EnemyPathMotion.new()
	motion.setup(path, maxf(0.0, start_distance), along_offset)
	e.path_motion = motion
	motion.apply_to(e, e.follow_path_rotation)

	if emit_path_trace and path_trace_scene != null and path_trace_parent != null:
		var trace: PathTrace = path_trace_scene.instantiate() as PathTrace
		if trace != null:
			path_trace_parent.add_child(trace)
			trace.begin(path, maxf(0.0, start_distance), along_offset, e.speed * 3.0)


func _spawn_boss_with_path() -> void:
	if enemy_parent == null or boss_scene == null:
		return
	var path: Path2D = EnemyPathLibrary.pick_random_boss_path(boss_paths_root, _rng)
	if path == null:
		push_error("EnemySpawner: no Path_Boss_* Path2D nodes found under boss_paths_root.")
		return

	var b: EnemyBoss = boss_scene.instantiate() as EnemyBoss
	if b == null:
		return
	b.playfield_rect = playfield_rect
	b.bullet_scene = enemy_bullet_scene
	b.bullet_parent = enemy_bullet_parent

	var motion: EnemyPathMotion = EnemyPathMotion.new()
	var L: float = 0.0
	if path.curve != null:
		L = path.curve.get_baked_length()
	var start_d: float = 0.0
	if L > 1.0:
		start_d = _rng.randf_range(0.0, minf(L * 0.04, 60.0))
	motion.setup(path, start_d, 0.0)
	b.path_motion = motion

	enemy_parent.add_child(b)
	b.tree_exited.connect(_on_enemy_exited)
	_spawned_this_wave += 1
	_alive_this_wave += 1
	motion.apply_to(b, b.follow_path_rotation)
	boss_spawned.emit(b)


func _compute_group_start_distance(_path: Path2D) -> float:
	# Always spawn at the start of the path so enemies enter from offscreen.
	# With staggered spawning, later enemies naturally appear at the back of the group.
	return 0.0
