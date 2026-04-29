extends CanvasLayer
class_name HUD

@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_text: Label = %HPText
@onready var _lives_text: Label = %LivesText
@onready var _wave_text: Label = %WaveText
@onready var _boss_banner: Label = %BossBanner

var _boss_banner_ticket: int = 0


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

