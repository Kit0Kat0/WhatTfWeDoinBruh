extends Area2D
class_name BulletPlayer

@export var ttl: float = 3.0
@export var radius: float = 4.0
@export var damage: int = 1
## If true, bullet is not destroyed on enemy hit and can damage many enemies (once each).
@export var pierce: bool = false

var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _hit_enemy_ids: Dictionary = {}
var _beam_visual: bool = false

@onready var _sprite: Sprite2D = get_node_or_null(^"Sprite") as Sprite2D


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER_BULLET)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += velocity * delta
	_t += delta
	if _t >= ttl:
		queue_free()
		return

	var view: Rect2 = get_viewport_rect()
	if global_position.y < view.position.y - 40.0:
		queue_free()


func configure_as_beam() -> void:
	pierce = true
	_beam_visual = true
	ttl = 2.0
	if _sprite != null:
		_sprite.visible = false
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs == null:
		return
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, 180.0)
	cs.shape = rect
	cs.position = Vector2(0.0, -90.0)
	queue_redraw()


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


func _draw() -> void:
	if not _beam_visual:
		return
	draw_rect(Rect2(-8.0, -180.0, 16.0, 180.0), Color(0.35, 0.88, 1.0, 0.55))
	draw_rect(Rect2(-5.0, -180.0, 10.0, 180.0), Color(0.75, 1.0, 1.0, 0.45))
