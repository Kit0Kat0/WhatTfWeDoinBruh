extends Area2D
class_name EnemyBoss

const OFFSCREEN_SPEED_CAP: float = EnemyBasic.OFFSCREEN_SPEED_CAP

signal health_changed(current_hp: float, max_hp: float)

@export var max_hp: float = 1600.0
var hp: float = 1600.0
@export var path_follow_speed: float = 190.0
@export var radius: float = 78.0
@export var shot_interval: float = 0.35
@export var shot_interval_jitter_ratio: float = 0.35
@export var shot_interval_min_sec: float = 0.1
## Straight-down volleys (normal-style): speed + damage.
@export var normal_bullet_speed: float = 280.0
@export var normal_bullet_damage: float = 20.0
## Three-way spread volleys (tanky-style): slower, harder-hitting.
@export var tank_bullet_speed: float = 200.0
@export var tank_bullet_damage: float = 30.0
@export var tank_spread_angle_degrees: float = 14.0
@export var follow_path_rotation: bool = false
@export var damage_flash_duration_sec: float = 0.1

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node
var path_motion: EnemyPathMotion

var _fire_cooldown: float = 0.0
var _pattern_volley: int = 0
var _damage_flash_remaining: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _is_on_screen(margin: float = 24.0) -> bool:
	if playfield_rect.size == Vector2.ZERO:
		return true
	return playfield_rect.grow(margin).has_point(global_position)

func _offscreen_speed(base_speed: float) -> float:
	var boosted: float = minf(base_speed * 2.0, OFFSCREEN_SPEED_CAP)
	return base_speed if boosted < base_speed else boosted


func _with_hit_flash(c: Color) -> Color:
	if _damage_flash_remaining <= 0.0 or damage_flash_duration_sec <= 0.0:
		return c
	var t: float = clampf(_damage_flash_remaining / damage_flash_duration_sec, 0.0, 1.0)
	return c.lerp(Color(1.0, 1.0, 1.0, c.a), t)


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	hp = max_hp
	_rng.randomize()
	_fire_cooldown = _rng.randf_range(0.0, shot_interval)
	_sync_collision_radius()
	queue_redraw()
	health_changed.emit(hp, max_hp)


func _sync_collision_radius() -> void:
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius


func _process(delta: float) -> void:
	if _damage_flash_remaining > 0.0:
		_damage_flash_remaining = maxf(0.0, _damage_flash_remaining - delta)
		queue_redraw()

	var effective_speed: float = path_follow_speed
	if not _is_on_screen(48.0):
		effective_speed = _offscreen_speed(path_follow_speed)
	if path_motion != null:
		path_motion.advance(delta, effective_speed)
		path_motion.apply_to(self, follow_path_rotation)

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		var span: float = shot_interval * shot_interval_jitter_ratio
		var next_interval: float = shot_interval + _rng.randf_range(-span, span)
		_fire_cooldown = maxf(shot_interval_min_sec, next_interval)
		if _is_on_screen(48.0):
			_fire_mixed_pattern_volley()


func _fire_mixed_pattern_volley() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	if _pattern_volley % 2 == 0:
		_fire_normal_forward()
	else:
		_fire_tanky_spread()
	_pattern_volley += 1
	AudioManager.play_sfx("boss_shot")


func _fire_normal_forward() -> void:
	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0.0, radius * 0.35)
	b.velocity = Vector2.DOWN * normal_bullet_speed
	b.damage = maxf(1.0, normal_bullet_damage)


func _fire_tanky_spread() -> void:
	var spread_radians: float = deg_to_rad(tank_spread_angle_degrees)
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
		b.global_position = global_position + d * (radius * 0.35)
		b.velocity = d * tank_bullet_speed
		b.damage = maxf(1.0, tank_bullet_damage)


func _draw() -> void:
	var rim: float = maxf(10.0, radius * 0.22)
	var core: float = maxf(6.0, radius * 0.11)
	draw_circle(Vector2.ZERO, radius, _with_hit_flash(Color(0.85, 0.2, 0.25, 1.0)))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - rim), _with_hit_flash(Color(0.25, 0.05, 0.08, 1.0)))
	draw_circle(Vector2.ZERO, core, _with_hit_flash(Color(1.0, 0.92, 0.35, 1.0)))


func apply_beam_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		health_changed.emit(hp, max_hp)
		AudioManager.play_sfx("boss_death")
		AudioManager.duck_music(6.0, 0.3, 0.7)
		for n in get_tree().get_nodes_in_group("game_controller"):
			if n.has_method("try_spawn_weapon_pickup"):
				n.call("try_spawn_weapon_pickup", global_position, true)
				break
		queue_free()
	else:
		health_changed.emit(hp, max_hp)
		_damage_flash_remaining = damage_flash_duration_sec
		queue_redraw()
		if int(hp) % 50 == 0:
			AudioManager.play_sfx("boss_hit")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		var dmg: float = 10.0
		var pb: BulletPlayer = area as BulletPlayer
		if pb != null:
			dmg = maxf(1.0, pb.damage)
		hp -= dmg
		if hp <= 0:
			hp = 0
			health_changed.emit(hp, max_hp)
			AudioManager.play_sfx("boss_death")
			AudioManager.duck_music(6.0, 0.3, 0.7)
			for n in get_tree().get_nodes_in_group("game_controller"):
				if n.has_method("try_spawn_weapon_pickup"):
					n.call("try_spawn_weapon_pickup", global_position, true)
					break
			queue_free()
		else:
			health_changed.emit(hp, max_hp)
			_damage_flash_remaining = damage_flash_duration_sec
			queue_redraw()
			if int(hp) % 50 == 0:
				AudioManager.play_sfx("boss_hit")
