# Virus Hunter — Audio Guide

This is the canonical reference for music and SFX direction, naming, and integration in `Virus Hunter`.

It pairs with the audio plan in `c:\Users\xxjon\.cursor\plans\` and is the runtime contract used by `scripts/AudioManager.gd`.

---

## 1. Direction

### Style
- Retro-futuristic arcade: synthwave + chiptune hybrid with light glitch/cyber overtones.
- Minor key tonal center. Bright lead synths over driving low end.
- "Cyber-viral" texture: short bitcrushed transients, occasional digital noise sweeps.

### Tempo
- **Menu**: 110-130 BPM (relaxed but energetic).
- **Gameplay (regular waves)**: 130-150 BPM.
- **Boss**: 150-170 BPM, doubled drums, sub-bass.
- **Pause loop (optional)**: 70-90 BPM, filtered, drum-less ambient.

### Loudness targets (per asset, before mix)
- Music loops: ~ -16 LUFS integrated, peaks <= -3 dBTP.
- Stingers: ~ -12 LUFS short-term, peaks <= -1 dBTP.
- SFX one-shots: ~ -10 LUFS short-term, peaks <= -1 dBTP.
- Bus headroom is set in `default_bus_layout.tres` so per-asset loudness can stay close to genre standard without clipping when stacked.

---

## 2. Naming conventions

All audio assets live under `res://audio/`.

```
audio/
  music/
    mus_<state>.ogg          # looping music
    sting_<event>.ogg        # short non-looping stingers
  sfx/
    sfx_<source>_<action>[_<variant>].wav
```

- Use **OGG Vorbis** for music/stingers (good loop support, small size).
- Use **WAV** (16-bit, 44.1 kHz, mono unless explicitly stereo) for SFX (low latency, no decode cost).
- Variant suffixes: `_a`, `_b`, `_c` for randomized one-shots.
- IDs in code use snake_case without prefix (e.g. `player_shot`, `enemy_tank_shot`).

---

## 3. First-pass asset checklist

Total: **4 music loops + 3 stingers + 21 SFX = 28 assets**.

### Music loops (`audio/music/`)
| ID         | File                  | When                       | Notes                                              |
|------------|-----------------------|----------------------------|----------------------------------------------------|
| `menu`     | `mus_menu.ogg`        | Main menu (`Main.tscn`)    | Mid-energy attract loop, 60-90s seamless.          |
| `gameplay` | `mus_gameplay.ogg`    | Regular waves              | Primary loop, 90-120s seamless.                    |
| `boss`     | `mus_boss.ogg`        | Boss waves (every 7)       | High-intensity loop, 45-90s seamless.              |
| `pause`    | `mus_pause.ogg`       | Pause overlay (optional)   | Filtered ambient bed; if absent, music just ducks. |

### Stingers (`audio/music/`)
| ID            | File                       | When                                          |
|---------------|----------------------------|-----------------------------------------------|
| `boss_intro`  | `sting_boss_intro.ogg`     | "BOSS WAVE" banner appears.                   |
| `game_over`   | `sting_game_over.ogg`      | Player loses last life.                       |
| `wave_clear`  | `sting_wave_clear.ogg`     | (Optional) Major wave milestone (every 5).    |

### SFX (`audio/sfx/`)
**Player (5)**
| ID                  | File                          | Trigger                                |
|---------------------|-------------------------------|----------------------------------------|
| `player_shot`       | `sfx_player_shot.wav`         | Bullet fired in `Player._update_shooting`. |
| `player_hit`        | `sfx_player_hit.wav`          | Damage taken (HP > 0) in `Player._take_damage`. |
| `player_death`      | `sfx_player_death.wav`        | HP reaches 0 in `Player._take_damage`. |
| `player_respawn_in` | `sfx_player_respawn_in.wav`   | `Player.reset_for_respawn` called.     |
| `player_respawn_out`| `sfx_player_respawn_out.wav`  | Respawn immunity ends.                 |

**Enemy generic (5)**
| ID                       | File                              | Trigger                                       |
|--------------------------|-----------------------------------|-----------------------------------------------|
| `enemy_normal_shot`      | `sfx_enemy_normal_shot.wav`       | `EnemyBasic._fire_forward` (default `shot_sfx_id`). |
| `enemy_tank_shot`        | `sfx_enemy_tank_shot.wav`         | `EnemyTank` overrides `shot_sfx_id`.          |
| `enemy_speedster_shot`   | `sfx_enemy_speedster_shot.wav`    | `EnemySpeedster` overrides `shot_sfx_id`.     |
| `enemy_hit`              | `sfx_enemy_hit.wav`               | Non-fatal hit in `EnemyBasic._on_area_entered`. |
| `enemy_kill`             | `sfx_enemy_kill.wav`              | Fatal hit in `EnemyBasic._on_area_entered`.   |

**Boss (4)**
| ID                | File                       | Trigger                                              |
|-------------------|----------------------------|------------------------------------------------------|
| `boss_telegraph`  | `sfx_boss_telegraph.wav`   | (Optional, future) wind-up for spread shots.         |
| `boss_shot`       | `sfx_boss_shot.wav`        | `EnemyBoss._fire_spread`.                            |
| `boss_hit`        | `sfx_boss_hit.wav`         | Non-fatal hit (every 5th hit to avoid spam).         |
| `boss_death`      | `sfx_boss_death.wav`       | Boss HP reaches 0; also ducks music.                 |

**UI / state (7)**
| ID                  | File                            | Trigger                                     |
|---------------------|---------------------------------|---------------------------------------------|
| `ui_hover`          | `sfx_ui_hover.wav`              | (Future hover hooks; not wired yet.)        |
| `ui_click`          | `sfx_ui_click.wav`              | Play / Settings / AutoShoot toggle.         |
| `ui_back`           | `sfx_ui_back.wav`               | Settings close, pause-quit-to-menu.         |
| `state_pause`       | `sfx_state_pause.wav`           | First Escape press during gameplay.         |
| `state_resume_tick` | `sfx_state_resume_tick.wav`     | Resume countdown 3 / 2 / 1 (pitch-shifted). |
| `state_wave_start`  | `sfx_state_wave_start.wav`      | Non-boss wave starts.                       |
| `state_restart`     | `sfx_state_restart.wav`         | Spacebar restart on game over.              |

---

## 4. Mix and ducking rules

### Bus baseline (`default_bus_layout.tres`)
| Bus     | Baseline `volume_db` | Send to  | Purpose                                                         |
|---------|----------------------|----------|-----------------------------------------------------------------|
| Master  | `0.0`                | (out)    | Final output.                                                   |
| Music   | `-14.0`              | Master   | Music loops + stingers. Headroom keeps shot SFX legible.        |
| SFX     | `-8.0`               | Master   | All one-shot combat / UI / state SFX.                           |

`scripts/GameSettings.gd` applies the user volume slider as a **trim** on top of the baseline, so the user's 100% slider equals the baseline target.

### Ducking
Triggered automatically by `AudioManager.duck_music()`:
- Default: -4 dB amount, 50 ms attack, 400 ms hold, 600 ms recover.
- Triggered by: stingers, player death, boss death.

### Pause fade
- On pause: music fades down -12 dB over 300 ms.
- On resume countdown end: music fades back to 0 dB (relative) over 500 ms.

---

## 5. Integration map

| Event                              | Owner          | API call                                        |
|------------------------------------|----------------|-------------------------------------------------|
| Menu opens                         | `Main.gd`      | `AudioManager.play_music("menu")`               |
| Click Play                         | `Main.gd`      | `play_sfx("ui_click")`                          |
| Open Settings                      | `Main.gd`      | `play_sfx("ui_click")`                          |
| Close Settings                     | `Main.gd`      | `play_sfx("ui_back")`                           |
| Toggle Auto Shoot                  | `Main.gd`      | `play_sfx("ui_click")`                          |
| Game scene loads (wave 1)          | `Game.gd`      | `play_music("gameplay")`                        |
| Regular wave starts                | `Game.gd`      | `play_sfx("state_wave_start")` + ensure music   |
| Boss wave starts                   | `Game.gd`      | `play_stinger("boss_intro")` + `play_music("boss")` |
| Player shoots                      | `Player.gd`    | `play_sfx("player_shot")`                       |
| Player takes damage                | `Player.gd`    | `play_sfx("player_hit")`                        |
| Player dies                        | `Player.gd`    | `play_sfx("player_death")` + `duck_music`       |
| Player respawn applied             | `Player.gd`    | `play_sfx("player_respawn_in")`                 |
| Enemy fires (normal/tank/speedster)| `EnemyBasic.gd`| `play_sfx(shot_sfx_id)`                         |
| Enemy hit (non-fatal)              | `EnemyBasic.gd`| `play_sfx("enemy_hit")`                         |
| Enemy killed                       | `EnemyBasic.gd`| `play_sfx("enemy_kill")`                        |
| Boss fires                         | `EnemyBoss.gd` | `play_sfx("boss_shot")`                         |
| Boss hit (every 5th)               | `EnemyBoss.gd` | `play_sfx("boss_hit")`                          |
| Boss dies                          | `EnemyBoss.gd` | `play_sfx("boss_death")` + `duck_music(6,...)`  |
| Pause                              | `Game.gd`      | `play_sfx("state_pause")` + fade music down     |
| Resume tick (3/2/1)                | `Game.gd`      | `play_resume_tick(seconds_left)`                |
| Resume complete                    | `Game.gd`      | fade music back up                              |
| Pause -> Quit to menu              | `Game.gd`      | `play_sfx("ui_back")`                           |
| Game over                          | `Game.gd`      | `play_stinger("game_over")` + `stop_music(1.0)` |
| Restart from game over             | `Game.gd`      | `play_sfx("state_restart")`                     |

---

## 6. Authoring tips

- Mix loops mono-friendly; stereo width is a luxury for stingers and boss music.
- Keep the first transient of every SFX < 50 ms to read instantly during dense bullet patterns.
- Avoid sub-50 Hz energy on small SFX so it doesn't muddy boss low-end.
- For looped music, bake a 1-2 bar pre-roll silence trim so the loop point lines up cleanly.

---

## 7. Adding new audio later

1. Drop the file into `audio/music/` or `audio/sfx/` with the right naming.
2. Add an entry to the relevant dict in `scripts/AudioManager.gd` (`MUSIC_PATHS`, `STINGER_PATHS`, or `SFX_PATHS`).
3. Call `AudioManager.play_music("...")`, `play_stinger("...")`, or `play_sfx("...")` from the trigger site.
4. **If a file is missing**, `AudioManager` synthesizes a short procedural `AudioStreamWAV` (soft pads for music, blips/chirps for SFX) so the game stays audible while you author assets. The editor prints a one-time warning. Adding the real file at the same path replaces the placeholder automatically.
