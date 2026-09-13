# CLAUDE.md — Graybox Protocol (Godot 4)

> Project instructions for AI assistants (Claude Code in VS Code, etc.) working on this repo.
> The human (Gregory) is technical, terse, and the final judge. Keep answers short with key
> reasons. Do the work; don't narrate the work.

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
- **Zero external assets**: all geometry is gray-box primitives, all SFX synthesized in code.
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
    `health.gd`, `mantle.gd`, `interactor.gd` and one kit.
    - `player/kits/` — **one file per operative**: `kit_regular.gd`, `kit_wizard.gd`,
      `kit_chad.gd`, sharing `kit_base.gd`. Changing a character means opening exactly
      one file. Do not split a moveset across files.
  - `enemies/` — `guard.gd` root composing `guard_senses.gd`, `guard_brain.gd`,
    `guard_combat.gd`, `guard_body.gd`; plus `target.gd` (VIP).
  - `world/` — `level_builder.gd` (orchestrator + the full floor plan in its header),
    `build_utils.gd` (box/label/plate/tunnel/stairs helpers), `guard_posts.gd`.
    - `world/sections/` — one builder per area, each with a `build(root, game)`:
      `sec_street`, `sec_tower`, `sec_undercroft`, `sec_courtyard`, `sec_dock`,
      `sec_mezzanine`, `sec_boardroom`, `sec_roof`.
    - `world/interactables/` — `interactable.gd` base plus `locked_door.gd`,
      `breakable_wall.gd`, `warded_seal.gd`.
  - `ui/` — `hud.gd` root composing `hud_vitals/abilities/feed/reticle/prompt.gd`
    (all extend `hud_panel.gd`); `ui/screens/` holds `screens.gd` (router) and one
    file per screen over `screen_base.gd`.
  - `fx/` — `audio_synth.gd` (synthesized SFX), `projectile.gd`, `meteor.gd`.
- `.godot/`, `*.import` files — generated. Never edit by hand.

## Core design — do not break these without asking

1. **Three characters**, data-driven, each with its own traversal verbs:
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
3. **One level, MERIDIAN CAPITAL** — five floors: undercroft (-4), ground (0),
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
6. **Gray-box aesthetic is intentional.** Don't pretty it up unless asked.
7. **No health regeneration.** Damage is permanent for the run — that is what makes the
   armour loadout a real choice and each mission a single life. Guards hit for 22.
8. **Guard fire is telegraphed, never instant.** `guard_combat.gd` holds a visible aim state
   for `aim_time` (0.55s) before firing, and every shot draws a `Tracer`. Both exist so the
   Wizard's 0.25s dodge has something to be timed against, and so a 22-damage hit is never
   an unannounced chunk of the health bar. Do not shorten the wind-up below ~2x the i-frames.

## Hard-won invariants — these bugs all shipped once

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

## Controls

WASD move · mouse look (captured) · LMB attack · RMB charge (wizard) · E ability
(Meteor / slam) · **F interact** (pick / unward / breach) · C/Ctrl crouch ·
Shift sprint, but **dash for the wizard** · Space jump / mantle · ESC pause.

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
