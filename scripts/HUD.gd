extends CanvasLayer
class_name HUD

signal pause_quit_requested
signal perk_keep_refresh_requested
signal perk_switch_requested(kind: WeaponPickup.PerkKind)

@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_text: Label = %HPText
@onready var _lives_text: Label = %LivesText
@onready var _wave_text: Label = %WaveText
@onready var _boss_banner: Label = %BossBanner
@onready var _game_over_panel: ColorRect = %GameOverPanel
@onready var _pause_panel: ColorRect = %PausePanel
@onready var _pause_text: Label = %PauseText
@onready var _pause_quit_button: Button = %PauseQuitButton
@onready var _perk_choice_panel: ColorRect = %PerkChoicePanel
@onready var _perk_button_box: VBoxContainer = %PerkButtonBox

var _boss_banner_ticket: int = 0

const _PERK_LABELS: Dictionary = {
	WeaponPickup.PerkKind.DOUBLE_STRAIGHT: "Double",
	WeaponPickup.PerkKind.TRIPLE_STRAIGHT: "Triple",
	WeaponPickup.PerkKind.BEAM: "Beam",
}


func set_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_text.text = "%d / %d" % [current, maximum]


func set_lives(lives: int) -> void:
	_lives_text.text = "Lives: %d" % maxi(0, lives)


func set_wave(wave_number: int) -> void:
	_wave_text.text = "Wave: %d" % maxi(1, wave_number)


func show_boss_banner(duration: float = 2.0) -> void:
	_boss_banner_ticket += 1
	var ticket: int = _boss_banner_ticket
	_boss_banner.visible = true
	await get_tree().create_timer(maxf(0.1, duration)).timeout
	if ticket == _boss_banner_ticket:
		_boss_banner.visible = false


func show_game_over() -> void:
	_game_over_panel.visible = true


func hide_game_over() -> void:
	_game_over_panel.visible = false


func show_paused() -> void:
	_pause_panel.visible = true
	_pause_text.text = "PAUSED\nPress Escape to resume"
	_pause_quit_button.visible = true


func show_resume_countdown(seconds_left: int) -> void:
	_pause_panel.visible = true
	_pause_text.text = "Resuming in %d..." % maxi(1, seconds_left)
	_pause_quit_button.visible = false


func hide_pause() -> void:
	_pause_panel.visible = false
	_pause_quit_button.visible = false


func show_perk_choice(current_kind: WeaponPickup.PerkKind) -> void:
	for c in _perk_button_box.get_children():
		c.queue_free()
	var keep_btn := Button.new()
	keep_btn.custom_minimum_size = Vector2(320, 40)
	keep_btn.text = "Keep %s — reset timer" % _perk_label(current_kind)
	keep_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		perk_keep_refresh_requested.emit()
	)
	_perk_button_box.add_child(keep_btn)
	var all_kinds: Array[WeaponPickup.PerkKind] = [
		WeaponPickup.PerkKind.DOUBLE_STRAIGHT,
		WeaponPickup.PerkKind.TRIPLE_STRAIGHT,
		WeaponPickup.PerkKind.BEAM,
	]
	for k in all_kinds:
		if k == current_kind:
			continue
		var captured: WeaponPickup.PerkKind = k
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(320, 40)
		sw.text = "Switch to %s" % _perk_label(captured)
		sw.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_click")
			perk_switch_requested.emit(captured)
		)
		_perk_button_box.add_child(sw)
	_perk_choice_panel.visible = true


func hide_perk_choice() -> void:
	_perk_choice_panel.visible = false
	for c in _perk_button_box.get_children():
		c.queue_free()


func _perk_label(kind: WeaponPickup.PerkKind) -> String:
	return str(_PERK_LABELS.get(kind, "?"))


func _on_pause_quit_button_pressed() -> void:
	pause_quit_requested.emit()

