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

- Player movement + focus + shooting
- Enemy spawner
- Basic enemy that fires a ring pattern

## Tech / tools

- **Engine**: Godot **4.6.2**
- **Language**: GDScript
- **Project entry**: `res://scenes/Game.tscn`

