## 05/05/26 - ZavHar

### What changed
  - Added per-shot pitch variation to the player’s firing sound by passing a small randomized `pitch_scale` into `AudioManager.play_sfx("player_shot", ...)` inside `Player._update_shooting`.

### Why
  - To make the repeated player shot SFX feel less mechanical and add a subtle sense of responsiveness without changing the underlying sound asset.

### Any pitfalls / fixes
  - Pitch range is intentionally conservative (`~0.94–1.06`) to avoid chipmunk/boomy artifacts on any final recorded SFX that replace the current procedural placeholder.

### Any thing important to mention if another AI agent were to move forward
  - Future variation (e.g., alternating multi-shot layers) should continue to route through `AudioManager.play_sfx` so mixing and volume trims stay centralized.

## 05/05/26 - ZavHar (Path2D enemy paths + wave groups)

### What changed
  - Added `EnemyPaths` / `BossPaths` hierarchies with named `Path2D` nodes under [`scenes/Game.tscn`](scenes/Game.tscn); curves are built at runtime from the playfield rect via [`scripts/EnemyPathLibrary.gd`](scripts/EnemyPathLibrary.gd) (Bezier-style routes for normals/splits, on-screen looping ovals for bosses).
  - Added [`scripts/EnemyPathMotion.gd`](scripts/EnemyPathMotion.gd) to advance enemies along baked curve length at `EnemyBasic.speed` (or `EnemyBoss.path_follow_speed`), wrapping distance at the end of the path.
  - Refactored [`scripts/EnemyBasic.gd`](scripts/EnemyBasic.gd) to follow `path_motion` instead of manual down/strafe/wrap movement; optional `follow_path_rotation` export.
  - Refactored [`scripts/EnemyBoss.gd`](scripts/EnemyBoss.gd) to use the same path motion with `path_follow_speed`; removed the old top-lane patrol exports.
  - Replaced [`scripts/EnemySpawner.gd`](scripts/EnemySpawner.gd) with a wave scheduler: groups share one rolled archetype; **split groups** spawn the same type on every path in a `Path_SplitSet*` set at one time; **single-path groups** stagger spawns along one path; groups are spaced across the wave via tunable gaps/stagger exports.
  - Wired [`scripts/Game.gd`](scripts/Game.gd) to call `EnemyPathLibrary.configure_paths` before the spawner runs and to assign `enemy_paths_root` / `boss_paths_root` on the spawner.

### Why
  - To meet the design goal of curved, authored-feeling approach routes using Godot `Path2D`, grouped wave spawns, optional simultaneous split routes, and bosses that loop on-screen.

### Any pitfalls / fixes
  - Paths are **procedurally filled** from the viewport `playfield_rect` so entry/exit stays consistent across resolutions; editing the route shapes means changing the generator in `EnemyPathLibrary`, not dragging handles in the editor (nodes are still real `Path2D`s for structure and naming).
  - `EnemyBasic.horizontal_speed` is now unused for movement but kept for scene compatibility with existing `.tscn` tuning.

### Any thing important to mention if another AI agent were to move forward
  - Naming drives behavior: `Path_Enemy_*` for random routes, `Path_SplitSetA_*` / `Path_SplitSetB_*` for split sets, `Path_Boss_*` for boss loops.
  - Wave pacing is controlled by the new `@export` knobs on `EnemySpawner` (`split_group_chance`, group size range, gaps, stagger, `along_path_separation`).

## 05/06/26 - ZavHar

### What changed
  - Added a new green weapon perk, **Cross-Fire**, that makes the player shoot in all four cardinal directions.
  - Updated perk drops to include Cross-Fire in the random roll.
  - Updated the perk timer bar color mapping to include Cross-Fire (green).

### Why
  - To add a distinct crowd-control style weapon perk that changes positioning and threat management.

### Any pitfalls / fixes
  - Cross-Fire currently uses the same bullet scene/TTL as normal shots; downward/side shots will persist until they expire/offscreen like any other player bullet.

### Any thing important to mention if another AI agent were to move forward
  - Cross-Fire is represented as `WeaponPickup.PerkKind.CROSS_FIRE` and `Player.WeaponMode.CROSS_FIRE`; keep these in sync if perk enums are reorganized.

## 05/06/26 - ZavHar (enemy damage flash)

### What changed
  - Enemies briefly **lerp their drawn colors toward white** when they take non-lethal player bullet damage: `EnemyBasic` (+ tank/speedster via `_with_hit_flash` in their `_draw`), and `EnemyBoss` with the same pattern.
  - Tunable `@export var damage_flash_duration_sec` (default `0.1`) on basic enemies and boss; `_damage_flash_remaining` decays in `_process` with `queue_redraw()` while active.

### Why
  - Clear hit feedback so players can see which enemies are being damaged.

### Any pitfalls / fixes
  - Killing blows skip the flash (enemy is freed immediately); only surviving hits show the effect.

### Any thing important to mention if another AI agent were to move forward
  - Subclasses that override `_draw` must wrap colors with `_with_hit_flash(...)` for the flash to appear.

## 05/06/26 - ZavHar (runtime fixes: pickups, audio warning, GDScript strictness)

### What changed
  - **`Game.try_spawn_weapon_pickup`**: defers actual `instantiate` / `add_child` to `_spawn_weapon_pickup_deferred` so weapon pickups are not created during physics `area_entered` (avoids “flushing queries” / `monitorable` errors).
  - **`AudioManager`**: added `@export var warn_on_procedural_audio_fallback` (default **false**) so missing `res://audio/` assets do not spam warnings unless enabled on the autoload.
  - **`EnemySpawner`**: `_compute_group_start_distance` parameter renamed to `_path` (unused); cache read uses `_variant_to_float(...)` instead of `float(variant)` for strict typing.

### Why
  - Pickups: spawning `Area2D` inside bullet–enemy collision must happen after the physics flush.
  - Audio: procedural placeholders are intentional during prototype; warnings are opt-in for final asset hookup.
  - Typing: Godot 4.6.x treats unsafe `Variant`→`float` as errors when warnings are errors.

### Any pitfalls / fixes
  - Deferred pickup spawn: perk kind and roll still happen synchronously; only node creation is deferred.

### Any thing important to mention if another AI agent were to move forward
  - Any future “spawn node that touches physics” from collision signals should use `call_deferred` / deferred helpers by default.

## 05/06/26 - ZavHar (enemy fire desync + player bullet facing)

### What changed
  - **`EnemyBasic` / `EnemyBoss`**: replaced lockstep `_shot_t` reset with a **cooldown**; each new shot gap is `shot_interval ± shot_interval_jitter_ratio` (with a floor `shot_interval_min_sec`) so groups do not resync every volley.
  - **`BulletPlayer`**: `rotation` / `_sync_travel_rotation()` from velocity + `travel_rotation_offset_radians` (default `PI * 0.5` so default upward shot matches prior art). **`Player._spawn_player_bullet`** sets `velocity` (and related fields) **before** `add_child` so `_ready` can orient sprites.

### Why
  - Fire desync: resetting the timer to `0` after every shot realigned every enemy that had fired together.
  - Bullet facing: Cross-Fire and angled triple shots need correct sprite direction.

### Any pitfalls / fixes
  - Tune `shot_interval_jitter_ratio` / min on the enemy scenes if patterns feel too irregular.

### Any thing important to mention if another AI agent were to move forward
  - Beam mode calls `configure_as_beam()` after add; `_sync_travel_rotation` runs in `configure_as_beam` too so beam hitbox stays aligned.

## 05/06/26 - ZavHar (boss waves: adds, HP bar, signals)

### What changed
  - **`EnemySpawner`**: `@export_range(0,1) boss_enemy_amount` scales how many **normal-style adds** spawn on boss waves vs a same-number non-boss wave target; `_wave_enemy_target()` returns `1 + add_count` on boss waves; `_append_grunt_spawn_events` re-used for adds; **`boss_spawned(boss: EnemyBoss)`** signal after boss is parented.
  - **`EnemyBoss`**: `max_hp` export, runtime `hp`, **`signal health_changed(current_hp, max_hp)`**; scene uses `max_hp` instead of setting `hp` in `.tscn`.
  - **`Game`**: connects **`boss_spawned`** and **`health_changed`** to drive HUD; hides boss bar when boss exits or on non-boss waves; **`HUD`**: boss HP uses **`TextureProgressBar`** with **`FILL_BILINEAR_LEFT_AND_RIGHT`** (gradient textures as subresources — **`PackedColorArray` must use raw floats**, not `Color(...)` constructors in `.tscn`).

### Why
  - Boss fights with adds; readable boss HP; bilinear bar drains from both sides toward the center.

### Any pitfalls / fixes
  - **`HUD.gd`** must stay aligned with the scene: removing `ColorRect` boss fills required dropping **`%BossHpLeftFill` / `%BossHpRightFill`** references when switching to `TextureProgressBar` only.

### Any thing important to mention if another AI agent were to move forward
  - Keep `WeaponPickup` / `Player` perk enums in sync when adding perks; boss bar colors/timer already map per perk kind.

## 05/06/26 - ZavHar (path trace VFX)

### What changed
  - New **`scripts/PathTrace.gd`** + **`scenes/PathTrace.tscn`**: follows same **`Path2D`** as enemies using **`EnemyPathMotion`** + **`advance_no_wrap`**; travels at **`enemy.speed * 3`** (tunable via code); stops after **one full arc length** of the baked curve, then stops particles and frees; **`Game`** adds **`PathTraces`** node and wires **`path_trace_scene` / `path_trace_parent`** on the spawner.
  - **`EnemySpawner`**: path trace only for groups whose archetype **`_get_scene_base_speed(scene) > path_trace_speed_threshold`** (default 300); **`emit_path_trace: true`** only on the **first spawn** in a single-path group (`j == 0`) or first path in a **split** group; spawns trace in `_spawn_enemy_on_path(..., emit_path_trace)` — not per-enemy.

### Why
  - Visualize fast routes once per group without cluttering every staggered spawn.

### Any pitfalls / fixes
  - Scene speed cache: use **`_variant_to_float`** when reading from `Dictionary` to satisfy strict typing.

### Any thing important to mention if another AI agent were to move forward
  - **`EnemyPathMotion.advance_no_wrap`** only adds distance; **`apply_to`** still wraps for sampling along the loop until travel budget completes in **`PathTrace`**.

## 05/06/26 - ZavHar (render order: bullets, backdrop, frame)

### What changed
  - **`Game`**: **`BULLETS_Z_INDEX = -10`** on **`PlayerBullets`** / **`EnemyBullets`** so shots draw **under** ships (`z_index` 0).
  - **`PlayfieldBackdrop`** (`class_name PlayfieldBackdrop`): dark fill only; **`BACKDROP_Z_INDEX = -50`** so fill sits **below** bullets (fixes bullets “invisible” when the root **`Game._draw()`** covered negative-`z` layers).
  - **`PlayfieldFrame`**: inner **`grow(-8)`** outline only, **`PLAYFIELD_FRAME_Z_INDEX = 100`**, **`PROCESS_MODE_ALWAYS`** so the border stays correct when paused; drawn **above** all world `Node2D` gameplay; **HUD `CanvasLayer` stays above** the world stack.
  - Fill uses **full `playfield_rect`** (no shrink on the solid color); inset is for the stroke only. **`_on_viewport_size_changed`** updates backdrop + frame + `playfield_rect` consumers.

### Why
  - Layering: background → bullets → ships → optional high overlay frame; avoid parent `_draw` painting over child layers.

### Any pitfalls / fixes
  - **Godot `.tscn` Gradients**: `PackedColorArray` expects float components, not nested **`Color(...)`** calls (parse error).

### Any thing important to mention if another AI agent were to move forward
  - Raise **`PLAYFIELD_FRAME_Z_INDEX`** only if something world-space exceeds 100; UI that must sit above the frame remains on **`CanvasLayer`** (or raise layer property there).

## 05/06/26 - ZavHar (beam overhaul, HP scaling, boss adds, path traces)

### What changed
  - **Beam weapon rework**: replaced the old `BulletPlayer`-based beam with a dedicated `PlayerBeamLine` scene (`Node2D` + `Line2D` + `Area2D`/`CollisionPolygon2D`) that:
    - Samples the player’s muzzle each frame until the polyline reaches ~100 px, then scrolls upward at bullet speed while keeping shape fixed.
    - Builds a thick polygon in the beam `Area2D`’s local space and runs `get_overlapping_areas()` in `_physics_process` to apply continuous damage without being destroyed on hit.
  - **Beam DPS + damage plumbing**: moved all combat values to **floats scaled by 10** (e.g. `Player.max_hp = 250.0`, normal bullet damage `10.0`, `EnemyBasic.hp = 80.0`, `EnemyBoss.max_hp = 1600.0`), and made the beam deal direct DPS (`PlayerBeamLine.DPS = 750.0` → 75 HP/s in pre-scale terms) via new `apply_beam_damage(amount: float)` methods on `EnemyBasic`/`EnemyBoss`.
  - **HP display and contact hits**: updated `HUD.set_hp` to show **integer HP** by dividing by 10 and rounding; normalized contact damage so enemy bodies / generic hits always apply an exact `10.0` damage step.
  - **First boss wave adds**: adjusted `EnemySpawner._boss_wave_add_count()` so the **very first boss wave** (when `_current_wave == boss_every_n_waves`) spawns **no extra grunt adds**, while later boss waves still use `boss_enemy_amount` to scale add count.
  - **Path trace behavior for fast split groups**: changed split-group spawn events so any “fast” archetype (speed above `path_trace_speed_threshold`) emits a **`PathTrace` for each split path**, not only the first path in the set.
  - **Runtime / strictness fixes**: cleaned up strict GDScript warnings (unused `_sprite` in `BulletPlayer`, confusable locals in `EnemySpawner`) and fixed player respawn by deferring `_spawn_player(true)` via `call_deferred` to avoid “flushing queries” physics errors when the player dies inside an overlap.

### Why
  - Beam: the old tall-rectangle beam projectile wasn’t expressive or reliable enough; this version gives a shmup-style laser ribbon that feels powerful, can slice through groups, and cooperates with Godot’s physics/overlap rules instead of fighting them.
  - HP/damage floats: moving to a float-with-scale model makes it easier to tune DPS and per-hit values without being constrained to whole numbers while keeping visible HP as simple integers.
  - First boss adds: the initial boss appearance should be focused and readable without extra trash; later boss waves can escalate difficulty with adds again.
  - Path traces: fast split routes looked visually “unbalanced” when only one of several paths had a trace; mirroring traces across the whole split reads better and still uses a single effect per path.
  - Runtime fixes: keeps the Godot console clean under “warnings as errors” and prevents physics-state-change crashes during intense moments (beam hits, deaths, respawns).

### Any pitfalls / fixes
  - Because HP values are stored scaled by 10, any new code should **never** assume `hp`/`damage` are integers; comparisons that used `%` now cast to `int` where needed (e.g. boss hit SFX cadence).
  - Beam collision relies on per-frame polygon rebuilds in `_physics_process`; if performance ever becomes an issue with many beams, we may need to cache or simplify the thickening logic.

### Any thing important to mention if another AI agent were to move forward
  - Beam implementation lives in `scripts/PlayerBeamLine.gd` + `scenes/PlayerBeamLine.tscn`; `Player` owns when to spawn it (beam weapon mode) and normal bullets are now fully separate from beam behavior.
  - All **HP/damage** semantics are now float-based with a hard-coded scale of **10**; UI and tuning should treat 1 “design HP” as `10.0` internal units going forward.
  - Boss wave add count logic is centralized in `_boss_wave_add_count()`; change that function if you want different behavior (e.g. no adds for the second boss, dynamic adds based on wave).
  - Path trace emission uses the `emit_path_trace` flag in the spawn event; traces are created in `_spawn_enemy_on_path` so any future archetype or group rules should respect that flag instead of instantiating traces ad-hoc elsewhere.

