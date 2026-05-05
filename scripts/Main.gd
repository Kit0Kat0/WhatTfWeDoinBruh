extends Node2D

const GAME_SCENE_PATH: String = "res://scenes/Game.tscn"

@onready var _settings_panel: Panel = %SettingsPanel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue
@onready var _auto_shoot_button: Button = %AutoShootButton


func _ready() -> void:
	_settings_panel.visible = false
	_music_slider.value = GameSettings.music_volume
	_sfx_slider.value = GameSettings.sfx_volume
	_refresh_music_label()
	_refresh_sfx_label()
	_refresh_auto_shoot_label()
	AudioManager.play_music("menu")


func _on_play_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_settings_panel.visible = true


func _on_settings_close_button_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	_settings_panel.visible = false


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


func _refresh_music_label() -> void:
	_music_value.text = "%d%%" % int(roundf(GameSettings.music_volume * 100.0))


func _refresh_sfx_label() -> void:
	_sfx_value.text = "%d%%" % int(roundf(GameSettings.sfx_volume * 100.0))


func _refresh_auto_shoot_label() -> void:
	var state: String = "On" if GameSettings.automatic_shooting else "Off"
	_auto_shoot_button.text = "Automatic Shooting: %s" % state
