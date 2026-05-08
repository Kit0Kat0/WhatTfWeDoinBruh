extends Node2D
class_name PlayerExplosionVfx

@export var duration_sec: float = 0.55
@export var burst_amount: int = 40

@onready var _p: CPUParticles2D = $CPUParticles2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if _p == null:
		queue_free()
		return
	_p.one_shot = true
	_p.emitting = false
	_p.amount = maxi(1, burst_amount)
	_p.lifetime = maxf(0.1, duration_sec)
	_p.explosiveness = 1.0
	_p.spread = 180.0
	_p.direction = Vector2.RIGHT
	_p.initial_velocity_min = 140.0
	_p.initial_velocity_max = 520.0
	_p.gravity = Vector2(0.0, 520.0)
	_p.damping_min = 6.0
	_p.damping_max = 14.0
	_p.scale_amount_min = 0.6
	_p.scale_amount_max = 1.2
	_p.color = Color(1.0, 0.55, 0.25, 1.0)
	_p.emitting = true

	await get_tree().create_timer(maxf(0.15, duration_sec), true).timeout
	queue_free()

