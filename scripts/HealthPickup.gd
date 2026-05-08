extends Area2D
class_name HealthPickup

const ZERO_DAY_ASCENT_SPEED_MULT: float = 5.0
const BASE_FALL_SPEED: float = 55.0

## Heal amount as a fraction of the player's current max HP (e.g. 0.1 = 10%).
@export var heal_fraction_of_max: float = 0.05
@export var fall_speed: float = 55.0
@export var life_seconds: float = 14.0

var _life: float = 0.0
var _playfield_rect: Rect2 = Rect2()
var _zero_day_ascending: bool = false


func _ready() -> void:
	add_to_group(Defs.GROUP_HEALTH_PICKUP)
	area_entered.connect(_on_area_entered)
	_life = life_seconds
	monitoring = true
	monitorable = true
	queue_redraw()


func setup(playfield: Rect2) -> void:
	_playfield_rect = playfield


func configure_zero_day_routing(enabled: bool) -> void:
	if not enabled or _playfield_rect.size == Vector2.ZERO:
		return
	var mid_y: float = _playfield_rect.position.y + _playfield_rect.size.y * 0.5
	if global_position.y <= mid_y:
		return
	_zero_day_ascending = true


func _process(delta: float) -> void:
	var step: float = fall_speed * delta
	if _zero_day_ascending:
		global_position.y -= step * ZERO_DAY_ASCENT_SPEED_MULT
		var mid_y: float = _playfield_rect.position.y + _playfield_rect.size.y * 0.5
		if global_position.y <= mid_y:
			global_position.y = mid_y
			_zero_day_ascending = false
	else:
		global_position.y += step
	# Keep pickup lifetime roughly consistent on-screen even when perks slow fall speed.
	var life_tick_scale: float = 1.0
	if BASE_FALL_SPEED > 0.001:
		life_tick_scale = clampf(fall_speed / BASE_FALL_SPEED, 0.05, 3.0)
	_life -= delta * life_tick_scale
	if _life <= 0.0:
		queue_free()
		return
	if _playfield_rect.size != Vector2.ZERO and global_position.y > _playfield_rect.end.y + 40.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(Defs.GROUP_PLAYER):
		return
	var p: Player = area as Player
	if p == null:
		return
	p.heal_by_max_hp_fraction(heal_fraction_of_max)
	queue_free()


func _draw() -> void:
	var arm: float = 10.5
	var thickness: float = 3.5
	var stroke: Color = Color(0.05, 0.22, 0.1, 0.92)
	var fill_col: Color = Color(0.32, 0.9, 0.48, 0.98)
	# Slight outline so it reads on dark backgrounds.
	draw_line(Vector2(-arm, 0.0), Vector2(arm, 0.0), stroke, thickness + 2.0, true)
	draw_line(Vector2(0.0, -arm), Vector2(0.0, arm), stroke, thickness + 2.0, true)
	draw_line(Vector2(-arm, 0.0), Vector2(arm, 0.0), fill_col, thickness, true)
	draw_line(Vector2(0.0, -arm), Vector2(0.0, arm), fill_col, thickness, true)
