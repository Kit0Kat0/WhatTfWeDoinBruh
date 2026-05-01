## 04/30/26 - ZavHar

### What changed
  - Committed + pushed the latest enemy projectile presentation work (`scenes/BulletEnemy.tscn`, `scripts/BulletEnemy.gd`).
  - Updated docs to reflect the new **FX atlas isolation** approach for enemy bullets and the rolling Phase 4 presentation status (`docs/SESSION_LOG.md`, `docs/GAME_OVERVIEW.md`, `docs/BUILD_PLAN.md`).

### Why
  - Enemy bullets were still reading like “debug circles” / placeholder art; isolating a single cell from the large `Effect and FX Pixel All Free` sheets gives a more intentional “orb / particle” read while staying inside the committed asset packs.
  - Keeping `docs/` + `logs/` aligned prevents the next session from rediscovering the same atlas-cropping workflow.

### Any pitfalls / fixes
  - FX sheets are **multi-atlas PNGs**: always prefer `AtlasTexture` + an explicit `Rect2` region (and avoid rotating radial sprites unless the art benefits from it).

### Any thing important to mention if another AI agent were to move forward
  - Current enemy bullet crop: `Assets/Effect and FX Pixel All Free/Free/Part 1/03.png` @ `Rect2(576, 0, 64, 64)` (see `scenes/BulletEnemy.tscn`).
  - If readability regresses at higher bullet density, iterate neighboring 64×64 cells or fall back to a simpler circular projectile sprite (e.g. `Assets/Craftpix/Projectiles/4.png`).

## 04/30/26 - ZavHar (AGENTS cold-start)

### What changed
  - Expanded `AGENTS.md` with a **documentation map** (`docs/*` + `logs/`), **HUD / muzzle VFX** paths in the prototype list, and an **Art / VFX workflow** section (`AtlasTexture` + `Rect2` for FX sheets, enemy bullet example, `art/player` + runtime `Image.load` note, future `vfx/` curation).
  - Clarified **attribution**: points to `ASSET_ATTRIBUTION.md` when present, else pack READMEs under `Assets/`.

### Why
  - So the next agent (or teammate) does not rely on chat history for where docs live or how FX atlases are isolated in this repo.

### Any pitfalls / fixes
  - None; small doc-only change.

### Any thing important to mention if another AI agent were to move forward
  - Treat `AGENTS.md` as the first file to read for layout, docs links, and VFX conventions before editing scenes.
