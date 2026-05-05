# audio/music/

Music loops and stingers. See [`docs/AUDIO_GUIDE.md`](../../docs/AUDIO_GUIDE.md) for full spec.

## Required files (first pass)

### Loops (`.ogg`, seamless)
- `mus_menu.ogg` — main menu attract loop (110-130 BPM).
- `mus_gameplay.ogg` — regular wave combat loop (130-150 BPM).
- `mus_boss.ogg` — boss wave loop (150-170 BPM).
- `mus_pause.ogg` — optional filtered ambient bed for pause overlay.

### Stingers (`.ogg`, non-looping)
- `sting_boss_intro.ogg` — plays with the BOSS WAVE banner.
- `sting_game_over.ogg` — plays when the player's last life is lost.
- `sting_wave_clear.ogg` — optional wave milestone sting.

## Authoring notes
- Target ~ -16 LUFS integrated, peaks <= -3 dBTP.
- Trim silence at start; bake the loop point at the bar boundary.
- Mix mono-compatible; reserve stereo width for boss + stingers.
