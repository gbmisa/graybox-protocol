# HANDOFF — after playtest round 6 and the overnight pass (Opus 5.5, 2026-10-02)

Gregory plays, reacts in one terse paragraph, quotes room IDs. He is the final judge.
**Nothing below was played by an assistant** — only the seven headless suites and
Forward+ screenshots. Read `docs/NEXT-SESSION.md` for the standing rules, then this.
Detail per change is in `docs/BUILD-LOG.md` ("Playtest round 6" and "Round 6c").

## State of the repo

- Branch `level-one-holloway-road`, last commit `8cb18cf`. **Everything since r4 is
  uncommitted** (~155 paths, plus every new file below). Commit/push only when he asks.
  `screenshots/` stays untracked; `assets/` (incl. `assets/textures/gen/`,
  `assets/models/custom/`, `assets/shaders/`) must be committed.
- All seven suites were 0 problems at handoff:
  `smoketest`, `smoketest_compound`, `smoketest_compound_systems`, `smoketest_nav`,
  `smoketest_civilians`, `smoketest_guard_stuck`, `smoketest_jumps`
  (`godot --headless --path . --script res://tools/<name>.gd`).
- Run the game: `godot --path .`. Screenshots: `xvfb-run -a godot --path . --resolution
  1280x720 --script res://tools/{play_shot,shot,intro_shot}.gd` — **Forward+ works under
  xvfb on this machine (RTX 5090)**; drop `--rendering-method gl_compatibility` to see the
  real look (fog, SSAO, glow, decals only exist in Forward+).

## What round 6 changed (his words in quotes)

**Fixes, early r6**
- "Stuck in C08 after hopping the wall" → now covered by the car-park deck (mantle to the
  wall top). "Can't get out through U01" → boiler-house door is a `RemoteDoor` with a
  DOOR RELEASE switch inside (exit only).
- "Allow the player to shut off the alarm" → hold F on any station's panel while the alarm
  is up (`interactables/alarm_reset.gd`, `AlertState.stand_down()`).

**Guards** ("grouped up and didn't move when I shot at them", then "still bunching ...
they rush to the alarm; should go to defensible positions")
- Root causes, all reproduced by `tools/smoketest_guard_stuck.gd` first: sight/shot rays hit
  colleagues (now `Guard.ray` excludes guards); guard head box 2.11 vs navmesh agent 1.8
  wedged them under the 2.0 portico roof (`GuardNav.AGENT_HEIGHT` 2.1, `CELL_H` 0.1,
  portico raised to 2.3); nav map cell size ≠ mesh cell size; corner-cutting in doorways.
- `NavWalker.steer`: separation, sidestep-to-the-free-side when stuck, corners reached at 0.35.
- **Alarm is a defence, not a rush** (now a CLAUDE.md core rule): one runner per alarm
  station; on ALARM `DefencePlan` sends the guard nearest the player to search and the rest
  to the nearest *walkable* free post in `MissionCompoundData.POSTS` (19 posts); sentries
  hold their own, G9 the panic-room door, overflow holds where it stands; posted guards
  fight within `GuardBrain.LEASH` 5m, fall back after 2.5s unseen, stand down after 20s.

**Viewmodel** ("pistol looked better ... wrong angle and the hand is still mangled", "add
aim down sights", then "does this gun look good?" → yes to glove/smaller/side-on)
- The mangling: WRAD finger bones curl on **negative X**; both earlier fits bent them
  backwards. New hand-first fit `tools/blender/viewmodel_fit.py` (exact export command in
  its header). Black glove material, smaller, yawed 22° / canted 12°. Rest pose is the
  identity; `GRIP`/`SIGHT_*`/`GUN_UP` constants come from the fit's `grip.txt`.
- **ADS is on RMB** — he wrote "left click", but LMB is fire. Not yet confirmed by him.
- ⚠ The fit needs WRAD `arms.blend` and the Kenney Blaster Kit, which only exist in an
  old session's `/tmp` scratchpad and may be gone. If he wants another gun pass, re-download
  them (WRAD: wriks.itch.io/wrad-arms, CC0; Kenney blaster-kit 2.1) before anything else.

**Level** ("more verticality, more complex", "new defensive areas, a secondary objective and
area", "an area with platforming, more things to jump on")
- `sec_cmp_vertical`: car-park deck (avenue, 3.0), west gantry (3.0), courtyard podium
  (2.85), plant-room top + water tank on the main roof, sentry G10. Tags C23–C25, R04–R05.
- `sec_annex` — **the Scoring Annex**, north of the avenue (the old north boundary has a
  checkpoint gap and a 1.0m crawl). Two-storey building, server room, fire stair, roof;
  checkpoint chicane + sandbag nest, dock, generator strip; guards N1–N6; 3 alarm stations.
  Tags N01–N12. Skyline pushed north to make room.
- **Secondary objective** (`secondary_score.gd`, `wipe_terminal.gd`): optional; hold F on the
  SCORE SERVER (3s, loud) → billboard reads ERR, PA line, HUD OPTIONAL line, end-screen line.
- `sec_crane_run` (N13): deck crates → catwalk on the annex wall → hung pallets → a sliding
  crane pallet (AnimatableBody3D) → container → pallets → annex roof behind N5. Mantles in
  `_compound_systems`; jumps are *played* by `smoketest_jumps` (real input/physics). Roof
  plant units on the main roof as a hop circuit.

**Look** ("like a real game, at least as good as Cruelty Squad, original, kind of trippy")
- `fx/post_fx.gd` + `assets/shaders/trip.gdshader`: dithered banding, edge fringe, acid
  shadows, warp, grain, vignette; alarm/hurt push it. OPTIONS > TRIP FILTER disables it.
- `SecCmpPerimeter.night()`: `assets/shaders/sky.gdshader`, filmic, glow, SSAO, volumetric
  haze. Tuned twice already (first pass was milky; neon first pass washed the frame).
- Our own art: `tools/gen/make_textures.py` → posters, graffiti, wallpaper (interior
  partitions, `BuildUtils.WALLPAPER`), terrazzo (`FLOOR`), 8 faces on every `Humanoid`.
  `sec_art`: posters/tags snapped to walls by raycast, neon tubes + signs, the courtyard
  mast eye and an annex eye (`fx/watcher_eye.gd`), CCTV cameras, CONSENTO statues
  (`tools/blender/mascot.py` → `assets/models/custom/consento.glb`).
- `Props._lit`: Kenney's unshaded materials (trees, lamps) now take light.

**Opening** ("opening visual novel cinematic ... I will iterate, don't put a ton of effort in")
- `ui/screens/screen_intro.gd`, OPENING on the title menu; `tools/intro_shot.gd`.
  Five scenes in crude 2D shapes with slow pushes and moving parts. **Content calls I made,
  and told him:** the moped courier doing tech support is a gig-economy joke, not an ethnic
  caricature; the burger boards are a parody brand (McGRATITUDE), not McDonald's; the
  sexualised ad is suggestive, not explicit. He may push back — if he asks for the
  caricature or the real trademark, explain why not and offer the satirical alternative.

## Unverified / likely feedback

- Feel of everything above is untested by hands: ADS sensitivity/zoom, the gun size,
  whether the trip shader is too much (strength is a uniform; levels 22), volumetric fog
  cost, the crane run's difficulty (the slider pallet especially), annex difficulty.
- Defence plan may make the post-alarm campus too hard; knobs are `DefencePlan.SEARCHERS`,
  `POSTS`, `GuardBrain.LEASH/HOLD_LOOK/HOLD_CALM`.
- `game.gd` is 306 lines (over the 250 rule, pre-existing); split it before adding more.
- The end screen shows "SECONDARY: SCORE INTACT" on MERIDIAN too (no secondary there).
- Room-name tags are on by default (playtest); `SecRoomNames.SHOW` turns them off.

## Suggested next steps (if he doesn't steer)

1. Ask him to play: the gun + ADS, an alarm in the courtyard, the annex via each of its three
   ways in, the crane run, the opening.
2. Kick / wall-kick movement (from the r5 Cruelty Squad research in HANDOFF-opus-r5.md) —
   it's what would make the new verticality fun.
3. Second pass on the opening once he gives notes (real art: render stills from the level,
   or paint panels with the texture generator's style).
4. Commit when he says so.
