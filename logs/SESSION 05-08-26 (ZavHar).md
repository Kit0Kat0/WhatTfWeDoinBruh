## 05/08/26 - ZavHar (meta perks + HUD/pause UX + scaling)

### Previous session (same chat)
  - Had to reset the app mid-session due to increasing editor/app lag.

### What changed
  - Added meta perk **Staller** (Legendary, stack cap 3): 25% chance per stack to add +1s to active weapon power-up duration on enemy kill.
  - Added meta perk **Additional Core** (Mythical, unique): baseline firing becomes **Double Straight**, Double Straight pickups convert to **health**, and player damage is **-15%**.
  - Added meta perk selection card stack display above rarity:
    - “Unique” for stack cap 1
    - “Limited: owned/cap” for cap > 1
    - Hidden for unlimited perks
  - Added **Focus Mode** setting (saved in `GameSettings`, default off) to hide in-game HUD only (not pause/settings/game over/perk select). Heat map indicators remain visible when enabled.
  - Added scrollable **perk list + hover tooltip** to the left side of the pause menu (mirrors game-over perk view), and wired it to current run perk history.
  - Improved tooltip readability by increasing perk tooltip background opacity (pause + game over).
  - Fixed multiple HUD edge cases:
    - Game-over level label now updates correctly (no longer stuck at 0).
    - Player hurt-bar visibility restored when HP bar flashes at low HP.
    - Low-HP yellow border flash now reliably works (HUD lazily re-finds `PlayfieldFrame`).
    - Focus Mode interactions corrected (no stuck wave/boss popups; perk timer hidden; boss HP suppressed).
  - Unpause UX tweaks:
    - Pause perk panel hidden during resume countdown.
    - “Press Escape to resume” is now a smaller dedicated label.
  - Enemy/boss scaling:
    - Normal enemies after wave 10 enable wavy bullets with chance \(5(x-10)\%\) (clamped to 100%).
    - Boss enemies deal **50% more damage** (on top of existing wave scaling).
  - Border behavior:
    - Low-HP border pulse animation pauses while the pause menu is active.
    - Border turns **red while dead**, then **purple during respawn invincibility**, then returns to normal.

### Why
  - To expand meta progression variety, improve clarity/readability of HUD and perk information, and add progression-based combat scaling for late waves.

### Any pitfalls / fixes
  - HUD focus-mode required careful “don’t force-visible” rules for transient popups (wave/boss banners) and to keep heat map indicators independent of focus mode.
  - Player hurt bar depends on HP bar background remaining empty so the delayed red bar behind remains readable.
  - `PlayfieldFrame` is spawned by `Game.gd` after HUD instantiation; HUD now reacquires it lazily to avoid missing the reference.

### Any thing important to mention if another AI agent were to move forward
  - Meta-perk UI cards are built dynamically in `scripts/HUD.gd` (`_build_meta_level_pick_ui`); card labels are found via `find_child()` name strings.
  - `MetaProgression._make_offer()` now includes `owned` and `stack_cap` fields for the perk selection UI.
  - Pause perk view uses `MetaProgression.pick_history` titles; pause list strips “(Rarity)” since rarity is encoded by color.
