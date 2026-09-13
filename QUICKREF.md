# Graybox Protocol — Quick Reference

## Run
```bash
~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol/build/graybox-protocol.x86_64
```

## Edit
```bash
cd ~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol
godot .
# F5 = play, F6 = current scene
```

## Export
```bash
godot --headless --path . --export-release "Linux" ./build/graybox-protocol.x86_64
```

## Validate Scripts
```bash
godot --headless --path . --import
```

---

## Tuning (all in `scripts/data.gd`)

**Characters:** HP, speed, jump, accel, air_accel
**Armor:** damage reduction, speed penalty
**Guards:** vision range/cone, detection rate, gun stats

---

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look |
| LMB | Attack |
| RMB | Wizard charge |
| E/Q | Ability |
| C | Crouch |
| Shift | Sprint |
| Space | Jump |
| ESC | Pause |

---

## Characters

**Regular:** 100 HP, pistol, armor loadout
**Wizard:** 60 HP, 100 mana, fireball + bolt + blink
**Chad:** 250 HP, punch combo + slam, high jump

---

## Files

- `scripts/game.gd` — mission state machine
- `scripts/player.gd` — character controller
- `scripts/guard.gd` — enemy AI
- `scripts/level_builder.gd` — procedural geometry
- `scripts/data.gd` — all balance numbers
- `HANDOFF.md` — full documentation
