extends Node2D
class_name PathTrace

@export var particle_lifetime: float = 0.55
@export var trail_color: Color = Color(0.4, 0.88, 1.0, 0.4)

var _motion: EnemyPathMotion = EnemyPathMotion.new()
var _trace_speed: float = 0.0
var _arc_covered: float = 0.0
var _path_length: float = 0.0
var _particles: CPUParticles2D


func begin(path: Path2D, start_distance: float, along_offset: float, trace_speed: float) -> void:
	_trace_speed = trace_speed
	_motion.setup(path, maxf(0.0, start_distance), along_offset)
	_path_length = _motion.get_baked_length()
	_arc_covered = 0.0
	_particles = CPUParticles2D.new()
	add_child(_particles)
	_configure_particles()
	_motion.apply_to(self, false)


func _configure_particles() -> void:
	_particles.emitting = true
	_particles.amount = 56
	_particles.lifetime = particle_lifetime
	_particles.one_shot = false
	_particles.explosiveness = 0.0
	_particles.randomness = 0.4
	_particles.local_coords = false
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	_particles.direction = Vector2.UP
	_particles.spread = 180.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 10.0
	_particles.initial_velocity_max = 32.0
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 4.0
	_particles.color = trail_color

	var grad: Gradient = Gradient.new()
	grad.add_point(0.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.9))
	grad.add_point(0.75, Color(trail_color.r, trail_color.g, trail_color.b, 0.35))
	grad.add_point(1.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	_particles.color_ramp = grad


func _process(delta: float) -> void:
	if _path_length <= 0.0:
		queue_free()
		return
	var step: float = _trace_speed * delta
	_arc_covered += step
	_motion.advance_no_wrap(delta, _trace_speed)
	_motion.apply_to(self, false)
	if _arc_covered >= _path_length:
		_finish_trace()


func _finish_trace() -> void:
	set_process(false)
	if is_instance_valid(_particles):
		_particles.emitting = false
	await get_tree().create_timer(minf(1.2, particle_lifetime + 0.25)).timeout
	queue_free()
