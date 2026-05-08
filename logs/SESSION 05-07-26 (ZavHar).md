## 05/07/26 - ZavHar (paths + HUD overhaul + pause/settings + meta perks)

### What changed
  - Added many new enemy movement paths:
    - 8 new normal enemy paths, 4 new boss paths, and 4 new split paths.
    - Updated `EnemyPathLibrary.gd` to generate more varied bezier chains and enforce off-screen entry/exit.
  - Tuned new siege boss HP down slightly (`EnemySiegeBoss` max HP reduced).
  - Game over screen perk history overhaul:
    - Perk list moved into a scrollable list with rarity-colored cards.
    - Hover tooltip for perk descriptions (no layout jitter).
    - Added perk count and player level display to game over.
  - HUD health/lives upgrades:
    - Player starting lives reduced by 1 (via `Game.gd`/exports).
    - Player HP bar flashes white/red under 20% HP.
    - Added a delayed red “hurt bar” behind player HP.
    - Lives display shows “LAST LIFE” when 0 lives remain.
  - Added player death/respawn readability:
    - Player ship explosion VFX on death.
    - Respawn delay before re-instantiating player.
  - Pause UX improvements:
    - Unpause delay set to 1 second (default) with a large radial countdown.
    - Removed countdown text and made pause countdown background more transparent.
    - After unpause, game speed lerps from 0 → 1 over 500ms.
    - Added unpause delay setting: Long (3s), Short (1s), None (0s) (still does time-scale lerp).
  - Settings menu improvements:
    - Settings panel integrated into pause menu.
    - Modal blockers fixed so clicking outside the settings panel doesn’t interact with underlying UI.
    - Added Quit button to main menu.
  - Pickup behavior tweaks:
    - Health drops heal 5% max HP.
    - Power-up lifetime scaling adjusted so slowed pickups don’t despawn prematurely.
    - Power-up timers tick at 10% speed when no enemies are active.
  - Meta progression + perks:
    - XP requirement growth increased to 1.15.
    - Rebound perk made Mythical-only.
    - Added meta perk **Redundancy** (Common–Legendary): increases healing from health pickups.
    - Added meta perk **Heat Map** (Rare): perimeter-following off-screen enemy indicators.
  - Enemy damage scaling:
    - Enemy damage increases by +5% additive per wave (applied in `EnemySpawner.gd` for normal enemies + bosses).
  - Visual feedback:
    - Playfield border occasionally flashes yellow under 20% HP (low HP warning).
  - Boss laser collision fix:
    - Reworked boss laser hitboxes from `CollisionPolygon2D` to dynamically generated `CollisionShape2D` segments to avoid convex decomposition errors.

### Why
  - To expand wave variety, improve HUD readability/feedback, tighten pause/settings UX, and add meaningful meta progression + perk-driven clarity.

### Any pitfalls / fixes
  - Modal input blocking depends on **scene tree order** as well as `z_index`; blockers must sit behind panels but above background UI.
  - Strict typing required defensive handling of `Variant` values when reading `Dictionary.get()` (helpers used to avoid warnings treated as errors).
  - Tooltip UI must be top-level / decoupled from layout to prevent hover flicker loops.

### Any thing important to mention if another AI agent were to move forward
  - Meta perk selection UI is built dynamically in `scripts/HUD.gd`; many nodes are looked up by name with `find_child(...)`.
  - Heat map indicators are drawn by `HudHeatMapIndicators.gd` using a ray-to-rect intersection to clamp indicators to the screen perimeter.
  - Enemy/boss damage scaling is centralized in `EnemySpawner.gd`; ensure any new boss damage fields are also scaled there.
