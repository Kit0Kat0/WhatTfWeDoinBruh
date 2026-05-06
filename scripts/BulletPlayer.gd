extends Area2D
class_name BulletPlayer

@export var ttl: float = 3.0
@export var radius: float = 4.0
@export var damage: float = 10.0
## If true, bullet is not destroyed on enemy hit and can damage many enemies (once each).
@export var pierce: bool = false
## Added to `velocity.angle()` so the projectile texture points along travel (tune if art faces +X instead of “up”).
@export var travel_rotation_offset_radians: float = PI * 0.5

var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _hit_enemy_ids: Dictionary = {}

func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER_BULLET)
	area_entered.connect(_on_area_entered)
	_sync_travel_rotation()


func _process(delta: float) -> void:
	global_position += velocity * delta
	_t += delta
	if _t >= ttl:
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if global_position.y < view.position.y - 40.0:
		queue_free()


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
	queue_free()
