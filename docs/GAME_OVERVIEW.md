# WhatTfWeDoin — game & tech overview

## What the game is

**Virus Hunter** is a **bullet hell shmup** prototype (top-down, arcade-style). The core loop is:

- **Dodge** dense enemy bullet patterns
- **Shoot** to clear enemies and survive waves
- Progress through **stages** with escalating pattern complexity

## Design pillars (early)

- **Readability first**: bullets, hitbox, and danger should be unambiguous.
- **Tight controls**: responsive movement with an optional **focus** mode for precision.
- **Deterministic patterns** where possible (seedable spawns/patterns later) to make tuning and replay testing easier.

## Current prototype slice

- Player movement + focus + boost + shooting (weapon perks: double/triple straight rows, piercing beam for ~45s) from occasional enemy/boss drops
- Player HP with top-left HUD bar
- Player respawn loop (3 lives) with short post-respawn immunity
- Game over overlay with spacebar restart
- Escape pause with 3-second countdown before resume
- Main menu settings controls for Music/SFX volume and automatic shooting toggle
- Wave-based enemy spawner with short inter-wave delay
- Mixed enemy archetypes (normal, tank, speedster) with distinct HP/speed/fire-rate/damage profiles
- Boss encounter every 7 waves (alternates normal forward shots and tanky 3-way spreads)
- Player + enemy bullets are now **sprite-driven** (enemy bullets use an `AtlasTexture` crop from the `Effect and FX Pixel All Free` sheets)
- Audio scaffolding in place: `Music` / `SFX` buses (`default_bus_layout.tres`), `AudioManager` autoload, asset checklist + integration map in [`AUDIO_GUIDE.md`](AUDIO_GUIDE.md). Drop assets into `audio/` to activate sound; missing files no-op safely.

## Tech / tools

- **Engine**: Godot **4.6.2**
- **Language**: GDScript
- **Project entry**: `res://scenes/Main.tscn` (menu), which starts `res://scenes/Game.tscn` on Play

