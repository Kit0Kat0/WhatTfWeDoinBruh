extends Node2D
class_name PlayfieldFrame

var playfield_rect: Rect2 = Rect2()

@export var inset_px: float = 8.0
@export var line_width_px: float = 2.0
@export var base_color: Color = Color(0.25, 0.25, 0.3, 1.0)
@export var damage_flash_color: Color = Color(1.0, 0.15, 0.2, 1.0)
@export var death_color: Color = Color(1.0, 0.12, 0.12, 1.0)
@export var respawn_immunity_color: Color = Color(0.75, 0.25, 1.0, 1.0)
@export var low_hp_flash_color: Color = Color(1.0, 0.92, 0.2, 1.0)
@export var damage_flash_duration_sec: float = 0.18
@export var low_hp_flash_hz: float = 2.8

var _damage_flash_left: float = 0.0
var _respawn_immunity_left: float = 0.0
var _low_hp_warning: bool = false
var _low_hp_phase: float = 0.0
var _player_dead: bool = false


func _ready() -> void:
	# Stay visible when the game tree is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func flash_damage() -> void:
	_damage_flash_left = maxf(_damage_flash_left, maxf(0.0, damage_flash_duration_sec))
	queue_redraw()


func set_respawn_immunity(duration_sec: float) -> void:
	_respawn_immunity_left = maxf(_respawn_immunity_left, maxf(0.0, duration_sec))
	queue_redraw()


func set_player_dead(enabled: bool) -> void:
	_player_dead = enabled
	# When dead, don't show respawn immunity tint.
	if _player_dead:
		_respawn_immunity_left = 0.0
	queue_redraw()


func set_low_hp_warning(enabled: bool) -> void:
	_low_hp_warning = enabled
	queue_redraw()


func set_playfield_rect(r: Rect2) -> void:
	playfield_rect = r
	queue_redraw()


func _process(delta: float) -> void:
	var changed: bool = false
	if _damage_flash_left > 0.0:
		_damage_flash_left = maxf(0.0, _damage_flash_left - delta)
		changed = true
	if _respawn_immunity_left > 0.0:
		_respawn_immunity_left = maxf(0.0, _respawn_immunity_left - delta)
		changed = true
	if _low_hp_warning:
		# Keep the border visible while paused, but stop the low-HP pulse animation during pause.
		var tree: SceneTree = get_tree()
		if tree == null or not tree.paused:
			_low_hp_phase += delta * TAU * maxf(0.1, low_hp_flash_hz)
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	if playfield_rect.size == Vector2.ZERO:
		return
	var inset: Rect2 = playfield_rect.grow(-maxf(0.0, inset_px))
	if inset.size.x > 0.0 and inset.size.y > 0.0:
		var col: Color = base_color
		# Priority: dead (red), respawn immunity (purple), damage (red), then low-HP pulse (yellow).
		if _player_dead:
			col = death_color
		elif _respawn_immunity_left > 0.0:
			col = respawn_immunity_color
		elif _damage_flash_left > 0.0:
			col = damage_flash_color
		elif _low_hp_warning:
			# Occasional pulse: spends most time near base, spikes to yellow.
			var u: float = (sin(_low_hp_phase) + 1.0) * 0.5
			u = pow(u, 3.0)
			col = base_color.lerp(low_hp_flash_color, u)
		draw_rect(inset, col, false, maxf(1.0, line_width_px))
