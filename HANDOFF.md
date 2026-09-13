# Graybox Protocol — Handoff Document

**Status:** Playable prototype. Level 2 (MERIDIAN CAPITAL) with three hard-gated routes,
traversal verbs, and a rebuilt Wizard kit. Codebase split into 49 single-purpose modules.

---

## Quick Start

```bash
~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol/build/graybox-protocol.x86_64
```

**Runs in:** Borderless windowed (1280×720). Exit via ESC → EXIT or Alt+F4.

---

## What This Is

**Graybox Protocol** is a first-person immersive-sim prototype in the vein of Cruelty Squad
and Dishonored. Three playable characters, one assassination target, three extraction points,
one five-storey gray-boxed office tower.

- **Tone:** Dark satire (abrasive, politically charged on purpose)
- **Mechanics:** Stealth, guns, magic, melee, traversal verbs, ability-based gameplay
- **Art:** Gray-box geometry, procedurally generated
- **Audio:** Synthesized SFX (no external files)

**The core idea:** character choice *is* level choice. Each operative has traversal verbs
nobody else has, and the level is gated so each one takes a genuinely different way in.

---

## Controls

```
WASD         Move
Mouse        Look / aim
LMB          Attack (varies by character)
RMB          Wizard: charge bolt
E            Ability (Wizard: Meteor, Chad: ground slam)
F            Interact — pick lock / unward / breach, depending on operative
C / Ctrl     Crouch (shrinks your collision capsule — this is how crawling works)
Shift        Sprint — except the Wizard, for whom it is the dash
Space        Jump, or mantle a ledge you are facing
ESC          Pause (Resume / Restart / Change Operative / Exit)
```

---

## Playable Characters

### THE REGULAR — "The Service Entrance"
- **HP:** 100 | **Speed:** 7.0 | **Crouch:** 0.85m | **Mantle:** 1.2m
- **LMB:** Pistol (hitscan, 25 dmg, 0.25s cooldown)
- **Verbs:** `lockpick` (3.0s, silent), `crawl`
- **Feel:** Balanced, fragile, best in corridors where nothing can flank you

### THE WIZARD — "The Vertical"
- **HP:** 60 | **Speed:** 6.6 | **Mana:** 100 | **Crouch:** 0.85m | **Mantle:** 1.2m
- **LMB:** Fireball (arcing, 35 dmg, 3.2m AoE, 20 mana)
- **RMB:** Charged Bolt (1s charge, 80m range, 70 dmg, 35 mana)
- **E:** **Meteor** — ground-targeted, 1.1s telegraph, 90 dmg @ 7m, then a burn pool
  (12/s for 4s @ 4m). 45 mana, 5s cd. Area denial, not a snipe.
- **Shift:** **Arcane Dash** — 0.35s, **0.25s of i-frames**, 1.2s cd, 15 mana.
  Replaces sprint entirely.
- **Verbs:** `arcane` (0.6s, 25–30 mana), `crawl`
- **Feel:** Glass cannon. No blink — the dash is the whole mobility kit.

### GIGA CHAD — "Through the Wall"
- **HP:** 250 | **Speed:** 7.6 | **Sprint:** 1.6x | **Crouch:** 1.45m | **Mantle:** 2.5m
- **LMB:** Punch Combo (3-hit, 55 dmg, 2.8m range)
- **E:** Ground Slam (AoE 60 dmg, knockback, camera shake, 8s cd, 5.5m radius)
- **Verbs:** `smash` (0.4s doors / 0.8s walls, **very loud**)
- **Cannot crawl.** At 1.45m crouched he does not fit through 1.0m gaps.
- **Feel:** Heavy. Every gate he opens wakes the building.

---

## Level — MERIDIAN CAPITAL

```
  y  18.6  ROOF         helipad extraction
  y  12.0  BOARDROOM    target; three gated doors; drop chute
  y   6.0  MEZZANINE    convergence floor
  y   0.0  GROUND       street, courtyard, loading dock, freight bay
  y  -4.0  UNDERCROFT   crawl tunnels, boiler room, sump extraction
```

Tower footprint x [-30, 30], z [-40, 10]. Player spawns at (0, 0, 70).
**The authoritative floor plan is the header comment in `scripts/world/level_builder.gd`.**

### The three routes

| | REGULAR | WIZARD | CHAD |
|---|---|---|---|
| Entry | Culvert crawl (1.0m) | WARDED GATE `[arcane]` | DOCK SHUTTER `[smash]` |
| Middle | MAINTENANCE DOOR `[lockpick]` → boiler room | Courtyard, 5 grouped guards | COLLAPSED WALL `[smash]` |
| Climb | Service stair (-4 → 6) | Vent shaft: 7m dash gaps | Container stacks: 2.3m mantles |
| Into boardroom | SERVER ACCESS `[lockpick]` | WARDED DOOR `[arcane]` | REINFORCED PANEL `[smash]` |

All three converge on the mezzanine at y=6, then take their own door into the boardroom.

### Extractions
- **Helipad** (roof) — stair up from the boardroom. All operatives.
- **Van** (street, west) — via the drop chute to the ground floor and out the north exit.
- **Sump outflow** (undercroft) — behind a 1.0m crawl, so **Chad can never use it**.

---

## How the gating works

Two mechanisms, and the difference is important if you edit the level:

**Interaction gates** are scripted. An `Interactable` declares which verbs open it and what
each costs:

```gdscript
open_methods = {
    "lockpick": {"time": 3.0, "noise":  0.0, "mana":  0.0},
    "arcane":   {"time": 0.6, "noise": 12.0, "mana": 30.0},
    "smash":    {"time": 0.4, "noise": 45.0, "mana":  0.0},
}
```

A hard gate is authored by *omission* — a wall with only `smash` is Chad-only. Anyone else
gets a greyed prompt reading "REQUIRES BRUTE FORCE", so a locked route explains itself
instead of reading as broken scenery.

**Crawl gates are not scripted at all.** Crouching resizes the player's collision capsule
(0.85m for Regular/Wizard, 1.45m for Chad), and crawl gaps are built exactly 1.0m tall.
Chad simply does not fit. There is no character check anywhere — **do not add one.**

---

## Project Structure

```
graybox-protocol/
├── project.godot, export_presets.cfg
├── CLAUDE.md, ASSETS.md, HANDOFF.md
├── scenes/main.tscn              # root node + GrayboxGame script only
├── build/                        # exported Linux binary + .pck
└── scripts/                      # 49 files, none over 250 lines
    ├── core/       game.gd · mission_flow.gd · input_actions.gd
    ├── data/       characters · armors · abilities · guard_data · verbs
    ├── player/     player.gd + movement · look · health · mantle · interactor
    │   └── kits/   kit_regular · kit_wizard · kit_chad  (one file per operative)
    ├── enemies/    guard.gd + senses · brain · combat · body · target.gd
    ├── world/      level_builder · build_utils · guard_posts
    │   ├── sections/       one builder per area (street, tower, undercroft, …)
    │   └── interactables/  interactable base + locked_door · breakable_wall · warded_seal
    ├── ui/         hud.gd + 5 panels · screens/ (router + one file per screen)
    └── fx/         audio_synth · projectile · meteor
```

**Where to make a change:**

| I want to… | Open |
|---|---|
| Retune any number | `scripts/data/` — no balance value lives in logic |
| Change an operative's moveset | one file in `scripts/player/kits/` |
| Change who gets through what | `scripts/data/verbs.gd` |
| Change one area's geometry | one file in `scripts/world/sections/` |
| Change how doors behave | `scripts/world/interactables/` |
| Move a patrol | `scripts/world/guard_posts.gd` |

---

## Editing

```bash
cd ~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol
godot .                # F5 to playtest
```

**Validate after every script change** (fast, no display needed):
```bash
godot --headless --path . --import
```

**Export:**
```bash
godot --headless --path . --export-release "Linux" ./build/graybox-protocol.x86_64
godot --headless --path . --export-release "Windows Desktop" ./build/graybox-protocol.exe
```

---

## Verification status

Automated: every script parses; the level builds and all three operatives spawn with the
correct kit and verbs; a raycast sweep of 33 waypoints across all three routes confirms
every one has floor to stand on, and that the three crawl gaps measure exactly 1.00m.
Exported binary boots clean.

**Not yet verified by hand — play these and check:**
1. The Wizard's 7m dash gaps in the vent shaft. The numbers say a running jump covers
   ~5.7m and a dash ~9m, so the climb should be dash-only, but it needs feel-testing.
2. Chad's 2.3m container mantles, and that the mantle trigger is not fiddly.
3. Whether the i-frame window (0.25s) is long enough to reliably dodge a guard shot.
4. Meteor's 1.1s telegraph — long enough to matter, short enough to hit a patrol.
5. That every route is completable end to end, and that the mezzanine walk-around at the
   freight opening is not annoying.

---

## Known Issues / Quirks

1. **No fall damage** — the boardroom drop chute relies on this; it is a 12m fall.
2. **Guards don't flank or coordinate** — simple by design.
3. **No friendly fire** — the Meteor burn pool does not hurt the player.
4. **The culvert descent is an open trench** rather than a covered drain. Reads fine in
   graybox, but it is not what a storm drain would look like.
5. **Audio is loud** — synthesized SFX are aggressive by design.

---

## Next Steps (Suggested)

1. **Playtest and tune the three routes** — see the verification list above. This is the
   highest-value next thing by a distance.
2. **Briefing / barks** — the satire is currently all in signage and card copy. Guard radio
   chatter and player commentary would carry it much further.
3. **Visual polish** — particles on the Meteor and breaches, blood decals.
4. **Skill trees** — the data layer is ready for it; `characters.gd` is where it hangs.
5. **Second level** — `world/sections/` was built so a new level is a new set of section
   files plus a new `level_builder` entry point.

---

## Git / Version Control

**No git repo yet.** To initialize:
```bash
cd ~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol
git init && git add . && git commit -m "Graybox Protocol: Meridian Capital, traversal verbs, module split"
```

---

- **Engine:** Godot 4.7.2 · **Language:** GDScript 4.x
- **Targets:** Linux (dev), Windows (export ready)
- No external dependencies, no plugins, no asset imports.

**Last updated:** 2026-09-12
