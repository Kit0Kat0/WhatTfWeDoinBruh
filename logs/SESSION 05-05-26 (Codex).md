## 05/05/26 - Codex

### What changed
  - Added a full-screen game over overlay to `scenes/HUD.tscn` with:
    - `GAME OVER` headline
    - `Press Spacebar to play again` instruction text
  - Extended `scripts/HUD.gd` with `show_game_over()` / `hide_game_over()`.
  - Updated `scripts/Game.gd` to:
    - detect when lives are fully exhausted
    - trigger game over state and show overlay
    - stop spawner processing and clear active enemies/bullets on game over
    - reload current scene when space (`shoot` action) is pressed during game over

### Why
  - To provide a clear end-of-run state and an immediate restart path without requiring editor interaction.

### Any pitfalls / fixes
  - Kept restart on the existing `shoot` action so keyboard space and existing controller mappings continue to work.

### Any thing important to mention if another AI agent were to move forward
  - Game-over flow now lives in `Game.gd` (`_game_over()`), and presentation is owned by HUD; keep gameplay-state and UI-state split this way for future menu expansion.

## 05/05/26 - Codex (main menu)

### What changed
  - Converted `scenes/Main.tscn` from a stub scene into a functional main menu UI.
  - Added `scripts/Main.gd` menu behavior:
    - Play button loads `res://scenes/Game.tscn`
    - Settings button opens an in-menu settings panel
    - Close button hides the settings panel
  - Updated startup scene in `project.godot`:
    - `run/main_scene` now points to `res://scenes/Main.tscn`

### Why
  - To provide a proper entry flow with a title, play path, and settings access before gameplay begins.

### Any pitfalls / fixes
  - Settings currently provides a placeholder panel scaffold for future options, not gameplay-affecting toggles yet.

### Any thing important to mention if another AI agent were to move forward
  - Game scene remains unchanged at `res://scenes/Game.tscn`; menu routes into it via `Main.gd`.

## 05/05/26 - Codex (settings controls)

### What changed
  - Added a global settings singleton at `scripts/GameSettings.gd` and registered it as an autoload in `project.godot`.
  - Expanded settings UI in `scenes/Main.tscn` to include:
    - Music volume slider
    - SFX volume slider
    - `Automatic Shooting: On/Off` toggle button
  - Updated `scripts/Main.gd` to initialize controls from saved runtime settings and apply changes live.
  - Updated `scripts/Player.gd` so automatic shooting fires even when shoot input is not held.

### Why
  - To provide requested user-facing settings controls and make automatic shooting configurable from the menu.

### Any pitfalls / fixes
  - Music/SFX sliders apply to audio buses named `Music` and `SFX` when those buses exist; missing buses are safely ignored.

### Any thing important to mention if another AI agent were to move forward
  - Menu settings currently persist for the runtime session through the autoload singleton; add save/load if cross-launch persistence is needed later.

## 05/05/26 - Codex (pause + resume countdown)

### What changed
  - Added a `pause_toggle` input action bound to `Escape` in `project.godot`.
  - Added pause overlay UI to `scenes/HUD.tscn` and pause display methods to `scripts/HUD.gd`.
  - Updated `scripts/Game.gd` to:
    - pause game on first `Escape`
    - on next `Escape`, show a 3-second countdown (`3`, `2`, `1`)
    - resume gameplay after countdown completes
  - Ensured game controller logic keeps processing while paused by setting `Game` process mode to `ALWAYS`.

### Why
  - To provide a controlled pause/resume flow that prevents abrupt re-entry and gives players a clear resume timing cue.

### Any pitfalls / fixes
  - Countdown timers are created with always-processing mode so they still tick while the scene tree is paused.

### Any thing important to mention if another AI agent were to move forward
  - Pause toggle is ignored during game over and while a resume countdown is already running, preventing state conflicts.

## 05/05/26 - Codex (pause freeze enforcement)

### What changed
  - Marked gameplay actor containers in `scripts/Game.gd` as `PROCESS_MODE_PAUSABLE`:
    - `Enemies`
    - `PlayerBullets`
    - `EnemyBullets`
  - Marked spawned `Player` and `EnemySpawner` as `PROCESS_MODE_PAUSABLE`.

### Why
  - To ensure player, enemies, and enemy projectiles fully stop while paused, then continue only after the resume countdown completes.

### Any pitfalls / fixes
  - `Game` controller remains `PROCESS_MODE_ALWAYS` so pause input and countdown continue while gameplay nodes are frozen.

### Any thing important to mention if another AI agent were to move forward
  - New gameplay nodes should default to pausable under these parent containers unless explicitly intended to run during pause.

## 05/05/26 - Codex (menu visual polish)

### What changed
  - Restyled `scenes/Main.tscn` for a more polished look:
    - layered/glow background accents
    - upgraded title styling with larger font and glow tint
    - subtitle under title
    - centered menu card panel with tinted backing
    - larger, cleaner Play/Settings button presentation
  - Updated scene signal paths to match the new menu-card hierarchy.

### Why
  - To make the menu feel more intentional and visually aligned with the game’s arcade tone.

### Any pitfalls / fixes
  - Visual pass only; menu behavior and existing settings logic remain unchanged.

### Any thing important to mention if another AI agent were to move forward
  - Further polish can be done with menu animation/particles, but current layout is stable and intentionally script-light.

## 05/05/26 - Codex (game rename)

### What changed
  - Renamed the project/application display name in `project.godot` to `Virus Hunter`.
  - Updated main menu title text in `scenes/Main.tscn` to `VIRUS HUNTER`.

### Why
  - To reflect the requested new game title consistently in app metadata and first-screen presentation.

### Any pitfalls / fixes
  - Name change is UI/config level only; resource paths and scene/script IDs are unchanged.

### Any thing important to mention if another AI agent were to move forward
  - If branding expands later, update docs and icon assets to match `Virus Hunter` naming.

## 05/05/26 - Codex (menu style reference pass)

### What changed
  - Reworked `scenes/Main.tscn` to visually match the provided arcade menu reference:
    - top score-strip style labels
    - stacked bold title treatment
    - invader-row style decorative line
    - vertical glossy button stack (`1 Player Start`, `2 Player Start`, `Options`, `Help`, `Recommended Apps`)
    - dark neon stripe background framing
  - Kept functional hooks intact:
    - `PlayButton` still starts gameplay
    - `SettingsButton` (shown as `Options`) still opens settings

### Why
  - To better align the game’s first impression with the user’s target visual direction.

### Any pitfalls / fixes
  - Decorative buttons (`2 Player Start`, `Help`, `Recommended Apps`) are intentionally disabled placeholders for now.

### Any thing important to mention if another AI agent were to move forward
  - Scene hierarchy changed significantly in `Main.tscn`; preserve existing signal endpoints for `PlayButton` and `SettingsButton` when iterating visuals.

## 05/05/26 - Codex (menu button simplification)

### What changed
  - Removed extra menu buttons from `scenes/Main.tscn`:
    - `2 Player Start`
    - `Help`
    - `Recommended Apps`
  - Renamed `1 Player Start` to `Play`.
  - Tightened menu card sizing/offset so the reduced button set stays centered and balanced.

### Why
  - To keep the menu focused on currently supported actions and reduce visual clutter.

### Any pitfalls / fixes
  - `Play` and `Options` wiring remains unchanged; only unused decorative entries were removed.

### Any thing important to mention if another AI agent were to move forward
  - If multiplayer/help flows are added later, reintroduce entries based on feature availability rather than static placeholders.

## 05/05/26 - Codex (menu cleanup: scores + x row)

### What changed
  - Removed score labels from `scenes/Main.tscn`:
    - `1-SCORE`
    - `SCORE`
    - `0000`
  - Removed the decorative small `x x x ...` row behind/below the title.

### Why
  - To declutter the menu and keep focus on title + primary actions.

### Any pitfalls / fixes
  - Purely visual cleanup; play/options behavior and settings panel wiring are unchanged.

### Any thing important to mention if another AI agent were to move forward
  - If score display returns later, prefer a dedicated HUD-style strip tied to real saved/high-score data.

## 05/05/26 - Codex (menu button label + size tweak)

### What changed
  - Updated `scenes/Main.tscn` menu button label:
    - `Options` -> `Settings`
  - Increased both primary menu button heights:
    - `Play`: 42 -> 58
    - `Settings`: 42 -> 58

### Why
  - To match requested wording and improve menu readability/click target size.

### Any pitfalls / fixes
  - Signal wiring and behavior remain unchanged; only text and sizing were adjusted.

### Any thing important to mention if another AI agent were to move forward
  - If additional primary menu actions are added, keep consistent button heights for visual rhythm.

## 05/05/26 - Codex (pause menu quit button)

### What changed
  - Added a new `Quit to Main Menu` button to the pause overlay in `scenes/HUD.tscn`, positioned under the pause resume text.
  - Updated pause layout to use a centered `VBoxContainer` so pause text and button are vertically stacked and remain centered.
  - Added `pause_quit_requested` signal in `scripts/HUD.gd` and emitted it from the new pause button handler.
  - Updated `scripts/Game.gd` to connect that signal and change scene to `res://scenes/Main.tscn` when clicked.
  - Ensured HUD remains interactive while paused by setting HUD process mode to `PROCESS_MODE_ALWAYS`.

### Why
  - To provide a direct in-pause way to leave a run and return to the main menu without forcing resume or game-over flow.

### Any pitfalls / fixes
  - Scene change now explicitly clears `get_tree().paused` first to avoid carrying a paused tree state into the main menu.

### Any thing important to mention if another AI agent were to move forward
  - Pause UI actions now route through HUD signals; keep gameplay flow in `Game.gd` and presentation/input controls in HUD for clean separation.

## 05/05/26 - Codex (pause quit hidden during resume countdown)

### What changed
  - In `scripts/HUD.gd`, `show_resume_countdown()` now hides `PauseQuitButton`; `show_paused()` shows it again; `hide_pause()` keeps it hidden when the overlay closes.
  - Marked `PauseQuitButton` with `unique_name_in_owner` in `scenes/HUD.tscn` for `%PauseQuitButton` access.

### Why
  - So after the player presses Escape to resume, the quit option is not shown during the 3–2–1 countdown; it only reappears the next time pause is opened.

### Any pitfalls / fixes
  - None; visibility is purely UI state tied to pause vs countdown vs closed.

### Any thing important to mention if another AI agent were to move forward
  - Any new pause-only controls should follow the same pattern: visible in `show_paused()`, hidden in `show_resume_countdown()` if they should not apply during resume.

## 05/05/26 - Codex (audio plan implementation)

### What changed
  - Added [`docs/AUDIO_GUIDE.md`](../docs/AUDIO_GUIDE.md) defining style, BPM, naming conventions, full asset checklist (4 loops + 3 stingers + 21 SFX), mix rules, and per-event integration map.
  - Added `audio/`, `audio/music/`, `audio/sfx/` folders with READMEs listing required filenames.
  - Added `default_bus_layout.tres` with `Master`, `Music` (`-14 dB`), and `SFX` (`-8 dB`) buses and registered it via `[audio]` in `project.godot`.
  - Refactored `scripts/GameSettings.gd` to apply the user volume slider as a trim on top of bus baselines (`MUSIC_BUS_BASELINE_DB`, `SFX_BUS_BASELINE_DB`) so user 100% lands at the baseline.
  - Added new `scripts/AudioManager.gd` autoload with:
    - `MUSIC_PATHS`, `STINGER_PATHS`, `SFX_PATHS` resolution maps
    - `play_music()` / `stop_music()` with fades, loop coercion (Ogg/MP3/WAV)
    - `play_stinger()` (auto-ducks music)
    - `play_sfx()` with pooled voices and pitch/volume args
    - `play_resume_tick(seconds_left)` (rising-pitch countdown ticks)
    - `pause_music_dip()` / `resume_music_restore()`
    - `duck_music()` for stingers, player death, and boss death
    - safe no-op when an asset path is missing
  - Wired audio triggers across:
    - `scripts/Main.gd` -> menu music, UI click/back SFX
    - `scripts/Game.gd` -> gameplay/boss music switching, wave start ping, pause dip + resume restore, resume ticks, game-over stinger + music stop, restart SFX, pause-quit SFX
    - `scripts/Player.gd` -> shot, hit, death (+ duck), respawn in/out
    - `scripts/EnemyBasic.gd` -> shot (via new `shot_sfx_id` export), hit, kill
    - `scripts/EnemyTank.gd` -> appends shot SFX after spread fire
    - `scripts/EnemyBoss.gd` -> shot, hit (every 5th), death + duck
  - Set per-archetype shot SFX in `scenes/EnemyTank.tscn` (`enemy_tank_shot`) and `scenes/EnemySpeedster.tscn` (`enemy_speedster_shot`).
  - Updated `docs/GAME_OVERVIEW.md` to mention the audio scaffolding.

### Why
  - To stand up the audio system end-to-end so authors only need to drop named files into `audio/` to activate music and SFX, with a documented mix budget that keeps gameplay cues legible over music.

### Any pitfalls / fixes
  - `AudioManager` runs as `PROCESS_MODE_ALWAYS` and creates tweens bound to itself so music fade/duck continues during the pause overlay.
  - `_try_load_stream()` checks `ResourceLoader.exists()` before loading, so missing assets degrade gracefully without spamming errors.
  - Loop coercion sets `loop = true` on Ogg/MP3 streams and `loop_mode = LOOP_FORWARD` on WAV when a music slot loads a one-shot by mistake.
  - Boss hit SFX is gated to every 5th HP drop so high fire rates don't drown the channel.

### Any thing important to mention if another AI agent were to move forward
  - Add new audio: drop files matching the names in `docs/AUDIO_GUIDE.md`, then add them to the relevant dictionary in `scripts/AudioManager.gd`.
  - Per-archetype enemy shot sounds live on `EnemyBasic.shot_sfx_id` and are set per-scene; new enemy types should set their own ID or reuse an existing one.
  - All gameplay-state SFX route through `Game.gd` so menus, pause, and game-over flows stay decoupled from HUD presentation.

## 05/05/26 - Codex (audio: procedural placeholders when files missing)

### What changed
  - Updated `scripts/AudioManager.gd` so when `ResourceLoader.exists()` fails for a mapped path, it builds a cached `AudioStreamWAV` from synthesized 16-bit mono PCM (soft pads for music, chirps for stingers, short blips for SFX) instead of staying silent.
  - Music pads use a sine envelope at loop boundaries to reduce clicks; stingers/SFX use `LOOP_DISABLED` so one-shots do not repeat.
  - Documented the behavior in `docs/AUDIO_GUIDE.md` §7.

### Why
  - The repo had no `audio/*.ogg` / `audio/*.wav` files yet, so every `_try_load_stream` returned null and the game was totally silent.

### Any pitfalls / fixes
  - First missing-asset use prints a single `push_warning` pointing at `docs/AUDIO_GUIDE.md`; dropping a real file at the same path replaces the placeholder with no code changes.

### Any thing important to mention if another AI agent were to move forward
  - Placeholder timbres are for development only; tune `_PROC_SFX_PARAMS` / `_build_procedural_for_path` if you need clearer temp cues before final assets land.

## 05/05/26 - Codex (boss every 7 waves + mixed normal/tanky patterns)

### What changed
  - Set default `boss_every_n_waves` from `10` to `7` in `scripts/EnemySpawner.gd`.
  - Reworked `scripts/EnemyBoss.gd` so each shot alternates:
    - **Normal-style:** one straight-down bullet (`normal_bullet_speed` / `normal_bullet_damage`, default like basic enemies).
    - **Tanky-style:** three-way spread using `tank_spread_angle_degrees` (same idea as `EnemyTank`), with `tank_bullet_speed` / `tank_bullet_damage`.
  - Single `boss_shot` SFX per volley after the pattern fires.
  - Updated `docs/GAME_OVERVIEW.md` and `docs/AUDIO_GUIDE.md` boss cadence notes.

### Why
  - Requested boss fights every 7 waves with bullet behavior that mixes normal and tank archetypes.

### Any pitfalls / fixes
  - Boss difficulty is tunable via new exports on `EnemyBoss`; spawner cadence remains overridable in the editor via `boss_every_n_waves`.

### Any thing important to mention if another AI agent were to move forward
  - Pattern alternation is driven by `_pattern_volley`; extend with more phases by switching on `_pattern_volley % N` if you add a third pattern later.

## 05/05/26 - Codex (boss: large, top lane, horizontal patrol)

### What changed
  - `EnemyBoss`: default `radius` **78** (was 34), HP **160**, slightly slower horizontal patrol; `top_lane_margin` pins the boss just under the top of the playfield; Y locks to that lane after entry (no drifting down).
  - `_sync_collision_radius()` keeps `CollisionShape2D` circle in sync with `radius`; draw rings scale with size.
  - `EnemySpawner._spawn_boss`: assigns `playfield_rect` / bullets **before** `add_child` so `_ready` computes lane correctly; spawn Y uses **`radius + 90`** above the playfield top.
  - `scenes/EnemyBoss.tscn`: collision radius and exported defaults aligned with script.

### Why
  - Requested a much larger boss that stays at the top and only moves left/right.

### Any pitfalls / fixes
  - If the playfield or boss `radius` changes at runtime, `_recompute_target_y()` runs each frame so the lane stays consistent with `playfield_rect`.

## 05/05/26 - Codex (weapon perk pickups)

### What changed
  - Added `WeaponPickup` (`scripts/WeaponPickup.gd`, `scenes/WeaponPickup.tscn`): collectible `Area2D` on layer 16, falls slowly; three perk kinds map to player weapon modes.
  - `Game.gd`: `Pickups` node, `try_spawn_weapon_pickup(at, from_boss)` with tunable `weapon_pickup_chance_normal` / `weapon_pickup_chance_boss`, random perk roll; clears pickups on game over; registers `game_controller` group.
  - `Player.gd`: `WeaponMode` (single / double / triple straight / beam), row spacing + `beam_fire_interval`, `apply_weapon_pickup()`, respawn resets to single; firing spawns 1/2/3 parallel bullets or one beam.
  - `BulletPlayer.gd`: `pierce` + per-enemy id dedupe; `configure_as_beam()` tall `RectangleShape2D`, longer TTL, drawn beam strip; non-pierce still frees on first enemy hit.
  - `EnemyBasic` (tank/speedster inherit): on kill, rolls pickup via `game_controller`; `EnemyBoss`: higher boss roll on death.
  - `Defs.gd`: `GROUP_WEAPON_PICKUP`; `docs/GAME_OVERVIEW.md` note.

### Why
  - Requested random drops on enemy defeat with double straight, triple straight, and full-pierce beam patterns matching base bullet damage (1 HP per hit per bullet).

### Any pitfalls / fixes
  - New perk replaces previous weapon mode until respawn (single) or another pickup.
  - Beam uses pierce + wide vertical hitbox so one cast can tag many enemies once per overlap lifecycle.

### Any thing important to mention if another AI agent were to move forward
  - Tune drop rates on `Game` exports; add HUD icon for current mode if desired.

## 05/05/26 - Codex (weapon perk 45s duration)

### What changed
  - `scripts/Player.gd`: `weapon_perk_duration_sec` export (default **45**); `_weapon_perk_time_left` counts down in `_process`; when it hits zero, `weapon_mode` returns to `SINGLE`. Picking any perk **refills** the timer. Respawn clears the timer and weapon.

### Why
  - Requested perks last only 45 seconds after pickup.

### Any pitfalls / fixes
  - Timer pauses with gameplay (`PROCESS_MODE_PAUSABLE`).

### Any thing important to mention if another AI agent were to move forward
  - HUD countdown for perk time is optional; duration is tunable per `Player` instance.
