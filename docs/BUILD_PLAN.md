# Next build — step-by-step execution plan

This document is the **single roadmap** for one coordinated build pass. Follow it **in order** unless a step is explicitly marked optional.

---

## Principles for this pass

1. **Finish a phase before starting the next** (avoid half-done surfaces).
2. **Each phase has an exit gate** — if the gate fails, fix before continuing.
3. **Prefer small commits** (or one branch) per phase.

---

## Phase 0 — Preconditions (same day, short)

| Step | Action | Exit gate |
|------|--------|-----------|
| 0.1 | Confirm Godot **4.6.2** opens the project and **Play** runs. | You can move, focus, shoot; enemies spawn; no errors. |
| 0.2 | Confirm Git status clean after pull. | No local drift before starting work. |

---

## Phase 1 — “Real” game loop scaffolding (blocking)

**Goal:** turn the current sandbox into a stage loop we can extend.

| Step | Action | Details |
|------|--------|---------|
| 1.1 | Add a `Stage` concept | Stage script/scene responsible for enemy waves + progression. |
| 1.2 | Add a `GameState` (minimal) | Running / Paused / GameOver; restart flow. |
| 1.3 | Add a basic HUD | Lives/bombs/score placeholder; “Game Over” overlay. |

**Exit gate**

- [ ] You can start, die (even if just by contact), see Game Over, and restart.
- [ ] Stage restarts cleanly (no leftover bullets/enemies).

---

## Phase 2 — Collision + damage model (blocking)

**Goal:** make hits “real” and readable.

| Step | Action | Details |
|------|--------|---------|
| 2.1 | Define hit rules | Player hitbox vs graze box; enemy hurtboxes; bullet despawn rules. |
| 2.2 | Add HP / lives | Player lives or HP; enemy HP already exists—formalize. |
| 2.3 | VFX hooks | Spawn an effect on hit/kill (even a placeholder). |

**Exit gate**

- [ ] Enemy bullets reliably damage the player.
- [ ] Player bullets damage enemies and kills are consistent.

---

## Phase 3 — Pattern authoring (core bullet hell)

**Goal:** patterns become data/authorable instead of hardcoded per enemy.

| Step | Action | Details |
|------|--------|---------|
| 3.1 | Create a `Pattern` API | e.g. ring, arc, aimed, spiral; parameterized (count/speed/spread). |
| 3.2 | Spawn determinism (optional) | Seedable RNG per stage for reproducible test runs. |
| 3.3 | Add 2–3 enemy types | Small set with distinct patterns/movement. |

**Exit gate**

- [ ] At least 3 distinct, parameterized bullet patterns exist.
- [ ] At least 2 enemies use patterns via shared APIs (not copy/paste).

---

## Phase 4 — Presentation pass (optional)

- Replace debug circles with sprite art
- Use the committed `Assets/` packs for player/enemy bullets and hit VFX
- Add parallax background

### Status (rolling)

- **Started:** enemy bullets now use an **`AtlasTexture` crop** from `Assets/Effect and FX Pixel All Free/Free/Part 1/03.png` (`Rect2(576, 0, 64, 64)`) instead of debug draw circles.
- **Next:** hit/kill VFX, enemy-specific bullet variants (duplicate `BulletEnemy` scenes or swap atlas regions per enemy).

---

## Maintenance

When a build pass finishes, add `Status: COMPLETED (date)` to the top of this file and start a fresh plan for the next milestone.

