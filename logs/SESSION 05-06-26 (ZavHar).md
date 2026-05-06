## 05/06/26 - ZavHar (enemy visuals + flash upgrade)

### What changed
  - Swapped enemy visuals from debug draw / placeholders to Craftpix run-cycle sprites:
    - `EnemyBasic`, `EnemyTank`, `EnemySpeedster`: `AnimatedSprite2D` + `SpriteFrames` (6-frame loop from `RunSD.png` sheets).
    - `EnemyBoss`: sprite-based presentation (Craftpix DropPod as current placeholder).
  - Added `shaders/flash_tint.gdshader` and moved the damage flash to a **shader uniform** (`flash`) so the hit flash reads crisp without destroying the palette tint.
  - Fixed “whole group flashes at once” by **duplicating the `ShaderMaterial` per enemy instance** on `_ready()`.
  - Preserved original perceived enemy sizes by scaling sprites based on **non-transparent pixel bounds** (alpha scan) instead of the full 48×48 frame padding.
  - Added a simple Virus vs Antivirus palette surface (`faction`, `virus_color`, `antivirus_color`) to keep tinting consistent.

### Why
  - To make enemies readable and lively with minimal art overhead, while keeping gameplay tuning stable (enemy collision radius / threat size stays consistent).

### Any pitfalls / fixes
  - Craftpix sprites are already colored; tinting is a hue-shift rather than a full recolor. For a “hard” palette swap later, we’ll want neutral/white sprites or a palette shader.
  - The visible-bounds scan is cached per atlas-region key so it’s not expensive per frame.

### Any thing important to mention if another AI agent were to move forward
  - If new enemies use `ShaderMaterial` flash, ensure the material is duplicated per instance to avoid shared-uniform bugs.
  - If spritesheets change frame sizes, update the atlas regions in the enemy scenes accordingly (current Craftpix run sheets are 6×48px frames).

## 05/06/26 - ZavHar (camera shake + enemy hit shake)

### What changed
  - Added **camera shake** on player damage by tracking `Player.health_changed` deltas in `Game.gd` and jittering a `Camera2D.offset` for a short duration.
  - Added **per-enemy sprite shake** on non-lethal hits (`EnemyBasic` + `EnemyBoss`), with punchier defaults and a directional kick component.
  - Forced `AnimatedSprite2D` enemies to `play("run")` on spawn to avoid any cases where the run loop stops unexpectedly.

### Why
  - To add immediate hit feedback (“juice”) without changing gameplay rules or timings.

### Any pitfalls / fixes
  - Per-enemy shake is applied to the sprite node’s local `position`; ensure `_sprite_base_pos` is captured after the node exists, and reset on pause.


