## 2026-04-29 - ZavHar

- Updated project context and workflow alignment using `AGENTS.md` as the cold-start baseline.
- Fixed GDScript typing/access issues after engine update by replacing dynamic property writes with explicit typed casts and property assignments.
- Added `class_name` declarations for gameplay scripts to support safer static typing across scene instantiation.
- Converted variable declarations from inference (`:=`) to explicit static types with `: Type = value` style in active gameplay scripts.
- Verified edited scripts are lint-clean after changes and left gameplay/error detection behavior unchanged.
