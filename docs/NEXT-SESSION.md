# NEXT SESSION — read this first

Handoff updated 2026-09-30 after the **verticality pass**. Gregory played the first build
("much better than it was before"), asked for "more vertical, more entry paths", played
that and said **it's improved**. Same direction; keep going in it.

Branch `level-one-holloway-road`. Commit `59a5839` is the first build; the verticality
pass and room-name tags are **uncommitted** in the working tree (not pushed, not merged).
`screenshots/` and `blender/` are generated and deliberately untracked.

## Standing rules from Gregory (these override older docs)

- **Level one = the Regular only, base kit, no lockpicks.** Wizard and Chad are shelved
  "for now": their data, kits and verbs are intact; `CharData.ids()` returns `["regular"]`.
  Lockpicks arrive in a later level. Don't reintroduce either without being asked.
- **Longer levels that build anticipation and reward exploration.** Smaller mechanical scope,
  bigger space. The goal should be visible from afar; escalate as the player closes in.
- Cruelty Squad over Dishonored. Satire everywhere, never sanitised. Fast and lethal beats
  slow crouch-sneaking. **No HUD detection meter** (removed); feedback is guard-side
  ("?", "!", barks, orange aim tell) and world-side (light tiers you can see).
- **Extractions unlabelled.** No sign may name a way out (a test enforces it).
- No character checks in script — collision and verbs gate everything.
- Gregory is terse and the final judge. Short answers, key reasons, do the work.

## What level one is

Title screen → **HOLLOWAY ROAD** (level id `compound`). Plan lives in the header of
`scripts/world/level_compound.gd`; the r4 design doc `docs/LEVEL-compound.md` is still the
reference for the campus but is **out of date** where the scope cut changed things.

- **Approach** (new, z 46–196, spawn `(0, 0, 190)`): bus stop + tower lobby + garages (bay 3
  open through to a hidden strip; bin → garage roofs) → estate yard (A1) → ring-road
  embankment with three crossings: subway (A2 sentry staring down it), crate steps onto the
  LIT deck (A3), unmarked crawl culvert → towpath with the duty-rota hut (intel = LOCATE;
  A4 sentry) → canal: footbridge / narrowboat jumps / canal bed + slipways → allotments (A5,
  shed-roof vantage) → terrace backs (three alleys, one walk-through house; A6) → south road.
  A 28m lit billboard ("COLLECTIVE CONSENT SCORE 412 ▼") is the lure; fog; PA line per stretch.
  Files: `sec_app_estate.gd`, `sec_app_canal.gd`.
- **High routes** (`sec_app_heights.gd`) — a second, higher way through each stretch:
  tower deck-access stair + balcony (4.0) + walkway along the west edge onto the road deck
  (H01–H02); pipe-bridge catwalk from the road deck over towpath and canal to a
  pumping-station roof (H03–H04); stepped extensions 1.1→5.4 onto the terrace roofs, with
  chimneys (H05–H06); overbridge at 5.0 over the south road, stairs both ends, whose verge
  landing is a 3m jump onto the compound wall top (H07–H08). No fall damage, so every high
  route drops anywhere.
- **Campus**: ways in — shutter crawl (east lane) → store → crate stair → roof → duct →
  ceiling void → gallery over the hall; bin-store gate → refuse yard → courtyard; gym →
  mezzanine → bridge → hall rear; canteen service door; portico → lobby → stairs.
  Plus (`sec_cmp_climbs.gd`): over the wall from the overbridge or the boiler-house climb
  (west alley: skip → pallets → cabinet → roof); **fire escape** on the west face → new 1F
  door into the west strip over the west corridor (F06) → door onto the west landing behind
  G9, and on to the roof; **scaffold** in the courtyard → new 1F door into G8's south
  corridor, and on to the roof. The main roof now has three ways up.
  Ex-lockpick doors are open doorways. Ways out: culvert → van (E1), gatehouse lever →
  gate → car (E3), or walk back out. Boiler-house door and cracked wall are walled up;
  helipad exit removed.
- **ALARM** (`core/alert_state.gd` → `MissionCompound.on_alarm`): CSD pair locks, target
  flees to panic room G.04 with G9, R1+R2 spawn (R3 on later alarms, cap 3), decays after
  60s unseen. Panic room is reachable by the staff-room hatch; the barred window is
  shoot-through (rods on collision layer 2).

## Room-name tags (playtest aid — on right now)

`sec_room_names.gd`: 94 cyan billboard tags, "ID NAME", depth-tested. Gregory gives
feedback by ID (A approach · H high routes · C campus outdoors · G main ground · F main 1F ·
R main roof · Y gym · U undercroft). **Read the `ROOMS` table there first when he quotes an
ID.** Off with `-- --no-room-names` or `SHOW = false`; turn off before any release export.
Tag text must avoid EXIT/VAN/CAR/HELI/EXTRACT (the unlabelled-exits test scans every Label3D).

## Where things are

- Geometry: `scripts/world/sections/` — `sec_app_*` (approach), `sec_cmp_*` (campus),
  `sec_cmp_dressing.gd` (all signs, billboard, vehicles, paint). Walls with openings go
  through `WallUtils.wall(...)` (door/window holes get headers and sills).
- Level wiring: `level_compound.gd` (`sections()` is the single list — tools read it too),
  `mission_compound.gd` (doors, switches, target, extractions, hazard, PA, alarm),
  numbers in `data/mission_compound_data.gd` (tiers, PA boxes, flee path, intel boxes),
  guards in `guard_posts_compound.gd` (`approach()` + `campus()` + `reinforcements()`),
  words in `data/level_text.gd`.
- Systems added this session: D14 mantle (rise from last floor) + parapet-safe landing +
  fence vault (`player/mantle.gd`); squeeze stance (`movement.gd`, dormant); head hitboxes +
  `take_hit` (guard/target); suppressor loadout (`data/loadouts.gd`, default SUPPRESSED);
  `light_tiers.gd`, `hazard.gd`, `interactables/switch.gd`, `interactables/remote_door.gd`;
  sentry `facing`/`waits`/`one_way` on guard posts; barks; stats (detected, loadout, radio).
- Collision: bodies mask 3, shots/LOS mask 1 (`VerbData.BODY_MASK/SHOT_MASK`). Any new ray
  must set one.

## Verify after any change

```bash
cd ~/AI\ projects/concerned\ citizen/graybox-protocol-godot/graybox-protocol
godot --headless --path . --import
godot --headless --path . --script res://tools/smoketest.gd                 # MERIDIAN
godot --headless --path . --script res://tools/smoketest_compound.gd        # level 1 geometry
godot --headless --path . --script res://tools/smoketest_compound_systems.gd  # level 1 systems
```
All four were clean at handoff (smoketest_compound now also covers the high routes:
17 points, 3 doors, 4 lines). Visual checks (need a renderer):
```bash
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://tools/screenshot_compound.gd   # magenta = hole
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://tools/screenshot_approach.gd   # real lighting
```
Then **Read the PNGs** — that is how the missing-wall bug was caught. Play:
`godot --path .` (add `-- --no-guards` to walk it empty).

## Gotchas learned the hard way

- Tools used to keep their own copy of the section list and silently rendered a building
  with no shell. Always go through `LevelCompound.sections()`.
- `WallUtils.wall` once cancelled a door with a window stacked above it; it now cuts
  strips per opening edge — keep it that way.
- A static body added this frame isn't in the physics space for queries yet; tests add
  props on an earlier frame.
- Shooting a guard raises the alarm — order test cases accordingly.
- `sign` is a GDScript builtin; `const X := SomeClass` is not a constant expression — use
  `preload`.
- Doc-vs-geometry conflicts in r4 were real bugs more than once (ramp landing on the wrong
  side of its hole, a door behind a crate stack, a "1.0m" void that was 0.8). Trust the
  measurement, fix forward, note it in `docs/BUILD-LOG.md`.
- Files stay under 250 lines. `game.gd` is ~207, `guard.gd` ~198 — split before growing.

## Open next steps (in rough order)

0. **Gregory's next step** — he'll name it; expect feedback quoted by room ID.
   Open decision: the compound wall top now runs boiler roof → north wall → gatehouse
   roof, so the avenue / E3 car is reachable without the lever. Legal shortcut or seal?
   Not yet confirmed by play: each climb step (all rises ≤ 1.15), the overbridge → wall
   jump. Fire-escape/scaffold ramps render as thick wedges (ramp thickness 1.2) — thin
   them if he minds.
1. Commit the verticality pass when he says so (branch, not main).
2. Tune by feel — approach guard count and lanes (A6 moved to z 44 for the overbridge
   stair), subway sentry head-on, fog density, billboard size, PA timing.
2. Re-export the Linux build (`build/` predates level one) when he wants a binary.
3. More exploration payoff on the approach if he wants it (more side pockets, vantage
   points, lore signs) — cheap and on-direction.
4. Van idle sound (E1 diegetic hint) not done.
5. Merge the branch to `main` / push only when asked.
6. `CLAUDE.md` and `HANDOFF.md` were updated; `docs/LEVEL-compound.md` was not — revise it
   to match the scope cut before anyone builds from it again.
