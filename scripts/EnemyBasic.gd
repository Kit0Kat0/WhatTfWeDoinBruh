extends Area2D
class_name EnemyBasic

const OFFSCREEN_SPEED_CAP: float = 300.0

@export var hp: float = 80.0
@export var speed: float = 220.0
@export var horizontal_speed: float = 80.0
@export var shot_interval: float = 0.85
## Randomizes each gap between shots: next interval is `shot_interval` ± this fraction (keeps groups from firing in lockstep after the first volley).
@export var shot_interval_jitter_ratio: float = 0.45
@export var shot_interval_min_sec: float = 0.08
@export var bullet_speed: float = 220.0
@export var bullet_damage: float = 20.0
@export var use_wave_bullets: bool = false
@export var wave_amplitude: float = 26.0
@export var wave_frequency: float = 7.0
@export var radius: float = 14.0
@export var shot_sfx_id: String = "enemy_normal_shot"
@export var follow_path_rotation: bool = false
@export var damage_flash_duration_sec: float = 0.1

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node
var path_motion: EnemyPathMotion

var _fire_cooldown: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _damage_flash_remaining: float = 0.0


func _is_on_screen(margin: float = 24.0) -> bool:
	if playfield_rect.size == Vector2.ZERO:
		return true
	return playfield_rect.grow(margin).has_point(global_position)

func _offscreen_speed(base_speed: float) -> float:
	# Offscreen speed-up rule:
	# - doubled
	# - set to OFFSCREEN_SPEED_CAP
	# - or unchanged
	# Choose the lowest value that does not reduce current speed.
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
	_rng.randomize()
	_fire_cooldown = _rng.randf_range(0.0, shot_interval)
	queue_redraw()


func _process(delta: float) -> void:
	if _damage_flash_remaining > 0.0:
		_damage_flash_remaining = maxf(0.0, _damage_flash_remaining - delta)
		queue_redraw()

	var effective_speed: float = speed
	if not _is_on_screen():
		effective_speed = _offscreen_speed(speed)
	if path_motion != null:
		path_motion.advance(delta, effective_speed)
		path_motion.apply_to(self, follow_path_rotation)
	else:
		# Fallback if spawned without a path (should not happen in normal waves).
		global_position.y += effective_speed * delta

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		var span: float = shot_interval * shot_interval_jitter_ratio
		var next_interval: float = shot_interval + _rng.randf_range(-span, span)
		_fire_cooldown = maxf(shot_interval_min_sec, next_interval)
		if _is_on_screen():
			_fire_forward()


func _fire_forward() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return

	bullet_parent.add_child(b)
	b.global_position = global_position
	b.velocity = Vector2.DOWN * bullet_speed
	b.damage = maxf(1.0, bullet_damage)
	if use_wave_bullets:
		b.wave_axis = Vector2.RIGHT
		b.wave_amplitude = wave_amplitude
		b.wave_frequency = wave_frequency
		b.wave_phase = _rng.randf_range(0.0, TAU)
	if shot_sfx_id != "":
		AudioManager.play_sfx(shot_sfx_id)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _with_hit_flash(Color(0.95, 0.95, 0.3, 1.0)))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 4.0), _with_hit_flash(Color(0.2, 0.2, 0.25, 1.0)))


func apply_beam_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp -= amount
	if hp <= 0:
		AudioManager.play_sfx("enemy_kill")
		_try_spawn_weapon_pickup_drop(false)
		queue_free()
	else:
		_damage_flash_remaining = damage_flash_duration_sec
		queue_redraw()
		AudioManager.play_sfx("enemy_hit")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		var dmg: float = 10.0
		var pb: BulletPlayer = area as BulletPlayer
		if pb != null:
			dmg = maxf(1.0, pb.damage)
		hp -= dmg
		if hp <= 0:
			AudioManager.play_sfx("enemy_kill")
			_try_spawn_weapon_pickup_drop(false)
			queue_free()
		else:
			_damage_flash_remaining = damage_flash_duration_sec
			queue_redraw()
			AudioManager.play_sfx("enemy_hit")


func _try_spawn_weapon_pickup_drop(from_boss: bool) -> void:
	for n in get_tree().get_nodes_in_group("game_controller"):
		if n.has_method("try_spawn_weapon_pickup"):
			n.call("try_spawn_weapon_pickup", global_position, from_boss)
			return
