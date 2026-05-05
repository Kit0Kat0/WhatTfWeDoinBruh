extends Node
class_name EnemySpawner

@export var spawn_interval: float = 1.1
@export var min_spawn_interval: float = 0.35
@export var spawn_interval_decay_per_wave: float = 0.08
@export var base_enemies_per_wave: int = 6
@export var enemies_per_wave_growth: int = 2
@export var inter_wave_delay: float = 2.0
@export var boss_every_n_waves: int = 7
signal wave_started(wave_number: int, enemy_target: int, is_boss_wave: bool)

var playfield_rect: Rect2
var enemy_scene: PackedScene
var tank_enemy_scene: PackedScene
var speedster_enemy_scene: PackedScene
var boss_scene: PackedScene
var enemy_parent: Node
var enemy_bullet_scene: PackedScene
var enemy_bullet_parent: Node
@export var tank_spawn_chance: float = 0.22
@export var speedster_spawn_chance: float = 0.3

var _t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_wave: int = 0
var _spawned_this_wave: int = 0
var _alive_this_wave: int = 0
var _wave_in_progress: bool = false
var _inter_wave_t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_start_next_wave()


func _process(delta: float) -> void:
	if not _wave_in_progress:
		_inter_wave_t += delta
		if _inter_wave_t >= inter_wave_delay:
			_start_next_wave()
		return

	_t += delta
	if _spawned_this_wave < _wave_enemy_target() and _t >= _current_spawn_interval():
		_t = 0.0
		_spawn_enemy()
		return

	if _spawned_this_wave >= _wave_enemy_target() and _alive_this_wave <= 0:
		_wave_in_progress = false
		_inter_wave_t = 0.0


func _spawn_enemy() -> void:
	if enemy_parent == null:
		return

	if _is_boss_wave():
		_spawn_boss()
	else:
		_spawn_regular_variant()


func _start_next_wave() -> void:
	_current_wave += 1
	_spawned_this_wave = 0
	_alive_this_wave = 0
	_t = 0.35
	_inter_wave_t = 0.0
	_wave_in_progress = true
	wave_started.emit(_current_wave, _wave_enemy_target(), _is_boss_wave())


func _wave_enemy_target() -> int:
	if _is_boss_wave():
		return 1
	return maxi(1, base_enemies_per_wave + enemies_per_wave_growth * (_current_wave - 1))


func _current_spawn_interval() -> float:
	return maxf(min_spawn_interval, spawn_interval - spawn_interval_decay_per_wave * float(_current_wave - 1))


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


func _spawn_basic_enemy() -> void:
	if enemy_scene == null:
		return
	_spawn_enemy_from_scene(enemy_scene)


func _spawn_regular_variant() -> void:
	var roll: float = _rng.randf()
	var tank_threshold: float = clampf(tank_spawn_chance, 0.0, 1.0)
	var speedster_threshold: float = clampf(tank_spawn_chance + speedster_spawn_chance, 0.0, 1.0)
	var scene_to_use: PackedScene = enemy_scene
	if roll < tank_threshold and tank_enemy_scene != null:
		scene_to_use = tank_enemy_scene
	elif roll < speedster_threshold and speedster_enemy_scene != null:
		scene_to_use = speedster_enemy_scene

	_spawn_enemy_from_scene(scene_to_use)


func _spawn_enemy_from_scene(scene_to_use: PackedScene) -> void:
	if scene_to_use == null:
		return

	var e: EnemyBasic = scene_to_use.instantiate() as EnemyBasic
	if e == null:
		return
	enemy_parent.add_child(e)
	e.tree_exited.connect(_on_enemy_exited)
	_spawned_this_wave += 1
	_alive_this_wave += 1

	var x: float = _rng.randf_range(playfield_rect.position.x + 40.0, playfield_rect.end.x - 40.0)
	e.global_position = Vector2(x, playfield_rect.position.y - 30.0)

	e.playfield_rect = playfield_rect
	e.bullet_scene = enemy_bullet_scene
	e.bullet_parent = enemy_bullet_parent


func _spawn_boss() -> void:
	if boss_scene == null:
		return

	var b: EnemyBoss = boss_scene.instantiate() as EnemyBoss
	if b == null:
		return
	b.playfield_rect = playfield_rect
	b.bullet_scene = enemy_bullet_scene
	b.bullet_parent = enemy_bullet_parent
	enemy_parent.add_child(b)
	b.tree_exited.connect(_on_enemy_exited)
	_spawned_this_wave += 1
	_alive_this_wave += 1

	# Spawn above the playfield so the boss can slide into the top lane; offset scales with boss size.
	b.global_position = Vector2(
		playfield_rect.position.x + playfield_rect.size.x * 0.5,
		playfield_rect.position.y - b.radius - 90.0
	)

