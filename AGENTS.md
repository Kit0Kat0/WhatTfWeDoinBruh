# WhatTfWeDoin — agent context

Use this file as a **cold-start** reference when picking up work on this bullet-hell shmup without prior chat history.

## Canonical location

- **Authoritative project root:** `E:\WhatTfWeDoin\`
- If you have other copies (OneDrive, zips, etc.), treat them as **non-authoritative** unless explicitly stated.

## Engine / version

- **Godot:** **4.6.2** (team version)
- Project file: `E:\WhatTfWeDoin\project.godot`

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
- Shared constants: `scripts/Defs.gd`

## Controls (prototype)

- **Move**: WASD / Arrow keys / left stick
- **Shoot**: Space / Joypad A
- **Focus**: Shift / Joypad LB

## Git (Windows gotcha)

If Git errors with **“detected dubious ownership”** on this drive, fix once with:

```powershell
git config --global --add safe.directory E:/WhatTfWeDoin
```

(This is a Git safety feature on some Windows filesystem setups.)

## Working conventions (recommended)

- **Small commits**: one feature/fix at a time; keep commits reviewable.
- **Branches**: use feature branches for anything non-trivial (patterns, player tweaks, new enemy types, UI/HUD).
- **Scene ownership**: if two people touch the same `.tscn` frequently, consider splitting responsibilities or composing via child scenes to reduce merge conflicts.
- **Prefer scripts for logic** and keep scenes mostly wiring/serialized data; use exported vars for tuning.

## Session log (recommended)

Add a lightweight running log at `docs/SESSION_LOG.md` once the project grows:

- What changed
- Why
- Any pitfalls / fixes
- Next actionable steps

