## 04/29/26 - ZavHar

### What changed
  - Scanned and mapped the project structure and startup flow for the current Godot setup.
  - Applied typing-safety fixes for updated GDScript behavior by replacing dynamic `set(...)` usage with typed casts and direct property assignments.
  - Added `class_name` identifiers to gameplay scripts used across scene instantiation boundaries.
  - Converted inferred variable declarations (`:=`) to explicit static type declarations (`: Type = value`) in active gameplay scripts.
  - Added the first running session log, then migrated it to the new logging location/format.
### Why
  - To align the project with Godot 4.6.x static-analysis expectations and avoid unsafe-access errors while preserving gameplay behavior.
  - To follow the updated team logging conventions in `AGENTS.md`.
### Any pitfalls / fixes
  - The prior `docs/SESSION_LOG.md` location no longer matched convention and was replaced by this `logs/` file.
### Any thing important to mention if another AI agent were to move forward
  - Keep explicit GDScript typing style (`: Type = value`) and avoid dynamic `set(...)` patterns unless absolutely required.

## 04/29/26 - Codex

### What changed
  - Updated enemy firing in `scripts/EnemyBasic.gd` from radial ring bullets to a forward shot (`Vector2.DOWN`).
  - Added a top-left health HUD using `scenes/HUD.tscn` + `scripts/HUD.gd`, wired through `scripts/Game.gd`.
  - Added player HP/state signals in `scripts/Player.gd` so HUD health updates on damage.
  - Implemented respawn flow in `scripts/Game.gd`: 3 lives, respawn at original start position.
  - Added respawn immunity behavior in `scripts/Player.gd`: 2 seconds of no damage and no shooting after respawn.

### Why
  - To align enemy behavior with requested forward-firing gameplay.
  - To surface survivability feedback via an always-visible HUD element.
  - To support a standard shmup death loop with fair post-respawn recovery.

### Any pitfalls / fixes
  - Refactored `Game.gd` to use a shared `_spawn_player(...)` path so initial spawn and respawn use consistent setup/wiring.

### Any thing important to mention if another AI agent were to move forward
  - Keep gameplay changes logged in both `logs/SESSION {date} ({username}).md` and `docs/SESSION_LOG.md` on the same day.
  - If player death flow is expanded (game over, continue screen, etc.), preserve the no-shoot window during respawn immunity unless design intentionally changes it.

## 04/29/26 - Codex (waves update)

### What changed
  - Implemented wave progression in `scripts/EnemySpawner.gd`.
  - Waves now spawn a finite enemy count, wait for wave clear, then start the next wave after an inter-wave delay.
  - Added per-wave scaling knobs: enemy count growth and spawn-rate acceleration with minimum spawn interval clamp.
  - Added `wave_started` signaling and exposed current-wave getters from `EnemySpawner`.
  - Extended HUD with a wave label (`Wave: X`) and wired `scripts/Game.gd` to keep it updated.

### Why
  - To introduce structured encounter pacing instead of endless uniform spawning.
  - To provide clear in-game feedback about progression state.

### Any pitfalls / fixes
  - First-wave HUD sync can race signal order depending on node readiness; `Game.gd` now also reads `EnemySpawner` current wave directly after setup to guarantee correct initial display.

### Any thing important to mention if another AI agent were to move forward
  - Balance tuning is now data-driven in `EnemySpawner` exports (`base_enemies_per_wave`, `enemies_per_wave_growth`, `spawn_interval_decay_per_wave`, `inter_wave_delay`).

## 04/29/26 - Codex (enemy movement + wrap)

### What changed
  - Updated `scripts/EnemyBasic.gd` so enemies now strafe left/right while moving downward.
  - Added horizontal movement tuning via exported `horizontal_speed`.
  - Added edge-bounce logic against playfield left/right bounds.
  - Replaced bottom-of-screen cleanup behavior: enemies now wrap to the top and keep their current HP instead of being freed.

### Why
  - To make enemy trajectories less linear and increase dodge variety.
  - To preserve pressure from surviving enemies and honor requested persistent HP across screen loops.

### Any pitfalls / fixes
  - Wrapping instead of despawning means wave clear depends on defeating enemies; missed enemies will continue cycling until killed.

### Any thing important to mention if another AI agent were to move forward
  - If future design wants different motion styles per enemy type, keep this behavior data-driven (exported speed/pattern vars) rather than hardcoding per-scene branches.

## 04/29/26 - Codex (boss waves)

### What changed
  - Added boss-wave cadence support in `scripts/EnemySpawner.gd` via exported `boss_every_n_waves` (default 10).
  - Implemented boss-wave routing so every 10th wave spawns a single boss instead of standard enemies.
  - Added `scripts/EnemyBoss.gd` and `scenes/EnemyBoss.tscn` as a dedicated boss encounter with high HP, horizontal movement, and spread shots.
  - Updated `scripts/Game.gd` to preload and pass `boss_scene` into the spawner.

### Why
  - To create milestone encounters and stronger progression beats across long runs.

### Any pitfalls / fixes
  - Boss-wave completion depends on boss defeat; if tuning feels too punishing, lower boss HP or shot interval first before changing cadence.

### Any thing important to mention if another AI agent were to move forward
  - Boss cadence is fully data-driven now; adjust `boss_every_n_waves` for frequency and tune `EnemyBoss` exports for difficulty.

## 04/29/26 - Codex (boss wave banner)

### What changed
  - Added a centered `BOSS WAVE` HUD banner in `scenes/HUD.tscn`.
  - Added `show_boss_banner()` in `scripts/HUD.gd` with timer-based auto-hide.
  - Extended `EnemySpawner.wave_started` signal to include `is_boss_wave`.
  - Updated `scripts/Game.gd` wave handler to trigger the banner when boss waves start.

### Why
  - To provide immediate, high-visibility feedback when milestone boss encounters begin.

### Any pitfalls / fixes
  - Added a ticket guard in HUD banner logic so overlapping triggers do not hide a newer banner early.

### Any thing important to mention if another AI agent were to move forward
  - Keep wave-start UI events sourced from `EnemySpawner` signal payload to avoid duplicated boss-wave checks in multiple systems.

## 04/29/26 - Codex (tanky + speedster enemies)

### What changed
  - Added per-bullet damage support in `scripts/BulletEnemy.gd`.
  - Extended `scripts/EnemyBasic.gd` to export `shot_interval`, `bullet_speed`, and `bullet_damage` so enemy variants can tune fire behavior/damage.
  - Added two new enemy variants:
    - `scripts/EnemyTank.gd` + `scenes/EnemyTank.tscn`
    - `scripts/EnemySpeedster.gd` + `scenes/EnemySpeedster.tscn`
  - Wired `scripts/EnemySpawner.gd` to spawn weighted normal/tank/speedster enemies on non-boss waves.
  - Updated `scripts/Game.gd` to provide new enemy scenes to the spawner.
  - Updated `scripts/Player.gd` to read enemy bullet damage from `BulletEnemy` instances instead of fixed damage.
  - Adjusted baseline damage tuning so relationships are correct:
    - Normal bullets stronger than speedster bullets
    - Tank bullets stronger than normal bullets

### Why
  - To add clear enemy archetypes with distinct threat profiles (durability pressure vs speed pressure).
  - To make enemy type differences meaningful in both dodge patterns and damage tradeoffs.

### Any pitfalls / fixes
  - Without per-bullet damage, “more/less damage than normal” could not be represented correctly; damage is now a bullet-level stat.

### Any thing important to mention if another AI agent were to move forward
  - Spawn mix is tunable from `EnemySpawner` exports (`tank_spawn_chance`, `speedster_spawn_chance`) without code changes.

## 04/29/26 - Codex (player boost input)

### What changed
  - Added a new `boost` input action in `project.godot` (keyboard `E`, joypad button `1`).
  - Added `boost_speed_multiplier` in `scripts/Player.gd`.
  - Updated movement logic so holding `boost` increases movement speed while still combining correctly with `focus`.

### Why
  - To give players an active speed-up option for repositioning and emergency dodges.

### Any pitfalls / fixes
  - Speed modifiers are multiplicative (`boost` then `focus`), so tuning can be done with either export value without changing code.

### Any thing important to mention if another AI agent were to move forward
  - If controls are remapped in editor, keep the `boost` action name stable so movement code stays compatible.

## 04/29/26 - Codex (boost key remap)

### What changed
  - Remapped keyboard `boost` input from `E` to `Shift` in `project.godot`.

### Why
  - To match requested control preference for faster access during movement.

### Any pitfalls / fixes
  - `focus` is also currently mapped to `Shift`, so both actions trigger together on keyboard until one is remapped.

### Any thing important to mention if another AI agent were to move forward
  - If independent behavior is desired, remap either `focus` or `boost` to avoid overlap on the same key.

## 04/29/26 - Codex (tank spread shot)

### What changed
  - Updated `scripts/EnemyTank.gd` to override firing and shoot a 3-bullet spread (center, left, right) instead of a single forward bullet.
  - Added exported `spread_angle_degrees` for easy spread-width tuning.

### Why
  - To make tank enemies feel heavier and more area-denial focused than other archetypes.

### Any pitfalls / fixes
  - Spread uses inherited `bullet_speed` and `bullet_damage`, so future balance tuning stays centralized in tank scene exports.

### Any thing important to mention if another AI agent were to move forward
  - If tank projectile density gets too punishing at high wave counts, adjust `spread_angle_degrees` and `shot_interval` before reducing damage.

## 04/29/26 - Codex (boost behavior fix)

### What changed
  - Updated player movement multiplier logic in `scripts/Player.gd` so `boost` takes priority over `focus` when both are active.

### Why
  - To fix the case where boost appeared broken due to overlapping key bindings (`Shift` mapped to both boost and focus).

### Any pitfalls / fixes
  - This preserves current key mapping while ensuring Shift produces a speed-up instead of an accidental slowdown.

### Any thing important to mention if another AI agent were to move forward
  - If independent focus/boost behavior is needed later, remap one of the two actions to a different key and this priority logic can still stay as a safe fallback.

## 04/29/26 - Codex (player HP increase)

### What changed
  - Increased player default HP values in `scripts/Player.gd`:
    - `max_hp` from `5` to `25`
    - initial `hp` from `5` to `25`

### Why
  - To make the player significantly more durable as requested.

### Any pitfalls / fixes
  - Respawn and HUD updates already reference `max_hp`, so no additional wiring changes were required.

### Any thing important to mention if another AI agent were to move forward
  - Balance impact is substantial; enemy damage/spawn pacing may need retuning if challenge drops too much.

## 04/29/26 - Codex (normal enemy wave bullets)

### What changed
  - Added sinusoidal left-right trajectory support to `scripts/BulletEnemy.gd` with wave axis/amplitude/frequency/phase properties.
  - Updated `scripts/EnemyBasic.gd` to fire slower wave bullets by default for normal enemies.
  - Added wave bullet tuning exports on `EnemyBasic` (`use_wave_bullets`, `wave_amplitude`, `wave_frequency`).
  - Disabled wave bullets on speedster scene (`scenes/EnemySpeedster.tscn`) so this pattern remains specific to normal enemies.

### Why
  - To give normal enemies the requested slow wave shot pattern and increase movement variety in non-boss waves.

### Any pitfalls / fixes
  - Wave displacement is applied as per-frame delta from the sine curve to avoid accumulating drift over time.

### Any thing important to mention if another AI agent were to move forward
  - If wave difficulty is too high, first lower `wave_amplitude` or `wave_frequency` in `EnemyBasic` exports.

## 04/29/26 - Codex (normal bullets straight fix)

### What changed
  - Reverted normal enemy bullets in `scripts/EnemyBasic.gd` to straight shots by disabling wave mode (`use_wave_bullets = false`).
  - Restored normal enemy bullet speed to `220.0`.

### Why
  - To match requested behavior (straight shots) and remove the unintended half-circle visual path.

### Any pitfalls / fixes
  - Wave bullet code remains available in `BulletEnemy` and can be re-enabled per-enemy via export values without new code changes.

### Any thing important to mention if another AI agent were to move forward
  - If reintroducing wave shots later, prefer enabling them on a dedicated enemy variant rather than changing normal baseline behavior.
