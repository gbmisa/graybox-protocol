# Graybox Protocol — Handoff Document

**Status:** Playable prototype. Completes in under 60 seconds on all routes. **Known problem:**
there is no friction, so a blind run is as fast as a mastered one. See `docs/PLAN-friction-and-pacing.md`
for the roadmap. Codebase split into 67 single-purpose modules under 250 lines each.

> **FORK NOTE (2026-09-13):** this copy is a Level 2 fork. It adds **PORT VESPER**, a second
> mission, plus the level-select flow — no mechanics changed. `MERIDIAN CAPITAL` is untouched
> (Level 1 smoketest still passes with 0 problems). Merge back into the main repo when the
> level is approved.

---

## Quick Start

```bash
~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol/build/graybox-protocol.x86_64
```

**Runs in:** Borderless windowed (1280×720). Exit via ESC → EXIT or Alt+F4.

---

## What This Is

**Graybox Protocol** is a first-person immersive-sim prototype in the vein of Cruelty Squad
and Dishonored. Three playable characters, assassination targets, three extraction points per
mission, and (in this fork) two gray-boxed missions: a five-storey office tower and a
waterfront impound dockyard.

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

## Level — PORT VESPER (fork only, redesigned 2026-09-13)

Target: **THE HARBORMASTER**. He patrols three stations *inside* the customs office and never
leaves it — his route crosses no gated doors, so it can never wedge itself on one.

**Layout:** a long east-west waterfront (x[-110,110], z[-80,25]), not a square. Water is the
southern boundary (no south fence). Four districts:
- **West:** container terminal with the Wizard's dash line
- **Center:** customs office (x[-16,16], z[-30,-14]), 3.0m walls, roof skylight
- **East:** pier, dock office, moored vessel, boat extraction
- **Far east:** dead crane zone (CRANE 2 — OUT OF SERVICE SINCE 2019, visibly dilapidated)

```
  x -100..-25   TERMINAL     container maze; dash line (P1→P2→office roof)
  x -16..16     OFFICE       customs office; E door [lockpick], W door [smash],
                             roof skylight [arcane]; target inside
  x 40..65      PIER         dock office, pier deck, PIER GATE [lockpick/key],
                             moored vessel, boat extraction
  x 80..100     CRANE        dead crane zone, storage key, Harbormaster's routine
  z -80..-60    NORTH        fence, spawn (0,0,-74) behind blast wall, van extraction
  x 70          CULVERT      1.0m crawl pipe under north fence (Regular's vector)
  z 25+         WATER        southern boundary, no fence
```

Spawn (0,0,-74) is behind a blast wall that blocks every guard post's sightline (verified
by raycast in smoketest2: 24 waypoints checked, none see the spawn within 34m).

### The three routes (physically distinct vectors, no shared corridor)

| | REGULAR | WIZARD | CHAD |
|---|---|---|---|
| Entry | East culvert — 1.0m crawl under north fence at x=70 | Terminal ramp → P1 (3.6m) → dash 9.0m → P2 → dash 9.0m → office roof | Warehouse west wall BREACH [smash] at (-96,-27) |
| Middle | Cross pier district, pick east office door | Warded skylight [arcane] into office | Through warehouse, smash west office door |
| Character | Quiet and slow | 60 HP, no cover, all tempo | Loud by design; 60m noise pulls guards |

The vectors enter the office from three different sides (east door, roof skylight, west
door) and do not converge before the office. The office interior — where the target
patrols — is the only shared space.

**Wizard dash-line physics:** the dash is perfectly horizontal (gravity suspended for
0.35s) at 26 m/s = 9.1m. Both gaps are 9.0m: unjumpable (max jump ~4.7m empirically) and
dashable (verified physically). Platform tops and office roof are all at 3.6m; the office
walls are 3.0m so the dash clears them.

**Chad's consequence is spatial:** the breach at (-96,-27) emits 60m noise, alerting both
warehouse guards and terminal guards. Their patrols cross his exit corridor.

**New systems (level-agnostic, data-driven):**
- **IntelPickup:** 4 optional notes (routine, manifest12c, complaint, seized) with title/body
  reading panel. Manifest 12-C is explicitly "OPTIONAL INTEL — flavor only."
- **KeyItem:** pier_key (dock office → pier gate), storage_key (crane zone → storage compound).
  Doors accept `key:<id>` as alternate methods. Minimal KEYS: HUD display.
- **One-way locks:** office doors/skylight exit freely from inside (0-time free exit);
  exterior entry remains gated.

**Bolt tuning:** Wizard's charged bolt range is 30m, just below guard vision (34m).

### Extractions
- **Boat** (east pier deck, all operatives)
- **Van** (north gate, guarded, all operatives)
- **Drainage outflow** (1.0m crawl at x=70 — **Chad can never use it**)

### Required signage
`PORT VESPER — CUSTOMS IMPOUND` · `CRANE 2 — OUT OF SERVICE SINCE 2019` ·
`DRAINAGE — KEEP CLEAR` · `DASH >` (terminal chevrons)

**Authoritative floor plan:** the header comment in `scripts/world/level2/level2_builder.gd`.

**Blind completion time:** unmeasured estimate only. The 5–8 minute target requires the
F1–F4 friction systems (randomized target/intel, alarm consequences, second leg,
bodyguards/fleeing target) which are not yet implemented.

---

## Mission select (level + operative) — fork only

`game.selected_level`: 1 = MERIDIAN CAPITAL, 2 = PORT VESPER (default 1). The select
screen shows operative cards plus a second row of level cards (`LevelData`); clicking a
level card re-labels the operative cards with that level's routes and highlights the pick.
Briefing shows the selected level's name, briefing copy, per-operative route and
extraction line. `LevelBuilder.build()` dispatches on `selected_level` — Level 1 goes
through the original code path unchanged.

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
├── tools/                        # smoketest.gd (L1) · smoketest2.gd (L2)
└── scripts/                      # 67 files, none over 250 lines
    ├── core/       game.gd · mission_flow.gd · input_actions.gd
    ├── data/       characters · armors · abilities · guard_data · verbs · levels
    ├── player/     player.gd + movement · look · health · mantle · interactor
    │   └── kits/   kit_regular · kit_wizard · kit_chad  (one file per operative)
    ├── enemies/    guard.gd + senses · brain · combat · body · target.gd
    ├── world/      level_builder.gd (dispatches on game.selected_level)
    │   ├── sections/   sec_* — MERIDIAN CAPITAL areas
    │   ├── level2/     level2_builder.gd · guard_posts2.gd
    │   │   └── sections/ sec2_perimeter · sec2_yard · sec2_culvert ·
    │   │                 sec2_office · sec2_warehouse
    │   └── interactables/ locked_door · breakable_wall · warded_seal
    ├── ui/         hud.gd + 5 panels · screens/ (router + one file per screen)
    └── fx/         audio_synth · projectile · meteor
```

**Where to make a change:**

| I want to… | Open |
|---|---|
| Retune any number | `scripts/data/` — no balance value lives in logic |
| Change an operative's moveset | one file in `scripts/player/kits/` |
| Change who gets through what | `scripts/data/verbs.gd` |
| Change one area's geometry | one file in `scripts/world/sections/` (L1) or `scripts/world/level2/sections/` (L2) |
| Change how doors behave | `scripts/world/interactables/` |
| Move a patrol | `scripts/world/guard_posts.gd` (L1) · `scripts/world/level2/guard_posts2.gd` (L2) |
| Add a level | new `scripts/world/levelN/` section files + `LevelData` entry + dispatch in `level_builder.gd` |

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

**Automated (tools/smoketest2.gd, fork only)** — PORT VESPER builds; 21 floor/headroom
points verified (culvert stations exactly 1.0m); 3 extraction zones; Harbormaster has 3
patrol points; 12 guards posted; culvert sealed at fence line; dash gaps measure 8.9m and
8.6m with clear corridor; 24 guard waypoints checked — none see the spawn within 34m;
gate barrier spans continuous at multiple offsets; 4 intel + 2 keys with valid IDs;
bolt range (30m) < guard vision (34m); briefing fits 720px. **0 problems.**

**Physics-verified:** Wizard dash clears both 9.0m gaps (lands on P2 and office roof);
jump-only reaches 4.7m (fails); Regular crawls the culvert (z -68 to -56); Chad (1.45m
crouched) is blocked by the 1.0m pipe.

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
- ~~Second level~~ — done in this fork (PORT VESPER); merge decision pending

---

## Git / Version Control

Repository: https://github.com/gbmisa/graybox-protocol (public)

Initial commit: `bfe64d1` on main. `.gitignore` excludes build/ and .godot/ so the repo
is source-only. `docs/PLAN-friction-and-pacing.md` is the design roadmap, committed at init.

---

- **Engine:** Godot 4.7.2 · **Language:** GDScript 4.x · **License:** MIT (see LICENSE)
- **Targets:** Linux (dev), Windows (export ready)
- No external dependencies, no plugins, no asset imports.

**Last updated:** 2026-09-13 (PORT VESPER fix pass: per-op spawns, 5.5m dash gaps, keyed storage, pier seal, intel prop fix, detection 0.87s, 3 bot playthroughs WIN, 15 guards)

---

## PORT VESPER fix pass — 2026-09-13 (post-judgment)

Gregory's judgment: spawn faced away/too near guards, dash too long, route was door→ramp→roof with no decisions, keys irrelevant, intel UI overflowed, detection too slow, manifest floated, storage/pier walkarounds. All addressed:

- **Per-operative spawns:** Regular (58,-70) faces culvert, Wizard (-66,-70) faces ramp, Chad (-84,-70) faces warehouse. All ≥25m from guards (raycast verified).
- **Wizard dash geometry:** two 5.5m gaps (P1 6m wide, P2 13m wide). Beyond 4.74m jump range, no precision braking. Dash mechanics untouched (0.35s, 26 m/s).
- **Guard pressure:** 15 guards (was 12); patrols under dash corridor and both office lanes.
- **Storage:** real keyed building (x[-46,-34], z[-6,18]), one 3m north entrance requiring storage_key, free exit. Key buys Harbormaster routine intel.
- **Pier:** gate fence x[28,72] at z=5, side fences z[5,25], full-length railings. Walkaround fixed.
- **Intel props:** datapads now rest on surfaces (was floating 0.85m). Seized/manifest on warehouse crates, routine on storage desk, complaint on dock-office desk.
- **Intel UI:** scrollable, fits 1280×720.
- **Detection:** 2.0/s → alert in 0.87s at 14m standing exposed (was ~1.4s).

**Validation (headless, all 0 problems):**
- Clean import: 0 errors
- Level 1 smoketest: 0 problems
- Level 2 smoketest: 0 problems (floor, zones, seals, spawns, dash line, intel, UI)
- Flood (BFS enclosure): office/storage/pier sealed with doors closed, reachable via gates only
- Bot playthroughs: Regular WIN 8.4s (dmg 22, alarms 3), Wizard WIN 6.5s (dmg 0, alarms 2), Chad WIN 3.7s (dmg 0, alarms 2). All used real gates, dashes, weapons, extractions.

**Known:** push to origin/port-vesper blocked (no GitHub credentials in build env); commit c2b328d ready locally.
