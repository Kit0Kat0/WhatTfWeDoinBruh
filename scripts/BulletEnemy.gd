extends Area2D
class_name BulletEnemy

@export var ttl: float = 6.0
@export var radius: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var wave_axis: Vector2 = Vector2.ZERO
var wave_amplitude: float = 0.0
var wave_frequency: float = 0.0
var wave_phase: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY_BULLET)


func _process(delta: float) -> void:
	var old_t: float = _t
	global_position += velocity * delta
	_t = old_t + delta
	if wave_amplitude > 0.0 and wave_frequency > 0.0 and wave_axis.length_squared() > 0.0:
		var prev_wave: float = sin(old_t * wave_frequency + wave_phase)
		var next_wave: float = sin(_t * wave_frequency + wave_phase)
		global_position += wave_axis.normalized() * ((next_wave - prev_wave) * wave_amplitude)

	if _t >= ttl:
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if not view.grow(120.0).has_point(global_position):
		queue_free()

