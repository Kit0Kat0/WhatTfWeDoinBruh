extends Area2D
class_name BulletPlayer

@export var ttl: float = 3.0
@export var radius: float = 4.0
@export var damage: float = 10.0
@export var fade_out_time: float = 0.25
## If true, bullet is not destroyed on enemy hit and can damage many enemies (once each).
@export var pierce: bool = false
## Added to `velocity.angle()` so the projectile texture points along travel (tune if art faces +X instead of “up”).
@export var travel_rotation_offset_radians: float = PI * 0.5

var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _hit_enemy_ids: Dictionary = {}
var _trail: CPUParticles2D
var _trail_detached: bool = false
@onready var _sprite: CanvasItem = get_node_or_null(^"Sprite") as CanvasItem
var _trail_base_color: Color = Color(0.45, 0.95, 1.0, 0.65)
## Global-space playfield; used when `border_bounces_left` > 0 for edge bounce.
var playfield_bounds: Rect2 = Rect2()
## Remaining legal reflections off the playfield border (meta Rebound).
var border_bounces_left: int = 0

func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER_BULLET)
	area_entered.connect(_on_area_entered)
	_sync_travel_rotation()
	_create_trail(_trail_base_color)


func _create_trail(c: Color) -> void:
	_trail = CPUParticles2D.new()
	add_child(_trail)
	# Draw behind the bullet sprite.
	_trail.z_index = -1
	_trail.emitting = true
	_trail.one_shot = false
	_trail.amount = 18
	_trail.lifetime = 0.18
	_trail.explosiveness = 0.0
	_trail.randomness = 0.55
	_trail.local_coords = false
	_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	_trail.gravity = Vector2.ZERO
	_trail.initial_velocity_min = 10.0
	_trail.initial_velocity_max = 26.0
	_trail.scale_amount_min = 0.8
	_trail.scale_amount_max = 1.9
	_trail.spread = 35.0
	_trail.direction = (-velocity.normalized()) if velocity.length_squared() > 0.0001 else Vector2.DOWN
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
	global_position += velocity * delta

	if border_bounces_left > 0 and playfield_bounds.size != Vector2.ZERO:
		if _apply_playfield_border_bounce():
			border_bounces_left -= 1
			_sync_travel_rotation()
			_refresh_trail_emit_direction()

	_t += delta
	_update_fade()
	if _t >= ttl:
		_detach_trail()
		queue_free()
		return

	if _should_despawn_off_playfield():
		_detach_trail()
		queue_free()


func _apply_playfield_border_bounce() -> bool:
	var inset: float = radius
	var left: float = playfield_bounds.position.x + inset
	var right: float = playfield_bounds.end.x - inset
	var top: float = playfield_bounds.position.y + inset
	var bottom: float = playfield_bounds.end.y - inset
	var bounced: bool = false
	var p: Vector2 = global_position
	if p.x < left:
		global_position.x = left
		velocity.x *= -1.0
		bounced = true
	elif p.x > right:
		global_position.x = right
		velocity.x *= -1.0
		bounced = true
	p = global_position
	if p.y < top:
		global_position.y = top
		velocity.y *= -1.0
		bounced = true
	elif p.y > bottom:
		global_position.y = bottom
		velocity.y *= -1.0
		bounced = true
	return bounced


func _should_despawn_off_playfield() -> bool:
	if playfield_bounds.size != Vector2.ZERO:
		var pad: float = radius + 64.0
		return not playfield_bounds.grow(pad).has_point(global_position)
	var view: Rect2 = get_viewport_rect()
	return global_position.y < view.position.y - 40.0


func _refresh_trail_emit_direction() -> void:
	if _trail == null or _trail_detached:
		return
	if velocity.length_squared() > 0.0001:
		_trail.direction = (-velocity.normalized())
func _update_fade() -> void:
	if _sprite == null:
		return
	if fade_out_time <= 0.0 or ttl <= 0.0:
		return
	var remaining: float = ttl - _t
	var t: float = clampf(remaining / fade_out_time, 0.0, 1.0)
	# t=1 early -> alpha 1, t=0 at end -> alpha 0
	var m: Color = _sprite.modulate
	m.a = t
	_sprite.modulate = m
	# CPUParticles2D doesn't fade via node modulate; scale its color_ramp.
	if _trail != null and not _trail_detached:
		_trail.color_ramp = _make_alpha_ramp(_trail_base_color, t)


func _sync_travel_rotation() -> void:
	if velocity.length_squared() < 0.000001:
		return
	rotation = velocity.angle() + travel_rotation_offset_radians


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(Defs.GROUP_ENEMY):
		return
	if pierce:
		var eid: int = area.get_instance_id()
		if _hit_enemy_ids.has(eid):
			return
		_hit_enemy_ids[eid] = true
		return
	_detach_trail()
	queue_free()


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
