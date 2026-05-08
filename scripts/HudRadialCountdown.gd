extends Control
class_name HudRadialCountdown

@export var radius_px: float = 108.0
@export var thickness_px: float = 14.0
@export var bg_color: Color = Color(1, 1, 1, 0.16)
@export var fg_color: Color = Color(1, 1, 1, 0.92)

var _ratio: float = 1.0


func set_ratio(r: float) -> void:
	_ratio = clampf(r, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var r: float = maxf(2.0, radius_px)
	var t: float = maxf(1.0, thickness_px)
	var c: Vector2 = size * 0.5
	# Background ring.
	draw_arc(c, r, 0.0, TAU, 64, bg_color, t, true)
	# Foreground arc: start at -90° and sweep clockwise as ratio decreases.
	var sweep: float = TAU * _ratio
	if sweep > 0.0001:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + sweep, 64, fg_color, t, true)

