# NEXT SESSION — read this first

> **Latest: `docs/HANDOFF-r6.md`** — read it after this file.
>
> **Round 6c (overnight 2026-10-01/02):** Scoring Annex + secondary objective, crane-run
> platforming, the new look (post shader, sky, neon, our own textures, CONSENTO model),
> the OPENING visual novel. See BUILD-LOG "Round 6c". All seven suites 0. Unplayed.
>
> **Round 6 (2026-10-01, BUILD-LOG "Playtest round 6"):** guards-freeze fix, new viewmodel
> fit + RMB aim, alarm reset, soft-lock fixes, `sec_cmp_vertical` (four new high levels).
> All six suites 0 problems, incl. new `smoketest_guard_stuck`. Unplayed by the assistant.
>
> **Previous: `docs/HANDOFF-opus-r5.md`** (playtest rounds 5a/5b — navigation, civilians,
> humanoid models, gore, gravity, lanes; plus what Opus should do next). Read it after this.

Handoff updated 2026-10-01, after the **past-graybox pass and four rounds of Gregory's
playtest fixes** (BUILD-LOG, last four entries). Gregory has played the build and is
iterating by feedback; he is the final judge. Direction history: first build "much better",
verticality pass "improved", then "very empty" -> assets / menu / viewmodel, then bug and
feel fixes (below).

## State of the repo — READ THIS

Branch `level-one-holloway-road`. Everything through round 6c is committed (`0b4200c`,
incl. `assets/`). Nothing is pushed; nothing is merged to `main`. Commit/push only when
Gregory asks. `screenshots/` and `blender/` stay untracked. Don't commit paid audio dropped
into `assets/audio/sfx/` (see ASSETS.md).

All three suites were 0 problems at handoff (`smoketest`, `smoketest_compound`,
`smoketest_compound_systems`). Visual checks were screenshots only; **nothing was playtested
by the assistant** — it can't run the game interactively.

## Standing rules from Gregory (these override older docs)

- **Past grayboxing is wanted now**: CC0 assets (Kenney first), textures, props, a real
  menu, a viewmodel. Keep it Cruelty Squad-crude. Areas must not feel empty.
- **The game is not entirely stealth** (2026-10-01): an alerted guard must physically reach
  an alarm station to raise the alarm; sounds come from their source (sirens, guards), never
  from the player's head. Furniture/props must never block a doorway or force a jump.
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

## What changed since the last handoff (details in BUILD-LOG)

- **Assets (CC0, ASSETS.md):** Kenney models/sounds/fonts, WRAD arms, Poly Haven textures.
  `Surfaces` textures every box by palette role; `Props` places models (`Props.vehicle()` for
  cars — one uniform scale, no height cap, mesh collision; `Props.tree()` — trunk-only collision);
  `sec_props_*` dress approach/campus/interiors; `sec_skyline` rings the level.
  "Gamemaster" = Gamemaster Audio, **paid**; `AudioSynth` loads drop-in files from
  `assets/audio/sfx/<name>.ogg` first, so a bought pack slots in with no code change.
- **Menu:** live backdrop, main menu / missions / options / credits / pause, `Settings`
  persisted to user://settings.cfg.
- **Viewmodel:** own SubViewport + narrow-FOV camera under the HUD (`viewmodel.gd` header
  explains why); barrel axis measured from the suppressor mesh and aimed at the crosshair;
  recoil, flash, sway, bob. Model re-fitted in Blender (fist on the front handle — this
  blaster is bullpup). The fit script lives only in the session scratchpad; the baked
  `viewmodel_pistol.glb` is the artifact.
- **Alarm (Gregory's rule, 2026-10-01):** an alerted guard is NOT the alarm. He runs to an
  `AlarmStation` (12 posts, `sec_alarm.gd`) and presses it; kill him first and nothing
  happens. Sirens are 3D horns (`AlarmSiren`), never a 2D sound. MERIDIAN (no stations)
  keeps alert = alarm. `Atmosphere`: red pulse + banner + PA line on alarm; ambient light
  eases by light tier (LIT 1.0 / DARK 0.28 / PITCH 0.05).
- **Guards:** a colleague dropping in view makes witnesses go investigate
  (`GrayboxGame._witness_death`). Guard sounds are 3D (`AudioSynth.play_at`).
- **Level fixes:** G12 stair no longer pokes through the wall (`RampBuilder` wedges);
  helipad exit E2 restored (stair + helicopter); pipe bridge continues to the terrace roofs
  (gantry); billboard scaffold + catwalk; lobby is a normal room under a full 1F slab;
  energised water has a WATER ISOLATOR switch and the undercroft squeeze + west-corridor
  shutter are 1.0m crawls (the Regular can't fit 0.6); canteen furniture off all doorways.
- **Mantle bug:** jumping at the main block's thin east wall from a crate used to carry you
  through it. `_wall_continues` fixed it; `_check_wall_not_vaulted` guards it.
- **Bob/footsteps** share `PlayerFootsteps.STRIDE` = 3.5m (was 2.1 / 11 bob cycles per sec).

## Known gaps / unverified (be honest about these with Gregory)

- **Gun feel is unconfirmed.** He has complained about the gun four times (points at floor,
  texture lost, hand mangled, aim). Latest fix: textured Kenney gun, fist on the handle,
  forearm below. Perspective is now sane, but recoil/size/position are by eye.
  `viewmodel.gd`: `RIG_SCALE`, `GRIP_TARGET`, `VM_FOV`, `KICK_*`.
- **Hand is blocky** (WRAD is ~1200 tris) and mostly hidden behind the gun. A better hand
  or glove would be a Blender job.
- **Boiler-house basement** now exits to the west alley (release switch inside; exit only).
- **Alarm tuning is untested by play:** 12 stations, 50m reach, 15s run timeout, guards
  walk straight lines (no navigation) so a station behind a wall just times out and the
  guard fights. Check the alarm doesn't feel too easy to stop or too rare.
- "A door that leads to nothing" next to the lobby was guessed to be the 1F corridor's
  gap (now floored). If he means a different door he'll quote a room ID.
- Textures/tints, skyline brightness and prop density are untuned by play.
- Still-open design call from before: the compound wall top reaches the avenue (E3 car)
  without the gatehouse lever — legal shortcut or seal?

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
  Ex-lockpick doors are open doorways. Ways out: culvert → van (E1), gym roof → steel
  stair → helipad helicopter (E2, restored), gatehouse lever → gate → car (E3), or walk
  back out. Boiler-house door and cracked wall are walled up.
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

## Grappling hook (Gregory, 2026-09-30 — "later on", not level one)

He wants the Regular to get a grappling hook in a later level: swinging like Cruelty
Squad's grappendix, "to a lesser extent Spider-Man's webs". Not built. When it comes:
it's a new verb (`grapple` in `verbs.gd`) and lives entirely in the kit file; swing
physics as a rope constraint on `movement` (pendulum around the anchor, release keeps
momentum), anchors = any static surface within range (CS-style, not marked points).
Level one's rooftop routes (gantry, terraces, billboard catwalk, overbridge, wall top)
are the natural test bed. Don't add it to level one unless asked.

## Open next steps (in rough order)

0. **Gregory's next step** — he plays and quotes room IDs (tags on; new ones H09 gantry,
   H10 scaffold, H11 billboard catwalk, Y07 deck stair). Read the `ROOMS` table in
   `sec_room_names.gd` first. Fix by testing, not by reading: a sweep/simulation found the
   wall bug and a knee-height probe found the canteen bug — both passed the older tests.
1. When he asks: commit (see "State of the repo"), then merge/push.
2. Re-export the Linux build (`build/` predates level one; export templates are NOT
   installed here — Godot > Manage Export Templates first, ~1GB). Turn room tags off for
   any release export (`SHOW`/Options).
3. `docs/LEVEL-compound.md` is out of date vs the scope cut — revise before building from it.
4. Later (not level one): grappling hook, below. Van idle sound exists now (engine loop).

