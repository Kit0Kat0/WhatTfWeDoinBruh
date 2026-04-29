extends Area2D

@export var speed := 420.0
@export var focus_speed_multiplier := 0.45
@export var fire_interval := 0.08
@export var i_frames := 0.8

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var _fire_cooldown := 0.0
var _invuln := 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	_update_movement(delta)
	_update_shooting(delta)


func _update_movement(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	var mult := focus_speed_multiplier if Input.is_action_pressed("focus") else 1.0
	global_position += dir * speed * mult * delta

	if playfield_rect.size != Vector2.ZERO:
		var margin := 14.0
		global_position.x = clampf(global_position.x, playfield_rect.position.x + margin, playfield_rect.end.x - margin)
		global_position.y = clampf(global_position.y, playfield_rect.position.y + margin, playfield_rect.end.y - margin)


func _update_shooting(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if not Input.is_action_pressed("shoot"):
		return
	if _fire_cooldown > 0.0:
		return
	if bullet_scene == null or bullet_parent == null:
		return

	_fire_cooldown = fire_interval

	var b := bullet_scene.instantiate()
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0, -16)
	b.set("velocity", Vector2(0, -900.0))


func _draw() -> void:
	var base := Color(0.35, 0.8, 1.0, 1.0)
	if _invuln > 0.0:
		base.a = 0.35

	draw_circle(Vector2.ZERO, 10.0, base)
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.1, 0.35, base.a))

	if Input.is_action_pressed("focus"):
		draw_circle(Vector2.ZERO, 14.0, Color(1, 1, 1, 0.2))


func _on_area_entered(area: Area2D) -> void:
	if _invuln > 0.0:
		return
	if area.is_in_group(Defs.GROUP_ENEMY_BULLET) or area.is_in_group(Defs.GROUP_ENEMY):
		_invuln = i_frames
		queue_redraw()

