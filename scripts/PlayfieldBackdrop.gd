extends Node2D
class_name PlayfieldBackdrop

var playfield_rect: Rect2 = Rect2()


func set_playfield_rect(r: Rect2) -> void:
	playfield_rect = r
	queue_redraw()


func _draw() -> void:
	if playfield_rect.size == Vector2.ZERO:
		return
	draw_rect(playfield_rect, Color(0.05, 0.05, 0.07, 1.0), true)
