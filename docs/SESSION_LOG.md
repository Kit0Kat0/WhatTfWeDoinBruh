# WhatTfWeDoin — session & issue log

**Purpose:** Record **prompts, symptoms, causes, and fixes** so future work doesn’t depend on chat history alone.

**Not a spec:** Roadmaps and targets live in [`BUILD_PLAN.md`](BUILD_PLAN.md) and [`GAME_OVERVIEW.md`](GAME_OVERVIEW.md).

---

## Agent pickup (read this on a cold start)

- **Repo root (authoritative):** `E:\WhatTfWeDoin`
- **Godot:** 4.6.2
- **Main scene:** `res://scenes/Game.tscn`
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

---

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

