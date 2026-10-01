# BUILD LOG — HOLLOWAY CAMPUS

Append three lines per block: what landed, what broke, what the next block needs to know.
Newest at the bottom. Keep it short — this is a handoff, not a diary.

Plan: `docs/BUILD-compound.md`. Design: `docs/LEVEL-compound.md` (r4).

---

**Block 0 · Opus · plan** — `BUILD-compound.md` written; `LEVEL-compound.md` revised to r4
against `REVIEW-compound-r3.md` (5 HIGH, 8 MEDIUM, 6 LOW applied, plus one author correction
to the puddle's damage).
*Broke:* nothing — no scripts touched yet.
*Next:* Block 1, Haiku, the `--no-guards` flag.

**Block 1 · Haiku · Walk mode** — `GrayboxGame` now reads `--no-guards` from `OS.get_cmdline_args()` at startup and skips `_spawn_guards()` in `spawn_mission()` when set.
*Broke:* nothing — headless import and smoketest both green.
*Next:* Block 2, Sonnet, level registry.

**Block 2 · Sonnet · Level registry** — `level_builder.gd` renamed to `level_meridian.gd`
(`class_name LevelMeridian`, no behaviour change). Added `scripts/world/level_compound.gd`
(`class_name LevelCompound`) with `build()` returning an empty root, spawn `(0, 0, 40)`, no
guard posts. Added `scripts/world/levels.gd` (`class_name Levels`) mapping `"meridian"` /
`"compound"` to their builder class; `game.gd` gained `selected_level` (default
`Levels.DEFAULT_ID`) and now calls `Levels.builder_for(selected_level).build(self)`.
*Broke:* nothing on its own, but `var data := ...build(self)` wouldn't type-infer through
the `Object`-typed `builder_for` return — needed an explicit `var data: Dictionary =`.
*Next:* Block 3, Sonnet, `sec_cmp_perimeter` and `sec_cmp_yards`. Both smoketests must run
clean (headless import + `tools/smoketest.gd`, MERIDIAN unaffected) — confirmed.

**Block 3 · Sonnet · The hull (perimeter + yards)** — Added `sec_cmp_perimeter.gd` (streets,
outer boundary fence, compound wall, gatehouse, west alley with the outfall pit and its two
ramps) and `sec_cmp_yards.gd` (north/west yard, courtyard + mast, refuse yard with its 2.2m
fence, gym forecourt + canopy). Geometry and lamps only, per the block — no guards, no
interactables, no light-tier volumes. Two gaps left open in the compound wall for later
Interactables: the north GATE at x [-3, 3] (built as a solid `CompoundGate`-named placeholder
box, not yet wired to a lever) and the south CRACKED WALL at x [20, 24] (left fully open for
`BreakableWall`). The east wall skips z [-20, 8] entirely — that stretch is the gym's own east
wall (roller-shutter tunnel), left for `sec_cmp_gym` in Block 5. Neither file is wired into
`LevelCompound.build()` yet — that's Block 7.
*Broke:* nothing new — MERIDIAN's smoketest is still 0 problems. Not yet checkable: no
compound-specific smoketest exists until Block 6, so this geometry is unverified beyond
"imports and doesn't crash."
*Disagreement logged:* §4.1 describes the west-yard culvert as "1.0m tunnel 8m west" from the
grate (-25, 0, 6) to the outfall (-28.8, 0, 6) — those two points are only 3.8m apart. Built to
the coordinates (3.8m), not the prose distance.
*Next:* Block 4, Sonnet, `sec_cmp_main_g`, `sec_cmp_main_1f`, and the roof.

**Block 4 · Sonnet · Main block, ground + 1F + roof** — Added `sec_cmp_main_g.gd` (the full
ground-floor room grid: west corridor + squeeze shutter, panic room + barred window, north
stair, records, kitchen, north corridor, caretaker + floor opening to the undercroft, toilets,
CSD passage, canteen, west foyer, lobby, riser block, west/east stairs — all three ramps built
`stairs()`-style), `sec_cmp_main_1f.gd` (assembly hall with the gallery's 1.4m-thick solid fill
underneath, staff room + floor hatch, the north-stair landing, west landing, passage W, AV
booth with its projection slot, south corridor with the lobby void and the cantilevered landing
plate, passage E, east landing), and `sec_cmp_main_roof.gd` (roof deck at 8.4 with the parapet
gap at z [-15,-13.5] for the crate stack, the hall's own 7.0 ceiling with a void shaft up to the
roof, the intake vent + duct, the plant room). Doors are full-height gaps, no header pieces —
cosmetic simplification to keep the files scoped, noted rather than chased with headers.
*Broke:* nothing — MERIDIAN's smoketest still 0 problems. Ground/1F/roof are internally
consistent (doors line up with the rooms on both sides of each wall) but **unverified against
the actual mantle/jump numbers** — no compound smoketest exists yet (Block 6), and the hall
ceiling's void-shaft footprint is a simplified approximation of the doc's two reference points,
(-2,7.0,-9) and (2,-12), rather than an exact reconstruction — flagged as a route/sightline
detail, not a gate, so not worth chasing to the centimetre at this stage.
*Next:* Block 5, Sonnet, `sec_cmp_gym`, `sec_cmp_alley`, `sec_cmp_undercroft`.

**Block 5 · Sonnet · Gym, alley, undercroft** — Added `sec_cmp_gym.gd` (store/floor/mezzanine/
roof, the compound's own east-wall stretch for z [-20,8] including the roller shutter — jammed
permanently 1.0m open, not a verb gate — hatch, plant box, helipad deck on four legs), `sec_
cmp_alley.gd` (six crate stacks at x=13 stepping 1.0m south / 1.15m up from z [-20,-18.5], tops
1.15–6.90; the link bridge, floor 4.0 roof 6.6, left open at both ends since the main block and
gym walls already carry matching door gaps there), and `sec_cmp_undercroft.gd` (boiler house
with its ramp down to the flooded basement, the 6.8m squeeze through to the west run, the west
run itself, the caretaker spur with its ramp up through the ground floor's existing slab
opening). The energised puddle is left as a visual marker only — the hazard volume itself is
Block 11's, per the plan.
*Broke:* nothing — MERIDIAN's smoketest still 0 problems, headless import clean across all six
new section files.
*Next:* Block 6, Sonnet, `tools/smoketest_compound.gd` (cases 1, 25, 26) — this is the first
point anything here gets checked against real coordinates rather than just "parses and doesn't
overlap on paper." Expect it to surface wall/door misalignments from Blocks 3-5; fix forward
rather than re-deriving the geometry from scratch.

**Block 6 · Sonnet · Smoketest cases 1, 25, 26** — Added `tools/smoketest_compound.gd`,
following `tools/smoketest.gd`'s frame-delayed structure. `POINTS` (47 entries) covers floor +
headroom (cases 1 and 25 together — 25 is just 1's headroom check generalized to 1.8m/1.0m
crawl/0.6m squeeze) built from §4's three route narratives, spawn through every named
extraction. `DOORS` (14) + `LINES` (2, the two §14.26 names outright: south corridor -> passage
E, and west foyer NOT connecting to the stair well per M8) cover case 26, approximated as a
centre raycast plus two edge raycasts ±0.6m along the wall to stand in for "shares 1.2m of
edge" and a capsule sweep.
*Broke:* nothing — headless import is clean. Ran the tool itself too (not required by this
block, but cheap): as expected, every point fails "no floor" and the M8 negative check fails
"expected blocked but is open", because `LevelCompound.build()` is still the empty stub —
there is no geometry yet for any ray to hit. That is the correct state before Block 7, not a
bug in this file.
*Next:* Block 7, Haiku, wire every `sec_cmp_*.gd` into `LevelCompound.build()` and run both
smoketests for real. The door/opening axis guesses in `DOORS` (which way each doorway's 1.2m
runs) were inferred from the §2.1 plan view, not copied from a table — treat a case 26 fail
there as "check the axis guess" before "check the wall."

**Block 7 · Haiku · Wire it and run it** — Called all eight section builders from
`LevelCompound.build()` in order (perimeter/yards, main ground/1F/roof, gym/alley/undercroft).
*Broke:* nothing — headless import is clean. Base smoketest still 0 problems (MERIDIAN
unaffected). Compound smoketest baseline against full hull:
  - R alley crate base: needs 1.8m clear headroom at (13.0, 1.2, -17.0)
  - R crate stack top: no floor at (11.0, 6.9, -14.25)
  - R vent intake / roof duct / slab hole / ceiling void: marked as crawl gaps but need
    measurement vs. spec
  - R gallery/hall floor: 1.85m headroom (ok for crouch)
  - R culvert grate: marked as crawl gap but measured 0.06m
  - W caretaker spur ramp: very low headroom 0.06m
  - W squeeze mouth/exit: measured 2.0m and 0.90m (spec ~0.6m)
  - W shutter squeeze: 0.60m (matches spec)
  - 14 case-26 failures: doors narrower than 1.2m or not open (west corridor/caretaker,
    toilets, lobby portico, south/AV, west landing/hall, east landing/hall, kitchen/canteen,
    records, north corridor/canteen, CSD/canteen, south->passage E, plus M8 check passes as
    declared).
*Next:* GATE A walk — visual check with `--no-guards`, all three characters, ten minutes. The
squeeze, the alley crates, and the door-width issues are the most likely to invalidate parts
of r4 during that walk.

**Block 7 fix-up · Opus · Level choice** — Block 7 wired the builders but gave no way to reach
them in a real run: the title screen had one BEGIN button and all text said MERIDIAN. Title now
shows one button per entry in `Levels.NAMES` (MERIDIAN CAPITAL / HOLLOWAY CAMPUS) that sets
`game.selected_level`; the spawn banner reads the level name. `DEFAULT_ID` is back to
`meridian`, because `tools/smoketest.gd` relies on the default being MERIDIAN.
*Broke:* nothing. Import clean, smoketest 0, smoketest_compound still 21 (unchanged).
*Still Meridian-only:* briefing route text and the operatives' route lines in `characters.gd`.
They don't match Holloway Campus yet. Card copy for it is in `LEVEL-compound.md` §1.

**Gate A, first pass · Opus · Blender export + mantle probe** — Gregory's walk: too many gaps
in walls, ceilings and floors to describe one by one, and routes aren't legible. Added
`tools/export_compound_glb.gd`, which writes `blender/holloway_campus.glb` (folder has
`.gdignore`): 279 meshes, one parent per section, plus empties for lamps, every smoketest route
point (`pt …`) and declared door (`door …`). Verified it imports in Blender 5.2. No reimport path
yet; collision would have to be regenerated on the Godot side.
*Mantle:* the code works. Probed at runtime: Wizard/Regular climb the 1.0 gallery step, Chad
climbs the skip (2.2) and the canopy (4.4). It feels broken for three reasons. (1) Wizard and
Regular reach 1.2, and by design only the crates and gallery step are that low. (2) **Canopy
-> gym roof has nothing to climb**: a chest ray from the canopy finds no wall within 12m. (3)
**0.2m fences can't be mantled by anyone**, because the top probe lands 0.45 past the lip, on
the ground behind. That includes the refuse-yard fence the doc calls Chad's band.

**Gate A, screenshot pass · Opus** — Added `tools/screenshot_compound.gd`. It renders 80 shots
into `screenshots/` (`.gdignore`, magenta sky, so magenta indoors is a hole): 5 overviews, both
ends of 18 hallways, and a 4-way sheet for 39 areas. Run it with `xvfb-run -a godot --path .
--rendering-method gl_compatibility --resolution 1280x720 --script
res://tools/screenshot_compound.gd` (~10s). Punch list:
- *Systemic:* 1F `WALL_H` 3.0 (walls reach 7.0) but the roof underside is 7.8, leaving a sky
  slot. Seen at the hall N wall, south corridor S wall, east landing E, west landing W end,
  and staff room N half. The gym shows the same slot on all four sides under its 6.6 roof
  (E wall ~4m). The canopy -> gym roof mantle fails because of this.
- *Open to outside at 1F:* north stair landing (N and W walls missing), passage E (N side
  open, stair below exposed), east end of the south corridor (N/E/S).
- *No ceiling:* ground-floor west corridor, full length; you see up to the 8.4 roof.
- *Missing:* the roof duct (only the intake hood exists); ground in the alley x [11, 15],
  z [-10.7, -2] (void).
- *Holes to the void:* outfall pit (both sides of both ramps, under the wall and boundary
  wall); boiler basement (beside the ramp and at the squeeze mouth); caretaker spur (beside
  the ramp); west run at the squeeze junction; ground slit along the gym's outer E wall
  z [-20, 8]; ground under the cracked-wall gap.
- *Wrong shape:* culvert grate is a 1.2m solid box, not a floor-level crawl entrance.
- *Fine:* records, kitchen, toilets, CSD passage, canteen, west foyer, panic room, boiler
  house, squeeze tunnel, link bridge, gatehouse, streets, yards, main and gym roof decks.

**Block 7b–15, collapsed · Opus · level one built, then re-scoped** — Gregory asked for the
level built out, then mid-build narrowed it: Regular only, no lockpicks on level one, and a
longer level with anticipation and exploration. What landed:
- *Hull repaired:* new `sec_cmp_main_shell` (exterior walls 0→8.4 with every opening),
  `WallUtils` (doors/windows with headers), 1F walls to the roof underside, west-corridor
  ceiling, riser block, void walls, gym walls to 6.6 at 0.8 on the compound line, alley
  ground, pit retaining walls. Interior screenshots are free of magenta.
- *r4 design bugs found and fixed:* the caretaker ramp landed on the far side of its own
  hole (now climbs west to the door); L1 sat behind the first crate stack (moved to the
  canteen, z -12, under the bridge); the crate stair was on G5's lane (x 13 → 11); the
  hall ceiling/roof slab left 0.8m in the "1.0m" void (ceiling 0.15 thick, slab 0.4);
  boiler-house roof at 2.2 was a Chad step onto the wall (now 4.0); lectern sat on the
  target's lane; gym props on G4's lane.
- *Systems:* D14 mantle (rise from last floor), parapet-safe landing, fence vault;
  squeeze stance (Wizard, dormant); collision layers + masks on every ray; head hitboxes
  (the MERIDIAN headshot bug: the capsule stopped below the head mesh); suppressor
  loadout (default SUPPRESSED); light tiers; hazard; switches; remote doors; AlertState
  (ALARM → CSD lock, target flees to G.04 with G9, R1/R2 then R3); sentry facing/waits;
  barks; LOCATE via sight or intel; stats (detected, loadout, radio line).
- *Scope cut:* roster `["regular"]`; lockpick doors removed (doorways left open); ward,
  cracked wall, helipad exit removed (boiler door and crack walled up); detection meter
  removed from the HUD (D11).
- *Approach:* `sec_app_estate` + `sec_app_canal`, spawn (0, 0, 190). Estate, embankment
  (subway / deck / culvert), towpath + intel hut, canal (bridge / boat / bed), allotments,
  terraces. Six approach guards, PA lines per stretch, 28m-wide lit billboard as the lure,
  fog.
*Broke:* nothing — import clean; smoketest, smoketest_compound, smoketest_compound_systems
all 0; a 33s live soak with guards throws no script errors.
*Next:* Gregory's blind run. Tuning by feel: approach guard count/lanes, fog density,
billboard size, whether the subway sentry is too hard head-on. Van idle sound not done.

**Verticality pass · Opus** — Gregory: "more vertical, more entry paths". New
`sec_app_heights` (tower deck-access walkway -> road deck; pipe bridge over the canal to a
pumping-station roof; extension chain 1.1-5.4 onto the terrace roofs, chimneys up top;
overbridge at 5.0 over the south road whose verge landing is a jump onto the compound
wall top) and `sec_cmp_climbs` (boiler-house climb from the west alley onto the wall;
west-face fire escape -> new 1F door into the strip over the west corridor -> door onto
the west landing behind G9, and on to the roof; courtyard scaffold -> new 1F door into
G8's south corridor, and on to the roof). Road-deck rails gapped where the walkway and
pipe bridge join; parapet gaps at both new roof tops. A6 moved z 49 -> 44 (off the
overbridge stair).
*Broke:* nothing — import clean, all three smoketests 0; 17 points, 3 doors, 4 lines added.
*Next:* walk it. Unverified by play: every mantle step (all rises <= 1.15), the 3m jump
from the overbridge to the wall top. The wall top now links to the gatehouse roof, so the
avenue (E3) is reachable without the lever — legal shortcut or seal it, Gregory's call.
