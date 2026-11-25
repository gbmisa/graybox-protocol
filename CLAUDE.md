# CLAUDE.md — Graybox Protocol (Godot 4)

> Project instructions for AI assistants (Claude Code in VS Code, etc.) working on this repo.
> The human (Gregory) is technical, terse, and the final judge. Keep answers short with key
> reasons. Do the work; don't narrate the work.
>
> **Starting a session? Read `docs/NEXT-SESSION.md` — the one handoff file** (current state,
> Gregory's standing rules, unverified items, open decisions, how to verify). Don't read
> `docs/BUILD-LOG.md` (history) or `docs/LEVEL-compound.md` (84KB design ref) whole — grep them.
> Before feel/animation/smoothing work, read `docs/BRIEF-animation.md`.
>
> **Finishing a large task? Write the handoff yourself, unprompted** (Gregory, r8: "always write a
> handoff when you finish a large task. So I don't have to send you a message"). **Rewrite
> `docs/NEXT-SESSION.md` in place** (state, what was asked in his words, what was built, what is
> unverified, next steps — replace the previous round's section, don't stack it) and append the
> round to `docs/BUILD-LOG.md` — before you report back, not after he asks. No per-round
> HANDOFF files.
>
> `screenshots/` is throwaway tool output (gitignored); delete stale frames when a round ends.

## What this is

Graybox Protocol is a first-person immersive-sim prototype in the vein of **Cruelty Squad**
and **Dishonored**: gray-boxed levels, assassination objectives, multiple entries/exits per
level, and sharply distinct playable characters. Single-player only.

This prototype is the **mechanics testbed** for a larger game. The roadmap: character skill
trees, more levels, and branching storylines that route each character through the same
levels with different motivations. Build everything so those can bolt on later.

## Creative direction

Dark satire in the Cruelty Squad tradition. Tone is abrasive and politically charged
**on purpose** — it is satire, and in-game writing (briefings, signage, NPC barks) should
punch in that direction. Don't sanitize it. Do keep the satire legible (the world pushes
back on its worst characters; consequences are ironic, not endorsing).

## Tech

- **Godot 4.x** (see `project.godot` for exact version), GDScript, default renderer.
- **CC0 assets only** (Kenney models/sounds/fonts, WRAD arms, Poly Haven textures — see
  `ASSETS.md`). Level geometry is still built in code from primitives; assets *dress* it
  (`Surfaces` textures every box by palette role, `Props` places models). Any new asset
  must be CC0 or equivalent and listed in `ASSETS.md`. Paid sounds (e.g. Gamemaster
  Audio) go in `assets/audio/sfx/` as drop-ins — never commit them to a public repo.
- Targets: **Linux** (dev machine), **Windows** (future Steam release).

## Project layout

- `project.godot` — project settings. Don't hand-edit unless you know why.
- `export_presets.cfg` — "Linux" and "Windows Desktop" export presets. Don't touch internals
  unless fixing an export.
- `scenes/` — `main.tscn` (root node + GrayboxGame script only). Everything else —
  title/select/briefing/pause/win/lose screens, HUD, level geometry, player,
  guards, target — is built programmatically from scripts.
- `scripts/` — gameplay code, split so the unit of editing matches the unit of thought.
  **No file exceeds 250 lines**; keep it that way.
  - `core/` — `game.gd` (GrayboxGame: spawning + world events), `mission_flow.gd`
    (screen state machine), `input_actions.gd` (InputMap registration).
  - `data/` — all tuning, no behaviour: `characters.gd`, `armors.gd`, `abilities.gd`,
    `guard_data.gd`, and `verbs.gd` (the traversal capability matrix).
  - `player/` — `player.gd` is a thin root composing `movement.gd`, `look.gd`,
    `health.gd`, `mantle.gd`, `interactor.gd`, `footsteps.gd` and one kit;
    `viewmodel.gd` (hand + pistol, recoil, flash, sway, bob, aim down sights; the GLB is
    exported from `art/viewmodel.blend`, which Gregory edits — the game reads its
    `grip`/`muzzle`/`sight_*` empties, see ASSETS.md) is created by the kit
    that holds something (the Regular); it renders in its own SubViewport with a
    narrow-FOV camera under the HUD (see its header) — don't parent it to the camera.
    r8: `weapons.gd` (PlayerWeapons — the Regular's arsenal: slots 1-5, wheel,
    reload, ammo, pellets, knockback, gibs; tuning in `data/weapons.gd`) and
    `player/tools/` (`tool_kick.gd` V, `tool_grapple.gd` Q, `tool_nightvision.gd` N,
    `tool_eat.gd` F on a corpse), all composed by `kit_regular.gd` — shared
    components like movement, so a future operative can carry them too.
    r9: `weapon_reload.gd` (WeaponReload — mag reloads, instant throwables,
    shell-at-a-time with `shell_time`); `ui/hud_scope.gd` (the rifle's 3x
    eyepiece; `WeaponData.zoom_for` turns `scope` into a true magnification).
    - `player/kits/` — **one file per operative**: `kit_regular.gd`, `kit_wizard.gd`,
      `kit_chad.gd`, sharing `kit_base.gd`. Changing a character means opening exactly
      one file. Do not split a moveset across files.
  - `enemies/` — `guard.gd` root composing `guard_senses.gd`, `guard_brain.gd`,
    `guard_combat.gd`, `guard_body.gd`; plus `target.gd` (VIP) and `civilian.gd`
    (bystanders that wander and panic). `guard_nav.gd` bakes the navmesh from the level's
    static colliders (rebaked when a `RemoteDoor` changes); `nav_walker.gd` follows it.
    Bodies are `world/humanoid.gd`: CC0 Quaternius bodies + animations
    (`tools/blender/people.py` bakes them, with a clothing mask in the vertex
    colours that `world/person.gdshader` paints garishly; then
    `tools/blender/people_lowpoly.py` decimates them to ~1.5k faces, flat-shaded,
    to match the Kenney props); blood is `fx/gore.gd`.
  - `world/` — `levels.gd` (level id -> builder), `level_meridian.gd` and
    `level_compound.gd` (orchestrators; each header holds that level's plan),
    `build_utils.gd` / `wall_utils.gd` (geometry helpers; `WallUtils.wall` cuts
    doors and windows with headers and sills), `surfaces.gd` (palette colour ->
    triplanar photo texture), `ramp_builder.gd` (stairs/ramps as wedges that never
    poke past their footprint), `props.gd` (Kenney model placement + box collision),
    `guard_posts*.gd`,
    `mission_compound.gd` (level one's doors, switches, target, extractions,
    PA lines, and its ALARM consequences), `light_tiers.gd`, `hazard.gd`.
    - `world/sections/` — one builder per area, each with a `build(root, game)`.
      MERIDIAN: `sec_street`, `sec_tower`, … HOLLOWAY ROAD: `sec_app_estate`,
      `sec_app_canal` (the approach), `sec_app_heights` (its high routes),
      `sec_cmp_*` (the campus; `sec_cmp_climbs` = fire escape, scaffold,
      boiler climb; `sec_cmp_billboard` = board + maintenance scaffold + catwalk;
      `sec_cmp_exits` = van, helicopter, helipad stair; the avenue car went in r9), `sec_props_*`
      (set dressing tables) and `sec_skyline` (city beyond the bounds).
      r6: `sec_cmp_vertical` (car-park deck, west gantry, podium, plant-room top,
      roof plant units), `sec_art` (posters, graffiti, neon, score screens, the
      watching eyes, CCTV, the CONSENTO statues). r7: the Scoring Annex
      district north of the avenue — `sec_annex` (walls, Consent Way, yards),
      `sec_annex_building`, `sec_annex_site` (the Consent Tower construction
      site: the long plank/ladder platforming route onto the annex roof);
      `sec_trip` (TripZone boxes). r9: `sec_r9_grapple` (grapple-only
      perches with ammo caches — billboard top, Holloway House roof, crane
      counterweight; `MissionCompoundData.CACHES`). Tools read
      `LevelCompound.sections()`, so a new section is never missing from them.
    - `world/interactables/` — `interactable.gd` base plus `locked_door.gd`,
      `breakable_wall.gd`, `warded_seal.gd`, `switch.gd` (no-verb lever),
      `remote_door.gd` (opened/locked by the level, never by hand).
  - `world/surveillance.gd` — what wiping the Score switches off (billboard,
    score screens, CCTV, eyes, door locks, alarm posts); `Surveillance.screen`
    makes a score screen. `world/ladder.gd` — ladders (climb zones checked by
    `PlayerMovement._climb`). `fx/trip_zone.gd` + `trip_parts.gd` +
    `trip_audio.gd` — the trip zones: wall eyes that follow you, faces at the
    edge of vision, a face behind you; drives PostFx's `trip`.
  - `world/defence_plan.gd` — on ALARM, who searches and who mans which of
    `MissionCompoundData.POSTS`. `world/secondary_score.gd` + `interactables/
    wipe_terminal.gd` — the optional objective (wipe the Consent Score).
  - `fx/post_fx.gd` + `assets/shaders/trip.gdshader` — the screen shader (OPTIONS >
    TRIP FILTER); `assets/shaders/sky.gdshader` — the night sky; the level's
    Environment is `SecCmpPerimeter.night()`. `fx/watcher_eye.gd` — things that
    turn to look at you. Our own art: `tools/gen/make_textures.py` (posters,
    graffiti, wallpaper, terrazzo, faces -> assets/textures/gen/) and
    `tools/blender/*.py` (the viewmodel fit, the CONSENTO mascot).
  - `ui/screens/screen_intro.gd` — the OPENING: Postal 4-style comic pages;
    the words and panel list are `data/intro_script.gd` (Gregory writes it).
    Panel art: `tools/intro_panels.gd` renders staged stills,
    `tools/gen/comicify.py` inks them into `assets/intro/` — or drop in a PNG.
  - `core/alert_state.gd` — building-wide CALM/ALARM; calls the level's
    `mission.on_alarm()`. `core/settings.gd` — options persisted to
    user://settings.cfg (volume, sensitivity, FOV, invert Y, fullscreen, vsync,
    room tags, weapon bob).
  - `ui/` — `hud.gd` root composing `hud_vitals/abilities/feed/reticle/prompt/
    subtitle.gd` (all extend `hud_panel.gd`; PA lines go through `hud.say()` as
    subtitles); `ui_theme.gd` (the menu look); `menu_backdrop.gd` (the live level
    behind the main menu — skipped headless and with `-- --no-backdrop`);
    `ui/screens/` holds `screens.gd` (router, layer 10 over the HUD) and one file
    per screen over `screen_base.gd`: title (main menu), missions, options,
    credits, select, briefing, pause, end.
  - `fx/` — `audio_synth.gd` (SFX by name: drop-in file -> our generated
    `assets/audio/gen/<name>_<n>.wav` from `tools/gen/make_sfx.py` -> Kenney sample ->
    synthesized fallback), `impact.gd` (sparks, bullet holes), `explosion.gd` +
    `grenade.gd`, `sound_at.gd` (3D one-shot at a point), `gore.gd` (`gib` on overkill), `atmosphere.gd` (ambient light by light tier + the alarm's
    siren / red pulse), `projectile.gd`, `meteor.gd`.
- `.godot/`, `*.import` files — generated. Never edit by hand.

## Core design — do not break these without asking

1. **Three characters**, data-driven, each with its own traversal verbs.
   **Roster is currently the Regular only** (`CharData.ids()`); the Wizard and
   Chad keep their data and kits and come back by editing that one line.
   - `THE REGULAR` — HP 100, speed 7.0. Hitscan pistol (25 dmg, LMB). Crouches to 0.85m.
     Verbs: **lockpick**, **crawl**. Mantle 1.2m. Stealth specialist, fragile.
   - `THE WIZARD` — HP 60, speed 6.6. LMB: arcing fireball (35 dmg). Hold RMB: charged
     bolt, ~1s charge, long range (70 dmg). E: **Meteor** — ground-targeted, 1.1s
     telegraph, 90 dmg @ 7m plus a burn pool. Shift: **arcane dash** with i-frames,
     which *replaces sprint*. Crouches to 0.85m. Verbs: **arcane**, **crawl**.
     Mana resource with regen. Glass cannon. **No blink** — the dash is the mobility tool.
   - `GIGA CHAD` — HP 250, speed 7.6, sprint 1.6x. LMB: 3-hit punch combo (55 dmg,
     knockback). E: ground slam, AoE 60 dmg + knockback + camera shake (8s cd).
     Verbs: **smash**, mantle **2.5m**. Crouches only to 1.45m, so he **cannot crawl**.
2. **Armor is a pre-mission LOADOUT choice, never a mid-game toggle.** Cruelty Squad rules —
   protection costs speed. Applies to all characters:
   - STREET CLOTHES: damage taken x1.0, speed x1.0
   - LIGHT VEST: damage taken x0.65, speed x0.88
   - HEAVY PLATE: damage taken x0.35, speed x0.70
3. **Level one is HOLLOWAY ROAD** (`level_compound.gd`, design in
   `docs/LEVEL-compound.md`): the Regular with his base kit, **no lockpicks**.
   A long approach (estate -> ring road -> canal -> terraces, z 46-196) to the
   campus, with the billboard in view most of the way. Default level id is
   still `meridian` because `tools/smoketest.gd` relies on it.
   **MERIDIAN CAPITAL** (the original testbed) — five floors: undercroft (-4), ground (0),
   mezzanine (6), boardroom (12), roof (18.6). Tower footprint x [-30, 30], z [-40, 10].
   The full floor plan lives in the `level_builder.gd` header — read it before moving
   any geometry. **Routes are mostly hard-gated**: each operative has their own way in,
   and they converge on the mezzanine.
   - REGULAR: culvert crawl → undercroft → MAINTENANCE DOOR [lockpick] → service stair
   - WIZARD: WARDED GATE [arcane] → courtyard → vent shaft (dash the 7m gaps)
   - CHAD: DOCK SHUTTER [smash] → COLLAPSED WALL [smash] → container stacks (2.3m mantles)
   Then three gated doors into the boardroom, one per operative. Three extractions:
   helipad (roof), van (street), sump outflow (**crawl-only**, so Chad cannot use it).
   Kill target → reach an extraction → win.
4. **Gating is enforced two different ways, and the distinction matters:**
   - *Interaction gates* (lockpick / arcane / smash) are checked in script. An
     `Interactable` lists which verbs open it and what each costs; omitting a verb is
     how a hard gate is authored. A character without the verb sees a greyed prompt
     naming what it would take — hard gates must always explain themselves.
   - *Crawl gates* are *not* scripted. They are pure collision: crouching resizes the
     capsule, crawl gaps are built exactly **1.0m** tall, and Chad's 1.45m floor means
     he physically does not fit. Never add a character check to a crawl gap.
5. **Enemy AI stays simple**: patrol waypoints → suspicious (investigate, "?" indicator) →
   alert (chase + shoot, "!" indicator). Vision cone + line-of-sight raycast, detection
   meter (crouch/distance slow it; sprint/proximity speed it), noise attraction from
   gunfire/explosions. Guards: HP 50, hitscan pistol with spread. No flanking, no squads.
   Guard gunfire deliberately emits **no** noise event — it would cascade alerts.
   **An alerted guard is not the alarm** (Gregory, 2026-10-01): he runs to an alarm station
   (`AlarmStation`, `GuardBrain._run_to_station`) and presses it; kill him on the way and
   there is no alarm. Sirens are 3D horns (`AlarmSiren`); never play the siren 2D.
   **Alarm posts are a run, not a reach** (Gregory, r7): every guard walks 12m+
   to his post (G5/G7 excepted); `_compound_systems` enforces it,
   `tools/alarm_reach.gd` prints the table.
   **The alarm is a defence, not a rush** (Gregory, r6): one runner per station; on alarm
   one guard searches and the rest man `MissionCompoundData.POSTS` (`DefencePlan`) and
   fight from them within `GuardBrain.LEASH`, falling back when they lose you.
   **No tracking through walls** (Gregory, r9): an alerted guard who loses sight
   for `LOST_GRACE` goes to `last_seen`, looks round, and drops to SUSPICIOUS after
   `HUNT_TIME`. **The rifle alerts** (WeaponData `alerts`): every guard in its 75m
   earshot goes ALERT hunting the shot, walls or not.
6. **Past grayboxing now (Gregory asked, 2026-09-30):** textures, props, skyline,
   viewmodel. Keep it Cruelty Squad-crude rather than realistic; tune by feel.
7. **No health regeneration.** Damage is permanent for the run — that is what makes the
   armour loadout a real choice and each mission a single life. Guards hit for 22.
   The one way back up is Cruelty Squad's: **eat a corpse** (`ToolEat`, +5 — Gregory, r9 —
   once per body, 2s standing still) — health taken from the dead, never given over time.
8. **Guard fire is telegraphed, never instant.** `guard_combat.gd` holds a visible aim state
   for `aim_time` (0.55s) before firing, and every shot draws a `Tracer`. Both exist so the
   Wizard's 0.25s dodge has something to be timed against, and so a 22-damage hit is never
   an unannounced chunk of the health bar. Do not shorten the wind-up below ~2x the i-frames.

## Hard-won invariants — these bugs all shipped once

- **Guards path on a navmesh, never in straight lines.** `Guard.move_to` -> `NavWalker`
  -> `GuardNav`. New collidable level geometry is picked up automatically at bake; doors
  that change state must go through `RemoteDoor` (it requests the rebake). Don't put a
  colliding prop in a gap narrower than ~1.0m beyond its width — the agent is 0.8m wide.
- **Guards are 2.1m tall (head box), and the navmesh knows it** (`GuardNav.AGENT_HEIGHT`
  2.1, `CELL_H` 0.1 — at 0.2 Recast rounded a 2.4 door header to "too low" and the lobby
  became an island). Any overhead under ~2.2m that guards should pass needs raising; the
  portico roof was 2.0 and wedged them. Guards' sight/shot rays ignore other guards
  (`Guard.ray`), and `NavWalker.steer` separates them and sidesteps when stuck.
  `tools/smoketest_guard_stuck.gd` shoots every guard near three spots and fails on any
  that freezes — run it after touching guard movement or campus geometry.
- **Player gravity is `PlayerMovement.PLAYER_GRAVITY` (24), not project gravity (9.8).**
  Jump heights in LEVEL-compound.md still hold; horizontal jump range is ~40% shorter.

- **Line-of-sight rays must exclude the target.** `Guard.ray()` takes `also_exclude` for
  this. Ask "is anything BETWEEN us"; a ray that ends inside the target's own capsule always
  reports a hit, which left guards blind for the entire early life of the project.
- **Stairs are ramps.** Godot's `CharacterBody3D` has no step-up, so a stack of risers is a
  stack of walls. `BuildUtils.stairs()` builds one sloped collider with tread lines drawn on
  it; keep rise/run under 1.0 so the slope stays inside `floor_max_angle`. `movement.gd` also
  carries a step-up assist for incidental ledges up to 0.45m.
- **A crawl gate is only as strong as the geometry around it.** The storm drain was a
  free-standing box with a 1.4m roof and a 1.84m jump walked straight over it. Every
  `BuildUtils.tunnel()` needs its surroundings sealed, and `tunnel()` builds no end caps —
  add your own or the player walks out of the world.
- **Every enclosed space needs its own lamp.** There is no global illumination; an interior
  with no light in it is a black void. Use `BuildUtils.lamp()` / `lamps()`.
- **Check for soft-locks.** Any space you can fall into needs a way out that the operatives
  who can reach it can actually use.
- **Ramps are wedges, not rotated boxes.** A rotated box's lower corner pokes out past the
  top of the stair by thickness × sin(slope); the west stair's came 0.75m through the foyer
  wall (G12). `RampBuilder` cuts the top end vertical and tapers to the base.
- **Parked vehicles are `Props.vehicle()`, never `place()`**: uncapped at one scale
  (`VEHICLE_SCALE` 1.4), collision from the bodywork's own mesh (the systems test checks
  hitbox roof/flank against the model); taller vehicles are cover, not a step; trees are `Props.tree()` (trunk only).
- **Furniture keeps every doorway and the middle of every room clear**; the door test
  probes at knee height (0.35m) because tables are under the 0.9m probe.
- **Props never go on a patrol lane or in a doorway.** A colliding prop in a lane strands
  the guard walking it. Lanes are listed in each `sec_props_*` header; clutter that could
  be anywhere is `collide = false`.

## Controls

ESC pause (resume / restart / options / main menu / desktop).
WASD move · mouse look (captured) · LMB attack · RMB aim down sights (Regular) /
charge (wizard) · E ability (Meteor / slam) · **F interact** (pick / unward / breach;
hold on a corpse to eat) · C/Ctrl crouch · Shift sprint, but **dash for the wizard** ·
Space jump / mantle · 1-5 / wheel weapons · R reload · V or MMB kick · Q grapple (hold;
hooks anything — a wall near its top hauls you over, a person gets yanked to you) ·
N night vision · ESC pause. Fall below y -30 (off the map) and you die.

## Running

- Open: Godot editor → Import → select `project.godot`.
- Play: **F5** in editor (F6 = current scene).
- Headless validation (catches GDScript parse errors, no display needed):
  `godot --headless --path . --import`
- Level and systems check — **run this after any geometry or sensing change**:
  `godot --headless --path . --script res://tools/smoketest.gd`
  It raycasts every waypoint on all three routes for floor and headroom, asserts the crawl
  gaps are 1.0m and sealed from above, and regression-tests guard vision, the freight-bay
  escape and no-regen. Add a case to it whenever you fix a bug of a kind it would have caught.
- Level one: `tools/smoketest_compound.gd` (floor, headroom, openings) and
  `tools/smoketest_compound_systems.gd` (mantle reach, vaults, crawl gates,
  collision layers, headshots, sentry facing, alarm, unlabelled exits).
  Visual: `tools/screenshot_compound.gd` (magenta sky = holes),
  `tools/screenshot_approach.gd` (real lighting), `tools/shot.gd -- views.txt
  [--magenta]` (ad-hoc views, one `name ex ey ez lx ly lz` per line) and
  `tools/smoketest_jumps.gd` plays the Consent Tower site's jumps with the real player;
  `tools/intro_shot.gd` photographs the opening's comic pages; `people_shot.gd`,
  `trip_shot.gd` and `alarm_reach.gd` (headless) are r7's.
  r8: `smoketest_arsenal.gd` (every weapon kills, reload, grenade, kick, grapple, night
  vision, eating, ammo drops) and `combat_probe.gd` (are alerted guards dangerous? fails
  under 6 dmg/s at a spot with fighters) — both headless. r9: `smoketest_r9.gd` (one
  case per r9 complaint: grenades, pump, drops, scope, NV, caches, yank, rifle alert,
  last_seen, fall death) and `r9_shot.gd` (NV off/on, scope, perches -> screenshots/r9_*). Review packs: `judge_pack.gd`
  (11 real-game frames -> screenshots/judge/), `map_plan.gd` + `tools/gen/draw_plan.py`
  (measured floor plans with room tags -> screenshots/plan_*.png).
  Screenshots render Forward+ under xvfb on this machine's GPU (drop the
  `--rendering-method gl_compatibility` flag to see the real look).
  `tools/play_shot.gd [-- x y z yaw]` (boots the real game: every menu screen, then
  the player's own view with viewmodel at rest and mid-recoil) — all need
  `xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution
  1280x720 --script …`. Add `-- --graybox` to see the untextured boxes.

## Exporting (do this FOR the user when asked — don't make him click through it)

1. First time only: Godot editor → Manage Export Templates → Download and Install.
2. GUI: Project → Export… → pick "Linux" or "Windows Desktop" → Export Project.
3. Command line (preferred — script it):
   `godot --headless --path . --export-release "Linux" ./build/graybox-protocol.x86_64`
   Windows: `--export-release "Windows Desktop" ./build/graybox-protocol.exe`

## Conventions

- GDScript 4.x, typed variables where practical. Commented sections, no clever one-liners.
- Balance numbers (damage, HP, detection rates, cooldowns) live in the data dicts — tune
  there, never in logic.
- Keep guard AI dumb on purpose (see rule 4). Complexity budget goes to character kits
  and level routing.
- New character = new data entry + select-screen card. New level = new scene + entries /
  exits / target / extraction markers wired to the mission-state script.
- After structural changes, update the layout section of this file.
- Verify with the headless import after every change that touches scripts.
