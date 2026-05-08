extends Node

const DEFAULT_MUSIC_VOLUME: float = 0.8
const DEFAULT_SFX_VOLUME: float = 0.8
const SAVE_PATH: String = "user://settings.cfg"

enum UnpauseDelayMode { LONG, SHORT, NONE }
const UNPAUSE_DELAY_DISPLAY: Array[String] = ["Long", "Short", "None"]

# Baselines match `default_bus_layout.tres`.
# User volume is applied as a trim ON TOP of these so user 100% lands at the baseline,
# preserving the readability budget between music and SFX.
const MUSIC_BUS_BASELINE_DB: float = -14.0
const SFX_BUS_BASELINE_DB: float = -8.0

var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var automatic_shooting: bool = false
var unpause_delay_mode: int = int(UnpauseDelayMode.SHORT)
var focus_mode: bool = false


func _ready() -> void:
	_load()
	_apply_audio_settings()

func _variant_to_float(v: Variant, fallback: float) -> float:
	match typeof(v):
		TYPE_FLOAT:
			return v as float
		TYPE_INT:
			return float(v as int)
		TYPE_BOOL:
			return 1.0 if (v as bool) else 0.0
		_:
			return fallback


func _variant_to_bool(v: Variant, fallback: bool) -> bool:
	match typeof(v):
		TYPE_BOOL:
			return v as bool
		TYPE_INT:
			return (v as int) != 0
		TYPE_FLOAT:
			return (v as float) != 0.0
		_:
			return fallback


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	_save()


func set_automatic_shooting(enabled: bool) -> void:
	automatic_shooting = enabled
	_save()


func set_unpause_delay_mode(mode: int) -> void:
	unpause_delay_mode = clampi(mode, 0, UNPAUSE_DELAY_DISPLAY.size() - 1)
	_save()


func set_focus_mode(enabled: bool) -> void:
	focus_mode = enabled
	_save()


func get_unpause_delay_seconds() -> float:
	match unpause_delay_mode:
		int(UnpauseDelayMode.LONG):
			return 3.0
		int(UnpauseDelayMode.NONE):
			return 0.0
		_:
			return 1.0


func _apply_audio_settings() -> void:
	_set_bus_volume_if_exists("Music", music_volume, MUSIC_BUS_BASELINE_DB)
	_set_bus_volume_if_exists("SFX", sfx_volume, SFX_BUS_BASELINE_DB)


func _set_bus_volume_if_exists(bus_name: String, volume_linear: float, baseline_db: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	var trim_db: float = linear_to_db(maxf(0.0001, volume_linear))
	AudioServer.set_bus_volume_db(bus_idx, baseline_db + trim_db)


func _save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("gameplay", "automatic_shooting", automatic_shooting)
	cfg.set_value("gameplay", "unpause_delay_mode", unpause_delay_mode)
	cfg.set_value("gameplay", "focus_mode", focus_mode)
	var err: Error = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save settings to %s (err=%s)" % [SAVE_PATH, str(err)])


func _load() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	if err != OK:
		return
	music_volume = clampf(_variant_to_float(cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME), DEFAULT_MUSIC_VOLUME), 0.0, 1.0)
	sfx_volume = clampf(_variant_to_float(cfg.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME), DEFAULT_SFX_VOLUME), 0.0, 1.0)
	automatic_shooting = _variant_to_bool(cfg.get_value("gameplay", "automatic_shooting", false), false)
	focus_mode = _variant_to_bool(cfg.get_value("gameplay", "focus_mode", false), false)
	var raw_mode: Variant = cfg.get_value("gameplay", "unpause_delay_mode", int(UnpauseDelayMode.SHORT))
	match typeof(raw_mode):
		TYPE_INT:
			unpause_delay_mode = clampi(raw_mode as int, 0, UNPAUSE_DELAY_DISPLAY.size() - 1)
		TYPE_FLOAT:
			unpause_delay_mode = clampi(int(raw_mode as float), 0, UNPAUSE_DELAY_DISPLAY.size() - 1)
		TYPE_BOOL:
			unpause_delay_mode = int(UnpauseDelayMode.SHORT) if (raw_mode as bool) else int(UnpauseDelayMode.NONE)
		_:
			unpause_delay_mode = int(UnpauseDelayMode.SHORT)
