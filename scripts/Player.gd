extends Area2D
class_name Player

@export var speed: float = 420.0
@export var focus_speed_multiplier: float = 0.45
@export var boost_speed_multiplier: float = 1.6
@export var fire_interval: float = 0.08
@export var i_frames: float = 0.8
@export var max_hp: int = 25

signal health_changed(current: int, maximum: int)
signal died

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var hp: int = 25
var _fire_cooldown: float = 0.0
var _invuln: float = 0.0
var _respawn_immunity: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER)
	area_entered.connect(_on_area_entered)
	hp = clampi(hp, 0, max_hp)
	health_changed.emit(hp, max_hp)
	queue_redraw()


func _process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	_respawn_immunity = maxf(0.0, _respawn_immunity - delta)
	_update_movement(delta)
	_update_shooting(delta)
	queue_redraw()


func _update_movement(delta: float) -> void:
	var dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	var mult: float = 1.0
	var boosting: bool = Input.is_action_pressed("boost")
	var focusing: bool = Input.is_action_pressed("focus")
	# Boost takes priority to avoid accidental slowdown when boost/focus share a key.
	if boosting:
		mult = boost_speed_multiplier
	elif focusing:
		mult = focus_speed_multiplier
	global_position += dir * speed * mult * delta

	if playfield_rect.size != Vector2.ZERO:
		var margin: float = 14.0
		global_position.x = clampf(global_position.x, playfield_rect.position.x + margin, playfield_rect.end.x - margin)
		global_position.y = clampf(global_position.y, playfield_rect.position.y + margin, playfield_rect.end.y - margin)


func _update_shooting(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _respawn_immunity > 0.0:
		return
	if not Input.is_action_pressed("shoot"):
		return
	if _fire_cooldown > 0.0:
		return
	if bullet_scene == null or bullet_parent == null:
		return

	_fire_cooldown = fire_interval

	var b: BulletPlayer = bullet_scene.instantiate() as BulletPlayer
	if b == null:
		return
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0, -16)
	b.velocity = Vector2(0, -900.0)


func _draw() -> void:
	var base: Color = Color(0.35, 0.8, 1.0, 1.0)
	if _invuln > 0.0 or _respawn_immunity > 0.0:
		base.a = 0.35

	draw_circle(Vector2.ZERO, 10.0, base)
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.1, 0.35, base.a))

	if Input.is_action_pressed("focus"):
		draw_circle(Vector2.ZERO, 14.0, Color(1, 1, 1, 0.2))


func _on_area_entered(area: Area2D) -> void:
	if _invuln > 0.0 or _respawn_immunity > 0.0:
		return
	if area.is_in_group(Defs.GROUP_ENEMY_BULLET):
		var enemy_bullet: BulletEnemy = area as BulletEnemy
		if enemy_bullet != null:
			_take_damage(enemy_bullet.damage)
		else:
			_take_damage(1)
	elif area.is_in_group(Defs.GROUP_ENEMY):
		_take_damage(1)


func _take_damage(amount: int) -> void:
	if amount <= 0:
		return
	_invuln = i_frames
	hp = maxi(0, hp - amount)
	health_changed.emit(hp, max_hp)
	queue_redraw()
	if hp <= 0:
		died.emit()
		queue_free()


func reset_for_respawn(respawn_immunity_duration: float) -> void:
	hp = max_hp
	_invuln = 0.0
	_respawn_immunity = maxf(0.0, respawn_immunity_duration)
	_fire_cooldown = fire_interval
	health_changed.emit(hp, max_hp)
	queue_redraw()
