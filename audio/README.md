# audio/

Runtime audio assets for Virus Hunter.

- `music/` — looping music loops and short stingers (`.ogg` preferred).
- `sfx/` — one-shot sound effects (`.wav` preferred for low latency).

Asset names, formats, and trigger events are catalogued in
[`docs/AUDIO_GUIDE.md`](../docs/AUDIO_GUIDE.md).

`scripts/AudioManager.gd` owns the runtime mapping from logical IDs to file paths.
Missing files are safely no-ops, so this folder can be filled in incrementally.
