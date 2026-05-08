extends Control
class_name HudMetaXpBar

## Colored fill (lerps toward `_target_ratio`).
var _display_ratio: float = 0.0
## True / immediate XP fraction (white bar).
var _target_ratio: float = 0.0
## When true, colored fill uses `color_fill_full`.
@export var bar_full: bool = false
@export var color_track: Color = Color(0.06, 0.07, 0.09, 0.88)
## Instant “true” progress (boss-style lead bar), drawn under the colored lerp fill.
@export var color_instant_bar: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var color_fill_normal: Color = Color(0.14, 0.52, 0.72, 0.93)
@export var color_fill_full: Color = Color(0.28, 0.78, 0.92, 0.95)
## How fast the colored bar approaches `_target_ratio` (normalized units per second). Set to 0 to snap.
## Lower = white “true” fill stays visible longer while the colored bar catches up.
@export_range(0.0, 50.0, 0.05) var fill_lerp_speed: float = 0.32


func _ready() -> void:
	# Must not inherit HUD's PROCESS_MODE_ALWAYS: otherwise this bar keeps lerping while
	# `get_tree().paused` (meta perk pick, ESC pause), so the fill catches up with no visible motion.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)


func set_progress(current: float, need: float, reset_colored_after_level: bool = false) -> void:
	_target_ratio = 0.0 if need <= 0.001 else clampf(current / need, 0.0, 1.0)
	bar_full = current >= need - 0.02
	if reset_colored_after_level:
		_display_ratio = 0.0
	if fill_lerp_speed <= 0.001:
		_display_ratio = _target_ratio
		queue_redraw()
		set_process(false)
		return
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_display_ratio = move_toward(_display_ratio, _target_ratio, fill_lerp_speed * delta)
	queue_redraw()
	if is_equal_approx(_display_ratio, _target_ratio):
		set_process(false)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, color_track, true)
	var w := size.x
	# Instant white (true progress), drawn beneath the colored lerp fill.
	var h_white: float = size.y * clampf(_target_ratio, 0.0, 1.0)
	if h_white > 0.5:
		draw_rect(Rect2(Vector2(0.0, size.y - h_white), Vector2(w, h_white)), color_instant_bar, true)
	# Colored fill (may lag); covers white where they overlap.
	var h_col: float = size.y * clampf(_display_ratio, 0.0, 1.0)
	var col: Color = color_fill_normal if not bar_full else color_fill_full
	if h_col > 0.5:
		draw_rect(Rect2(Vector2(0.0, size.y - h_col), Vector2(w, h_col)), col, true)
