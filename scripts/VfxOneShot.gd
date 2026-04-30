extends Node2D
class_name VfxOneShot

@export var sprite_path: NodePath = ^"AnimatedSprite2D"

@onready var _anim: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D


func _ready() -> void:
	if _anim == null:
		queue_free()
		return
	_anim.animation_finished.connect(_on_animation_finished)
	_anim.play()


func _on_animation_finished() -> void:
	queue_free()

