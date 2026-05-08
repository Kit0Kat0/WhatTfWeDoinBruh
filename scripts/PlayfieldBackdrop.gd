extends Node2D
class_name PlayfieldBackdrop

var playfield_rect: Rect2 = Rect2()

@export var grid_enabled: bool = true
@export var grid_spacing_px: float = 64.0
@export var grid_scroll_speed_px_per_sec: float = 50.0
@export var grid_scroll_x_multiplier: float = 0.65
@export var grid_line_width: float = 1.0
@export var grid_color: Color = Color(0.25, 0.95, 1.0, 0.08)
@export var grid_back_alpha_multiplier: float = 0.45
@export var grid_back_speed_multiplier: float = 0.5
## Solid playfield fill: separate, slower creep toward boss palette (seconds, full 0→1 move).
@export_range(0.25, 12.0, 0.05) var boss_wave_background_transition_sec: float = 3.25
## Scrolling grids: faster read of danger (still lerps; keep ≤ background time if you want lines to arrive first).
@export_range(0.05, 8.0, 0.01) var boss_wave_grid_transition_sec: float = 0.85
## Fill color at full boss-wave tint.
@export var boss_wave_background_color: Color = Color(0.095, 0.02, 0.032, 1.0)
## Front-grid color at full boss-wave tint (`c_back` still applies `grid_back_alpha_multiplier`).
@export var boss_wave_grid_color: Color = Color(0.92, 0.2, 0.22, 0.092)

var _grid_scroll_y: float = 0.0
var _grid_scroll_x: float = 0.0
## Separate phase for the parallax grid — must not reuse fposmod(wrap) of the front layer scaled by `grid_back_speed_multiplier` or the pattern jumps at wrap boundaries.
var _grid_scroll_back_y: float = 0.0
var _grid_scroll_back_x: float = 0.0

var _boss_wave_blend_target: float = 0.0
var _boss_wave_bg_blend: float = 0.0
var _boss_wave_grid_blend: float = 0.0


func _enter_tree() -> void:
	set_process(true)


func set_playfield_rect(r: Rect2) -> void:
	playfield_rect = r
	queue_redraw()


func set_boss_wave_active(active: bool) -> void:
	_boss_wave_blend_target = 1.0 if active else 0.0


func _process(delta: float) -> void:
	if playfield_rect.size == Vector2.ZERO:
		return

	var bg_prev: float = _boss_wave_bg_blend
	var grid_prev: float = _boss_wave_grid_blend
	var dt_bg: float = delta / maxf(0.05, boss_wave_background_transition_sec)
	var dt_grid: float = delta / maxf(0.05, boss_wave_grid_transition_sec)
	_boss_wave_bg_blend = move_toward(_boss_wave_bg_blend, _boss_wave_blend_target, dt_bg)
	_boss_wave_grid_blend = move_toward(_boss_wave_grid_blend, _boss_wave_blend_target, dt_grid)

	if grid_enabled:
		var spacing: float = maxf(8.0, grid_spacing_px)
		var back_mul: float = clampf(grid_back_speed_multiplier, 0.0, 1.0)
		var spd: float = grid_scroll_speed_px_per_sec
		var x_mul: float = grid_scroll_x_multiplier
		_grid_scroll_y = fposmod(_grid_scroll_y + spd * delta, spacing)
		_grid_scroll_x = fposmod(_grid_scroll_x + spd * x_mul * delta, spacing)
		_grid_scroll_back_y = fposmod(_grid_scroll_back_y - spd * back_mul * delta, spacing)
		_grid_scroll_back_x = fposmod(_grid_scroll_back_x - spd * x_mul * back_mul * delta, spacing)

	var blending: bool = (not is_equal_approx(bg_prev, _boss_wave_bg_blend)) or (
		not is_equal_approx(grid_prev, _boss_wave_grid_blend)
	)
	if grid_enabled or blending:
		queue_redraw()


func _draw() -> void:
	if playfield_rect.size == Vector2.ZERO:
		return
	var bf_bg: float = clampf(_boss_wave_bg_blend, 0.0, 1.0)
	var bg_base := Color(0.05, 0.05, 0.07, 1.0)
	draw_rect(playfield_rect, bg_base.lerp(boss_wave_background_color, bf_bg), true)

	if not grid_enabled:
		return
	var bf_grid: float = clampf(_boss_wave_grid_blend, 0.0, 1.0)
	var spacing: float = maxf(8.0, grid_spacing_px)
	var w: float = maxf(0.5, grid_line_width)
	var c_front: Color = grid_color.lerp(boss_wave_grid_color, bf_grid)
	var back_am: float = clampf(grid_back_alpha_multiplier, 0.0, 1.0)
	var c_back: Color = Color(
		c_front.r,
		c_front.g,
		c_front.b,
		c_front.a * back_am
	)

	# Vertical lines (scrolling right)
	var x0: float = playfield_rect.position.x
	var x1: float = playfield_rect.end.x
	var y0: float = playfield_rect.position.y
	var y1: float = playfield_rect.end.y
	# Back grid (draw first): uses its own wrapped phase (see _process).
	var xb: float = floorf(x0 / spacing) * spacing + _grid_scroll_back_x
	while xb <= x1 + spacing:
		draw_line(Vector2(xb, y0), Vector2(xb, y1), c_back, w)
		xb += spacing

	var yb: float = floorf(y0 / spacing) * spacing + _grid_scroll_back_y
	while yb <= y1 + spacing:
		draw_line(Vector2(x0, yb), Vector2(x1, yb), c_back, w)
		yb += spacing

	# Front grid (draw on top): down/right.
	var x: float = floorf(x0 / spacing) * spacing + _grid_scroll_x
	while x <= x1 + spacing:
		draw_line(Vector2(x, y0), Vector2(x, y1), c_front, w)
		x += spacing

	var y: float = floorf(y0 / spacing) * spacing + _grid_scroll_y
	while y <= y1 + spacing:
		draw_line(Vector2(x0, y), Vector2(x1, y), c_front, w)
		y += spacing
