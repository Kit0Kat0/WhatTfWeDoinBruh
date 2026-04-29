# WhatTfWeDoin — session & issue log

**Purpose:** Record **prompts, symptoms, causes, and fixes** so future work doesn’t depend on chat history alone.

**Not a spec:** Roadmaps and targets live in [`BUILD_PLAN.md`](BUILD_PLAN.md) and [`GAME_OVERVIEW.md`](GAME_OVERVIEW.md).

---

## Agent pickup (read this on a cold start)

- **Repo root (authoritative):** `E:\WhatTfWeDoin`
- **Godot:** 4.6.2
- **Main scene:** `res://scenes/Game.tscn`
- **Current playable slice:** Player (move/focus/shoot), spawner, basic enemy ring pattern, bullets.
- **Asset tracking:** see `ASSET_ATTRIBUTION.md`
- **FX isolation convention:** keep raw packs in `Assets/`; copy curated game-ready VFX into `vfx/` (textures/resources/scenes) when we start authoring reusable effects.

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

