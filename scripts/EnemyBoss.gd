extends Area2D
class_name EnemyBoss

@export var hp: int = 120
@export var horizontal_speed: float = 120.0
@export var entry_speed: float = 90.0
@export var target_y_offset: float = 110.0
@export var radius: float = 34.0
@export var shot_interval: float = 0.35
@export var bullet_speed: float = 260.0

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var _shot_t: float = 0.0
var _x_dir: float = 1.0
var _target_y: float = 110.0


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	_target_y = playfield_rect.position.y + target_y_offset
	queue_redraw()


func _process(delta: float) -> void:
	if global_position.y < _target_y:
		global_position.y = minf(_target_y, global_position.y + entry_speed * delta)

	global_position.x += _x_dir * horizontal_speed * delta
	_shot_t += delta

	if playfield_rect.size != Vector2.ZERO:
		var x_min: float = playfield_rect.position.x + radius
		var x_max: float = playfield_rect.end.x - radius
		if global_position.x <= x_min:
			global_position.x = x_min
			_x_dir = 1.0
		elif global_position.x >= x_max:
			global_position.x = x_max
			_x_dir = -1.0

	if _shot_t >= shot_interval:
		_shot_t = 0.0
		_fire_spread()


func _fire_spread() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var dirs: Array[Vector2] = [
		Vector2.DOWN,
		Vector2(0.28, 1.0).normalized(),
		Vector2(-0.28, 1.0).normalized(),
	]

	for d in dirs:
		var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
		if b == null:
			continue
		bullet_parent.add_child(b)
		b.global_position = global_position + d * (radius * 0.35)
		b.velocity = d * bullet_speed
		b.damage = 2


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.2, 0.25, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 8.0), Color(0.25, 0.05, 0.08, 1.0))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.92, 0.35, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		hp -= 1
		if hp <= 0:
			queue_free()
