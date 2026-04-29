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
- Shared constants: `scripts/Defs.gd`

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

Add to the running log at `docs/SESSION_LOG.md` for every change:

- What changed
- Why
- Any pitfalls / fixes
- Next actionable steps

The format should be have a header to denote the date of the change and include the name of the github username and a bullet point list to show what was changed