extends Area2D
class_name EnemyBasic

@export var hp: int = 8
@export var speed: float = 110.0
@export var horizontal_speed: float = 80.0
@export var shot_interval: float = 0.85
@export var bullet_speed: float = 220.0
@export var bullet_damage: int = 2
@export var use_wave_bullets: bool = false
@export var wave_amplitude: float = 26.0
@export var wave_frequency: float = 7.0
@export var radius: float = 14.0

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var _shot_t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _x_dir: float = 1.0


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	_rng.randomize()
	_shot_t = _rng.randf_range(0.0, shot_interval)
	_x_dir = -1.0 if _rng.randf() < 0.5 else 1.0
	queue_redraw()


func _process(delta: float) -> void:
	global_position.x += _x_dir * horizontal_speed * delta
	global_position.y += speed * delta
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
		_fire_forward()

	if playfield_rect.size != Vector2.ZERO and global_position.y > playfield_rect.end.y + 60.0:
		global_position.y = playfield_rect.position.y - 30.0


func _fire_forward() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return

	bullet_parent.add_child(b)
	b.global_position = global_position
	b.velocity = Vector2.DOWN * bullet_speed
	b.damage = maxi(1, bullet_damage)
	if use_wave_bullets:
		b.wave_axis = Vector2.RIGHT
		b.wave_amplitude = wave_amplitude
		b.wave_frequency = wave_frequency
		b.wave_phase = _rng.randf_range(0.0, TAU)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.95, 0.3, 1.0))
	draw_circle(Vector2.ZERO, maxf(1.0, radius - 4.0), Color(0.2, 0.2, 0.25, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		hp -= 1
		if hp <= 0:
			queue_free()

