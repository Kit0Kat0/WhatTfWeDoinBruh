extends Node2D

const GAME_SCENE_PATH: String = "res://scenes/Game.tscn"

@onready var _settings_panel: Panel = %SettingsPanel
@onready var _settings_blocker: ColorRect = %SettingsModalBlocker
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue
@onready var _auto_shoot_button: Button = %AutoShootButton
@onready var _focus_mode_button: Button = %FocusModeButton
@onready var _unpause_delay_option: OptionButton = %UnpauseDelayOption


func _ready() -> void:
	_settings_panel.visible = false
	if _settings_blocker != null:
		_settings_blocker.visible = false
	_music_slider.value = GameSettings.music_volume
	_sfx_slider.value = GameSettings.sfx_volume
	_refresh_music_label()
	_refresh_sfx_label()
	_refresh_auto_shoot_label()
	_refresh_focus_mode_label()
	_setup_unpause_delay_option()
	AudioManager.play_music("menu")


func _setup_unpause_delay_option() -> void:
	if _unpause_delay_option == null:
		return
	_unpause_delay_option.clear()
	for i in range(GameSettings.UNPAUSE_DELAY_DISPLAY.size()):
		_unpause_delay_option.add_item(GameSettings.UNPAUSE_DELAY_DISPLAY[i], i)
	_unpause_delay_option.select(clampi(GameSettings.unpause_delay_mode, 0, GameSettings.UNPAUSE_DELAY_DISPLAY.size() - 1))


func _on_play_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if _settings_blocker != null:
		_settings_blocker.visible = true
	_settings_panel.visible = true


func _on_settings_close_button_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	_settings_panel.visible = false
	if _settings_blocker != null:
		_settings_blocker.visible = false


func _on_quit_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().quit()


func _on_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)
	_refresh_music_label()


func _on_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)
	_refresh_sfx_label()


func _on_auto_shoot_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_automatic_shooting(not GameSettings.automatic_shooting)
	_refresh_auto_shoot_label()


func _on_focus_mode_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_focus_mode(not GameSettings.focus_mode)
	_refresh_focus_mode_label()


func _on_unpause_delay_option_item_selected(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_unpause_delay_mode(index)


func _refresh_music_label() -> void:
	_music_value.text = "%d%%" % int(roundf(GameSettings.music_volume * 100.0))


func _refresh_sfx_label() -> void:
	_sfx_value.text = "%d%%" % int(roundf(GameSettings.sfx_volume * 100.0))


func _refresh_auto_shoot_label() -> void:
	var state: String = "On" if GameSettings.automatic_shooting else "Off"
	_auto_shoot_button.text = "Automatic Shooting: %s" % state


func _refresh_focus_mode_label() -> void:
	if _focus_mode_button == null:
		return
	var state: String = "On" if GameSettings.focus_mode else "Off"
	_focus_mode_button.text = "Focus Mode: %s" % state
