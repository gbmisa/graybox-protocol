# NEXT SESSION — read this first (the only handoff file)

This file is the **current** state, rewritten in place at the end of every round.
History lives in `docs/BUILD-LOG.md` (one entry per round, newest last; grep it,
don't read it whole). Old per-round handoffs were deleted 2026-10-16; their content
is in BUILD-LOG and git history (`git log -- docs/`).

Last updated: **2026-10-16** (docs cleanup; no game changes since r9, 2026-10-07).

## State of the repo

- Branch `level-one-holloway-road`, last commit `2cde81e` (through round 6c).
  **r7, r8 and r9 are uncommitted.** Nothing pushed or merged to `main`. Commit or
  push only when Gregory asks. Never commit paid audio in `assets/audio/sfx/`
  (ASSETS.md). `screenshots/` and `build/` are gitignored output.
- Suites: all eleven at 0 problems after r9. The exit-code-134 "double free" in
  `smoketest`, `smoketest_compound`, `smoketest_civilians` is old. Read the
  "N problem(s)" line, not the exit code. `combat_probe` 42-75 dmg/s.
- **Nothing since r8 has been played by a human.** Headless suites and Forward+
  screenshots only.
- `build/` is empty. Export templates are **not installed** on this machine
  (Godot > Manage Export Templates, ~1GB) before `--export-release` works. Turn
  room tags off for any release export.

## Standing rules from Gregory (these override older docs)

- **Cruelty Squad over Dishonored.** Satire everywhere, never sanitised. Fast and
  lethal beats crouch-sneaking. Crude on purpose: keep assets CS-crude, tune by feel.
- **Level one = the Regular only, base kit, no lockpicks.** Wizard/Chad shelved
  (`CharData.ids()` returns `["regular"]`). Don't reintroduce either unasked.
- **Long levels, anticipation, exploration.** Goal visible from afar; escalate on
  approach. "Empty" is a failure: areas must be dressed.
- **Alarm = a guard reaching a station** (kill him first and nothing happens). 3D
  sound only, sirens are horns at their source. Posts are runs (12m+). On alarm:
  one searcher, the rest defend posts.
- **No tracking through walls** (r9). **The rifle alerts** everyone in 75m (r9).
- **Grapple is a route tool** (r9): hooks anything, ledge haul, fall off the map
  = death below y -30.
- **No HUD detection meter.** Feedback is guard-side ("?", "!", barks, aim tell)
  and world-side (visible light tiers).
- **Extractions unlabelled** (a test scans every Label3D). Exits need *tells*, not
  signs. Exits now: van (E1), helipad (E2). The avenue car (E3) is gone.
- **No prop in a doorway, lane, or forcing a jump.** No character checks in script.
- He gives feedback by **room ID**. Read `ROOMS` in `sec_room_names.gd` first.
- Reproduce bugs by **sweeping/simulating**, not by reading code.
- Terse, final judge. Short answers, key reasons, do the work. **Write this file
  + a BUILD-LOG entry yourself at the end of every big task.**

## Round 9 — what he asked (his words) → what was built

| He said | Now |
|---|---|
| "Grapple does nothing to civilians or guards" | Hooked people are yanked to ~1.5m. Guards reel 0.9s then go ALERT; civilians panic. |
| "Picking up ammo picks up ammo for all weapons" | Dead guards drop 6 pistol rounds only. Boxes labelled (9MM/SHELLS/.308/FRAGS); a box for a gun you don't own stays put. |
| "Grenades refused to reload" | One in hand, the rest on the belt; the next is ready instantly. |
| "pump shotgun reload always reloads all six" | One shell per 0.42s; firing mid-reload stops, pumps, fires. |
| "Night vision does nothing" | Real gain, night ambient x2.5, PITCH rooms lifted; works with the trip filter off. |
| "Eating corpses should heal five" | +5. |
| "three times zoom through the scope" | True 3x at any FOV. The gun hides and an eyepiece is drawn (`ui/hud_scope.gd`). |
| "Remove the exit car from the second area" | E3, its trigger and radio line removed. |
| "grapple … a route tool" | Hooks everything, range 40, ledge haul, three grapple-only perches with caches (billboard top .308, Holloway House roof shells, crane counterweight frags). |
| "respond aggressively to the rifle" | Rifle noise 75m alerts every guard in earshot through walls; one runs the alarm. |
| "should not continue tracking through walls" | Unseen >0.35s → runs to `last_seen`, scans, SUSPICIOUS after 9s. |

## Unverified — ask him

- Grapple feel: ledge-haul pop (14 m/s), yank strength, fall-off danger. Are the
  three perches findable? (Red beacons + lamp; nothing points at them.)
- Rifle response: whole-campus ALERT from one shot too much? (`noise` 75 in
  `data/weapons.gd`.)
- Night-vision brightness. Trip-zone eyes vanish under NV (side effect).
- Ammo may now be too tight (SMG/shotgun/rifle: own pickup + one cache each).
- Eat +5 for 2s of chewing may feel worthless.
- Scope: HUD text still draws over the eyepiece.
- Gun feel overall: he has complained about it repeatedly. Numbers are by eye.

## Open decisions for Gregory (from the r8 judges; #1, #4, #5 were settled in r9)

1. **A second way to kill Vandermeer**: accident (water tank R05 over his lane),
   poison, a second location?
2. **The annex's role**: loop it back to the campus, or make the score wipe
   change the campus (CCTV off, a door opens)?

## Next steps (if he doesn't steer)

1. Ask him to play the grapple routes and the rifle-from-H10 trap.
2. Split `core/game.gd` (309 lines, over the 250 rule).
3. Feel work → read `docs/BRIEF-animation.md` first (springs for the viewmodel,
   frame-rate-independent damping, physics interpolation is **off**, Humanoid
   upgrade paths, look-at heads for guards).
4. Commit r7-r9 when he asks.

## What level one is (HOLLOWAY ROAD, level id `compound`)

Plan in the header of `scripts/world/level_compound.gd`. `docs/LEVEL-compound.md`
is the r4 design doc: still the campus reference and jump heights, but **out of
date** where the scope cut changed things. Trust measurement over it.

- **Approach** (z 46-196, spawn `(0,0,190)`): bus stop/tower/garages → estate
  yard (A1) → ring-road embankment (subway A2, crate steps A3, crawl culvert) →
  towpath (A4) → canal → allotments (A5) → terrace backs (A6) → south road. The 28m
  billboard is the lure. `sec_app_estate`, `sec_app_canal`.
- **High routes** (`sec_app_heights`, H01-H11): tower balcony + walkway, pipe-bridge
  catwalk, terrace roofs, overbridge → 3m jump onto the compound wall. No fall
  damage (except off the map).
- **Campus** (`sec_cmp_*`): shutter crawl → roof → duct → hall gallery; bin-store
  gate → courtyard; gym → mezzanine → hall; canteen door; portico → lobby. Fire
  escape, scaffold, boiler climb (`sec_cmp_climbs`), `sec_cmp_vertical` high levels,
  billboard catwalk.
- **Scoring Annex** north of the avenue (`sec_annex*`): Consent Way, yards, the
  Consent Tower site platforming, the server wipe (secondary objective = blackout).
- **ALARM** (`MissionCompound.on_alarm`): CSD locks, target flees to panic room G.04,
  reinforcements spawn, `DefencePlan` mans `POSTS`, decays after 60s unseen.

Room tags (`sec_room_names.gd`, on): A approach · H high · C campus outdoors · G main
ground · F main 1F · R main roof · Y gym · U undercroft. Tag text must avoid
EXIT/VAN/CAR/HELI/EXTRACT. Off with `-- --no-room-names`.

## Where things are (beyond CLAUDE.md's layout)

- Level wiring: `level_compound.gd` (`sections()` is the single list; tools read
  it), `mission_compound.gd`, numbers in `data/mission_compound_data.gd`, guards in
  `guard_posts_compound.gd`, words in `data/level_text.gd`.
- Collision: bodies mask 3, shots/LOS mask 1 (`VerbData.BODY_MASK/SHOT_MASK`). Any
  new ray must set one.

## Verify after any change

```bash
godot --headless --path . --import
for t in smoketest smoketest_compound smoketest_compound_systems smoketest_guard_stuck \
         smoketest_civilians smoketest_jumps smoketest_nav smoketest_target smoketest_arsenal \
         smoketest_r9 combat_probe; do   # the eleven suites; alarm_reach.gd prints a table
  godot --headless --path . --script res://tools/$t.gd 2>&1 | grep -E "problem|FAIL" | tail -3
done
```

Visual (Forward+ under xvfb): `xvfb-run -a godot --path . --resolution 1280x720
--script res://tools/<shot>.gd` with `screenshot_compound` (magenta = hole),
`screenshot_approach`, `shot.gd -- views.txt`, `play_shot`, `judge_pack`, `r9_shot`.
Then **Read the PNGs**. Clear old `screenshots/` output when done; it's ~1MB a frame.

## Gotchas learned the hard way

- Always go through `LevelCompound.sections()`. Tools that kept their own list
  rendered a building with no shell.
- A static body added this frame isn't queryable yet. Tests add props a frame early.
- Shooting a guard raises the alarm. Order test cases accordingly.
- `sign` is a GDScript builtin. `const X := SomeClass` isn't constant; use `preload`.
- Doc-vs-geometry conflicts were real bugs more than once. Measure, fix forward,
  note it in BUILD-LOG.
