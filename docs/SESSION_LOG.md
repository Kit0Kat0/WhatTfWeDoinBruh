# WhatTfWeDoin — session & issue log

**Purpose:** Record **prompts, symptoms, causes, and fixes** so future work doesn’t depend on chat history alone.

**Not a spec:** Roadmaps and targets live in [`BUILD_PLAN.md`](BUILD_PLAN.md) and [`GAME_OVERVIEW.md`](GAME_OVERVIEW.md).

---

## Agent pickup (read this on a cold start)

- **Repo root (authoritative):** `E:\WhatTfWeDoin`
- **Cold-start index:** `AGENTS.md` (layout, docs map, art/VFX workflow).
- **Godot:** 4.6.2
- **Main scene:** `res://scenes/Game.tscn`
- **Main scene:** `res://scenes/Main.tscn` (menu) → `res://scenes/Game.tscn` (gameplay)
- **Current playable slice:** Player (move/focus/shoot), wave-based spawner, forward-firing enemies, bullets, HP/lives HUD.
- **Asset tracking:** see `ASSET_ATTRIBUTION.md`
- **FX isolation convention:** keep raw packs in `Assets/`; for big FX atlases, isolate a single effect using `AtlasTexture` + a fixed `Rect2` cell (example: enemy bullets use `Effect and FX Pixel All Free/Free/Part 1/03.png` @ `Rect2(576, 0, 64, 64)`). Long-term, still prefer copying curated authored VFX into `vfx/` once we start building reusable scenes/resources.

---

## One document vs many

**Default:** keep this file as the single searchable log.  
**Split** only if a domain gets too large (then leave a short “See `docs/FOO.md`” pointer here).

---

## Entries

### Project bootstrap + shmup prototype (04/29/26)

- **Prompt:** Start a collaborative bullet hell shmup; make it playable quickly.
- **Changes:**
  - Added `Game`, `Player`, `EnemyBasic`, `EnemySpawner`, `BulletPlayer`, `BulletEnemy` scenes/scripts.
  - Added input map (move/shoot/focus).
  - Added `ASSET_ATTRIBUTION.md`, `AGENTS.md`, and `docs/*` structure.
  - Fixed `.gitignore` so `Assets/` can be committed while ignoring `*.import`, `__MACOSX`, coupons, and other pack clutter.
- **Notes:** Some asset packs were initially missing source `.png` and had to be re-imported.

### Enemy fire direction + player HP HUD + respawn lives (04/29/26)

- **Prompt:** Change enemy bullets to shoot forward; add player health bar; add 3-life respawn loop with immunity and no shooting during immunity.
- **Symptom:** Enemy bullets were radial ring pattern only, and player had no HP/lives/HUD feedback.
- **Cause:** Prototype only implemented baseline movement/shooting/spawn loop and did not include survivability/UI systems yet.
- **Fix:** Replaced enemy fire pattern with forward shots, added HUD scene/script for HP display, added player HP and health signals, and added game-managed respawn lifecycle (3 lives, same spawn point, 2s immunity, shooting disabled during immunity).
- **Files:** `scripts/EnemyBasic.gd`, `scripts/Player.gd`, `scripts/Game.gd`, `scripts/HUD.gd`, `scenes/HUD.tscn`.

### Logging policy alignment (04/29/26)

- **Prompt:** Log all previous and future changes to logs and docs.
- **Symptom:** Recent gameplay changes were not yet mirrored in both log locations.
- **Cause:** Work moved quickly across gameplay and UI without same-turn mirrored documentation updates.
- **Fix:** Backfilled this document and `logs/SESSION 04-29-26 (ZavHar).md` with current session changes and set policy to log future updates in both places.
- **Files:** `docs/SESSION_LOG.md`, `logs/SESSION 04-29-26 (ZavHar).md`.

### Wave progression system (04/29/26)

- **Prompt:** Add waves into the game.
- **Symptom:** Enemy spawning had no clear wave lifecycle or pacing breaks.
- **Cause:** Spawner behavior was originally a continuous loop intended for early prototype validation.
- **Fix:** Converted `EnemySpawner` to finite wave progression with scalable per-wave enemy counts, dynamic spawn cadence, and inter-wave downtime; added wave broadcast/update wiring into HUD.
- **Files:** `scripts/EnemySpawner.gd`, `scripts/Game.gd`, `scripts/HUD.gd`, `scenes/HUD.tscn`.

### Enemy lateral movement + top wrap with persistent HP (04/29/26)

- **Prompt:** Allow enemies to move left and right while going down; if they reach bottom, respawn them at top with current HP.
- **Symptom:** Enemies traveled straight downward and were removed when leaving the bottom of playfield.
- **Cause:** `EnemyBasic` prototype movement only implemented vertical drift plus off-screen cleanup.
- **Fix:** Added horizontal strafe motion with side-wall bounce and changed bottom-out behavior from `queue_free()` to vertical wrap (`y` reset to top) while preserving HP state.
- **Files:** `scripts/EnemyBasic.gd`.

### Boss encounter cadence (04/29/26)

- **Prompt:** Every 10 waves have a boss fight.
- **Symptom:** Wave progression lacked milestone encounters and used only standard enemy waves.
- **Cause:** Spawner had no boss-wave branch or boss-specific scene.
- **Fix:** Added a boss enemy scene/script and updated the wave spawner to route every 10th wave into a single-boss encounter (`boss_every_n_waves`), with game bootstrap wiring for boss scene injection.
- **Files:** `scripts/EnemySpawner.gd`, `scripts/EnemyBoss.gd`, `scenes/EnemyBoss.tscn`, `scripts/Game.gd`.

### Boss wave HUD banner (04/29/26)

- **Prompt:** Add a “BOSS WAVE” HUD banner when boss waves start.
- **Symptom:** Boss encounters started without a distinct on-screen announcement.
- **Cause:** HUD only displayed passive status labels (HP/lives/wave) with no event banner.
- **Fix:** Added a centered timed `BOSS WAVE` banner in HUD, extended `wave_started` payload with boss-wave metadata, and triggered banner display from `Game.gd` on boss wave start.
- **Files:** `scenes/HUD.tscn`, `scripts/HUD.gd`, `scripts/EnemySpawner.gd`, `scripts/Game.gd`.

### New enemy archetypes: Tank + Speedster (04/29/26)

- **Prompt:** Add two new enemy types: Tanky and Speedster, with distinct size/speed/fire-rate/HP/damage profiles.
- **Symptom:** Non-boss enemies used a single profile, so there was limited combat variety between waves.
- **Cause:** Spawner only routed to one standard enemy scene and enemy bullets had fixed damage assumptions.
- **Fix:** Added new tank and speedster enemy scenes/scripts, introduced weighted variant spawning in `EnemySpawner`, and added per-bullet damage so each archetype can deal different damage than normal.
- **Files:** `scripts/BulletEnemy.gd`, `scripts/EnemyBasic.gd`, `scripts/EnemyTank.gd`, `scripts/EnemySpeedster.gd`, `scenes/EnemyTank.tscn`, `scenes/EnemySpeedster.tscn`, `scripts/EnemySpawner.gd`, `scripts/Game.gd`, `scripts/Player.gd`.

### Player boost movement action (04/29/26)

- **Prompt:** Add a button to allow the player to boost and go faster.
- **Symptom:** Player had movement, focus, and shooting but no explicit speed-up input.
- **Cause:** Movement implementation only supported base speed plus focus slowdown.
- **Fix:** Added a `boost` input action (`E` / joypad button `1`) and integrated a `boost_speed_multiplier` into player movement math while preserving focus behavior.
- **Files:** `project.godot`, `scripts/Player.gd`.

### Boost key remap to Shift (04/29/26)

- **Prompt:** Change boost button to Shift.
- **Symptom:** Boost input was initially mapped to `E`.
- **Cause:** First boost implementation used a default keyboard binding rather than preferred key.
- **Fix:** Remapped keyboard `boost` action to `Shift` in the input map.
- **Files:** `project.godot`.

### Tank enemy spread fire pattern (04/29/26)

- **Prompt:** For tanky enemies, change bullet path to a 3 bullet spread.
- **Symptom:** Tank enemies were still firing a single forward bullet like the base enemy.
- **Cause:** `EnemyTank` inherited default `EnemyBasic` forward-fire implementation.
- **Fix:** Overrode tank fire method to emit a 3-shot spread (center + symmetric angles) with exported spread-angle tuning.
- **Files:** `scripts/EnemyTank.gd`.

### Boost input behavior fix (04/29/26)

- **Prompt:** Player boost button is not working; please fix it.
- **Symptom:** Holding Shift did not feel like a speed boost after remapping boost to Shift.
- **Cause:** `boost` and `focus` were both bound to Shift, causing conflicting movement multipliers.
- **Fix:** Updated movement logic so boost takes priority when both boost/focus are active, restoring reliable speed-up on Shift.
- **Files:** `scripts/Player.gd`.

### Player HP increase to 25 (04/29/26)

- **Prompt:** Increase player HP to 25.
- **Symptom:** Default player survivability was tuned around low starting HP.
- **Cause:** Baseline prototype value for `max_hp` remained at early-test defaults.
- **Fix:** Raised default `max_hp` and initial `hp` to `25`.
- **Files:** `scripts/Player.gd`.

### Normal enemy wave bullet path (04/29/26)

- **Prompt:** Change normal enemy bullets to a slow wave path moving left and right.
- **Symptom:** Normal enemies were firing straight downward bullets.
- **Cause:** Enemy bullet motion only used linear velocity without lateral oscillation.
- **Fix:** Added sine-wave trajectory support to enemy bullets and enabled it for normal enemy fire with slower bullet speed; explicitly disabled wave mode for speedsters to keep this behavior scoped to normal enemies.
- **Files:** `scripts/BulletEnemy.gd`, `scripts/EnemyBasic.gd`, `scenes/EnemySpeedster.tscn`.

### Normal bullet path correction to straight fire (04/29/26)

- **Prompt:** Normal enemies should shoot straight; current shots are half-circle in front of them.
- **Symptom:** Normal enemy bullets visibly curved rather than traveling as straight shots.
- **Cause:** Normal enemy wave-bullet mode remained enabled from prior trajectory update.
- **Fix:** Disabled wave bullet mode for normal enemies and restored normal straight-shot speed.
- **Files:** `scripts/EnemyBasic.gd`.

### Enemy projectile visuals via FX atlas isolation (04/30/26)

- **Prompt:** Improve enemy projectile visuals; prefer circular “virus orb” reads; learn how to isolate particles from large FX sheets.
- **Symptom:** `Projectiles/` sprites often read like weapon parts; `Effect and FX Pixel All Free` PNGs are huge multi-effect atlases.
- **Cause:** Wrong asset family for “clean orb” reads + atlases need explicit crop rects (not whole-file textures).
- **Fix:** Switched `BulletEnemy` to render a `Sprite2D` using an `AtlasTexture` subresource cut from `Assets/Effect and FX Pixel All Free/Free/Part 1/03.png` (`Rect2(576, 0, 64, 64)`), scaled/tinted for readability; removed debug `_draw()` circles from enemy bullets.
- **Files:** `scenes/BulletEnemy.tscn`, `scripts/BulletEnemy.gd`.

### AGENTS cold-start: docs map + VFX workflow (04/30/26)

- **Prompt:** Extend `AGENTS.md` so it matches how the repo documents work and how FX atlases are used.
- **Symptom:** `AGENTS.md` listed scenes but not where design/roadmap/session logs live, nor the `AtlasTexture` / `art/player` conventions agents hit in practice.
- **Cause:** Cold-start file lagged behind `docs/*` and recent presentation work.
- **Fix:** Added **Documentation**, **Art / VFX workflow**, and prototype pointers (HUD, muzzle VFX); clarified attribution when `ASSET_ATTRIBUTION.md` is absent.
- **Files:** `AGENTS.md`, `docs/SESSION_LOG.md` (pickup line), `logs/SESSION 04-30-26 (ZavHar).md`.

### Game over screen + restart prompt (05/05/26)

- **Prompt:** Once the player has lost all lives, add a game over screen and tell them to press spacebar to play again.
- **Symptom:** Runs ended silently after final life loss with no explicit fail-state UI or restart guidance.
- **Cause:** Life/respawn flow only handled respawns and did not include a terminal game-over state.
- **Fix:** Added HUD game-over overlay, added game-over state handling in `Game.gd`, and wired restart via space (`shoot` action) by reloading the current scene.
- **Files:** `scripts/Game.gd`, `scripts/HUD.gd`, `scenes/HUD.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu entry flow (05/05/26)

- **Prompt:** Start the game with a main menu containing the game name at top, a Play button, and a Settings button.
- **Symptom:** Project launched directly into gameplay without an entry menu.
- **Cause:** `run/main_scene` was set directly to gameplay scene and `Main` scene/script were placeholder-only.
- **Fix:** Built a functional menu scene (`Main.tscn`) with title and buttons, wired button behavior in `Main.gd`, and switched startup scene to `Main.tscn`.
- **Files:** `scenes/Main.tscn`, `scripts/Main.gd`, `project.godot`, `logs/SESSION 05-05-26 (Codex).md`.

### Settings controls: music/sfx + auto shoot toggle (05/05/26)

- **Prompt:** In settings, add two volume sliders (music and SFX) and an Automatic Shooting On/Off option.
- **Symptom:** Settings panel had no gameplay/audio controls.
- **Cause:** Initial menu settings implementation was only a UI placeholder.
- **Fix:** Added menu controls and wiring for music/SFX sliders and automatic shooting toggle; introduced a global `GameSettings` autoload used by menu + player shooting logic.
- **Files:** `scenes/Main.tscn`, `scripts/Main.gd`, `scripts/Player.gd`, `scripts/GameSettings.gd`, `project.godot`, `logs/SESSION 05-05-26 (Codex).md`.

### Pause on Escape + 3-second resume countdown (05/05/26)

- **Prompt:** Pressing Escape should pause the game; pressing it again should start a 3-second countdown before resuming.
- **Symptom:** Gameplay had no in-run pause state or controlled resume sequence.
- **Cause:** Game loop lacked a pause state manager and pause UI overlay.
- **Fix:** Added `pause_toggle` input, implemented pause/resume countdown state handling in `Game.gd`, and added HUD pause overlay text for paused/countdown states.
- **Files:** `project.godot`, `scripts/Game.gd`, `scripts/HUD.gd`, `scenes/HUD.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Pause freeze enforcement for gameplay actors (05/05/26)

- **Prompt:** When paused, freeze player, enemies, and enemy projectiles; continue only after countdown hits zero.
- **Symptom:** Pause state needed explicit guarantees for actor freeze scope.
- **Cause:** Pause controller existed, but gameplay-node process modes needed hard enforcement.
- **Fix:** Set gameplay node containers and spawned gameplay actors to pausable process mode while keeping the game controller always-processing for countdown/input handling.
- **Files:** `scripts/Game.gd`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu visual polish (05/05/26)

- **Prompt:** Make the menu screen look cooler.
- **Symptom:** Main menu was functionally complete but visually plain.
- **Cause:** Initial menu pass prioritized functionality over presentation.
- **Fix:** Added layered background glow, stronger title/subtitle styling, and a centered menu card with improved button presentation while preserving existing menu/settings behavior.
- **Files:** `scenes/Main.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Game rename to Virus Hunter (05/05/26)

- **Prompt:** Change the name of the game to Virus Hunter.
- **Symptom:** Project/app and menu title still used the previous name.
- **Cause:** Naming had not yet been updated in configuration and menu UI.
- **Fix:** Updated app config name and main menu title text to `Virus Hunter`.
- **Files:** `project.godot`, `scenes/Main.tscn`, `docs/GAME_OVERVIEW.md`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu restyle to arcade reference (05/05/26)

- **Prompt:** Make the menu similar to provided Space Invaders-style reference image.
- **Symptom:** Existing menu polish still differed from target arcade layout/composition.
- **Cause:** Prior visual pass focused on generic polish rather than reference-matching structure.
- **Fix:** Rebuilt main menu composition with score-strip top area, stacked title, invader-row accent, and reference-like vertical button stack while preserving Play/Options functionality and settings wiring.
- **Files:** `scenes/Main.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu action simplification (05/05/26)

- **Prompt:** Remove `1/2 Player Start` split and remove `Help` + `Recommended Apps`; keep just `Play` and options.
- **Symptom:** Menu included unsupported/placeholder actions that could confuse users.
- **Cause:** Reference-style pass intentionally included decorative button stack.
- **Fix:** Removed unused buttons, renamed primary start action to `Play`, and rebalanced menu card spacing for the reduced action set.
- **Files:** `scenes/Main.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu visual cleanup: remove score labels + x row (05/05/26)

- **Prompt:** Remove menu scores and the small x's behind the title.
- **Symptom:** Menu had extra decorative text elements that competed with title/actions.
- **Cause:** Earlier arcade-reference pass added score-strip and invader-row accents as style elements.
- **Fix:** Removed score labels (`1-SCORE`, `SCORE`, `0000`) and removed the `x x x ...` decorative row from the menu scene.
- **Files:** `scenes/Main.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Main menu button label + sizing tweak (05/05/26)

- **Prompt:** Change `Options` to `Settings` and make both menu buttons bigger.
- **Symptom:** Primary menu text/size did not match preferred wording and visual emphasis.
- **Cause:** Previous reference pass retained `Options` label and smaller button heights.
- **Fix:** Renamed button text to `Settings` and increased both primary button heights for stronger prominence.
- **Files:** `scenes/Main.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Pause menu quit-to-main action (05/05/26)

- **Prompt:** In the pause menu, add a quit button below the resume text that returns the player to the main menu.
- **Symptom:** Pause menu only supported Escape-based resume/countdown and had no direct leave-run option.
- **Cause:** Pause overlay originally contained text-only status UI without button actions or a quit route.
- **Fix:** Added a `Quit to Main Menu` button under pause text in HUD, emitted a HUD signal on click, connected it in `Game.gd`, and changed scene to `res://scenes/Main.tscn` after unpausing the tree.
- **Files:** `scenes/HUD.tscn`, `scripts/HUD.gd`, `scripts/Game.gd`, `logs/SESSION 05-05-26 (Codex).md`.

### Pause quit hidden during resume countdown (05/05/26)

- **Prompt:** After pressing Escape to resume, remove the quit option until pause is opened again.
- **Symptom:** Quit button stayed visible during the “Resuming in N…” countdown.
- **Cause:** Countdown reused the same pause overlay without toggling quit button visibility.
- **Fix:** Show quit only in `show_paused()`; hide it in `show_resume_countdown()` and `hide_pause()`.
- **Files:** `scripts/HUD.gd`, `scenes/HUD.tscn`, `logs/SESSION 05-05-26 (Codex).md`.

### Procedural audio placeholders when files absent (05/05/26)

- **Prompt:** No music or SFX audible in-game.
- **Symptom:** Silent gameplay and menu despite `AudioManager` wiring.
- **Cause:** No files existed under `res://audio/`; `_try_load_stream` returned null for every path.
- **Fix:** When a mapped asset is missing, `AudioManager` now synthesizes cached `AudioStreamWAV` PCM (looping pads for music, one-shot chirps/blips for stingers/SFX) and warns once; real files at the same path override automatically.
- **Files:** `scripts/AudioManager.gd`, `docs/AUDIO_GUIDE.md`, `logs/SESSION 05-05-26 (Codex).md`.

### Audio plan + AudioManager scaffolding (05/05/26)

- **Prompt:** Set up a plan of what music and SFX should go into the game and implement it.
- **Symptom:** Project had a `Music`/`SFX` settings UI but no audio system, no bus layout, no asset spec, and no playback hooks at gameplay/menu events.
- **Cause:** Audio was never authored beyond the menu sliders; gameplay events were silent.
- **Fix:** Wrote a full audio guide with style/BPM/naming/asset checklist/mix rules/integration map, added `Music` (`-14 dB`) and `SFX` (`-8 dB`) buses in `default_bus_layout.tres`, refactored `GameSettings` to apply user volume as a trim on the baseline, added an `AudioManager` autoload that resolves logical IDs to res:// paths and safely no-ops missing assets, and wired triggers across menu, gameplay, pause/resume, wave start, boss intro, player shoot/hit/death/respawn, enemy shoot/hit/kill, boss shoot/hit/death, game over, and restart.
- **Files:** `docs/AUDIO_GUIDE.md`, `audio/README.md`, `audio/music/README.md`, `audio/sfx/README.md`, `default_bus_layout.tres`, `project.godot`, `scripts/GameSettings.gd`, `scripts/AudioManager.gd`, `scripts/Main.gd`, `scripts/Game.gd`, `scripts/Player.gd`, `scripts/EnemyBasic.gd`, `scripts/EnemyTank.gd`, `scripts/EnemyBoss.gd`, `scenes/EnemyTank.tscn`, `scenes/EnemySpeedster.tscn`, `docs/GAME_OVERVIEW.md`, `logs/SESSION 05-05-26 (Codex).md`.

---

### Weapon perk 45 second duration (05/05/26)

- **Prompt:** After gaining bullet perks, have them last only 45 seconds.
- **Symptom:** Perks persisted until respawn or another pickup.
- **Cause:** No time limit on `weapon_mode`.
- **Fix:** `Player` tracks `_weapon_perk_time_left` from export `weapon_perk_duration_sec` (45); countdown in `_process` then resets to `SINGLE`; pickup refreshes timer; respawn clears.
- **Files:** `scripts/Player.gd`, `docs/GAME_OVERVIEW.md`, `logs/SESSION 05-05-26 (Codex).md`.

### Weapon perk pickups (double/triple/beam) (05/05/26)

- **Prompt:** On enemy kills, occasionally drop perks: double straight, triple straight, beam through all enemies; same damage as original per bullet.
- **Symptom:** Only single straight player shots existed.
- **Cause:** No pickup or weapon-mode system on `Player` / `BulletPlayer`.
- **Fix:** Added `WeaponPickup` scene + `Game.try_spawn_weapon_pickup` (normal vs boss chance), `Player` weapon modes and multi-spawn / beam, `BulletPlayer` pierce + beam hitbox; enemies call spawn roll on death.
- **Files:** `scripts/WeaponPickup.gd`, `scenes/WeaponPickup.tscn`, `scripts/Game.gd`, `scripts/Player.gd`, `scripts/BulletPlayer.gd`, `scripts/EnemyBasic.gd`, `scripts/EnemyBoss.gd`, `scripts/Defs.gd`, `docs/GAME_OVERVIEW.md`, `logs/SESSION 05-05-26 (Codex).md`.

### Boss cadence every 7 waves + mixed normal/tank boss fire (05/05/26)

- **Prompt:** After every 7 waves add a boss fight that mixes normal and tanky bullet types and patterns.
- **Symptom:** Boss was every 10 waves and only used one 3-way spread pattern.
- **Cause:** `boss_every_n_waves` defaulted to 10; `EnemyBoss` only implemented a single spread volley.
- **Fix:** Default `boss_every_n_waves` to 7; boss alternates straight-down shots (normal tuning) with tank-style 3-bullet spreads (separate speed/damage/spread exports).
- **Files:** `scripts/EnemySpawner.gd`, `scripts/EnemyBoss.gd`, `docs/GAME_OVERVIEW.md`, `docs/AUDIO_GUIDE.md`, `logs/SESSION 05-05-26 (Codex).md`.

## Adding new entries

Copy/paste under **Entries**:

```markdown
### Short title (mm/dd/yy)

- **Prompt:** What was asked (one line).
- **Symptom:** What you saw.
- **Cause:** Root cause.
- **Fix:** What changed (idea + files).
- **Files:** `path/to/file.gd`, `path/to/scene.tscn`.
```

