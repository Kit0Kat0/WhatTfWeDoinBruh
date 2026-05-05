# audio/sfx/

One-shot sound effects. See [`docs/AUDIO_GUIDE.md`](../../docs/AUDIO_GUIDE.md) for full spec.

Format: 16-bit WAV, 44.1 kHz, mono unless noted.
Target ~ -10 LUFS short-term, peaks <= -1 dBTP.

## Required files (first pass)

### Player
- `sfx_player_shot.wav`
- `sfx_player_hit.wav`
- `sfx_player_death.wav`
- `sfx_player_respawn_in.wav`
- `sfx_player_respawn_out.wav`

### Enemy
- `sfx_enemy_normal_shot.wav`
- `sfx_enemy_tank_shot.wav`
- `sfx_enemy_speedster_shot.wav`
- `sfx_enemy_hit.wav`
- `sfx_enemy_kill.wav`

### Boss
- `sfx_boss_telegraph.wav`
- `sfx_boss_shot.wav`
- `sfx_boss_hit.wav`
- `sfx_boss_death.wav`

### UI / state
- `sfx_ui_hover.wav`
- `sfx_ui_click.wav`
- `sfx_ui_back.wav`
- `sfx_state_pause.wav`
- `sfx_state_resume_tick.wav` (single sample, AudioManager pitch-shifts per countdown step)
- `sfx_state_wave_start.wav`
- `sfx_state_restart.wav`

## Authoring notes
- Keep first transient < 50 ms so cues read during dense bullet patterns.
- Cut sub-50 Hz on light SFX so they don't muddy boss bass.
- Tank shots: lower-pitch, chunkier transient; speedster: high-pitch, very short tail.
