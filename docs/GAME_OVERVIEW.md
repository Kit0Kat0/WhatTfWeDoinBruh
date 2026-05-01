# WhatTfWeDoin — game & tech overview

## What the game is

**WhatTfWeDoin** is a **bullet hell shmup** prototype (top-down, arcade-style). The core loop is:

- **Dodge** dense enemy bullet patterns
- **Shoot** to clear enemies and survive waves
- Progress through **stages** with escalating pattern complexity

## Design pillars (early)

- **Readability first**: bullets, hitbox, and danger should be unambiguous.
- **Tight controls**: responsive movement with an optional **focus** mode for precision.
- **Deterministic patterns** where possible (seedable spawns/patterns later) to make tuning and replay testing easier.

## Current prototype slice

- Player movement + focus + boost + shooting
- Player HP with top-left HUD bar
- Player respawn loop (3 lives) with short post-respawn immunity
- Wave-based enemy spawner with short inter-wave delay
- Mixed enemy archetypes (normal, tank, speedster) with distinct HP/speed/fire-rate/damage profiles
- Boss encounter every 10 waves
- Player + enemy bullets are now **sprite-driven** (enemy bullets use an `AtlasTexture` crop from the `Effect and FX Pixel All Free` sheets)

## Tech / tools

- **Engine**: Godot **4.6.2**
- **Language**: GDScript
- **Project entry**: `res://scenes/Game.tscn`

