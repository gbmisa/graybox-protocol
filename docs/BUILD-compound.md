# BUILD — HOLLOWAY CAMPUS, model-by-model

Execution plan for Phase 3 of `PLAN-level-compound.md`, allocated so no step runs on a
bigger model than it needs. Design input is `LEVEL-compound.md` (r4).

## How to run this

One block per session. Between blocks: **`/clear`, then `/model <name>`**, then this one line:

```
Read docs/BUILD-compound.md and docs/BUILD-LOG.md. Do Block N only, then stop.
```

**"Only, then stop" is load-bearing.** Without it a session will roll on into the next block,
which is how the cheap work ends up running on the expensive model again.

Clearing matters too — `/model` on its own keeps the whole conversation, so a Haiku step would
inherit an Opus-sized context and cost more than the step is worth.

You can also paste a block's prompt verbatim instead; each one names its own read list and is
self-contained. Every block ends by appending three lines to `docs/BUILD-LOG.md`: what landed,
what broke, what the next block should know. That file is the handoff; keep it short.

If a block finishes and the log says something is broken, fix it in that same session before
switching — a red import or smoketest is that block's problem, not the next model's.

**Verification after every block that touches scripts:**
```
godot --headless --path . --import
godot --headless --path . --script res://tools/smoketest.gd
```
Both green or the block isn't done.

## Who does what

| Model | Gets | Doesn't get |
|---|---|---|
| **Haiku 4.5** | Data dicts, waypoint tables, verbatim transcription from the design doc, wiring a builder, find-and-edit across a named file list, running import / smoketest / export, doc sync | Anything with a judgment call |
| **Sonnet 5** | One scoped file against an existing pattern — a section builder, a component, a subclass. Most of this build | Cross-cutting state, design decisions, tone |
| **Opus 5** | Two things only: the F2 alert state machine, and the post-playtest triage in fresh context | Bulk code. It has been doing too much of it |
| **Fable 5.1** | Nothing outstanding — §13's signage and barks are already written | — |
| **Gregory** | Every gate below. The walk is the test | — |

---

# Stage 1 — something walkable, fast

The goal is your ten-minute walk, not correctness. Guards, gates and tiers come after.

### Block 1 · Haiku · Walk mode

> Read `CLAUDE.md` and `scripts/core/game.gd`. Add a debug switch that skips guard and target
> spawning so a level can be explored without being sent back to spawn: a
> `--no-guards` command-line flag read via `OS.get_cmdline_args()` in `GrayboxGame`, default
> off, checked in `spawn_mission` before `_spawn_guards`. Do not change any other behaviour.
> Verify with the headless import and the existing smoketest, then append to
> `docs/BUILD-LOG.md`.

### Block 2 · Sonnet · Level registry

> Read `CLAUDE.md`, `docs/PLAN-level-compound.md` §3.1, and
> `scripts/world/level_builder.gd`, `scripts/core/game.gd`, `scripts/core/mission_flow.gd`.
> Create `scripts/world/levels.gd` mapping level id → builder script, spawn point and guard
> posts. Rename `level_builder.gd` to `level_meridian.gd` (`class_name LevelMeridian`) with no
> behaviour change, and add `scripts/world/level_compound.gd` (`class_name LevelCompound`)
> whose `build()` returns the same dict shape with an empty level, the compound spawn at
> (0, 0, 40), and no guard posts. Point `game.gd` at the registry. MERIDIAN must still play
> identically. Verify, then log.

### Blocks 3–5 · Sonnet ×3 · The hull

Geometry and lamps only. No guards, no interactables, no light-tier volumes. Each block is one
session; they touch different files so order between them doesn't matter.

> Read `CLAUDE.md` (especially the hard-won invariants), `scripts/world/build_utils.gd`, an
> existing `scripts/world/sections/sec_*.gd` for the pattern, and `docs/LEVEL-compound.md`
> §2. Build **<the sections for this block>** as `scripts/world/sections/sec_cmp_*.gd`, each
> under 250 lines with a `build(root, game)`. Geometry, lamps and nothing else. Stairs are
> ramps; every enclosed space gets a lamp; `tunnel()` has no end caps so add them. Where the
> design doc and the geometry disagree, follow the doc and note the disagreement in the build
> log rather than silently adjusting. Verify with the headless import, then log.

- **Block 3** — `sec_cmp_perimeter` (wall, gate, gatehouse, streets, verge, east lane, west
  alley **including the outfall pit and its two ramps**) and `sec_cmp_yards` (north yard, west
  yard, courtyard, mast, refuse yard + 2.2m fences, forecourt, canopy, skip).
- **Block 4** — `sec_cmp_main_g` (§2.3 ground floor, **including the solid riser block at
  x [2,4]**), `sec_cmp_main_1f` (§2.4, **gallery floor 5.0 with solid fill beneath**), and the
  roof with its parapet gap at z [-15, -13.5].
- **Block 5** — `sec_cmp_gym` (§2.5 store, floor, mezzanine, roof with the **2.0 × 2.0** hatch,
  plant box, deck), `sec_cmp_alley` (**six crate stacks, 2.0 × 1.5, stepping 1.0m south from
  z [-20,-18.5], tops 1.15 · 2.30 · 3.45 · 4.60 · 5.75 · 6.90**, link bridge), and
  `sec_cmp_undercroft` (§2.6 boiler house, squeeze tunnel, west run, spur, both ramps — the
  hazard volume itself comes later).

### Block 6 · Sonnet · The two sweeps worth having before you walk

> Read `tools/smoketest.gd` and `docs/LEVEL-compound.md` §14. Create
> `tools/smoketest_compound.gd` following the existing file's structure, implementing **only
> cases 1, 25 and 26** — floor under every listed point, 1.8m of clear headroom on every
> walkable surface (case 25, the general form of the bug that cost the most on paper), and
> declared openings sharing at least 1.2m of edge (case 26). Build the point list from §4's
> three vectors. Report each failure as a coordinate. Verify, then log.

### Block 7 · Haiku · Wire it and run it

> Read `docs/BUILD-LOG.md` and `scripts/world/level_compound.gd`. Call every `sec_cmp_*.gd`
> builder from `LevelCompound.build()`. Run the headless import, fix parse errors only, then
> run both `tools/smoketest.gd` and `tools/smoketest_compound.gd` and paste the full output
> into the build log. Do not fix geometry failures — list them.

## ▶ GATE A — you walk the hull

`--no-guards`, all three characters, ten minutes. What's too narrow, what you can't reach,
what's missing, what reads wrong. Expect this to invalidate parts of r4; that's the cheapest
outcome available and it's why this gate is early.

**Don't judge vertical gates yet.** Mid-air mantle still stacks on the jump, so Chad reaches
5.4m instead of 2.5m and every roof will lie to you until Block 8.

---

# Stage 2 — make the gates real

### Block 8 · Sonnet · Traversal prerequisites

> Read `docs/PLAN-level-compound.md` §3.3 and Phase 3a, `docs/LEVEL-compound.md` §0 and the
> appendix, and `scripts/player/mantle.gd`, `scripts/player/movement.gd`,
> `scripts/data/verbs.gd`. Two changes.
> **D14:** `mantle.gd` records the floor height at the last `is_on_floor()` frame and measures
> `rise` from it, so a mid-air grab cannot exceed what a floor mantle reaches.
> **Squeeze:** `verbs.gd` gains `squeeze_h: 0.5` and `squeeze_r: 0.25` on the Wizard only;
> `movement.gd` gets a third capsule state on a held key. `_resize_capsule` must write
> **radius and height** — radius first when shrinking, height first when growing, because
> Godot clamps `radius ≤ height / 2` in the setters — and restore `BODY_RADIUS` on stand-up.
> Speed ×0.4, 8 mana/s, and `player._regen_mana` skips while squeezed. No character checks
> anywhere; collision does the gating. Add smoketest cases: a 2.2m ledge is unreachable to a
> 1.2-mantle capsule by any jump and a 1.6m one is; after a squeeze-and-stand cycle the
> capsule reads radius 0.4 and height 1.7. Verify, then log.

## ▶ GATE B — you walk the vertical

Chad: from the ground, guess which roofs are yours, then try them. Every guess should be
right. Wizard: the squeeze, and the 6.8m crawl under the west yard. ~10 min.

### Block 9 · Haiku · Two mechanical corrections

> Read `docs/LEVEL-compound.md` appendix. Two edits, both exact.
> **Collision masks (H3):** set `collision_mask = 3` in the constructors of `Player`,
> `Guard` and `Target`, and add `q.collision_mask = 1` after every
> `PhysicsRayQueryParameters3D.create(...)` in `kit_base.gd`, `kit_wizard.gd`,
> `projectile.gd`, `guard.gd` (`ray`), `mantle.gd`, `movement.gd` and `interactor.gd`. Add a
> `LAYER_BODY_ONLY = 2` constant and a `layer: int = 1` parameter to `BuildUtils.box()`.
> **Sentry facing (H4):** `guard_posts.gd` entries may carry `facing` (a yaw) and `wait` (per
> waypoint, default 1.0). `Guard` stores `facing`; in `guard_brain._patrol`, when
> `waypoints.size() <= 1`, call `guard.face(facing, delta)` instead of only `stop()` — so the
> facing is restored every time the sentry returns to PATROL, **not** once at setup.
> The existing guard-vision smoketest case must stay green. Verify, then log.

### Block 10 · Sonnet · Combat prerequisites

> Read `docs/PLAN-level-compound.md` Phase 3a and `docs/LEVEL-compound.md` §3 and appendix.
> **D12:** `guard_body.gd` gains a separate head shape inside the head mesh — centre y 1.95,
> mesh spans 1.775–2.125, body capsule tops out at 1.75 and must not overlap it — both shapes
> on the guard's body. `Guard.take_hit(dmg, shape_idx)` applies `headshot_mul` 2.5; the
> Regular's hitscan and `projectile.gd` pass the shape index. Same for `target.gd`.
> **Silencer:** a pre-mission loadout row beside armour — `SUPPRESSED {damage_mul 0.7,
> noise 0}` / `LOUD {1.0, 25}` — read by `kit_regular.gd`, shown on the select card, never a
> mid-run toggle. Smoketest: a ray at 1.95 reports head, at 1.2 reports body, the head shape's
> AABB lies inside the head mesh's, and 25 × 2.5 kills a 50 HP guard. Verify, then log.

### Block 11 · Sonnet · World systems

> Read `docs/LEVEL-compound.md` §2.6, §7 and the appendix, and `scripts/world/build_utils.gd`,
> `scripts/enemies/guard_senses.gd`. Three small additions.
> `BuildUtils.light_tier(aabb, tier)` → an `Area3D` tagged PITCH/DARK/LIT plus matching floor
> tint and lamp energy; `player.movement.light_tier`; `guard_senses._rate()` multiplies by
> `GuardData.stats()["tier_mul"]`. **No HUD element** — D11.
> `world/hazard.gd`: an `Area3D` dealing damage per second through `player.take_damage`, so
> armour and i-frames both apply. The puddle is 95 dmg/s.
> `world/interactables/switch.gd`: an `Interactable` with no verb requirement that fires a
> game event — the mast isolator, the gate lever, the panic-room release.
> Also add `billboard: bool = true` to `BuildUtils.label()`. Verify, then log.

### Block 12 · Opus · The alarm

The only genuinely cross-cutting piece left, and the one holding up the most.

> Read `docs/PLAN-level-compound.md` §3.5, `docs/LEVEL-compound.md` §6, and
> `scripts/core/game.gd`, `scripts/enemies/guard.gd`. Build `scripts/core/alert_state.gd`:
> the SUSPICIOUS/ALARM state machine, the target's flee-to-panic-room behaviour, reinforcement
> spawning under the §5 policy, the CSD door pair locking, and 60s decay. `emit_noise` keeps
> its radius semantics and gains one rule on top: radius ≥ 25 with a guard inside 12m raises
> ALARM. Note in the build log that the level's rush test depends entirely on the flee
> behaviour — Chad reaches the hall ~16s from spawn and the only thing making that legal is
> that the target has left. Verify, then log.

---

# Stage 3 — populate

### Block 13 · Haiku · Data, verbatim

> Read `docs/LEVEL-compound.md` §5, §6, §9 and the appendix. Transcribe, changing nothing:
> `scripts/world/guard_posts_compound.gd` — the nine posts with waypoints, facings and waits;
> `scripts/data/mission_compound.gd` — extractions (E1 at (-38, -2.2, 6) r 3.5, E2 at
> (23, 12.0, -8) r 2.5, E3 at (0, 0, -34) r 3.5), panic room door override, R-post spawn
> policy, the CSD pair, decay 60s, the tier volumes with their y ranges, the hazard volume.
> If any number in the doc looks wrong, log it — do not correct it. Verify, then log.

### Block 14 · Sonnet · Interactables and extractions

> Read `docs/LEVEL-compound.md` §2.3, §2.5, §9 and `scripts/world/interactables/`. Place every
> gate as an `Interactable` instance: the warded boiler door, the cracked wall, the four
> lockpick doors, the panic-room door with its per-verb override, the barred window's rods on
> `LAYER_BODY_ONLY`, the CSD pair, the three switches. Add the extraction zones, unlabelled,
> prompt on arrival only. Verify, then log.

### Block 15 · Haiku · Signage and the rest of the smoketest

> Read `docs/LEVEL-compound.md` §13 and §14. Place the eighteen signs as `BuildUtils.label()`
> plates, wall-mounted ones with `billboard: false`, text verbatim. Then extend
> `tools/smoketest_compound.gd` with the remaining cases from §14 (2–24, 27–29), following the
> structure Block 6 established. Each case must fail before its geometry exists and pass after
> — report both states. Verify, then log.

## ▶ GATE C — you play it

Blind runs, one per character. Then mastered runs after three attempts each. Stats screen
records the times. Then the feel checks from `PLAN-level-compound.md` Phase 4 — death loop,
headshots, Chad overland, alarm feel, extraction discovery.

### Block 16 · Opus · Triage, fresh context

> You have Gregory's stopwatch numbers, the stats screens and his notes. Rank what to fix.
> Geometry fixes go to Sonnet, tuning to Haiku, data only. Do not rewrite the design doc.

### Block 17 · Haiku · Ship it

> Export Linux and Windows per `CLAUDE.md`. Update the layout section of `CLAUDE.md`, update
> `HANDOFF.md`, and update `LevelCompound`'s header floor plan. Confirm the export boots and
> the level is selectable.

---

## Where the money goes

Of the seventeen blocks, **two are Opus** (the alarm state machine, the post-playtest triage),
**seven are Sonnet**, **six are Haiku**, and the two that decide whether any of it is any good
are you, walking it. That is the correct shape. The r3 review ran entirely on Opus and spent
most of its effort deriving from coordinates what a ten-minute walk answers for free — Gate A
exists so that doesn't happen again.
