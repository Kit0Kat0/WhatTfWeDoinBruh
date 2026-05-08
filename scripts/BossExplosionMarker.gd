extends Node2D
class_name BossExplosionMarker

## Warn with a red ring; after fuse time damages the player if inside blast_radius_px.

var fuse_seconds: float = 1.35
var blast_radius_px: float = 72.0
var damage: float = 38.0

var _t: float = 0.0
var _exploded: bool = false


func setup(fuse_sec: float, blast_px: float, dmg: float) -> void:
	fuse_seconds = fuse_sec
	blast_radius_px = blast_px
	damage = dmg


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -4


func _process(delta: float) -> void:
	if _exploded:
		return
	_t += delta
	queue_redraw()
	if _t >= fuse_seconds:
		_exploded = true
		_explode_once()


func _draw() -> void:
	if _exploded:
		return
	var pulse: float = 0.5 + 0.5 * sin(_t * 13.0)
	var warn_r: float = lerp(14.0, minf(38.0, blast_radius_px * 0.42), clampf(_t / maxf(0.001, fuse_seconds), 0.0, 1.0))
	var alpha: float = lerp(0.92, 0.55, clampf(_t / maxf(0.001, fuse_seconds), 0.0, 1.0))
	draw_arc(Vector2.ZERO, warn_r + pulse * 6.0, 0.0, TAU, 52, Color(1.0, 0.12, 0.14, alpha), 4.0, true)
	draw_arc(Vector2.ZERO, warn_r * 0.45 + pulse * 3.0, 0.0, TAU, 36, Color(1.0, 0.35, 0.35, alpha * 0.85), 2.5, true)


func _explode_once() -> void:
	var parent_n := get_parent()
	var burst := CPUParticles2D.new()
	if parent_n != null:
		parent_n.add_child(burst)
	else:
		add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	burst.one_shot = true
	burst.amount = 54
	burst.lifetime = 0.55
	burst.explosiveness = 0.92
	burst.randomness = 0.88
	burst.local_coords = false
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = blast_radius_px * 0.35
	burst.gravity = Vector2.ZERO
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 220.0
	burst.scale_amount_min = 1.5
	burst.scale_amount_max = 4.0
	burst.color = Color(1.0, 0.2, 0.12, 0.95)

	for n in get_tree().get_nodes_in_group(Defs.GROUP_PLAYER):
		var pl: Player = n as Player
		if pl == null:
			continue
		if pl.global_position.distance_to(global_position) <= blast_radius_px:
			pl.receive_damage(damage)
	get_tree().create_timer(burst.lifetime + 0.4).timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)
	queue_free()
