extends Area2D
class_name BulletEnemy

@export var ttl: float = 6.0
@export var radius: float = 5.0
@export var fade_out_time: float = 0.25
@export var scale_factor: float = 0.65
@export var spin_degrees_per_sec: float = 540.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var wave_axis: Vector2 = Vector2.ZERO
var wave_amplitude: float = 0.0
var wave_frequency: float = 0.0
var wave_phase: float = 0.0
var _t: float = 0.0
var _trail: CPUParticles2D
var _trail_detached: bool = false
@onready var _sprite: CanvasItem = get_node_or_null(^"Sprite") as CanvasItem
var _trail_base_color: Color = Color(1.0, 0.25, 0.3, 0.65)


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY_BULLET)
	_apply_scale()
	_create_trail(_trail_base_color)


func _apply_scale() -> void:
	var s: float = maxf(0.05, scale_factor)
	var spr_a: Sprite2D = get_node_or_null(^"Sprite") as Sprite2D
	if spr_a != null:
		spr_a.scale = Vector2(s, s)
	var spr_b: Sprite2D = get_node_or_null(^"Sprite2D") as Sprite2D
	if spr_b != null:
		spr_b.scale = Vector2(s, s)
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius * s


func _create_trail(c: Color) -> void:
	_trail = CPUParticles2D.new()
	add_child(_trail)
	# Draw behind the bullet (simpler than show_behind_parent).
	_trail.z_index = -1
	_trail.emitting = true
	_trail.one_shot = false
	_trail.amount = 18
	_trail.lifetime = 0.32
	_trail.explosiveness = 0.0
	_trail.randomness = 0.8
	_trail.local_coords = false
	# Emit from a circle around the bullet so it doesn't form a rigid line.
	_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	var effective_r: float = radius * maxf(0.05, scale_factor)
	_trail.emission_sphere_radius = maxf(1.0, effective_r * 3.0)
	_trail.gravity = Vector2.ZERO
	_trail.initial_velocity_min = 10.0
	_trail.initial_velocity_max = 26.0
	_trail.scale_amount_min = 0.8
	_trail.scale_amount_max = 1.9
	_trail.spread = 120.0
	_trail.direction = (-velocity.normalized()) if velocity.length_squared() > 0.0001 else Vector2.UP
	_trail.color = c
	_trail.color_ramp = _make_alpha_ramp(c, 1.0)


func _make_alpha_ramp(c: Color, alpha_mult: float) -> Gradient:
	var a: float = clampf(alpha_mult, 0.0, 1.0)
	var grad: Gradient = Gradient.new()
	# Gradients always keep at least 2 points; normalize then edit.
	while grad.get_point_count() > 2:
		grad.remove_point(grad.get_point_count() - 1)
	grad.set_color(0, Color(c.r, c.g, c.b, 0.75 * a))
	grad.set_offset(0, 0.0)
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	grad.set_offset(1, 1.0)
	grad.add_point(0.55, Color(c.r, c.g, c.b, 0.25 * a))
	return grad


func _process(delta: float) -> void:
	var old_t: float = _t
	global_position += velocity * delta
	_t = old_t + delta
	_update_fade()
	_apply_spin(delta)
	if wave_amplitude > 0.0 and wave_frequency > 0.0 and wave_axis.length_squared() > 0.0:
		var prev_wave: float = sin(old_t * wave_frequency + wave_phase)
		var next_wave: float = sin(_t * wave_frequency + wave_phase)
		global_position += wave_axis.normalized() * ((next_wave - prev_wave) * wave_amplitude)

	if _t >= ttl:
		_detach_trail()
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if not view.grow(120.0).has_point(global_position):
		_detach_trail()
		queue_free()


func _apply_spin(delta: float) -> void:
	var spr: Node2D = get_node_or_null(^"Sprite") as Node2D
	if spr != null:
		spr.rotation += deg_to_rad(spin_degrees_per_sec) * delta
	var spr2: Node2D = get_node_or_null(^"Sprite2D") as Node2D
	if spr2 != null:
		spr2.rotation += deg_to_rad(spin_degrees_per_sec) * delta


func _update_fade() -> void:
	if _sprite == null:
		return
	if fade_out_time <= 0.0 or ttl <= 0.0:
		return
	var remaining: float = ttl - _t
	var t: float = clampf(remaining / fade_out_time, 0.0, 1.0)
	var m: Color = _sprite.modulate
	m.a = t
	_sprite.modulate = m
	# CPUParticles2D doesn't fade via node modulate; scale its color_ramp.
	if _trail != null and not _trail_detached:
		_trail.color_ramp = _make_alpha_ramp(_trail_base_color, t)


func _detach_trail() -> void:
	if _trail_detached:
		return
	if _trail == null:
		return
	_trail_detached = true

	var parent: Node = get_parent()
	if parent == null:
		return

	_trail.reparent(parent)
	_trail.global_position = global_position
	_trail.emitting = false
	get_tree().create_timer(_trail.lifetime + 0.35).timeout.connect(func() -> void:
		if is_instance_valid(_trail):
			_trail.queue_free()
	)
