# Graybox Protocol — Quick Reference

## Play / edit
```bash
cd ~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol
godot --path .            # play (add -- --no-guards to walk it empty)
godot -e --path .         # editor: F5 play, F6 current scene
```

## Export (needs export templates: Godot > Manage Export Templates, once)
```bash
godot --headless --path . --export-release "Linux" ./build/graybox-protocol.x86_64
```

## Validate
```bash
godot --headless --path . --import
godot --headless --path . --script res://tools/smoketest_compound_systems.gd
```
Full suite list: `docs/NEXT-SESSION.md` → "Verify after any change".

## Controls
WASD move · mouse look · LMB fire · RMB aim · 1-5 / wheel weapons · R reload ·
Space jump/mantle · C/Ctrl crouch · Shift sprint · F interact (hold on a corpse: eat) ·
V/MMB kick · Q grapple (hold) · N night vision · ESC pause.

## Tuning — `scripts/data/`
`characters.gd` · `armors.gd` · `weapons.gd` · `guard_data.gd` ·
`mission_compound_data.gd` (level one) · `level_text.gd` (words) · `intro_script.gd` (opening comic).

## Docs
- `CLAUDE.md` — project rules + code layout
- `docs/NEXT-SESSION.md` — current state, open questions (the handoff)
- `docs/BUILD-LOG.md` — per-round history
- `docs/LEVEL-compound.md` — level one design reference
- `docs/BRIEF-animation.md` — game-loop/animation research for the AI
- `ASSETS.md` — asset sources and licences
