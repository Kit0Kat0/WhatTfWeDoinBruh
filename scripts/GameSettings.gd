extends Node

const DEFAULT_MUSIC_VOLUME: float = 0.8
const DEFAULT_SFX_VOLUME: float = 0.8
const SAVE_PATH: String = "user://settings.cfg"

# Baselines match `default_bus_layout.tres`.
# User volume is applied as a trim ON TOP of these so user 100% lands at the baseline,
# preserving the readability budget between music and SFX.
const MUSIC_BUS_BASELINE_DB: float = -14.0
const SFX_BUS_BASELINE_DB: float = -8.0

var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var automatic_shooting: bool = false


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
