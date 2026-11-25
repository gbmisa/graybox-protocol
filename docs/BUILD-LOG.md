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

**Past-graybox pass · Opus** — Gregory played the verticality build: "a lot better but it
feels very empty"; asked for a real game menu, a hand holding a gun with recoil, free
assets (Kenney; "Gamemaster" turned out to be Gamemaster Audio, which is paid — drop-in
hook instead), and fixes by room ID.
- *Assets (all CC0, `ASSETS.md`):* Kenney car / city ×3 / retro urban / survival / furniture
  / blaster kits, interface + impact + sci-fi sounds, fonts; WRAD ARMS (wriks); Poly Haven
  textures. `Surfaces` maps every palette colour to a triplanar photo texture (brick walls,
  asphalt, worn concrete, steel plate, plywood); `Props` places models bottom-centred with
  one box collider. `sec_props_approach/_campus/_interior` dress every stretch, clear of
  every patrol lane; `sec_skyline` rings the level with lit towers and red beacons.
- *Viewmodel:* WRAD arm posed round Kenney blaster-a in Blender (script fits the grip into
  the curled fingers), baked to one GLB with the eye at the origin. `viewmodel.gd`: kick
  back + barrel climb about the grip, muzzle flash (light + additive radial quad), mouse
  sway, stride bob, own visual layer and fill light. `look.add_recoil` punches the head
  node. Footsteps (`footsteps.gd`, Kenney concrete). Kit HUD lines moved bottom-left.
- *Menu:* live `MenuBackdrop` (the level at night, slow camera shots, fades), main menu
  (NEW GAME / MISSIONS / OPTIONS / CREDITS / QUIT, consent-score ticker), OPTIONS persisted
  via `Settings` (volume, sensitivity, FOV, invert Y, bob, fullscreen, vsync, room tags),
  CREDITS, pause menu with OPTIONS and QUIT TO MAIN MENU. `UiTheme`: Kenney Future for
  headings/buttons, engine font for paragraphs. Screens on canvas layer 10, over the HUD.
- *Feedback fixes:* **H03/H04** pipe bridge now continues — gantry over the back yards and
  a stair onto the east terrace roof, so it is one rooftop route ring road → terraces →
  overbridge → wall top. **Billboard area** — maintenance scaffold (3 flights) to a catwalk
  *behind* the board overlooking the courtyard, a third way onto the wall; verge dressed
  with the audit guests' cars. **C19** portico read as roofless: its slab was the night
  sky's colour — textured and lit now. **G13** void dressed as an atrium (banner, lamp).
  **G12** "something sticking out of the wall" was the west stair's ramp box poking 0.75m
  through — all ramps are now `RampBuilder` wedges. **Exit/helipad** — steel stair from the
  gym roof to the deck and a box-built continuity helicopter (rotor, blinking beacon,
  engine drone) = extraction E2 "heli"; van and car are Kenney models with idling engines
  and headlights. **Words popping up** — PA lines are now subtitles tagged "PUBLIC ADDRESS ·
  VANDERMEER INSTITUTE", with a chime; every wall sign has a backing board.
- *Audio:* `AudioSynth` resolves a name to `assets/audio/sfx/<name>.ogg|wav` (drop-ins,
  e.g. bought Gamemaster packs), then Kenney samples, then the synth; new synthesized
  suppressed shot.
*Broke:* MERIDIAN's "target spawn" headroom probe hit the target's own capsule once he had
shuffled 2cm — the probes now exclude CharacterBody3Ds. Otherwise nothing: import clean,
all three smoketests 0. Added 10 points and 4 lines (gantry, scaffold, catwalk, helipad
stair, G12 ceiling line).
*Next:* Gregory plays it. Grappling hook is his stated next tool (later levels; Cruelty
Squad grappendix / lighter Spider-Man) — design note in NEXT-SESSION.

**Playtest fixes · Sonnet** — Gregory played the past-graybox build.
- *Vehicles:* the box colliders matched the models exactly — the models were just 2.1-2.6m
  tall (scaled 1.6x), above the 1.84m jump apex, and one box fills a truck's low cab.
  `Props.vehicle()` now caps the roof at 1.5m and builds collision from the mesh itself
  (trimesh); tests assert every parked model's roof is 0.9-1.6m. Trees collide on the trunk
  only (one box over the whole canopy had walled off the deck-access stair) and the tree
  at the stair foot moved; a line test keeps the foot clear.
- *Floating windows:* the skyline's fake lit-window boxes were cut (the Kenney towers carry
  their own).
- *G13 / "a door to nothing":* the 1F south corridor stopped at the lobby void and resumed
  5m on — a Wizard dash showcase. Bridged with a railed 1.6m catwalk (`_lobby_catwalk`),
  atrium kept. If the door he meant is elsewhere he'll quote an ID.
- *Bob / footsteps:* 11 bob cycles a second at walk speed (1.6/m x 7 m/s) -> both now share
  `PlayerFootsteps.STRIDE` = 3.5m, a footfall every half second.
- *Alarm:* previously silent (doors locked, reinforcements spawned, nothing to perceive).
  `Atmosphere` adds a looping siren, red ambient pulse, flashing HUD banner and a PA line.
- *Light tiers:* `Atmosphere` also eases ambient light by the tier under the player
  (LIT 1.0 / DARK 0.28 / PITCH 0.05 of the level's ambient) — visible, still no HUD gauge.
*Broke:* nothing — all three smoketests 0 (+8 vehicle, 2 stair-foot, 1 lobby-bridge cases).

**Alarm stations + aimed pistol · Sonnet** — Gregory: the alarm must not fire the instant a
guard is hit ("the point of the game is not entire stealth"); a guard has to go to an alarm
station; the siren must come from the siren, not the player character; point the pistol at
the crosshair.
- *Alarm:* an ALERT guard (spotted you, was hit, or heard loud noise within 12m) now sets
  `alarm_run`; `GuardBrain._run_to_station` takes him at 1.1x chase speed to the nearest
  `AlarmStation` on his floor within 50m, no shooting on the way, and he presses it — that
  raises the alarm. Kill him first and nothing happens. 15s timeout, then he fights.
  12 red posts (`sec_alarm.gd`, "REPORT AN EVENT (REPORTS ARE SCORED)") stand off the
  patrol lanes. A level with no stations (MERIDIAN) keeps alert = alarm.
- *Siren:* 9 `AlarmSiren` horns (tower, road deck, roofs, gatehouse) play the wail as
  `AudioStreamPlayer3D` from where they are mounted, lamps pulsing. The 2D player is gone.
  `AudioSynth.play_at` (3D) now carries guard aim/shot/shout and target hurt, so guard
  sounds also come from the guard.
- *Pistol:* `viewmodel.gd` solves the rest rotation so rear sight -> muzzle runs through the
  point 20m dead ahead; measured 0.01 degrees / 3mm off the crosshair at 20m.
*Tests:* stations exist, a hit guard does not raise the alarm and is sent running, reaching
a station does. All three suites 0.

**Playtest round 3 · Sonnet** — witnesses, energised water, crawl sizes, canteen, gun.
- *Witnesses:* `GrayboxGame._witness_death` — a guard with a clear line to a colleague who
  drops (<=24m; one facing away only within 6m) goes suspicious at the body with his meter at
  0.9, so one glimpse of the player finishes it.
- *Energised water:* new WATER ISOLATOR switch on the west run's wall straight ahead of the
  spur mouth (before the puddle); `Hazard.set_enabled(false)` stops the damage and turns the
  glow cold blue. The 0.6m squeeze past the puddle was the Wizard's and the Regular (crouch
  0.85) couldn't enter it — now a 1.0m crawl; the west corridor's shutter gap likewise.
  Tests: points are "crawl", plus a hazard-toggle case.
- *Canteen:* mid-room tables walled off the kitchen door. Tables now sit on the east wall's
  corners, off all five doorways. `smoketest_compound` probes every door at knee height too
  (0.35m) — the 0.9m probes passed over 0.66m tables.
- *Viewmodel rendering:* now its own SubViewport + Camera3D (FOV 55, near 0.03) on a
  CanvasLayer under the HUD, staged at y=4000; world camera culls the layer. Fixes the
  stretched-diagonal look of a gun 15cm from an 80-degree lens, and wall clipping. Barrel
  axis is measured from the suppressor mesh and aimed at the point 20m ahead; muzzle flash
  also lights the world through a light on the player camera.

**Playtest round 4 · Sonnet** — walked through a wall; ceiling; gun.
- *Through the wall:* `PlayerMantle` treated the main block's 0.3m east wall as a thin ledge
  (and, in the vault branch, a fence): standing on a crate and jumping at it put you on the
  floor behind it — ground floor or F10 (4.0) depending on the crate. Found by sweeping
  `_find_ledge` over every crate, the bridge roof and the alley (354 of 1962 samples
  crossed the wall). New rule `_wall_continues`: a ledge or fence only counts if nothing
  solid sits within 0.85m above its lip (parapets are 0.6, so roof climbs still work).
  Re-sweep: 0 crossings. Systems test `_check_wall_not_vaulted` keeps it that way.
- *Lobby:* the 1F corridor over the lobby is a full slab again (the lobby is a normal 3.6m
  room) — not a void, not a catwalk.
- *Gun:* the black override material made the pistol a flat cut-out; Kenney's own colours
  are back, the stage has its own ambient + key/fill lights (`viewmodel.gd`). The hand was
  "mangled" because my Blender script scaled the gun AFTER translating it to the grip, so
  the fist sat ~2x the grip offset away, and because this bullpup blaster's real grip is
  the black handle at the front, not the rear box. Re-fit, re-exported
  (`viewmodel_pistol.glb`); `GRIP` is the fist centre written out by the fit script.

**Playtest round 5 · Sonnet** — small cars, loud alarm, floaty jump, cone; alarm does
nothing, guards hit walls; "guards unmodeled, civilians, Cruelty Squad, too open".
- *Feel:* vehicle scale cap 1.75 (roofs ≤1.58); siren quieter/lower/shorter range;
  `PLAYER_GRAVITY` 24 with 1.35x fall, `jump_v` 9.2/11.7 to keep apex 1.84/2.85; removed
  `car/cone-flat`.
- *Navigation:* `GuardNav` (navmesh baked from static colliders; agent r 0.4, cell 0.2,
  ~0.45s) + `NavWalker`; doors rebake async. Alerted guards without LOS keep pathing.
  The 0.5m radius first tried left the barrier-blocked fence gap (1.0m each side) unusable.
- *Alarm:* guards converge on the player (suspicious, meter 0.6); R4/R5 added, cap 5.
- *People:* `Humanoid` rig for guards/target/civilians; `Civilian` (20, panic that
  spreads, killable, no penalty); `Gore` bursts + stains. Tests: `smoketest_civilians`.
- *Level:* `SecCmpLanes` (estate zigzag walls + courtyard container stacks and catwalk).
- Handoff to Opus 5.5: `docs/HANDOFF-opus-r5.md`.

**Playtest round 6 · Opus** — stuck in C08 avenue / U01 basement; alarm reset; guards
froze when shot; pistol angle + hand; aim down sights.
- *Soft-locks:* rubble stair inside the avenue at x 6-8 back onto the wall (1.0m steps);
  the boiler-house door is a `RemoteDoor` with a DOOR RELEASE switch inside (exit only).
- *Alarm:* hold F on any station's panel while the alarm is up to silence it
  (`AlarmReset`, 1.2s, 6m noise); `AlertState.stand_down()` shared with the decay.
- *Guards:* reproduced (`smoketest_guard_stuck`, 31 frozen guards over three spots) and
  fixed: sight/shot rays hit colleagues, so a squad "lost" the player at arm's length and
  pushed into one clump; head box 2.11 vs navmesh agent 1.8 wedged them under the 2.0
  portico roof (raised to 2.3); nav map cell size != mesh cell size (edges unjoined);
  `NavWalker.steer` adds separation + sidestep-when-stuck; strafing checks for room;
  investigators stop short when a colleague holds the spot. Now 0 frozen.
- *Viewmodel:* the hand was mangled because WRAD fingers curl on NEGATIVE X — both earlier
  fits bent them backwards. New hand-first fit (`tools/blender/viewmodel_fit.py`): fist
  closed round the black grip, gun yawed/canted 12 degrees so its flank shows, magazine
  dropped (the forearm runs where it sat). Rest pose = identity; no runtime re-aim.
  RMB = aim down sights (sight line to screen centre, FOV x0.72, sensitivity scaled).
- *Verticality (r6, `sec_cmp_vertical.gd`):* car-park deck over the avenue (3.0, ramp,
  cars under it; replaces the rubble stair), west gantry along the compound wall (3.0,
  stairs both ends, over G3's lane), courtyard podium (2.85, stair, crouch wall, benches
  under), plant-room top + water-tank plinth on the main roof (10.4 / 11.55) with sentry
  G10. Each tops out one mantle under the wall top / next perch (systems test
  `_check_vertical`). Room tags C23-C25, R04-R05. Trees, a pole and clutter moved off
  the new footprints; civilian spot moved off the podium stair.
- *Alarm = defence (r6b):* "guards still bunching ... they rush to the alarm; should go
  to defensible positions". `_converge` is gone. One runner per alarm station (claimed);
  on alarm `DefencePlan` sends the guard nearest the player to search and the rest to the
  nearest free of 13 `POSTS` (chokepoints + the new high levels); sentries hold their
  own, G9 the panic-room door, overflow holds where it stands. `GuardBrain._hold`: fight
  within 5m of the post, fall back after 2.5s unseen, stand down after 20s. NavWalker
  reaches corners at 0.35 (0.6 cut doorway jambs) and sidesteps to the free side.
  `smoketest_guard_stuck` now also fails on any 3 guards within 2.5m and checks every
  post is walkable: 0 clumps, 18-19 guards on posts per alarm.

**Round 6c, overnight · Opus** — "new defensive areas, more complex, a secondary objective
and area"; "an area with platforming"; "graphics like a real game, original, trippy";
"an opening visual-novel cinematic".
- *Scoring Annex (`sec_annex`):* new walled area north of the avenue (the old north
  boundary now has a checkpoint gap and a 1.0m crawl under the car-park deck). Two-storey
  building: hall with racks, ramp, office, corridor with a desk barricade, server room
  with three doors, fire stair to the roof. Checkpoint chicane + floodlit sandbag nest,
  dock containers + a nest facing away from the crawl, generator strip. Guards N1-N6, 3
  alarm stations, 6 new defensive POSTS (DefencePlan now only sends a guard to a post he
  can walk to). Skyline pushed north 24m to make room. Room tags N01-N13.
- *Secondary objective:* hold F on the SCORE SERVER (3s, loud) — billboard reads ERR, PA
  line, HUD's OPTIONAL line updates, end screen reports it. Systems test covers it.
- *Crane run (`sec_crane_run`):* deck crates -> catwalk on the annex wall (6.0) -> hung
  pallets -> a sliding crane pallet -> container stack -> pole pallet -> pallets -> annex
  roof behind N5. Mantles in the systems test; the jumps are PLAYED by
  `smoketest_jumps` (real input, real physics). Plant units on the main roof as a hop
  circuit.
- *Look:* screen shader (dithered banding, edge fringe, acid shadows, warp, grain;
  alarm/hurt push it), shader sky (violet/acid, drifting bands, haloed moon), filmic +
  bloom + SSAO + volumetric haze; neon trims and signs; posters/graffiti/wallpaper/
  terrazzo/faces generated by our own script; guards and civilians have drawn faces; the
  courtyard mast is an eye that follows you, CCTV cameras track you; CONSENTO mascot
  statues (Blender metaballs). Kenney's unshaded tree/lamp materials now take light.
- *Opening:* `ScreenIntro`, OPENING on the title menu. First-pass 2D visual novel (flat,
  VR helmet; the hot-dog ad; the come-on ad; the street of parody burger boards and a
  courier doing tech support on a moped; title). Kept as satire of the ads and the gig
  economy, not of the courier's ethnicity; parody brand, not the real logo.
*Tests:* all seven suites 0 (smoketest, _compound, _compound_systems, _nav, _civilians,
_guard_stuck incl. an annex spot, _jumps).

**Playtest round 7 · Opus 5.5 (2026-10-02)** — ten notes in one message. All seven suites
0 problems; visual checks by Forward+ screenshot. **Nothing played by hand.**
- *Alarm posts* ("an opportunity to kill guards without them being right next to an
  alarm"): 15 posts -> 9, moved off the lanes. Every guard now walks 12m+ of navmesh to
  his post (most 20-50m; G5/G7 ~12-14m, the agreed exceptions; the road deck and plant-room
  top have none and just fight). `tools/alarm_reach.gd` prints it; `_check_alarm_runs`
  enforces it. Annex posts are deep inside; nothing on Consent Way.
- *Scoring Annex, 4x+* ("a head on approach ... a much longer platforming option involving
  a plank walk ... a construction zone for a surveillance building ... ladder or
  staircase"): district x [-34, 34] z [-106, -40]. Consent Way runs straight from the
  checkpoint to a bigger annex (36x20, 2 floors + roof). West yard, back strip. East: the
  Consent Tower site — stair, ladders, plank over the excavation, long plank, a beam and a
  sliding pallet on the crane's hook, the tower frame, a plank onto the annex roof (~70m).
  New `Ladder` (climb zones in `PlayerMovement._climb`). `sec_crane_run` is gone (its roof
  plant units moved to `sec_cmp_vertical`). `smoketest_jumps` now plays the site route.
- *The server* ("nothing visually changes ... turn off the cctv cameras and the tracking
  eyes, visual consent scores, automatic door locks, alarm system"): `Surveillance.blackout`
  — billboard flickers dark, score screens (new, 9 on walls + every alarm post) die,
  cameras and eyes sag dead, every RemoteDoor releases, alarm posts die, alarm can never
  rise again. (The billboard code worked before; it only changed text under a glow.)
- *Bloom* "way too high": glow intensity 0.75 -> 0.3, threshold 1.05 -> 1.6, levels 2-5 -> 1-2.
- *Gun vs crosshair* (with a Cruelty Squad screenshot): the rest pose turns the gun about
  the fist so the barrel points at (0, 0, -0.36) on the view axis; REST_OFFSET brings it
  closer. Side-on, nose toward the crosshair. ADS unchanged.
- *Medium-poly models*: people are now Quaternius CC0 bodies (~12.5k tris, rigged) with
  the Universal Animation Library (idle/walk/jog/sprint/aim/death/cower...), baked by
  `tools/blender/people.py` with a clothing mask in vertex colours; `person.gdshader`
  paints garish clothes; helmets/caps/pistol on bones. `Humanoid` keeps its API plus
  `die()` and `set_aim()`. Deaths are the death animation now.
- *Trip* ("faces and eyes that appear to watch the player ... extremely unsettling"):
  `TripZone` x6 (subway, canal bed, undercroft, boiler basement, excavation, server room):
  wall eyes that track and blink; faces (`trip_face_*`, 3D eyes in the sockets) that fade
  in only outside your view and vanish when looked at; a face behind you after a while,
  with a sting when you turn. PostFx `trip` (breathing, ghosting, acid) near them.
- *Mascot* redone (`tools/blender/mascot.py`): glossy yellow bean, pin-prick pupils, too
  many teeth, thumbs up, phone showing 412, a CCTV camera for a hat, plaque.
- *Intro* -> Postal 4-style comic pages (`screen_intro.gd`, script in
  `data/intro_script.gd`). Placeholder art = staged level stills inked by
  `tools/gen/comicify.py`. Gregory is writing the script.
- Not done, on purpose: "McGoySlop" (antisemitic slur term) and an ethnic-caricature joke.
  The McGRATITUDE ads were in the old intro and are gone with it.


## Playtest round 8 (2026-10-06)

Gregory: "fix the lighting, it's extremely dark. the people models don't fit the scene.
the colors on the intro are really bad. can you recreate the arm and gun in blender and
let me edit the file?"

- *Lighting*: `SecCmpPerimeter.night()` ambient 0.5 -> 1.35 (lighter lavender), moon
  0.3 -> 1.0, exposure 1.0 -> 1.25, fog colour lifted; `Atmosphere.TIER_AMBIENT` DARK
  0.28 -> 0.6, PITCH 0.05 -> 0.32 (guards' tier detection unchanged); post shader
  vignette 0.85 -> 0.35. Mean frame brightness ~25 -> ~78 /255 along the approach.
- *People*: `person.gdshader` now flat — faceted normals, one colour per clothing region
  (mask snapped to the strongest channel), no normal map, skin a flat colour with the
  texture's darkest marks kept as crude eyes/brows/mouth. Hair untextured. Meshes
  decimated 12.5k -> 1.5k faces by new `tools/blender/people_lowpoly.py` (run once per
  people.py bake). Rig, mask and animations survive.
- *Intro*: `comicify.py` snaps every pixel to one fixed 15-colour print palette (Lab
  nearest) instead of free posterizing, halftone only on the night colours, mode-filtered
  to kill speckle. Raw panels re-rendered with the new light and people.
- *Viewmodel*: new `art/viewmodel.blend` (our own; old WRAD/Kenney rig in a hidden
  reference collection). `viewmodel.gd` reads `gun`/`grip`/`muzzle`/`sight_*` empties
  from the GLB instead of constants and the suppressor measurement; the glove override is
  gone (Blender materials are used as authored).

### r8, second half (after Gregory's second message)

Gregory: "Guards need to be more aggressive ... lighting ... doesn't distinguish stealthy
areas ... the hand is facing the wrong direction ... bring this game to [a full game's]
level ... weapons, and tools like Cruelty Squad ... spin up an agent to judge the
graphics ... level design ... [and] an additional agent to judge." Also: "always write a
handoff when you finish a large task" (now in CLAUDE.md).

- Guards: one alarm runner level-wide (`GuardRunner`, hand-off after 3s fighting or
  give-up); aim at capsule centre (crouch immunity was the real bug), `Spread.cone`,
  0.15s led lock, aim cancel when unticked/LOS lost, per-shot aim spoil (>=15 summed),
  dead men's "!" stays down, walls halve noise reach (`GuardSenses.muffled`).
  `combat_probe` + `--crouch`.
- Tiers in the world (`LightTiers.dress`: PITCH ReflectionProbes, LIT fills), hotter
  lamps with bulbs and emissive floor pools (`BuildUtils._pool`), night ambient
  (0.4,0.36,0.66)x0.6, exposure 1.45, contrast 1.3, black point, sky x0.7, SSR.
- Viewmodel WYSIWYG: `_solve_rest`/`REST_OFFSET`/`AIM_DIST` removed; EYE camera in the
  blend; 5 weapon collections; suffix-tolerant marker lookup; `set_model` + `dip`.
- Arsenal/tools/pickups/eating/corpses/ammo drops/impacts/gibs/explosions — see HANDOFF-r8.
- Sound: `tools/gen/make_sfx.py` -> `assets/audio/gen/`, looked up before Kenney.
- HUD: `HudAmmo`, red bar, plain face under 22px, 20s/F1 help, objective band.
- Level: `sec_r8_cover` (Consent Way van + barriers, estate shelters/wall/burnt van,
  deck lorries + barriers), `sec_r8_clutter` (seeded litter + puddles, no collision),
  guard A7, alarm posts deck NE / annex roof / site stair foot / estate substation,
  `NO_GRAPPLE` boxes, target window routine (`smoketest_target`), rifle at H10.
- Skyline tints + rooftop ads; moon ring gone; people outline pass + guard variety.
- `smoketest_guard_stuck`: clump check only when the alarm went up (guards now fight).
- Review tools: `judge_pack.gd`, `map_plan.gd` + `tools/gen/draw_plan.py`.
- Scores: graphics 4.5 -> 5.5 -> 6.0; level 5.5 -> 6.0 -> 6.5; combat 4.5 -> 6.0 -> 7.0.
- After the last rounds: decal pools emission-only (no tan rectangles), lighter rougher
  puddles, hazard-striped anti-climb paint where the hook won't bite (`SecR8Cover.PAINT`),
  noise muffled only if blocked at knee AND head height, kick 13 dmg (4 kicks).
- Final run: all ten suites 0 problems (exit-time "double free" in three is pre-existing).


## Playtest round 9 (2026-10-07)

Gregory (first play of r8): "Grapple does nothing to civilians or guards. Picking up ammo
picks up ammo for all weapons ... Grenades refused to reload ... The pump shotgun reload
animation always reloads all six shots. Night vision does nothing. Eating corpses should
heal five. add a three times zoom through the scope for the rifle. Remove the exit car
from the second area ... The grapple should be versatile and even allow the player to fall
off the side of the map ... Incorporate it as a route tool. guards should respond
aggressively to the rifle being shot from the scaffold ... Alerted guards should not
continue tracking through walls. The sounds are pretty good. Overall, it's a huge
improvement."

- *Grenades*: `give` pools hand + belt (1 in hand, rest spare); throwables have no reload
  time, so the next one is in hand at once (it used to sit at 0/N forever).
- *Pump*: reloading split into `player/weapon_reload.gd`; `shell_time` 0.42 loads one
  shell per step until full; LMB with a shell in stops it, pumps, fires. New sounds
  `shell_in`, `pump` (make_sfx.py).
- *Ammo*: `WeaponData.DROP` = pistol 6 only (guards carry pistols). Boxes say what they
  hold (`ammo` key: 9MM / SHELLS / .308 / FRAGS); a box for a gun you don't carry stays.
- *Scope*: rifle `scope` 3.0 -> `WeaponData.zoom_for` (tan-correct 3x at any FOV); raised,
  the gun hides and `ui/hud_scope.gd` draws the eyepiece; crosshair dot hides.
- *Eat*: `ToolEat.HEAL` 5.
- *Night vision*: the gain ran after the banding/black point, so black stayed black, and
  PITCH probes zeroed ambient. Now: green gain on the raw frame (shader), night ambient x2.5
  (`Atmosphere.NV_AMBIENT`), PITCH probes lifted (`pitch_probe` group), IR 5.0/32m, and it
  works with TRIP FILTER off. Avenue mean 49 -> 86/255, detail kept.
- *Car*: E3 avenue car + trigger + radio line removed (it sat on the way to the annex).
- *Grapple*: hooks anything on the shot mask; a person gets yanked to ~1.5m (guards reel
  0.9s and go ALERT, civilians panic and don't run mid-throw); a wall face within 2m of its
  top anchors on the lip and hauls you over (`LEDGE_*`); range 40; `NO_GRAPPLE` emptied
  and the anti-climb paint removed; `PlayerHealth.KILL_Y` -30 = fell off the map.
  Routes (`sec_r9_grapple`, `CACHES`): billboard top (24, .308), Holloway House roof (28,
  shells; its west edge is the world's), crane jib + counterweight made solid (frags).
- *Rifle*: noise 55 -> 75 and `alerts`: everyone in earshot goes ALERT hunting the shot
  through walls (12 guards from H10 in the test). `AlertState.on_noise` seeds `last_seen`.
- *Through walls*: `GuardBrain` — unseen > 0.35s, an alerted guard runs to `last_seen`,
  scans, and after 9s drops to SUSPICIOUS; he no longer paths to or faces your live position.
- Tests: `smoketest_r9` (25 cases), arsenal's wall-top case now expects the haul-up;
  `r9_shot.gd` renders NV/scope/perches. Final run: all eleven suites 0 problems
  (exit-time "double free" in three is pre-existing); combat_probe 42-75 dmg/s (r8 range).
