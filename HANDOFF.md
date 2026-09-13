# Graybox Protocol — Handoff Document

**Status:** Playable prototype. Completes in under 60 seconds on all routes. **Known problem:**
there is no friction, so a blind run is as fast as a mastered one. See `docs/PLAN-friction-and-pacing.md`
for the roadmap. Codebase split into 49 single-purpose modules under 250 lines each.

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
- **LMB:** Pistol (hitscan, 25 dmg, 0.25s cooldown, no aim wind-up)
- **Verbs:** `lockpick` (3.0s, silent), `crawl`
- **Feel:** Balanced, fragile, best in corridors where nothing can flank you

### THE WIZARD — "The Vertical"
- **HP:** 60 | **Speed:** 6.6 | **Mana:** 100 | **Crouch:** 0.85m | **Mantle:** 1.2m
- **LMB:** Fireball (arcing, 35 dmg, 3.2m AoE, 20 mana)
- **RMB:** Charged Bolt (1s charge, 80m range, 70 dmg, 35 mana)
- **E:** **Meteor** — ground-targeted, 1.1s telegraph, 90 dmg @ 7m then a burn pool
  (12/s for 4s @ 4m). 45 mana, 5s cd. Telegraph exists so incoming is readable, not a surprise.
- **Shift:** **Arcane Dash** — 0.35s flat, **0.25s invulnerability frames**, 1.2s cd, 15 mana.
  Replaces sprint. I-frames match guard aim wind-up (0.55s) so a well-timed dodge beats a shot.
- **Verbs:** `arcane` (0.6s unward, 12 noise, 30 mana), `crawl`
- **Feel:** Glass cannon, 60 HP vs. 100. No blink — the dash is the whole mobility kit and
  defensive layer.

### GIGA CHAD — "Through the Wall"
- **HP:** 250 | **Speed:** 7.6 | **Sprint:** 1.6x | **Crouch:** 1.45m | **Mantle:** 2.5m
- **LMB:** Punch Combo (3-hit, 55 dmg, 2.8m range)
- **E:** Ground Slam (AoE 60 dmg, knockback, camera shake, 8s cd, 5.5m radius)
- **Verbs:** `smash` (0.4s doors, 0.8s walls, **45 noise each**), cannot crawl
- **Cannot crawl.** At 1.45m crouched he physically does not fit through 1.0m gaps. This is
  pure collision, not scripted — he cannot get in and no character check can override it.
- **Feel:** Heavy. Every gate he opens makes audible chaos. He is loud by design and routes
  into fights rather than stealth.

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

**Automated (tools/smoketest.gd)** — every script parses; the level builds; all three
operatives spawn with correct kit and verbs; a raycast sweep of 33 waypoints confirms floor
exists on every route and crawl gaps measure exactly 1.0m; regression tests confirm:
- Guards CAN see the player with clear line of sight (guards were blind before this build)
- Crawl gates are sealed from above (no jumping over the culvert)
- Freight bay has an escape route (not soft-locked)
- Health does NOT regenerate
- All three screens fit their viewport without overflow
- Exported binary boots clean

**Hand-tested and passing:**
- All three routes are completable end-to-end
- The Wizard's dash-jumping vent shaft works as designed
- Chad's container mantles do not feel fiddly
- Guard aim wind-up (0.55s) feels readable; i-frame dodge (0.25s) is achievable
- Stairs are walkable (no jumping required)
- Meteor telegraph is visible before impact

**Known problem:** level completes in under 60 seconds on any operative on a blind first run,
including a learned one — there is no progression or replayability value yet. This is by
design pending the friction-and-pacing pass (see Next Steps).

---

## Known Issues / Quirks

1. **No fall damage** — the boardroom drop chute relies on this; it is a 12m fall.
2. **Guards don't flank or coordinate** — simple by design. AI is dumb on purpose; complexity
   budget goes to character kits and level routing.
3. **No friendly fire** — the Meteor burn pool does not hurt the player.
4. **Guard fire emits no noise** — intentional, or one alerted guard cascades the building
   into chaos. Fights are deliberate choices, not audio avalanches.
5. **Audio is loud** — synthesized SFX are aggressive by design and set player adrenaline.

---

## Next Steps

**ROADMAP — Friction and Pacing** (high-priority; see `docs/PLAN-friction-and-pacing.md`):

The level completes in under 60 seconds on all routes, including learned ones. This is not
a size problem — Cruelty Squad runs are 60–90 seconds. The problem is that the *blind* run
is also 60 seconds (nothing to learn, nothing to master). The gap is zero, so there is no
reason to replay as another operative.

Four orthogonal friction mechanisms, each owned by a character, will create the gap:

1. **F1 Information gating** (Regular favoured) — target room is randomised per run; intel
   comes from a directory, a terminal, or guard chatter. Learning the *fastest way to obtain*
   the answer preserves replayability.
2. **F2 Lockdown on alert** (Chad punished) — being seen relocates the target to a panic
   room and locks sector doors. Stealth becomes instrumental, not optional. Chad's loud
   breaches mean he always plays the hard variant, which is his identity made real.
3. **F3 Second leg** (Wizard favoured) — after the kill, wipe records at a terminal on
   another floor. Forces a return trip through a hostile building, which is exactly what
   the Wizard's dash kit excels at.
4. **F4 Bodyguards + target fleeing** (Chad's fight) — the target gains two armoured
   bodyguards and flees on alarm. Gives Meteor an obvious best use and makes Chad's slam
   load-bearing.

Target: 5–8 min blind, 60–90 s mastered. F2 is the spine and should be built first.

**Tier 2 (can happen after friction):**

- Guard chatter and player barks — the satire currently lives only in signage and card copy
- Visual polish — particles on Meteor, decals on breaches
- Skill trees — the data layer is ready; bind them to `characters.gd`
- Second level — `world/sections/` structure lets a new level be new section files + entry point

---

## Git / Version Control

Repository: https://github.com/gbmisa/graybox-protocol (public)

Initial commit: `bfe64d1` on main. `.gitignore` excludes build/ and .godot/ so the repo
is source-only. `docs/PLAN-friction-and-pacing.md` is the design roadmap, committed at init.

---

- **Engine:** Godot 4.7.2 · **Language:** GDScript 4.x · **License:** MIT (see LICENSE)
- **Targets:** Linux (dev), Windows (export ready)
- No external dependencies, no plugins, no asset imports.

**Last updated:** 2026-09-12
