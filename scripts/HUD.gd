extends CanvasLayer
class_name HUD

signal pause_quit_requested

@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_text: Label = %HPText
@onready var _lives_text: Label = %LivesText
@onready var _wave_text: Label = %WaveText
@onready var _boss_banner: Label = %BossBanner
@onready var _boss_hp_bar: TextureProgressBar = %BossHpBar
@onready var _perk_timer_bar: ProgressBar = %PerkTimerBar
@onready var _game_over_panel: ColorRect = %GameOverPanel
@onready var _pause_panel: ColorRect = %PausePanel
@onready var _pause_text: Label = %PauseText
@onready var _pause_quit_button: Button = %PauseQuitButton

var _boss_banner_ticket: int = 0
var _perk_fill_style: StyleBoxFlat
var _perk_bg_style: StyleBoxFlat


func _ready() -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.fill_mode = TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT


func set_perk_timer(kind: WeaponPickup.PerkKind, ratio: float) -> void:
	_perk_timer_bar.visible = true
	_perk_timer_bar.value = clampf(ratio, 0.0, 1.0)

	var col: Color = Color(0.45, 0.95, 1.0, 0.95)
	match kind:
		WeaponPickup.PerkKind.TRIPLE_STRAIGHT:
			col = Color(0.95, 0.45, 1.0, 0.95)
		WeaponPickup.PerkKind.BEAM:
			col = Color(1.0, 0.82, 0.25, 0.95)
		WeaponPickup.PerkKind.CROSS_FIRE:
			col = Color(0.35, 1.0, 0.45, 0.95)

	if _perk_fill_style == null:
		_perk_fill_style = StyleBoxFlat.new()
		_perk_fill_style.corner_radius_top_left = 6
		_perk_fill_style.corner_radius_top_right = 6
		_perk_fill_style.corner_radius_bottom_left = 6
		_perk_fill_style.corner_radius_bottom_right = 6
	if _perk_bg_style == null:
		_perk_bg_style = StyleBoxFlat.new()
		_perk_bg_style.corner_radius_top_left = 6
		_perk_bg_style.corner_radius_top_right = 6
		_perk_bg_style.corner_radius_bottom_left = 6
		_perk_bg_style.corner_radius_bottom_right = 6

	_perk_fill_style.bg_color = col
	_perk_bg_style.bg_color = Color(col.r, col.g, col.b, 0.18)
	_perk_timer_bar.add_theme_stylebox_override("fill", _perk_fill_style)
	_perk_timer_bar.add_theme_stylebox_override("background", _perk_bg_style)


func hide_perk_timer() -> void:
	_perk_timer_bar.visible = false



func set_hp(current: float, maximum: float) -> void:
	_hp_bar.max_value = float(maximum)
	_hp_bar.value = float(current)
	var cur_i: int = int(roundi(current / 10.0))
	var max_i: int = int(roundi(maximum / 10.0))
	_hp_text.text = "%d / %d" % [cur_i, max_i]


func set_lives(lives: int) -> void:
	_lives_text.text = "Lives: %d" % maxi(0, lives)


func set_wave(wave_number: int) -> void:
	_wave_text.text = "Wave: %d" % maxi(1, wave_number)


func set_boss_hp(current_hp: float, maximum_hp: float) -> void:
	if _boss_hp_bar == null:
		return
	var max_h: float = maxf(1.0, maximum_hp)
	var cur: float = clampf(current_hp, 0.0, max_h)
	_boss_hp_bar.max_value = max_h
	_boss_hp_bar.value = cur
	_boss_hp_bar.visible = true


func hide_boss_hp_bar() -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = false


func show_boss_banner(duration: float = 2.0) -> void:
	_boss_banner_ticket += 1
	var ticket: int = _boss_banner_ticket
	_boss_banner.visible = true
	await get_tree().create_timer(maxf(0.1, duration)).timeout
	if ticket == _boss_banner_ticket:
		_boss_banner.visible = false


func show_game_over() -> void:
	hide_boss_hp_bar()
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


func _on_pause_quit_button_pressed() -> void:
	pause_quit_requested.emit()
