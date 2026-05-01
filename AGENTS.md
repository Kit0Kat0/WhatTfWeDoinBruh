# WhatTfWeDoin — agent context

Use this file as a **cold-start** reference when picking up work on this bullet-hell shmup without prior chat history.

## Canonical location

- **Authoritative project root:** `E:\WhatTfWeDoin\`
- If you have other copies (OneDrive, zips, etc.), treat them as **non-authoritative** unless explicitly stated.

## Engine / version

- **Godot:** **4.6.2** (team version)

## Repo layout (current)

- **Scenes:** `scenes/`
- **Scripts:** `scripts/`
- **Main scene:** `res://scenes/Game.tscn`

Prototype gameplay slice currently lives in:

- `scenes/Game.tscn`, `scripts/Game.gd`
- `scenes/Player.tscn`, `scripts/Player.gd`
- `scenes/EnemyBasic.tscn`, `scripts/EnemyBasic.gd`
- `scenes/EnemySpawner.tscn`, `scripts/EnemySpawner.gd`
- `scenes/BulletPlayer.tscn`, `scripts/BulletPlayer.gd`
- `scenes/BulletEnemy.tscn`, `scripts/BulletEnemy.gd`
- HUD: `scenes/HUD.tscn`, `scripts/HUD.gd`
- One-shot VFX example: `scenes/VFX/MuzzleFlash.tscn`, `scripts/VfxOneShot.gd`
- Shared constants: `scripts/Defs.gd`

## Documentation (humans + agents)

- **Design / roadmap:** `docs/GAME_OVERVIEW.md`, `docs/BUILD_PLAN.md`
- **Technical session history (symptoms → fixes):** `docs/SESSION_LOG.md`
- **Per-session notes:** `logs/SESSION {date} ({username}).md` (see below)
- **Third-party credits:** `docs/SESSION_LOG.md` points at `ASSET_ATTRIBUTION.md` when that file exists in the tree; otherwise check README/license files inside `Assets/` pack folders.

## Art / VFX workflow

- **Player frames:** curated PNGs under `art/player/` (e.g. `player_frame_0.png` …). If Godot complains about `preload` on raw PNGs in a given setup, `scripts/Player.gd` uses **runtime** `Image.load` → `ImageTexture.create_from_image` for those paths.
- **Large FX atlases** (e.g. `Assets/Effect and FX Pixel All Free/...`): do **not** use the whole PNG as one sprite; use a `Sprite2D` + **`AtlasTexture`** with an explicit **`Rect2`** region for one cell/effect.
  - **Example (enemy bullet):** `scenes/BulletEnemy.tscn` crops `.../Free/Part 1/03.png` at **`Rect2(576, 0, 64, 64)`**. Adjust the rect or pick a neighbor cell if density/readability suffers; simpler fallback sprites live under `Assets/Craftpix/Projectiles/` if needed.
- **Direction:** keep raw packs in `Assets/`; promote stable, reused VFX into a dedicated `vfx/` (or similar) once scenes/resources are authored around them.

## Controls (prototype)

- **Move**: WASD / Arrow keys / left stick
- **Shoot**: Space / Joypad A
- **Focus**: Shift / Joypad LB

## Working conventions (recommended)

- **Small commits**: one feature/fix at a time; keep commits reviewable.
- **Branches**: use feature branches for anything non-trivial (patterns, player tweaks, new enemy types, UI/HUD).
- **Scene ownership**: if two people touch the same `.tscn` frequently, consider splitting responsibilities or composing via child scenes to reduce merge conflicts.
- **Prefer scripts for logic** and keep scenes mostly wiring/serialized data; use exported vars for tuning.

## Session log (recommended)

Add to a new running log at `logs/SESSION {date} ({username}).md` for every change in a session

Each bullet point should be a header with a list or paragraph below it
- What changed
- Why
- Any pitfalls / fixes
- Any thing important to mention if another AI agent were to move forward (should not include instructions to continue using the same log file)

The format should be have a header to denote the date of the change and include the name of the github username and a bullet point list to show what was changed

The date format should be mm/dd/yy