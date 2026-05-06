extends Node2D
class_name PlayfieldFrame

var playfield_rect: Rect2 = Rect2()


func _ready() -> void:
	# Stay visible when the game tree is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_playfield_rect(r: Rect2) -> void:
	playfield_rect = r
	queue_redraw()


func _draw() -> void:
	if playfield_rect.size == Vector2.ZERO:
		return
	var inset: Rect2 = playfield_rect.grow(-8.0)
	if inset.size.x > 0.0 and inset.size.y > 0.0:
		draw_rect(inset, Color(0.25, 0.25, 0.3, 1.0), false, 2.0)
