extends Node

# Centralized audio playback for music, stingers, and SFX.
# Resolves logical IDs to res:// paths and gracefully no-ops when assets are missing,
# so the project can be authored incrementally per docs/AUDIO_GUIDE.md.

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

const SFX_VOICE_COUNT: int = 16

const MUSIC_DEFAULT_FADE: float = 0.5
const MUSIC_PAUSE_DUCK_DB: float = -12.0
const MUSIC_RESUME_FADE: float = 0.5
const MUSIC_PAUSE_FADE: float = 0.3
const MUSIC_DUCK_AMOUNT_DB: float = 4.0
const MUSIC_DUCK_HOLD: float = 0.4
const MUSIC_DUCK_RECOVER: float = 0.6
const MUSIC_SILENT_DB: float = -40.0

const MUSIC_PATHS: Dictionary[String, String] = {
	"menu": "res://audio/music/mus_menu.ogg",
	"gameplay": "res://audio/music/mus_gameplay.ogg",
	"boss": "res://audio/music/mus_boss.ogg",
	"pause": "res://audio/music/mus_pause.ogg",
}

const STINGER_PATHS: Dictionary[String, String] = {
	"boss_intro": "res://audio/music/sting_boss_intro.ogg",
	"game_over": "res://audio/music/sting_game_over.ogg",
	"wave_clear": "res://audio/music/sting_wave_clear.ogg",
}

const SFX_PATHS: Dictionary[String, String] = {
	"player_shot": "res://audio/sfx/sfx_player_shot.wav",
	"player_hit": "res://audio/sfx/sfx_player_hit.wav",
	"player_death": "res://audio/sfx/sfx_player_death.wav",
	"player_respawn_in": "res://audio/sfx/sfx_player_respawn_in.wav",
	"player_respawn_out": "res://audio/sfx/sfx_player_respawn_out.wav",
	"enemy_normal_shot": "res://audio/sfx/sfx_enemy_normal_shot.wav",
	"enemy_tank_shot": "res://audio/sfx/sfx_enemy_tank_shot.wav",
	"enemy_speedster_shot": "res://audio/sfx/sfx_enemy_speedster_shot.wav",
	"enemy_hit": "res://audio/sfx/sfx_enemy_hit.wav",
	"enemy_kill": "res://audio/sfx/sfx_enemy_kill.wav",
	"boss_telegraph": "res://audio/sfx/sfx_boss_telegraph.wav",
	"boss_shot": "res://audio/sfx/sfx_boss_shot.wav",
	"boss_hit": "res://audio/sfx/sfx_boss_hit.wav",
	"boss_death": "res://audio/sfx/sfx_boss_death.wav",
	"ui_hover": "res://audio/sfx/sfx_ui_hover.wav",
	"ui_click": "res://audio/sfx/sfx_ui_click.wav",
	"ui_back": "res://audio/sfx/sfx_ui_back.wav",
	"state_pause": "res://audio/sfx/sfx_state_pause.wav",
	"state_resume_tick": "res://audio/sfx/sfx_state_resume_tick.wav",
	"state_wave_start": "res://audio/sfx/sfx_state_wave_start.wav",
	"state_restart": "res://audio/sfx/sfx_state_restart.wav",
}

var _music_player: AudioStreamPlayer
var _stinger_player: AudioStreamPlayer
var _sfx_voices: Array[AudioStreamPlayer] = []

var _current_music_id: String = ""
var _music_fade_tween: Tween
var _duck_tween: Tween

# When `res://audio/...` files are absent, generate tiny PCM loops/blips so the
# game is audible during development. Drop real assets to replace these.
var _procedural_warned: bool = false
var _procedural_cache: Dictionary[String, AudioStreamWAV] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = _make_player(MUSIC_BUS)
	_stinger_player = _make_player(MUSIC_BUS)

	for i in range(SFX_VOICE_COUNT):
		_sfx_voices.append(_make_player(SFX_BUS))


# region: Public API ---------------------------------------------------------

func play_music(id: String, fade_in: float = MUSIC_DEFAULT_FADE, restart: bool = false) -> void:
	if id == _current_music_id and _music_player.playing and not restart:
		return
	var stream: AudioStream = _try_load_stream(MUSIC_PATHS.get(id, ""))
	_current_music_id = id
	if stream == null:
		_music_player.stop()
		return

	_kill_tween(_music_fade_tween)
	_ensure_loop(stream)
	_music_player.stream = stream
	if fade_in > 0.0:
		_music_player.volume_db = MUSIC_SILENT_DB
		_music_player.play()
		_music_fade_tween = _create_tween_safe()
		if _music_fade_tween != null:
			_music_fade_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)
	else:
		_music_player.volume_db = 0.0
		_music_player.play()


func stop_music(fade_out: float = MUSIC_DEFAULT_FADE) -> void:
	_current_music_id = ""
	if not _music_player.playing:
		return
	_kill_tween(_music_fade_tween)
	if fade_out <= 0.0:
		_music_player.stop()
		return
	_music_fade_tween = _create_tween_safe()
	if _music_fade_tween == null:
		_music_player.stop()
		return
	_music_fade_tween.tween_property(_music_player, "volume_db", MUSIC_SILENT_DB, fade_out)
	_music_fade_tween.tween_callback(Callable(_music_player, "stop"))


func play_stinger(id: String) -> void:
	var stream: AudioStream = _try_load_stream(STINGER_PATHS.get(id, ""))
	if stream == null:
		return
	_stinger_player.stream = stream
	_stinger_player.play()
	duck_music()


func duck_music(amount_db: float = MUSIC_DUCK_AMOUNT_DB, hold: float = MUSIC_DUCK_HOLD, recover: float = MUSIC_DUCK_RECOVER) -> void:
	if not _music_player.playing:
		return
	_kill_tween(_duck_tween)
	_duck_tween = _create_tween_safe()
	if _duck_tween == null:
		return
	_duck_tween.tween_property(_music_player, "volume_db", -absf(amount_db), 0.05)
	_duck_tween.tween_interval(maxf(0.0, hold))
	_duck_tween.tween_property(_music_player, "volume_db", 0.0, maxf(0.05, recover))


func fade_music_to(target_db: float, duration: float) -> void:
	_kill_tween(_music_fade_tween)
	_music_fade_tween = _create_tween_safe()
	if _music_fade_tween == null:
		_music_player.volume_db = target_db
		return
	_music_fade_tween.tween_property(_music_player, "volume_db", target_db, maxf(0.0, duration))


func pause_music_dip() -> void:
	fade_music_to(MUSIC_PAUSE_DUCK_DB, MUSIC_PAUSE_FADE)


func resume_music_restore() -> void:
	fade_music_to(0.0, MUSIC_RESUME_FADE)


func play_sfx(id: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	var stream: AudioStream = _try_load_stream(SFX_PATHS.get(id, ""))
	if stream == null:
		return
	var voice: AudioStreamPlayer = _get_free_voice()
	if voice == null:
		return
	voice.stream = stream
	voice.pitch_scale = maxf(0.05, pitch_scale)
	voice.volume_db = volume_offset_db
	voice.play()


func play_resume_tick(seconds_left: int) -> void:
	# 3 -> base, 2 -> +2 semitones, 1 -> +4 semitones (rising urgency).
	var step: int = clampi(3 - seconds_left, 0, 3)
	var pitch: float = pow(2.0, step * (2.0 / 12.0))
	play_sfx("state_resume_tick", pitch)


# endregion ------------------------------------------------------------------


func _make_player(bus_name: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = bus_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func _try_load_stream(path: Variant) -> AudioStream:
	# Accept Variant so Dictionary.get() / strict typing never trips a parse error.
	var s: String = path if path is String else str(path)
	if s == "":
		return null
	if ResourceLoader.exists(s):
		var res: Resource = ResourceLoader.load(s)
		return res as AudioStream
	return _get_procedural_stream(s)


func _get_procedural_stream(res_path: String) -> AudioStreamWAV:
	if _procedural_cache.has(res_path):
		return _procedural_cache[res_path]
	if not _procedural_warned:
		_procedural_warned = true
		push_warning(
			"Audio assets missing under res://audio/. Using procedural placeholders. "
			+ "Add files listed in docs/AUDIO_GUIDE.md to hear final mix."
		)
	var wav: AudioStreamWAV = _build_procedural_for_path(res_path)
	_procedural_cache[res_path] = wav
	return wav


func _build_procedural_for_path(res_path: String) -> AudioStreamWAV:
	var file: String = res_path.get_file().to_lower()
	match file:
		"mus_menu.ogg":
			return _proc_wav_pad(3.2, PackedFloat32Array([261.63, 329.63, 392.0]), 0.07)
		"mus_gameplay.ogg":
			return _proc_wav_pad(2.6, PackedFloat32Array([220.0, 277.18, 349.23, 440.0]), 0.065)
		"mus_boss.ogg":
			return _proc_wav_pad(2.0, PackedFloat32Array([146.83, 196.0, 246.94, 293.66]), 0.08)
		"mus_pause.ogg":
			return _proc_wav_pad(4.0, PackedFloat32Array([174.61, 220.0]), 0.06)
		"sting_boss_intro.ogg":
			return _proc_wav_chirp(0.42, 220.0, 880.0, 0.28, false)
		"sting_game_over.ogg":
			return _proc_wav_chirp(0.55, 392.0, 98.0, 0.3, false)
		"sting_wave_clear.ogg":
			return _proc_wav_chirp(0.28, 523.25, 1046.5, 0.22, false)
		_:
			return _proc_sfx_for_filename(file)


func _proc_sfx_for_filename(file: String) -> AudioStreamWAV:
	# Explicit tuning for readability; fallback: deterministic variety from hash.
	var p_raw: Variant = _PROC_SFX_PARAMS.get(file, [])
	var p: Array = []
	if p_raw is Array:
		p = p_raw as Array
	if p.size() >= 3:
		return _proc_wav_blip(_variant_to_f(p[0]), _variant_to_f(p[1]), _variant_to_f(p[2]), false)
	var h: int = int(hash(file))
	var h_abs: int = absi(h)
	var f: float = 320.0 + float(h_abs % 900)
	var d: float = 0.045 + float(absi(h >> 3) % 5) * 0.012
	var v: float = 0.22 + float(absi(h >> 7) % 6) * 0.02
	return _proc_wav_blip(f, d, v, false)


# freq_hz, duration_sec, peak_linear
const _PROC_SFX_PARAMS: Dictionary = {
	"sfx_player_shot.wav": [1250.0, 0.05, 0.32],
	"sfx_player_hit.wav": [180.0, 0.12, 0.42],
	"sfx_player_death.wav": [110.0, 0.35, 0.45],
	"sfx_player_respawn_in.wav": [660.0, 0.14, 0.28],
	"sfx_player_respawn_out.wav": [880.0, 0.1, 0.26],
	"sfx_enemy_normal_shot.wav": [520.0, 0.055, 0.24],
	"sfx_enemy_tank_shot.wav": [220.0, 0.09, 0.3],
	"sfx_enemy_speedster_shot.wav": [900.0, 0.035, 0.22],
	"sfx_enemy_hit.wav": [480.0, 0.04, 0.2],
	"sfx_enemy_kill.wav": [740.0, 0.08, 0.26],
	"sfx_boss_telegraph.wav": [160.0, 0.2, 0.35],
	"sfx_boss_shot.wav": [310.0, 0.1, 0.34],
	"sfx_boss_hit.wav": [140.0, 0.07, 0.36],
	"sfx_boss_death.wav": [98.0, 0.45, 0.4],
	"sfx_ui_hover.wav": [1200.0, 0.02, 0.16],
	"sfx_ui_click.wav": [1000.0, 0.035, 0.24],
	"sfx_ui_back.wav": [700.0, 0.045, 0.22],
	"sfx_state_pause.wav": [440.0, 0.08, 0.26],
	"sfx_state_resume_tick.wav": [523.25, 0.06, 0.28],
	"sfx_state_wave_start.wav": [587.33, 0.1, 0.27],
	"sfx_state_restart.wav": [784.0, 0.12, 0.3],
}


func _proc_wav_pad(duration: float, freqs: PackedFloat32Array, vol_each: float) -> AudioStreamWAV:
	var mix_rate: int = 44100
	var n: int = maxi(2, int(duration * float(mix_rate)))
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(mix_rate)
		var env: float = sin(PI * float(i) / float(n - 1))
		var acc: float = 0.0
		for k in range(freqs.size()):
			var fk: float = freqs[k]
			acc += sin(TAU * fk * t) * vol_each
		acc = clampf(acc * env, -1.0, 1.0)
		_pcm_write_s16le(data, i * 2, int(acc * 32767.0))
	return _wrap_pcm_mono16(data, mix_rate, true)


func _proc_wav_chirp(duration: float, f0: float, f1: float, vol: float, loop: bool) -> AudioStreamWAV:
	var mix_rate: int = 44100
	var n: int = maxi(8, int(duration * float(mix_rate)))
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	for i in range(n):
		var lin_t: float = float(i) / float(n - 1)
		var f: float = lerpf(f0, f1, lin_t)
		phase += TAU * f / float(mix_rate)
		var env: float = smoothstep(0.0, 0.08, lin_t) * (1.0 - smoothstep(0.75, 1.0, lin_t))
		var s: float = sin(phase) * vol * env
		s = clampf(s, -1.0, 1.0)
		_pcm_write_s16le(data, i * 2, int(s * 32767.0))
	return _wrap_pcm_mono16(data, mix_rate, loop)


func _proc_wav_blip(freq_hz: float, duration: float, vol: float, loop: bool) -> AudioStreamWAV:
	var mix_rate: int = 44100
	var n: int = maxi(8, int(duration * float(mix_rate)))
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(mix_rate)
		var env: float = exp(-22.0 * t)
		var s: float = sin(TAU * freq_hz * t) * vol * env
		s = clampf(s, -1.0, 1.0)
		_pcm_write_s16le(data, i * 2, int(s * 32767.0))
	return _wrap_pcm_mono16(data, mix_rate, loop)


func _wrap_pcm_mono16(pcm: PackedByteArray, mix_rate: int, loop: bool) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	return stream


func _pcm_write_s16le(data: PackedByteArray, offset: int, sample: int) -> void:
	var s: int = clampi(sample, -32768, 32767)
	data[offset] = s & 0xFF
	data[offset + 1] = (s >> 8) & 0xFF


func _variant_to_f(v: Variant) -> float:
	match typeof(v):
		TYPE_FLOAT:
			return v as float
		TYPE_INT:
			return float(v as int)
		TYPE_BOOL:
			return 1.0 if (v as bool) else 0.0
		_:
			return 0.0


func _ensure_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD


func _get_free_voice() -> AudioStreamPlayer:
	for v in _sfx_voices:
		if not v.playing:
			return v
	if _sfx_voices.size() > 0:
		return _sfx_voices[0]
	return null


func _kill_tween(t: Tween) -> void:
	if t != null and t.is_valid():
		t.kill()


func _create_tween_safe() -> Tween:
	# Tweens created here are bound to this AudioManager autoload, which is
	# PROCESS_MODE_ALWAYS, so they keep running through SceneTree pauses
	# (needed for music fade/duck during the pause overlay).
	return create_tween()
