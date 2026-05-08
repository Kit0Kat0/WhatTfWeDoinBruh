extends CanvasLayer
class_name HUD

signal pause_quit_requested
signal meta_perk_chosen(which: int)

@onready var _hp_bar: ProgressBar = %HPBar
@onready var _player_hp_hurt_bar: ProgressBar = %PlayerHpHurtBar
@onready var _player_hp_bar_stack: Control = %PlayerHpBarStack
@onready var _hp_text: Label = %HPText
@onready var _heat_map_indicators: HudHeatMapIndicators = %HeatMapIndicators
@onready var _top_left_panel: Control = %TopLeft
@onready var _lives_icons: HBoxContainer = %LivesIcons
@onready var _boss_banner: Label = %BossBanner
@onready var _wave_center_text: Label = %WaveCenterText
@onready var _boss_hp_bar: TextureProgressBar = %BossHpBar
@onready var _boss_hurt_bar: TextureProgressBar = %BossHpHurtBar
@onready var _perk_timer_bar: ProgressBar = %PerkTimerBar
@onready var _game_over_panel: ColorRect = %GameOverPanel
@onready var _wave_reached_text: Label = %WaveReachedText
@onready var _level_label: Label = %LevelLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _game_over_score_text: Label = %GameOverScoreText
@onready var _game_over_level_text: Label = %GameOverLevelText
@onready var _game_over_perk_count_text: Label = %GameOverPerkCountText
@onready var _game_over_meta_scroll: ScrollContainer = %GameOverMetaScroll
@onready var _game_over_perk_list: VBoxContainer = %GameOverPerkList
@onready var _game_over_perk_tooltip: PanelContainer = %GameOverPerkTooltip
@onready var _game_over_perk_tooltip_label: Label = %TooltipLabel
@onready var _pause_panel: ColorRect = %PausePanel
@onready var _pause_text: Label = %PauseText
@onready var _pause_hint_text: Label = %PauseHintText
@onready var _pause_quit_button: Button = %PauseQuitButton
@onready var _resume_radial: HudRadialCountdown = %ResumeRadial
@onready var _pause_settings_button: Button = %PauseSettingsButton
@onready var _pause_settings_panel: Panel = %PauseSettingsPanel
@onready var _pause_settings_blocker: ColorRect = %PauseSettingsModalBlocker
@onready var _pause_perk_panel: PanelContainer = %PausePerkPanel
@onready var _pause_perk_scroll: ScrollContainer = %PausePerkScroll
@onready var _pause_perk_list: VBoxContainer = %PausePerkList
@onready var _pause_perk_tooltip: PanelContainer = %PausePerkTooltip
@onready var _pause_perk_tooltip_label: Label = %PausePerkTooltipLabel
@onready var _pause_music_slider: HSlider = %PauseMusicSlider
@onready var _pause_music_value: Label = %PauseMusicValue
@onready var _pause_sfx_slider: HSlider = %PauseSfxSlider
@onready var _pause_sfx_value: Label = %PauseSfxValue
@onready var _pause_auto_shoot_button: Button = %PauseAutoShootButton
@onready var _pause_focus_mode_button: Button = %PauseFocusModeButton
@onready var _pause_unpause_delay_option: OptionButton = %PauseUnpauseDelayOption
@onready var _pause_settings_close_button: Button = %PauseSettingsCloseButton

var _wave_center_ticket: int = 0
var _boss_banner_ticket: int = 0
var _perk_fill_style: StyleBoxFlat
var _perk_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat
var _hp_bg_style: StyleBoxFlat
var _hp_bar_empty_bg: StyleBoxEmpty
var _player_hurt_fill_style: StyleBoxFlat
var _player_hurt_bg_style: StyleBoxFlat

@export var life_icon_texture: Texture2D = preload("res://art/player/player_frame_0.png")
@export var life_icon_size_px: int = 18
@export var wave_center_duration_sec: float = 1.15

## HP bar width scales with max HP using diminishing returns (sqrt); caps at this viewport fraction.
@export var hp_bar_max_viewport_fraction: float = 0.5
## Matches default player max HP — bar width equals `hp_bar_reference_width_px` here before clamping.
@export var hp_bar_reference_max_hp: float = 250.0
@export var hp_bar_reference_width_px: float = 140.0
@export var hp_bar_min_width_px: float = 96.0
## Extra horizontal space in the HP row besides the bar (“HP”, gaps, “250 / 250” text).
@export var hp_bar_row_chrome_extra_px: float = 132.0
## Below this fraction of max HP (exclusive), the bar fill flashes white ↔ red.
@export_range(0.05, 0.45, 0.01) var hp_low_warning_ratio: float = 0.2
## How fast the low-HP warning pulses (full sine cycles per second).
@export_range(2.0, 24.0, 0.5) var hp_low_flash_hz: float = 8.0

## Score rolls up toward the real value; base speed plus extra speed proportional to how far behind the target display is.
@export var score_tick_points_per_sec: float = 380.0
## Extra rolled score per second, multiplied by the gap (target − displayed); bigger lag → faster catch-up.
@export var score_tick_gap_accel_per_point: float = 12.0
@export var score_tick_max_catchup_sec: float = 1.05

var _last_wave_number: int = 1
var _hp_bar_height_px: float = 16.0
var _last_hp_max_for_bar: float = -1.0
var _score_displayed: int = 0
var _score_target: int = 0

@export var boss_hurt_delay_sec: float = 0.35
@export var boss_hurt_drop_per_sec: float = 450.0

var _boss_hurt_delay_left: float = 0.0
var _boss_hurt_target: float = 0.0

var _player_hurt_delay_left: float = 0.0
var _player_hurt_target: float = 0.0
var _player_hp_hurt_bar_armed: bool = false

var _hp_low_flash_phase: float = 0.0
var _hp_bar_in_low_warning_flash: bool = false

@onready var _xp_bar: HudMetaXpBar = %MetaXpBar

## Meta perk pick: panel backgrounds by `MetaProgression.Rarity` order (common → mythical).
const _META_RARITY_PANEL_BG: Array[Color] = [
	Color(0.94, 0.94, 0.96, 1.0),
	Color(0.14, 0.38, 0.82, 1.0),
	Color(0.93, 0.82, 0.22, 1.0),
	Color(0.76, 0.11, 0.18, 1.0),
]
const _META_RARITY_TITLE_COL: Array[Color] = [
	Color(0.07, 0.07, 0.09, 1.0),
	Color(0.98, 0.99, 1.0, 1.0),
	Color(0.14, 0.11, 0.03, 1.0),
	Color(1.0, 0.94, 0.94, 1.0),
]
const _META_RARITY_BODY_COL: Array[Color] = [
	Color(0.12, 0.13, 0.17, 0.94),
	Color(0.86, 0.92, 1.0, 0.95),
	Color(0.22, 0.18, 0.06, 0.94),
	Color(0.94, 0.82, 0.82, 0.92),
]
const _META_RARITY_LINE_COL: Array[Color] = [
	Color(0.38, 0.39, 0.44, 0.65),
	Color(0.06, 0.12, 0.28, 0.72),
	Color(0.52, 0.38, 0.08, 0.72),
	Color(0.38, 0.06, 0.1, 0.72),
]
const _META_RARITY_CAPTION_COL: Array[Color] = [
	Color(0.28, 0.29, 0.34, 0.92),
	Color(0.72, 0.82, 0.98, 0.9),
	Color(0.34, 0.28, 0.1, 0.88),
	Color(0.88, 0.72, 0.74, 0.88),
]

var _meta_pick_panel: ColorRect
var _meta_offer_cards: Array[PanelContainer] = []
var _meta_queue_label: Label
var _meta_hover_arrow: Label

var _game_over_tooltip_text: String = ""
var _pause_tooltip_text: String = ""
var _player_level_display: int = 0
var _resume_countdown_total: float = 0.0
var _resume_countdown_left: float = 0.0
var _pause_panel_color_paused: Color = Color(0, 0, 0, 0.62)
var _pause_panel_color_resume: Color = Color(0, 0, 0, 0.22)

var _heat_map_enabled: bool = false

var _low_hp_border_frame: PlayfieldFrame

var _focus_mode_hiding_ui: bool = false
var _focus_restore_boss_hp: bool = false
var _focus_restore_boss_hurt: bool = false
var _focus_restore_perk_timer: bool = false
var _focus_restore_wave_center: bool = false
var _focus_restore_boss_banner: bool = false


func _ready() -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.fill_mode = TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT
	if _boss_hurt_bar != null:
		_boss_hurt_bar.fill_mode = TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT
	if _hp_bar != null:
		var sy: float = _hp_bar.custom_minimum_size.y
		if sy <= 0.001 and _player_hp_bar_stack != null:
			sy = _player_hp_bar_stack.custom_minimum_size.y
		_hp_bar_height_px = sy
	_sync_hp_bar_style()
	_sync_player_hurt_bar_style()
	_build_meta_level_pick_ui()
	var vp: Viewport = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_on_viewport_size_changed_hp_bar):
		vp.size_changed.connect(_on_viewport_size_changed_hp_bar)
	set_process(true)
	# Optional: drive border low-HP flash if a PlayfieldFrame is present in the scene.
	var parent_node: Node = get_parent()
	if parent_node != null:
		_low_hp_border_frame = parent_node.get_node_or_null(^"PlayfieldFrame") as PlayfieldFrame
	if _pause_panel != null:
		_pause_panel_color_paused = _pause_panel.color
	_setup_pause_settings_ui()
	_sync_focus_mode_ui()
	_hide_pause_tooltip()


func _setup_pause_settings_ui() -> void:
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = false
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = false

	if _pause_settings_button != null and not _pause_settings_button.pressed.is_connected(_on_pause_settings_button_pressed):
		_pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)
	if _pause_settings_close_button != null and not _pause_settings_close_button.pressed.is_connected(_on_pause_settings_close_button_pressed):
		_pause_settings_close_button.pressed.connect(_on_pause_settings_close_button_pressed)

	if _pause_music_slider != null and not _pause_music_slider.value_changed.is_connected(_on_pause_music_slider_value_changed):
		_pause_music_slider.value_changed.connect(_on_pause_music_slider_value_changed)
	if _pause_sfx_slider != null and not _pause_sfx_slider.value_changed.is_connected(_on_pause_sfx_slider_value_changed):
		_pause_sfx_slider.value_changed.connect(_on_pause_sfx_slider_value_changed)
	if _pause_auto_shoot_button != null and not _pause_auto_shoot_button.pressed.is_connected(_on_pause_auto_shoot_button_pressed):
		_pause_auto_shoot_button.pressed.connect(_on_pause_auto_shoot_button_pressed)
	if _pause_focus_mode_button != null and not _pause_focus_mode_button.pressed.is_connected(_on_pause_focus_mode_button_pressed):
		_pause_focus_mode_button.pressed.connect(_on_pause_focus_mode_button_pressed)
	if _pause_unpause_delay_option != null and not _pause_unpause_delay_option.item_selected.is_connected(_on_pause_unpause_delay_option_item_selected):
		_pause_unpause_delay_option.item_selected.connect(_on_pause_unpause_delay_option_item_selected)

	if _pause_music_slider != null:
		_pause_music_slider.value = GameSettings.music_volume
	if _pause_sfx_slider != null:
		_pause_sfx_slider.value = GameSettings.sfx_volume
	if _pause_unpause_delay_option != null:
		_pause_unpause_delay_option.clear()
		for i in range(GameSettings.UNPAUSE_DELAY_DISPLAY.size()):
			_pause_unpause_delay_option.add_item(GameSettings.UNPAUSE_DELAY_DISPLAY[i], i)
		_pause_unpause_delay_option.select(clampi(GameSettings.unpause_delay_mode, 0, GameSettings.UNPAUSE_DELAY_DISPLAY.size() - 1))
	_refresh_pause_settings_labels()


func _refresh_pause_settings_labels() -> void:
	if _pause_music_value != null:
		_pause_music_value.text = "%d%%" % int(roundf(GameSettings.music_volume * 100.0))
	if _pause_sfx_value != null:
		_pause_sfx_value.text = "%d%%" % int(roundf(GameSettings.sfx_volume * 100.0))
	if _pause_auto_shoot_button != null:
		var state: String = "On" if GameSettings.automatic_shooting else "Off"
		_pause_auto_shoot_button.text = "Automatic Shooting: %s" % state
	if _pause_focus_mode_button != null:
		var fm: String = "On" if GameSettings.focus_mode else "Off"
		_pause_focus_mode_button.text = "Focus Mode: %s" % fm


func _on_pause_settings_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = true
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = true


func _on_pause_settings_close_button_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = false
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = false


func _on_pause_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)
	_refresh_pause_settings_labels()


func _on_pause_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)
	_refresh_pause_settings_labels()


func _on_pause_auto_shoot_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_automatic_shooting(not GameSettings.automatic_shooting)
	_refresh_pause_settings_labels()


func _on_pause_focus_mode_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_focus_mode(not GameSettings.focus_mode)
	_refresh_pause_settings_labels()
	_sync_focus_mode_ui()


func _on_pause_unpause_delay_option_item_selected(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	GameSettings.set_unpause_delay_mode(index)


func _sync_focus_mode_ui() -> void:
	var should_hide_ui: bool = GameSettings.focus_mode
	var suppress_popups: bool = false
	# Focus mode hides ONLY the in-game HUD, not the pause/game-over/level-up UI.
	# However, it should still hide the in-game HUD even while those overlays are visible.
	if _pause_panel != null and _pause_panel.visible:
		suppress_popups = true
	if _game_over_panel != null and _game_over_panel.visible:
		suppress_popups = true
	if is_meta_level_pick_open():
		suppress_popups = true

	if should_hide_ui and not _focus_mode_hiding_ui:
		_focus_mode_hiding_ui = true
		_focus_restore_boss_hp = (_boss_hp_bar != null and _boss_hp_bar.visible)
		_focus_restore_boss_hurt = (_boss_hurt_bar != null and _boss_hurt_bar.visible)
		_focus_restore_perk_timer = (_perk_timer_bar != null and _perk_timer_bar.visible)
		_focus_restore_wave_center = (_wave_center_text != null and _wave_center_text.visible)
		_focus_restore_boss_banner = (_boss_banner != null and _boss_banner.visible)
	elif not should_hide_ui and _focus_mode_hiding_ui:
		_focus_mode_hiding_ui = false
		if _boss_hp_bar != null:
			_boss_hp_bar.visible = _focus_restore_boss_hp
		if _boss_hurt_bar != null:
			_boss_hurt_bar.visible = _focus_restore_boss_hurt
		if _perk_timer_bar != null:
			_perk_timer_bar.visible = _focus_restore_perk_timer
		if _wave_center_text != null:
			_wave_center_text.visible = _focus_restore_wave_center
		if _boss_banner != null:
			_boss_banner.visible = _focus_restore_boss_banner

	if _top_left_panel != null:
		_top_left_panel.visible = not should_hide_ui
	# Popups (wave/boss) are transient; never force them visible.
	# Only hide them while focus-mode is actively hiding UI, or while pause/gameover/levelup are up.
	if _boss_banner != null:
		if should_hide_ui or suppress_popups:
			_boss_banner.visible = false
	if _wave_center_text != null:
		if should_hide_ui or suppress_popups:
			_wave_center_text.visible = false
	if _boss_hp_bar != null:
		if should_hide_ui:
			_boss_hp_bar.visible = false
	if _boss_hurt_bar != null:
		if should_hide_ui:
			_boss_hurt_bar.visible = false
	if _perk_timer_bar != null:
		if should_hide_ui:
			_perk_timer_bar.visible = false
	if _score_label != null:
		_score_label.visible = not should_hide_ui
	if _level_label != null:
		_level_label.visible = not should_hide_ui
	if _xp_bar != null:
		_xp_bar.visible = not should_hide_ui
	if _heat_map_indicators != null:
		# Focus mode should NOT hide heat-map indicators; only the perk enable flag controls them.
		_heat_map_indicators.visible = _heat_map_enabled


func _build_meta_level_pick_ui() -> void:
	_meta_pick_panel = ColorRect.new()
	_meta_pick_panel.z_index = 200
	_meta_pick_panel.visible = false
	_meta_pick_panel.color = Color(0, 0, 0, 0.82)
	_meta_pick_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_meta_pick_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_meta_pick_panel)

	var cx := CenterContainer.new()
	cx.set_anchors_preset(Control.PRESET_FULL_RECT)
	cx.mouse_filter = Control.MOUSE_FILTER_STOP
	_meta_pick_panel.add_child(cx)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	cx.add_child(vb)

	var hdr := Label.new()
	hdr.text = "LEVEL UP — Choose a perk"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 30)
	vb.add_child(hdr)

	_meta_queue_label = Label.new()
	_meta_queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_queue_label.add_theme_font_size_override("font_size", 18)
	_meta_queue_label.modulate = Color(0.82, 0.88, 0.96, 1.0)
	vb.add_child(_meta_queue_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)

	_meta_offer_cards.clear()
	for i in 3:
		var card: PanelContainer = _make_meta_offer_card(i)
		row.add_child(card)
		_meta_offer_cards.append(card)

	_meta_hover_arrow = Label.new()
	_meta_hover_arrow.text = "▲"
	_meta_hover_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meta_hover_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_hover_arrow.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_meta_hover_arrow.add_theme_font_size_override("font_size", 34)
	_meta_hover_arrow.modulate = Color(0.92, 0.96, 1.0, 0.96)
	_meta_hover_arrow.visible = false
	_meta_hover_arrow.z_index = 210
	add_child(_meta_hover_arrow)


func _make_meta_offer_card(slot_index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(312, 208)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb_placeholder := StyleBoxFlat.new()
	sb_placeholder.bg_color = Color(0.12, 0.13, 0.16, 1.0)
	sb_placeholder.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", sb_placeholder)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var line_wrap := MarginContainer.new()
	line_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line_wrap.add_theme_constant_override("margin_top", 8)
	line_wrap.add_theme_constant_override("margin_bottom", 8)

	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.name = "AccentLine"
	line.custom_minimum_size = Vector2(4, 2)
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.color = Color(0.35, 0.36, 0.4, 0.65)

	line_wrap.add_child(line)

	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 10)

	var title_lbl := Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.name = "TitleLabel"
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_lbl.add_theme_font_size_override("font_size", 22)

	var desc_lbl := Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.name = "DescLabel"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_lbl.add_theme_font_size_override("font_size", 14)

	var rarity_lbl := Label.new()
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_lbl.name = "RarityLabel"
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rarity_lbl.add_theme_font_size_override("font_size", 11)

	var stack_lbl := Label.new()
	stack_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack_lbl.name = "StackLabel"
	stack_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stack_lbl.add_theme_font_size_override("font_size", 12)
	stack_lbl.visible = false

	texts.add_child(title_lbl)
	texts.add_child(desc_lbl)
	texts.add_child(stack_lbl)
	texts.add_child(rarity_lbl)

	row.add_child(line_wrap)
	row.add_child(texts)
	card.add_child(row)

	var idx_loc: int = slot_index
	card.mouse_entered.connect(_on_meta_offer_card_mouse_entered.bind(card))
	card.mouse_exited.connect(func() -> void:
		call_deferred("_meta_offer_refresh_hover_arrow")
	)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				meta_perk_chosen.emit(idx_loc)
	)
	return card


func _meta_offer_rarity_index(offer: Dictionary) -> int:
	var v: Variant = offer.get("rarity", 0)
	if v is int:
		return clampi(v as int, 0, _META_RARITY_PANEL_BG.size() - 1)
	if v is float:
		return clampi(int(v as float), 0, _META_RARITY_PANEL_BG.size() - 1)
	return 0


func _populate_meta_offer_card(card: PanelContainer, offer: Dictionary) -> void:
	var r_idx: int = _meta_offer_rarity_index(offer)
	var rarity_name: String = str(offer.get("rarity_name", ""))
	if rarity_name.is_empty():
		rarity_name = MetaProgression.RARITY_DISPLAY_NAME[r_idx]

	var sb := StyleBoxFlat.new()
	sb.bg_color = _META_RARITY_PANEL_BG[r_idx]
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)

	var line := card.find_child("AccentLine", true, false) as ColorRect
	if line != null:
		line.color = _META_RARITY_LINE_COL[r_idx]

	var title_lbl := card.find_child("TitleLabel", true, false) as Label
	var desc_lbl := card.find_child("DescLabel", true, false) as Label
	var stack_lbl := card.find_child("StackLabel", true, false) as Label
	var rarity_lbl := card.find_child("RarityLabel", true, false) as Label
	if title_lbl != null:
		title_lbl.text = str(offer.get("title", ""))
		title_lbl.modulate = _META_RARITY_TITLE_COL[r_idx]
	if desc_lbl != null:
		desc_lbl.text = str(offer.get("description", ""))
		desc_lbl.modulate = _META_RARITY_BODY_COL[r_idx]
	if stack_lbl != null:
		var cap_v: Variant = offer.get("stack_cap", -1)
		var owned_v: Variant = offer.get("owned", 0)
		var cap: int = -1
		if cap_v is int:
			cap = cap_v as int
		elif cap_v is float:
			cap = int(cap_v as float)
		elif cap_v is bool:
			cap = 1 if (cap_v as bool) else 0
		var owned: int = 0
		if owned_v is int:
			owned = owned_v as int
		elif owned_v is float:
			owned = int(owned_v as float)
		elif owned_v is bool:
			owned = 1 if (owned_v as bool) else 0

		if cap == 1:
			stack_lbl.visible = true
			stack_lbl.text = "Unique"
		elif cap > 1:
			stack_lbl.visible = true
			stack_lbl.text = "Limited: %d/%d" % [owned, cap]
		else:
			stack_lbl.visible = false
			stack_lbl.text = ""
		stack_lbl.modulate = _META_RARITY_CAPTION_COL[r_idx]
	if rarity_lbl != null:
		rarity_lbl.text = "(%s)" % rarity_name
		rarity_lbl.modulate = _META_RARITY_CAPTION_COL[r_idx]


func set_meta_xp(current: float, need: float, reset_colored_after_level: bool = false) -> void:
	if _xp_bar == null:
		return
	_xp_bar.set_progress(current, need, reset_colored_after_level)


func is_meta_level_pick_open() -> bool:
	return _meta_pick_panel != null and _meta_pick_panel.visible


func request_meta_perk_choice(offers: Array[Dictionary], queued_level_ups: int = 1) -> int:
	if _meta_queue_label != null:
		if queued_level_ups <= 1:
			_meta_queue_label.text = "1 level-up queued"
		else:
			_meta_queue_label.text = "%d level-ups queued" % queued_level_ups
	if _meta_hover_arrow != null:
		_meta_hover_arrow.visible = false
	for i in range(_meta_offer_cards.size()):
		if i < offers.size():
			_populate_meta_offer_card(_meta_offer_cards[i], offers[i])
			_meta_offer_cards[i].visible = true
			_meta_offer_cards[i].mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			_meta_offer_cards[i].visible = false
			_meta_offer_cards[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meta_pick_panel.visible = true
	var choice: int = await meta_perk_chosen
	_meta_pick_panel.visible = false
	if _meta_hover_arrow != null:
		_meta_hover_arrow.visible = false
	return choice


func _on_meta_offer_card_mouse_entered(card: PanelContainer) -> void:
	if _meta_hover_arrow == null or card == null or not card.visible:
		return
	_meta_offer_place_hover_arrow(card)


func _meta_offer_place_hover_arrow(card: PanelContainer) -> void:
	if _meta_hover_arrow == null or card == null or not is_instance_valid(card):
		return
	if not card.visible:
		_meta_hover_arrow.visible = false
		return
	_meta_hover_arrow.visible = true
	# Label may not have a stable width until laid out; center with a fixed glyph estimate.
	const APPROX_ARROW_W: float = 38.0
	var cx: float = card.global_position.x + card.size.x * 0.5 - APPROX_ARROW_W * 0.5
	var cy: float = card.global_position.y + card.size.y + 10.0
	_meta_hover_arrow.global_position = Vector2(cx, cy)


func _meta_offer_refresh_hover_arrow() -> void:
	if _meta_hover_arrow == null:
		return
	var h: Control = get_viewport().gui_get_hovered_control()
	while h != null:
		if h is PanelContainer and _meta_offer_cards.has(h):
			_meta_offer_place_hover_arrow(h as PanelContainer)
			return
		h = h.get_parent() as Control
	_meta_hover_arrow.visible = false


func _sync_hp_bar_style() -> void:
	if _hp_bar == null:
		return
	if _hp_fill_style == null:
		_hp_fill_style = StyleBoxFlat.new()
		_hp_fill_style.corner_radius_top_left = 6
		_hp_fill_style.corner_radius_top_right = 6
		_hp_fill_style.corner_radius_bottom_left = 6
		_hp_fill_style.corner_radius_bottom_right = 6
	if _hp_bg_style == null:
		_hp_bg_style = StyleBoxFlat.new()
		_hp_bg_style.corner_radius_top_left = 6
		_hp_bg_style.corner_radius_top_right = 6
		_hp_bg_style.corner_radius_bottom_left = 6
		_hp_bg_style.corner_radius_bottom_right = 6
	var col: Color = Color(0.45, 0.95, 1.0, 0.95)
	_hp_fill_style.bg_color = col
	_hp_bg_style.bg_color = Color(col.r, col.g, col.b, 0.18)
	if _hp_bar_empty_bg == null:
		_hp_bar_empty_bg = StyleBoxEmpty.new()
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)
	_hp_bar.add_theme_stylebox_override("background", _hp_bar_empty_bg)


func _sync_player_hurt_bar_style() -> void:
	if _player_hp_hurt_bar == null:
		return
	if _player_hurt_fill_style == null:
		_player_hurt_fill_style = StyleBoxFlat.new()
		_player_hurt_fill_style.corner_radius_top_left = 6
		_player_hurt_fill_style.corner_radius_top_right = 6
		_player_hurt_fill_style.corner_radius_bottom_left = 6
		_player_hurt_fill_style.corner_radius_bottom_right = 6
	if _player_hurt_bg_style == null:
		_player_hurt_bg_style = StyleBoxFlat.new()
		_player_hurt_bg_style.corner_radius_top_left = 6
		_player_hurt_bg_style.corner_radius_top_right = 6
		_player_hurt_bg_style.corner_radius_bottom_left = 6
		_player_hurt_bg_style.corner_radius_bottom_right = 6
	var track_base: Color = Color(0.45, 0.95, 1.0, 0.95)
	_player_hurt_bg_style.bg_color = Color(track_base.r, track_base.g, track_base.b, 0.18)
	_player_hurt_fill_style.bg_color = Color(0.9, 0.12, 0.14, 0.94)
	_player_hp_hurt_bar.add_theme_stylebox_override("fill", _player_hurt_fill_style)
	_player_hp_hurt_bar.add_theme_stylebox_override("background", _player_hurt_bg_style)


func _tick_player_hp_low_flash(delta: float) -> void:
	if _hp_bar == null or _hp_fill_style == null or _hp_bg_style == null:
		return
	var tree: SceneTree = get_tree()
	if tree != null and tree.paused:
		return
	var cur: float = float(_hp_bar.value)
	var mxv: float = maxf(float(_hp_bar.max_value), 1.0)
	var ratio: float = cur / mxv
	if cur <= 0.001 or ratio >= hp_low_warning_ratio:
		if _hp_bar_in_low_warning_flash:
			_hp_bar_in_low_warning_flash = false
			_sync_hp_bar_style()
		return
	_hp_bar_in_low_warning_flash = true
	_hp_low_flash_phase += delta * TAU * hp_low_flash_hz
	var u: float = (sin(_hp_low_flash_phase) + 1.0) * 0.5
	var white := Color(1.0, 1.0, 1.0, 0.95)
	var red := Color(1.0, 0.14, 0.12, 0.95)
	var col: Color = white.lerp(red, u)
	_hp_fill_style.bg_color = col
	_hp_bg_style.bg_color = Color(col.r, col.g, col.b, 0.18)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)
	# Keep the background empty so the red "hurt bar" behind remains visible.
	if _hp_bar_empty_bg == null:
		_hp_bar_empty_bg = StyleBoxEmpty.new()
	_hp_bar.add_theme_stylebox_override("background", _hp_bar_empty_bg)


func _process(delta: float) -> void:
	_tick_player_hp_low_flash(delta)
	_tick_player_hurt_bar(delta)
	_tick_score_display(delta)
	_tick_boss_hurt_bar(delta)
	_tick_resume_countdown(delta)
	# Keep the tooltip near the cursor without affecting layout.
	if _game_over_panel != null and _game_over_panel.visible:
		_position_game_over_tooltip_near_mouse()
	if _pause_panel != null and _pause_panel.visible:
		_position_pause_tooltip_near_mouse()


func start_resume_countdown(total_sec: float) -> void:
	_resume_countdown_total = maxf(0.01, total_sec)
	_resume_countdown_left = _resume_countdown_total
	if _pause_text != null:
		_pause_text.text = ""
		_pause_text.visible = false
	if _pause_hint_text != null:
		_pause_hint_text.visible = false
	if _pause_panel != null:
		_pause_panel.color = _pause_panel_color_resume
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = false
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = false
	if _pause_settings_button != null:
		_pause_settings_button.visible = false
	if _pause_quit_button != null:
		_pause_quit_button.visible = false
	if _resume_radial != null:
		_resume_radial.visible = true
		_resume_radial.set_ratio(1.0)
	if _pause_perk_panel != null:
		_pause_perk_panel.visible = false
	_hide_pause_tooltip()


func _tick_resume_countdown(delta: float) -> void:
	if _resume_countdown_left <= 0.0:
		return
	_resume_countdown_left = maxf(0.0, _resume_countdown_left - maxf(0.0, delta))
	var ratio: float = 0.0
	if _resume_countdown_total > 0.0001:
		ratio = clampf(_resume_countdown_left / _resume_countdown_total, 0.0, 1.0)
	if _resume_radial != null:
		_resume_radial.set_ratio(ratio)
		if _resume_countdown_left <= 0.0:
			_resume_radial.visible = false


func _tick_boss_hurt_bar(delta: float) -> void:
	if _boss_hp_bar == null or _boss_hurt_bar == null:
		return
	if not _boss_hp_bar.visible or not _boss_hurt_bar.visible:
		return
	if _boss_hurt_delay_left > 0.0:
		_boss_hurt_delay_left = maxf(0.0, _boss_hurt_delay_left - delta)
		return

	var cur: float = float(_boss_hurt_bar.value)
	var target: float = _boss_hurt_target
	# Snap once we're close, so we don't asymptote forever.
	if cur <= target + 0.5:
		_boss_hurt_bar.value = target
		return
	# Use a fixed drop rate so the bar catches up even under sustained DPS.
	_boss_hurt_bar.value = move_toward(cur, target, maxf(1.0, boss_hurt_drop_per_sec) * delta)


func _tick_player_hurt_bar(delta: float) -> void:
	if _player_hp_hurt_bar == null:
		return
	if _player_hurt_delay_left > 0.0:
		_player_hurt_delay_left = maxf(0.0, _player_hurt_delay_left - delta)
		return
	var cur: float = float(_player_hp_hurt_bar.value)
	var target: float = _player_hurt_target
	if cur <= target + 0.5:
		_player_hp_hurt_bar.value = target
		return
	_player_hp_hurt_bar.value = move_toward(cur, target, maxf(1.0, boss_hurt_drop_per_sec) * delta)


func _tick_score_display(delta: float) -> void:
	if _score_displayed == _score_target:
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.paused:
		return
	var gap: int = _score_target - _score_displayed
	var gap_abs: float = float(absi(gap))
	var rate: float = score_tick_points_per_sec + gap_abs * score_tick_gap_accel_per_point
	if score_tick_max_catchup_sec > 0.0001:
		rate = maxf(rate, gap_abs / score_tick_max_catchup_sec)
	var step: int = maxi(1, roundi(rate * delta))
	if gap > 0:
		_score_displayed = mini(_score_target, _score_displayed + step)
	else:
		_score_displayed = maxi(_score_target, _score_displayed - step)
	_sync_score_labels()


func set_perk_timer(kind: WeaponPickup.PerkKind, ratio: float) -> void:
	if GameSettings.focus_mode:
		hide_perk_timer()
		return
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
	_last_hp_max_for_bar = maximum
	_apply_hp_bar_width_for_max(maximum)
	var mxv: float = float(maximum)
	var curf: float = float(current)
	_hp_bar.max_value = mxv
	_hp_bar.value = curf
	if _player_hp_hurt_bar != null:
		_player_hp_hurt_bar.max_value = mxv
		if not _player_hp_hurt_bar_armed:
			_player_hp_hurt_bar.value = curf
			_player_hurt_target = curf
			_player_hurt_delay_left = 0.0
			_player_hp_hurt_bar_armed = true
		elif curf < float(_player_hp_hurt_bar.value) - 0.001:
			_player_hurt_target = curf
			_player_hurt_delay_left = maxf(0.0, boss_hurt_delay_sec)
		else:
			_player_hurt_target = minf(_player_hurt_target, curf)
	var mx_for_ratio: float = maxf(maximum, 1.0)
	var ratio: float = curf / mx_for_ratio
	# PlayfieldFrame is spawned by Game.gd after HUD is instantiated, so we may need to lazily reacquire it.
	if _low_hp_border_frame == null:
		var parent_node: Node = get_parent()
		if parent_node != null:
			_low_hp_border_frame = parent_node.get_node_or_null(^"PlayfieldFrame") as PlayfieldFrame
	if _low_hp_border_frame != null:
		_low_hp_border_frame.set_low_hp_warning(current > 0.001 and ratio < hp_low_warning_ratio)
	if ratio >= hp_low_warning_ratio or current <= 0.001:
		if _hp_bar_in_low_warning_flash:
			_hp_bar_in_low_warning_flash = false
			_sync_hp_bar_style()
	var cur_i: int = ceili(current)
	var max_i: int = ceili(maximum)
	_hp_text.text = "%d / %d" % [cur_i, max_i]


func _on_viewport_size_changed_hp_bar() -> void:
	if _last_hp_max_for_bar > 0.0:
		_apply_hp_bar_width_for_max(_last_hp_max_for_bar)


func _hp_bar_width_for_max_hp(max_hp: float) -> float:
	var cap_px: float = get_viewport().get_visible_rect().size.x * clampf(hp_bar_max_viewport_fraction, 0.05, 1.0)
	var ref_hp: float = maxf(1.0, hp_bar_reference_max_hp)
	var m: float = maxf(1.0, max_hp)
	# Sublinear growth: each extra max-HP point adds less width than the last; asymptotes toward cap_px.
	var grown: float = hp_bar_reference_width_px * sqrt(m / ref_hp)
	return clampf(grown, hp_bar_min_width_px, cap_px)


func _apply_hp_bar_width_for_max(max_hp: float) -> void:
	if _hp_bar == null:
		return
	var w: float = _hp_bar_width_for_max_hp(max_hp)
	_hp_bar.custom_minimum_size = Vector2(w, _hp_bar_height_px)
	if _player_hp_bar_stack != null:
		_player_hp_bar_stack.custom_minimum_size = Vector2(w, _hp_bar_height_px)
	if _top_left_panel != null:
		var need_panel_w: float = hp_bar_row_chrome_extra_px + w
		var cur_w: float = _top_left_panel.offset_right - _top_left_panel.offset_left
		var new_w: float = maxf(cur_w, need_panel_w)
		_top_left_panel.offset_right = _top_left_panel.offset_left + new_w


func set_lives(lives: int, show_last_notice_when_empty: bool = true) -> void:
	if _lives_icons == null:
		return
	for c in _lives_icons.get_children():
		c.queue_free()
	var n: int = maxi(0, lives)
	if n <= 0:
		if show_last_notice_when_empty:
			var last_lbl: Label = Label.new()
			last_lbl.text = "LAST LIFE"
			last_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			last_lbl.add_theme_font_size_override("font_size", maxi(life_icon_size_px + 4, 13))
			last_lbl.modulate = Color(1.0, 0.48, 0.38, 1.0)
			_lives_icons.add_child(last_lbl)
		return
	for i in range(n):
		var t := TextureRect.new()
		t.texture = life_icon_texture
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(float(life_icon_size_px), float(life_icon_size_px))
		t.modulate = Color(0.55, 0.95, 1.0, 1.0)
		_lives_icons.add_child(t)


func set_wave(wave_number: int) -> void:
	_last_wave_number = maxi(1, wave_number)
	if _wave_reached_text != null:
		_wave_reached_text.text = "Wave reached: %d" % _last_wave_number


func set_score(score: int) -> void:
	var s: int = maxi(0, score)
	_score_target = s
	if _score_target < _score_displayed:
		_score_displayed = _score_target
	_sync_score_labels()


func set_player_level(level: int) -> void:
	_player_level_display = maxi(0, level)
	if _level_label != null:
		_level_label.text = "Level: %d" % _player_level_display
	# Update game-over label regardless of panel visibility; show_game_over() sets level before making the panel visible.
	if _game_over_level_text != null:
		_game_over_level_text.text = "Level: %d" % _player_level_display


func set_heat_map_enabled(enabled: bool) -> void:
	_heat_map_enabled = enabled
	if _heat_map_indicators != null:
		_heat_map_indicators.enabled = enabled
		# Keep visibility in sync immediately (focus mode must not affect heat-map visibility).
		_heat_map_indicators.visible = enabled


func _sync_score_labels() -> void:
	var txt: String = "Score: %d" % _score_displayed
	if _score_label != null:
		_score_label.text = txt
	if _game_over_score_text != null:
		_game_over_score_text.text = txt


func show_wave_center(wave_number: int) -> void:
	_last_wave_number = maxi(1, wave_number)
	if _wave_center_text == null:
		return
	_wave_center_text.text = "WAVE %d" % _last_wave_number
	_wave_center_text.visible = true
	var ticket: int = _wave_center_ticket + 1
	_wave_center_ticket = ticket
	await get_tree().create_timer(maxf(0.1, wave_center_duration_sec), true).timeout
	if ticket == _wave_center_ticket and is_instance_valid(_wave_center_text):
		_wave_center_text.visible = false


func set_boss_hp(current_hp: float, maximum_hp: float) -> void:
	if _boss_hp_bar == null:
		return
	var max_h: float = maxf(1.0, maximum_hp)
	var cur: float = clampf(current_hp, 0.0, max_h)
	_boss_hp_bar.max_value = max_h
	_boss_hp_bar.value = cur
	_boss_hp_bar.visible = not GameSettings.focus_mode

	if _boss_hurt_bar != null:
		_boss_hurt_bar.max_value = max_h
		if not _boss_hurt_bar.visible and not GameSettings.focus_mode:
			_boss_hurt_bar.value = cur
			_boss_hurt_target = cur
			_boss_hurt_delay_left = 0.0
			_boss_hurt_bar.visible = true
		elif cur < float(_boss_hurt_bar.value) - 0.001:
			_boss_hurt_target = cur
			_boss_hurt_delay_left = maxf(0.0, boss_hurt_delay_sec)
		else:
			_boss_hurt_target = minf(_boss_hurt_target, cur)
	if GameSettings.focus_mode and _boss_hurt_bar != null:
		_boss_hurt_bar.visible = false


func hide_boss_hp_bar() -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = false
	if _boss_hurt_bar != null:
		_boss_hurt_bar.visible = false


func show_boss_banner(duration: float = 2.0, wave_number: int = -1) -> void:
	_wave_center_ticket += 1
	if _wave_center_text != null:
		_wave_center_text.visible = false
	_boss_banner_ticket += 1
	var ticket: int = _boss_banner_ticket
	if wave_number >= 1:
		_boss_banner.text = "BOSS WAVE %d" % wave_number
	else:
		_boss_banner.text = "BOSS WAVE"
	_boss_banner.visible = true
	await get_tree().create_timer(maxf(0.1, duration)).timeout
	if ticket == _boss_banner_ticket:
		_boss_banner.visible = false


func show_game_over(meta_perks: Array[Dictionary] = [], final_score: int = 0, player_level: int = 0) -> void:
	hide_boss_hp_bar()
	if _wave_reached_text != null:
		_wave_reached_text.text = "Wave reached: %d" % _last_wave_number
	set_score(final_score)
	set_player_level(player_level)
	if _game_over_perk_count_text != null:
		_game_over_perk_count_text.text = "Perks picked: %d" % meta_perks.size()
	_build_game_over_perk_list(meta_perks)
	_game_over_panel.visible = true


func _build_game_over_perk_list(meta_perks: Array[Dictionary]) -> void:
	if _game_over_meta_scroll == null or _game_over_perk_list == null:
		return

	for c in _game_over_perk_list.get_children():
		c.queue_free()

	var has_any: bool = not meta_perks.is_empty()
	_game_over_meta_scroll.visible = has_any
	_hide_game_over_tooltip()
	if not has_any:
		return

	for entry: Dictionary in meta_perks:
		var title: String = str(entry.get("title", ""))
		var desc: String = str(entry.get("description", ""))
		var r_idx: int = _meta_offer_rarity_index(entry)

		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.custom_minimum_size = Vector2(0.0, 34.0)

		var bg := StyleBoxFlat.new()
		bg.bg_color = _META_RARITY_PANEL_BG[r_idx]
		bg.corner_radius_top_left = 8
		bg.corner_radius_top_right = 8
		bg.corner_radius_bottom_left = 8
		bg.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("panel", bg)

		var lbl := Label.new()
		lbl.text = title
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.modulate = _META_RARITY_TITLE_COL[r_idx]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lbl)

		card.mouse_entered.connect(func() -> void:
			_show_game_over_tooltip(desc)
		)
		card.mouse_exited.connect(func() -> void:
			_hide_game_over_tooltip()
		)

		_game_over_perk_list.add_child(card)


func _show_game_over_tooltip(text: String) -> void:
	if _game_over_perk_tooltip == null or _game_over_perk_tooltip_label == null:
		return
	_game_over_tooltip_text = text
	_game_over_perk_tooltip_label.text = text
	_game_over_perk_tooltip.visible = text != ""
	_position_game_over_tooltip_near_mouse()


func _hide_game_over_tooltip() -> void:
	_game_over_tooltip_text = ""
	if _game_over_perk_tooltip != null:
		_game_over_perk_tooltip.visible = false


func _position_game_over_tooltip_near_mouse() -> void:
	if _game_over_perk_tooltip == null or not _game_over_perk_tooltip.visible:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vr: Rect2 = vp.get_visible_rect()
	var m: Vector2 = vp.get_mouse_position()
	var pad: float = 12.0
	var pos: Vector2 = m + Vector2(18.0, 18.0)
	# After setting text, size may be stale until next layout pass; clamp using current size anyway.
	var sz: Vector2 = _game_over_perk_tooltip.size
	pos.x = clampf(pos.x, vr.position.x + pad, vr.end.x - pad - maxf(1.0, sz.x))
	pos.y = clampf(pos.y, vr.position.y + pad, vr.end.y - pad - maxf(1.0, sz.y))
	_game_over_perk_tooltip.global_position = pos


func hide_game_over() -> void:
	_game_over_panel.visible = false


func show_paused() -> void:
	_pause_panel.visible = true
	if _pause_text != null:
		_pause_text.text = "PAUSED"
		_pause_text.visible = true
	if _pause_hint_text != null:
		_pause_hint_text.text = "Press Escape to resume"
		_pause_hint_text.visible = true
	if _pause_perk_panel != null and _pause_perk_scroll != null:
		_pause_perk_panel.visible = _pause_perk_scroll.visible
	_hide_pause_tooltip()
	_sync_focus_mode_ui()
	_pause_quit_button.visible = true
	if _pause_panel != null:
		_pause_panel.color = _pause_panel_color_paused
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = false
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = false
	if _pause_settings_button != null:
		_pause_settings_button.visible = true
	_resume_countdown_left = 0.0
	if _resume_radial != null:
		_resume_radial.visible = false


func show_resume_countdown(_seconds_left: int) -> void:
	_pause_panel.visible = true
	if _pause_text != null:
		_pause_text.text = ""
		_pause_text.visible = false
	if _pause_hint_text != null:
		_pause_hint_text.visible = false
	_pause_quit_button.visible = false
	if _resume_radial != null:
		_resume_radial.visible = true
	if _pause_settings_panel != null:
		_pause_settings_panel.visible = false
	if _pause_settings_blocker != null:
		_pause_settings_blocker.visible = false
	if _pause_settings_button != null:
		_pause_settings_button.visible = false
	if _pause_perk_panel != null:
		_pause_perk_panel.visible = false
	_hide_pause_tooltip()


func hide_pause() -> void:
	_pause_panel.visible = false
	_pause_quit_button.visible = false
	_resume_countdown_left = 0.0
	if _pause_hint_text != null:
		_pause_hint_text.visible = false
	if _pause_panel != null:
		_pause_panel.color = _pause_panel_color_paused
	if _resume_radial != null:
		_resume_radial.visible = false
	_hide_pause_tooltip()
	_sync_focus_mode_ui()


func set_pause_perk_history(meta_perks: Array[Dictionary]) -> void:
	_build_pause_perk_list(meta_perks)


func _build_pause_perk_list(meta_perks: Array[Dictionary]) -> void:
	if _pause_perk_scroll == null or _pause_perk_list == null:
		return
	for c in _pause_perk_list.get_children():
		c.queue_free()

	var has_any: bool = not meta_perks.is_empty()
	_pause_perk_scroll.visible = has_any
	if _pause_perk_panel != null:
		_pause_perk_panel.visible = has_any
	_hide_pause_tooltip()
	if not has_any:
		return

	for entry: Dictionary in meta_perks:
		var title: String = _pause_perk_title_without_rarity(str(entry.get("title", "")))
		var desc: String = str(entry.get("description", ""))
		var r_idx: int = _meta_offer_rarity_index(entry)

		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.custom_minimum_size = Vector2(0.0, 30.0)

		var bg := StyleBoxFlat.new()
		bg.bg_color = _META_RARITY_PANEL_BG[r_idx]
		bg.corner_radius_top_left = 8
		bg.corner_radius_top_right = 8
		bg.corner_radius_bottom_left = 8
		bg.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("panel", bg)

		var lbl := Label.new()
		lbl.text = title
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = _META_RARITY_TITLE_COL[r_idx]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lbl)

		card.mouse_entered.connect(func() -> void:
			_show_pause_tooltip(desc)
		)
		card.mouse_exited.connect(func() -> void:
			_hide_pause_tooltip()
		)

		_pause_perk_list.add_child(card)


func _pause_perk_title_without_rarity(title: String) -> String:
	# pick_history titles are stored as "Name (Rarity)" — pause list already encodes rarity by color.
	if title.is_empty():
		return title
	for rname: String in MetaProgression.RARITY_DISPLAY_NAME:
		var suffix: String = " (%s)" % rname
		if title.ends_with(suffix):
			return title.substr(0, title.length() - suffix.length())
	return title


func _show_pause_tooltip(text: String) -> void:
	if _pause_perk_tooltip == null or _pause_perk_tooltip_label == null:
		return
	_pause_tooltip_text = text
	_pause_perk_tooltip_label.text = text
	_pause_perk_tooltip.visible = text != ""
	_position_pause_tooltip_near_mouse()


func _hide_pause_tooltip() -> void:
	_pause_tooltip_text = ""
	if _pause_perk_tooltip != null:
		_pause_perk_tooltip.visible = false


func _position_pause_tooltip_near_mouse() -> void:
	if _pause_perk_tooltip == null or not _pause_perk_tooltip.visible:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vr: Rect2 = vp.get_visible_rect()
	var m: Vector2 = vp.get_mouse_position()
	var pad: float = 12.0
	var pos: Vector2 = m + Vector2(18.0, 18.0)
	var sz: Vector2 = _pause_perk_tooltip.size
	pos.x = clampf(pos.x, vr.position.x + pad, vr.end.x - pad - maxf(1.0, sz.x))
	pos.y = clampf(pos.y, vr.position.y + pad, vr.end.y - pad - maxf(1.0, sz.y))
	_pause_perk_tooltip.global_position = pos


func _on_pause_quit_button_pressed() -> void:
	pause_quit_requested.emit()
