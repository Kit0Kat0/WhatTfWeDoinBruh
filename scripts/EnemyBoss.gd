extends Area2D
class_name EnemyBoss

@export var hp: int = 160
@export var horizontal_speed: float = 95.0
@export var entry_speed: float = 140.0
## Boss sits in the top lane: center Y = playfield top + radius + this margin.
@export var top_lane_margin: float = 36.0
@export var radius: float = 78.0
@export var shot_interval: float = 0.35
## Straight-down volleys (normal-style): speed + damage.
@export var normal_bullet_speed: float = 280.0
@export var normal_bullet_damage: int = 2
## Three-way spread volleys (tanky-style): slower, harder-hitting.
@export var tank_bullet_speed: float = 200.0
@export var tank_bullet_damage: int = 3
@export var tank_spread_angle_degrees: float = 14.0

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var _shot_t: float = 0.0
var _x_dir: float = 1.0
var _target_y: float = 0.0
var _pattern_volley: int = 0


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	_recompute_target_y()
	_sync_collision_radius()
	queue_redraw()


func _recompute_target_y() -> void:
	if playfield_rect.size == Vector2.ZERO:
		_target_y = global_position.y
		return
	_target_y = playfield_rect.position.y + radius + top_lane_margin


func _sync_collision_radius() -> void:
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius


func _process(delta: float) -> void:
	_recompute_target_y()

	if global_position.y < _target_y:
		global_position.y = minf(_target_y, global_position.y + entry_speed * delta)
	else:
		global_position.y = _target_y

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
		_fire_mixed_pattern_volley()


func _fire_mixed_pattern_volley() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	if _pattern_volley % 2 == 0:
		_fire_normal_forward()
	else:
		_fire_tanky_spread()
	_pattern_volley += 1
	AudioManager.play_sfx("boss_shot")


func _fire_normal_forward() -> void:
	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0.0, radius * 0.35)
	b.velocity = Vector2.DOWN * normal_bullet_speed
	b.damage = maxi(1, normal_bullet_damage)


func _fire_tanky_spread() -> void:
	var spread_radians: float = deg_to_rad(tank_spread_angle_degrees)
	var dirs: Array[Vector2] = [
		Vector2.DOWN,
		Vector2.DOWN.rotated(spread_radians),
		Vector2.DOWN.rotated(-spread_radians),
	]
	for d in dirs:
		var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
		if b == null:
			continue
		bullet_parent.add_child(b)
		b.global_position = global_position + d * (radius * 0.35)
		b.velocity = d * tank_bullet_speed
		b.damage = maxi(1, tank_bullet_damage)


func _draw() -> void:
	var rim: float = maxf(10.0, radius * 0.22)
	var core: float = maxf(6.0, radius * 0.11)
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.2, 0.25, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - rim), Color(0.25, 0.05, 0.08, 1.0))
	draw_circle(Vector2.ZERO, core, Color(1.0, 0.92, 0.35, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		var dmg: int = 1
		var pb: BulletPlayer = area as BulletPlayer
		if pb != null:
			dmg = maxi(1, pb.damage)
		hp -= dmg
		if hp <= 0:
			AudioManager.play_sfx("boss_death")
			AudioManager.duck_music(6.0, 0.3, 0.7)
			for n in get_tree().get_nodes_in_group("game_controller"):
				if n.has_method("try_spawn_weapon_pickup"):
					n.call("try_spawn_weapon_pickup", global_position, true)
					break
			queue_free()
		elif hp % 5 == 0:
			AudioManager.play_sfx("boss_hit")
