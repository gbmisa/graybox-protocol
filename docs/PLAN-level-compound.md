# Graybox Protocol — Level 1 ("THE COMPOUND") Design & Build Plan

**This is level one.** It precedes MERIDIAN CAPITAL in the level list and is designed against
the **base kit only** — no skill-tree unlocks, no fancy weapons (see §5). The squeeze and the
silencer (D9) are base kit.

**This document is a plan for producing the level, not the level.** It breaks the design
brief into phases, assigns each step to a model or to Gregory, states what each step must
produce, and defines the acceptance gate for each. Nothing here fixes geometry, guard
positions or numbers — those are the outputs of Phase 1 and Phase 2 and live in
`docs/LEVEL-compound.md` once written.

Working title only. The level's real name is a Phase 5 output.

---

## 0. Decisions — resolved by Gregory, 2026-09-13

The brief was written against a slightly different game than the one in the repo. These
are the calls. Every later phase treats them as fixed.

| # | Decision | Consequence for the design |
|---|---|---|
| D1 | **Dash, not blink.** One mobility tool per character. | The Wizard's vector is a *dash line*, 1.2s cooldown. Mistiming leaves 60 HP in the open for ~1s — enough for a guard's 0.55s aim wind-up. No `barred_window.gd`. *(Corrected after §3.3: gaps gate nobody, so the dash's routing value is its i-frames — a hazard field — and its exposure windows, not 5–7m gaps.)* |
| D2 | **Lockpick gates optional rooms only.** And: **routes share space.** The Wizard can use most of what the Regular uses (both crouch to 0.85m). Fully disjoint routes would be three levels, not one. | Each character gets a *signature entry* the others can't use; after entry, shared interiors are expected and good. The choke-point audit (§12) is reframed: convergence is not a defect. See §1.5. |
| D3 | Not a real decision — the brief's jump numbers were guesses. `verbs.gd` is the source of truth. | Shared steps ≤ 1.2m (mantle). Chad-only steps 1.2–2.5m. Crawl gaps 1.0m. |
| D4 | **Alarm brings extra enemies but must not make the level feel impossible.** Estimate requested → §3.5. | This level consumes F2's `alert_state`; the numbers in §3.5 are the starting tune. |
| D5 | **No target guard count.** (The "~8" came from the brief text, not the repo.) The number falls out of the routes; tune to fun. | Design §5 places as many guards as the sightline table needs, then Phase 4 adds or removes by feel. Expect 6–12. |
| D6 | **No cameras in this level.** Cameras arrive in a later level as a *trap*: tripping one releases a robot enemy rather than raising the alarm. | `enemies/camera.gd` dropped from scope. Logged under §6. |
| D7 | **Character-gated extractions, unlabelled.** Some are only reachable by Chad (2.5m mantles), some only by the small characters (crawl). A player may not even know a spot *is* an extraction until they reach it. | Three or more extractions; at least one Chad-only (a mantle chain) and one crawl-only. No signage pointing at any of them; the interaction prompt appears only on arrival. Confirms: Chad-only jump/mantle chains are a real gate category from now on. |
| D8 | **Darkness affects detection, in three obvious tiers: PITCH / DARK / LIT.** Many light levels can exist visually, but detection reads exactly three. | Implemented as tiered shadow volumes, not light sampling — §3.4. Tier must be visible in the gray-box (floor tint or lamp energy) *and* on the HUD. |
| D9 | **Kits differentiate stealth — powers open areas.** The Wizard gets a **squeeze** (fits through holes the Regular cannot) and can sneak through everything the Regular can, paying for it elsewhere. The Regular gets **range** (guns) and a **silencer** loadout for stealth kills. | Two stealth *styles* over shared space: the Regular is stealth-by-silence (suppressed range, crawl), the Wizard is stealth-by-geometry (squeeze, dash, vertical) whose every offensive act is loud. Kit work in §3.6; new gate class (0.6m squeeze holes) in §3.3. |
| D10 | **Chad's mantle opens routes that don't look like routes.** He should be able to jump and pull himself onto a building roof that reads as scenery to the other two. Not every roof — additional options, not a rule. The player must be able to tell by eye whether a roof is his or not. Roofs can be quiet in some places and guarded in others. | §3.7 is the authoring rule; design §4 must show ≥2 such Chad-only overland shortcuts. Readability by silhouette is the constraint, not coverage. |
| D11 | **No Splinter Cell / Hitman feel.** No on-screen detection meters, stealth bars or visibility gauges — they break immersion. Feedback comes from the world: guard head-turn, bark, "?"/"!" over the guard, the light you're standing in. Take from those games only what's necessary (nothing UI-side). | The `detect` float stays internal. Light tier is shown by the world (tint / lamp), never by a HUD pip. §3.4 amended. |
| D12 | **Enemy hitboxes must be right, and headshots must exist** with a damage multiplier. Headshots weren't landing in MERIDIAN. | Prerequisite fix in Phase 3a before any level work: separate head shape on `guard_body.gd`, hitscan and projectiles report the shape, headshot ×2.5 (data). Smoketested. Applies to MERIDIAN too. |
| D13 | **Base kit only for this level.** Skill trees and extra weapons come later; levels are designed so unlocks make routes *faster or safer*, never *possible*. | §5 states the rule and when trees become necessary. |

---

## 1. Research digest — what good looks like, distilled to rules for this project

Sources at the end. Each rule is stated as a check the design must pass.

### 1.0 North star: Cruelty Squad first, Dishonored as a recognisable ghost

The engine choice was partly *because* Cruelty Squad is a Godot game. So when the two
references disagree, Cruelty Squad wins. What that means in practice:

| Cruelty Squad | Dishonored | This level does |
|---|---|---|
| Fast. Everyone dies in 1–3 hits, you included. | Deliberate, forgiving. | Guards 50 HP / hit for 22 (already so). Player death → restart in under a second, no screen, no cutscene. |
| Stealth is **routing and timing**, not crouch-walking. | Stealth is crouch + lean + powers-as-keys. | Squeeze, dash, silencer are *routing tools used at speed*. If the squeeze feels like a Dishonored lockpick minigame, make it faster (§3.6 speed is a starting number, not a floor). |
| Score is time. Ranks are speedrun challenges. | Chaos system, moral ranking. | Stats are time / kills / alarms. No moral grade. |
| Geometry is honest and exploitable. Going "behind the map" is a route. | Curated set-pieces. | If the collision allows it, it's legal. The smoketest hunts soft-locks and missing floors, **never** shortcuts. A shortcut that beats the intended line *is* the mastered run. |
| The world is grotesque; the satire is in everything. | Restrained, painterly. | Signage, barks, briefing — abrasive, everywhere. |
| Levels are compact and dense; you learn by dying and rerouting. | Large, explored once slowly. | Compact footprint (< MERIDIAN); the 5–8 min blind run comes from *not knowing*, not from distance. |
| No detection UI. Guards just react. | Detection "chevrons" fill on screen. | Nothing on the HUD about being seen (D11). The guard's own "?"/"!" and bark are the feedback. |

Dishonored's contribution is one idea: **powers open areas** (D9). It's a design rule, not a
feel. The feel is Cruelty Squad's. Splinter Cell, Thief and Hitman are cited below for
*mechanism* research only (how a light tier or an alarm stage can work) — their feel, and in
particular their meters, are explicitly not wanted (D11).

### 1.1 Multi-path (Dishonored / Deus Ex / Cruelty Squad)

- **Routes are infiltration vectors, not doors.** Dishonored's postmortem calls this
  "stereoscopic structure": vertical space, hidden paths that "lead to objects other than
  the explicit one." Three doors in one wall is one route. *Check: can you describe each
  route without mentioning any geometry the other two use before the target room?*
- **Skills are the routing.** "Touchable possibilities" — abilities tied to specific
  environmental affordances, not stat checks. This is already the repo's philosophy
  (verbs + collision gates). *Check: every character-specific step is gated by kit, and
  the gate explains itself (greyed prompt or visibly-too-tall gap).*
- **Compact but layered.** Dishonored levels feel large through "complex layout and
  multiple progressive routines," not footprint. *Check: the compound footprint should be
  smaller than MERIDIAN's 60×50m and the blind run still 5–8 min.* The friction plan already
  proved that adding metres adds time to both runs equally and changes nothing.
- **Cruelty Squad stealth is routing, not crouching.** "Traditional sneak-by-the-enemies
  stealth isn't really possible, but with practice you can beat levels without alerting
  anybody." Score = time. *Check: the mastered run is a memorised line through the gaps,
  and the gaps are real (guard timing windows), not a crouch-walk.*
- **Observation points.** Verticality doubles as reconnaissance — the roof and high
  windows should let a patient player *see* patrol loops before committing. *Check: from
  each route's first safe vantage, at least two guard loops are visible.*

### 1.2 Stealth systems (Thief / Splinter Cell / MGS / Hitman)

- **Detection feedback must be legible — from the world, not a gauge.** The surveyed games
  use meters; we don't (D11). The repo's "?"/"!" over the guard, a head-turn toward
  `last_seen`, and a bark are the whole channel. *Check: the player can always tell why
  they were seen by looking at the guard and at the floor they're standing on.*
- **Light-based stealth is a whole system or nothing.** Thief's rule (darkness + stillness
  = hidden) is the mechanism reference; the light gem UI is not. Half-implementations read
  as bugs. This is D8: three tiers, shown by the world.
- **Alarms escalate in stages and each stage costs something.** MGS: reinforcements you
  must fight. Hitman: target lockdown — VIP escorted to a secure room. Both are F2.
  *Check: ALARM makes the target harder to reach, not just the guards angrier.*
- **Patrol gaps must look intentional.** "Design patrol routes that offer exploitable gaps
  without feeling arbitrary." *Check: each blind spot has a diegetic reason (a corner, a
  parked vehicle, a vent) — signage can even joke about it.*

### 1.3 Blockout process (Level Design Book / Radiator)

- **Metrics before geometry.** Define player width, eye height, crouch height, mantle
  heights, door and corridor widths, ramp slope — then build a metrics gym and walk it.
  The repo already has most of these (`verbs.gd`, `BuildUtils.stairs()` rise/run < 1.0).
  *Check: Phase 2 produces a metrics table and Phase 3a builds the gym before any section.*
- **Sketch → floor plane → scale capsules → rooms → walk it, in minutes not hours.**
  Rapid iteration; expect to throw away layout. *Check: the first Phase 3 milestone is a
  walkable hull with no guards, timed by hand.*
- **Playtest metrics to log:** time-to-objective, deaths, confusion points, backtracking.
  *Check: end-of-mission stats (time / kills / alarms) exist before the first hand playtest
  so timing is recorded, not guessed.*
- **Ramps not stairs** is both a metrics rule and a pathfinding rule; the repo learned it
  the hard way (`CLAUDE.md` invariants).

### 1.4 Rules specific to this repo (hard-won, from `CLAUDE.md`)

Exclude the target from LOS rays. Stairs are ramps. Seal around every crawl gate; `tunnel()`
has no end caps. Every enclosed space gets a lamp. Audit for soft-locks. **Add a smoketest
case for every bug class fixed.** These are not optional and every Phase 3 task inherits them.

### 1.5 Shared space vs. signature entry (D2, D7)

The unit of differentiation is the **entry** and the **extraction**, not the whole route.

- Each character has one entry the others cannot perform (vent 1.0m / warded seal + 0.6m squeeze / smash wall)
  and at least one extraction only they can reach.
- Between entry and target, spaces are shared. A Wizard following the Regular's crouch
  corridor is fine. A Regular walking the corridor behind Chad's wall is fine *if* the wall
  is the only way in from that side.
- A shared space becomes a **defect** only when it deletes a signature: e.g. every entry
  dumps into one 2m corridor 5m later, so the entries were three doors after all. The test
  is: *after their signature entry, does each character arrive at the target from a
  different side, or at a different time, or in a different guard's sightline?* If all three
  answers are "no", fix it.
- Shared interiors are where the three kits get compared under the same conditions — that's
  the replay value, not disjoint mazes.
- Within shared space the two stealth characters diverge by *method*, not by corridor
  (D9): the Regular handles a guard from 15m with a suppressed shot; the Wizard handles
  the same guard by squeezing past behind a 0.6m gap or dashing across his blind window.
  Design §4 should show, for at least two shared guards, both solutions.

---

## 2. Phase plan and model allocation

Principle for who does what:

| Model | Use for | Never for |
|---|---|---|
| **Fable 5.1** | Open-ended design where the *reasoning* is the deliverable; writing (satire copy); final integrated review | Bulk code, data entry |
| **Opus 5** | Cross-cutting systems and adversarial audits in a *fresh context* (not the author) | Repetitive edits |
| **Sonnet 5** | Scoped code against an existing pattern (one section builder, one subclass, one panel) | Design decisions, tone |
| **Haiku 4.5** | Mechanical: data dicts, waypoint tables, running `--import` / smoketest / export, doc sync | Anything with a judgment call |
| **Gregory** | Every decision in §0, every stopwatch test, tone sign-off, "is it fun" | — |

Authorship and review are always different models. Phases are sequential; steps within a
phase marked ∥ can run in parallel.

### Phase 0 — Decisions  ·  *Gregory*  ·  done 2026-09-13

See §0. Phase 1 may start.

### Phase 1 — Level design document  ·  *Fable 5.1*  ·  output `docs/LEVEL-compound.md`

Produce the full deliverable in the brief. The document must contain, in this order, and
each section has an acceptance test that Phase 2 will run:

| § | Section | Must contain | Acceptance |
|---|---|---|---|
| 1 | Briefing + tone | 150-word mission briefing in-voice; level name; who the VIP is and why they deserve it (satire, legible) | Gregory reads it and doesn't wince for the wrong reason |
| 2 | Footprint + zones | Compound outer dims; each building's dims and floor heights; courtyard; wall heights; roof heights; extraction positions (≥3: one Chad-only mantle chain, one crawl-only, one open); **ASCII plan view and one elevation**; **light tier per zone** (PITCH / DARK / LIT) | Every number is on a 0.5m grid; no two volumes overlap; total footprint < MERIDIAN; no extraction is signposted |
| 3 | Metrics table | Per character: stand/crouch/squeeze height, mantle, jump, speed with each armour, weapon ranges and noise (loud vs. suppressed). Shared-step max, Chad-only step max, crawl gap (1.0m), squeeze hole (0.6m), ramp slope, door/corridor widths | Every value traces to `verbs.gd` / `characters.gd` / `armors.gd` or is flagged NEW |
| 4 | Three vectors, step-by-step | For each: numbered steps with coordinates, verb/traversal used, what the other two characters experience at that step (blocked / can follow / can follow badly), exposure risk and light tier per step; where each vector joins shared space; for ≥2 shared guards, the Regular's suppressed-range solution *and* the Wizard's squeeze/dash solution; **≥2 Chad-only overland shortcuts** (roof / ledge / wall-top, 1.3–2.4m) that read as scenery to the others | Each vector's **entry** has ≥1 step the other two **cannot** perform; the "cannot" is kit or collision, never a script check. After entry, sharing is expected (§1.5). The Wizard has ≥1 squeeze hole on-route and ≥1 optional one that shortcuts a shared space. Chad's overland shortcuts are unsignposted and each skips a guard or a door |
| 5 | Guards | Posts with waypoints, facing, loop time — as many as the sightline table needs, no target count; sightline table (who covers which door/gap); explicit blind-spot list with diegetic reason; which posts are the SUSPICIOUS/ALARM reinforcement spawns | Each vector's first 30s is passable unseen by a patient player; no guard loop shorter than 8s (unlearnable) or longer than 40s (trivial) |
| 6 | Alarm | What trips ALARM here (Chad's wall always; guard confirm; gunfire ≥ N noise); the F2 consequence with this level's data: panic-room position, which doors lock, reinforcement spawn points and count, decay time. Start from §3.5's numbers | Loud Chad run reaches VIP and one extraction under ALARM; blind Regular who trips ALARM once can still finish |
| 7 | Light tiers | Every zone assigned PITCH / DARK / LIT; where the tier boundaries are (they must be readable — a doorway, a lamp's edge, a step down); which sightlines cross a tier boundary (guard in LIT looking into DARK is the classic hide) | Every critical-path door is in DARK or LIT, never PITCH (or stealth collapses to "stand in the black box"); each vector passes through all three tiers at least once |
| 8 | Lockpick side rooms | 2–3 optional rooms: what's inside (intel on VIP's schedule, alternate sightline for a bolt/pistol kill, loot), time saved by using them | None is on any critical path; Regular reaches all, others reach ≤1 by another way |
| 9 | Objective loop + stats | Kill VIP → reach any extraction you can physically reach; the second-leg (F3) hook if enabled; stats tracked: time, kills, alarms, detections, which extraction | Mirrors `core/objectives.gd` states |
| 10 | Timing table | Per character: blind est. and mastered est., broken into approach / entry / locate / kill / extract, same shape as the friction plan's table | Ratio ≈ 5× on every character; if any mastered est. < 45s the route has no gaps |
| 11 | Replayability checklist | What run 2 and run 3 do differently and which character each favours; what a player learns on run 1 that run 2 spends | Each run is a different *character*, not the same character faster |
| 12 | Convergence audit | Every shared space listed with which characters use it and from which direction. Apply the §1.5 test to each: different side, different time, or different sightline? Mark the ones that fail all three as defects, with a geometry fix | Zero unfixed defects; shared spaces that pass are listed as *intended* so Phase 2 doesn't re-flag them |
| 13 | Signage + bark list | ≥12 signs, ≥8 guard barks (patrol/suspicious/alert), 2 extraction radio lines | In-voice, abrasive, legible as satire |
| 14 | Smoketest cases | A list of assertions the level must pass, phrased so Sonnet can implement them | Covers: floor under every waypoint; crawl gaps 1.0m and squeeze holes 0.6m, both sealed above; Chad-only step heights > 1.2m; shared steps ≤ 1.2m; each vector's entry step blocks the other two; every extraction reachable by the characters it's meant for and **unreachable** by the ones it isn't; no soft-locks; every enclosed volume has a lamp; no critical-path door inside a PITCH volume |

**Guardrails for the author:** it's a Cruelty Squad level (§1.0) — dense, fast, lethal,
honest geometry; if a section reads as a slow Dishonored sneak, cut it. Design in the existing vocabulary — `BuildUtils` primitives
(box / tunnel / stairs-as-ramp / lamp / plate / label), `Interactable` verbs, `GuardPosts`
waypoint dicts. Don't invent a helper the repo doesn't have without listing it in §3 as NEW.
Keep the whole thing under ~600 lines; longer means it's over-specified and Phase 3 will
find the numbers don't fit anyway.

### Phase 2 — Adversarial design review  ·  *Opus 5, fresh context*  ·  ~30 min

Given `docs/LEVEL-compound.md` and this file only. Runs the acceptance column of every
row above and additionally attacks:

- **Collapse test:** is there one *entry* every character would take if they could? If a
  Regular can reach Chad's post-wall corridor by another way faster than the vent, the vent
  is decoration. (Shared space *after* entry is not a collapse — §1.5.)
- **Extraction test:** for each extraction, which characters can physically reach it, and
  does the gate hold (mantle height / crawl height only, no script)? Can a Chad who kills
  the VIP always reach *some* extraction, including under ALARM?
- **Tier test:** walk each vector and list the light tier at every step. Is there a
  PITCH pocket that trivialises a whole guard? Is there a vector that never gets a DARK
  moment (then darkness isn't a tool for that character)?
- **Rush test:** with 7.6 m/s and no gates, what's the straight-line time from spawn to
  VIP? If it's under 40s and nothing stops it, the level has the MERIDIAN problem.
- **Roof exposure test:** who can see the crate stair and roof, from where, for how many
  seconds per loop? The brief wants exposure; it must be *countable*.
- **Cooldown test (Wizard):** map each dash/blink point; where does a mistimed cooldown
  leave the Wizard, and who sees them there?
- **Alarm test (Chad):** trace the loud run from wall breach to extraction under ALARM.
  Count reinforcements met. 250 HP vs 22/shot = 11 hits; is it winnable, is it *tense*?
- **Soft-lock sweep** over every pit, roof, and side room.

Output: a findings list, severity-ranked, each with a concrete geometry/number change.
**Fable 5.1** then revises the design doc (not Opus — author revises, reviewer re-checks).
Loop until Opus reports zero *high* findings. Cap: two loops, then Gregory arbitrates.

### Phase 3 — Build

Sequenced so each milestone is walkable. Every step ends with
`godot --headless --path . --import` and the smoketest.

**3a. Prerequisites  ·  Opus 5 (systems), Sonnet 5 (metrics gym)**

| Step | Model | Output |
|---|---|---|
| **Mantle from takeoff floor (D14)** | Sonnet 5 | `mantle.gd`: record the floor height at the last `is_on_floor()` frame and measure `rise` from it; `_find_ledge()` rejects a ledge whose top exceeds `takeoff_y + limit`. Keeps mid-air grabs (feel) but caps them at the same height a floor mantle reaches. Smoketest: a 2.2m ledge is unreachable to a 1.2-mantle capsule by any jump; a 1.6m one is |
| **Hitboxes + headshots (D12) — first, before anything else** | Sonnet 5 | `guard_body.gd`: body capsule + separate head shape **inside the head mesh — centre y 1.95, the mesh spans 1.775–2.125** (the body capsule tops out at 1.75 and must not overlap it), both on the guard's `PhysicsBody` as two shapes; `Guard.take_hit(dmg, shape_idx)` applies `GuardData.stats()["headshot_mul"]` (start 2.5) when the head shape is hit; `kit_regular.gd` hitscan and `projectile.gd` pass the shape index from the raycast result. Verify the visible mesh and the shapes coincide — a mesh offset from its collider is the likeliest cause of the MERIDIAN misses. Same for `target.gd` and (F4) bodyguards. Smoketest: a ray at 1.95 reports head, at 1.2 reports body, the head shape's AABB lies inside the head mesh's, and a 25-dmg headshot kills a 50 HP guard in one |
| F2 alert state machine if not already built | Opus 5 | `core/alert_state.gd`, per friction plan, with §3.5's reinforcement + decay contract |
| Wizard squeeze | Sonnet 5 | `verbs.gd` gains `squeeze_h` (Wizard 0.5, others absent); `movement.gd` gets a third capsule state (held key, slower than crouch, mana drain per second — numbers in `characters.gd`); `kit_wizard.gd` binds it. Pure collision like crawl — **no character check** |
| Regular silencer | Sonnet 5 | Pre-mission loadout row alongside armour in `data/` (`SUPPRESSED`: noise 0, damage ×0.7 / `LOUD`: noise as now); `kit_regular.gd` reads it; select-screen card shows it. Never a mid-run toggle — same rule as armour |
| Metrics gym additions | Sonnet 5 | 0.6m squeeze hole next to the 1.0m crawl; a 15m firing lane with a guard dummy so the suppressed shot's noise radius can be watched on the alert HUD |
| Light tiers | Sonnet 5 | `BuildUtils.light_tier(aabb, tier)` → `Area3D` + matching floor tint / lamp energy; `player.movement.light_tier`; `guard_senses._rate()` × `GuardData.stats()["tier_mul"][tier]`. No HUD element (D11). **Not** real light sampling — §3.4 |
| Extraction gating check | Sonnet 5 | Smoketest helper that, for each extraction, sweeps the approach with each character's capsule/mantle and asserts the intended reachability set |
| Level registry | Sonnet 5 | `world/levels.gd` mapping level id → builder + spawn + posts, so `mission_flow` can pick a level. `LevelBuilder` becomes `LevelMeridian`; new `LevelCompound` |
| Metrics gym | Sonnet 5 | `world/sections/sec_gym.gd` behind a debug flag: steps at 1.0/1.2/1.6/2.5m, gaps at 5/6/7/8m, a 1.0m crawl, a 0.6m squeeze, ramps at three slopes, one volume of each light tier. Gregory walks it as all three characters **before 3b starts** |

**3b. Hull  ·  Sonnet 5, one section per task ∥**

One `sec_*.gd` per zone from design §2, each under 250 lines, geometry only, lamps
included, no guards. Then **Haiku 4.5** wires `LevelCompound.build()` and runs the
import. **Gregory** walks the hull with all three characters and stopwatches the
no-guard straight line per route. If any route is under design §10's mastered estimate by
more than 30%, back to Phase 2 for that route before adding anything else.

**3c. Vectors + gates  ·  Sonnet 5 ∥**

| Vector | Work |
|---|---|
| Regular | Crate stair (mantle-height boxes, offsets), roof, vent `tunnel()` with sealed surroundings and end caps, drop point; ≥1 long sightline onto a shared guard for the suppressed shot |
| Wizard | The hazard field the dash's i-frames cross (`world/hazard.gd`, design §2.6); the exposed crossing where a mistimed cooldown is punished (design §4.2, the void); 0.6m × 1.0m squeeze holes (`tunnel()`, sealed like crawls, end-capped) |
| Chad | `breakable_wall.gd` instance with `smash` only, `noise` high enough to guarantee ALARM; post-wall corridor; Chad-only mantle chain to his extraction; the §3.7 ledge chains on the roofs design §4 marks reachable, sheer faces on the rest |
| All | Light-tier volumes per design §7 |

Then **Haiku 4.5** adds smoketest cases from design §14. Each case must **fail** before the
geometry it tests exists and pass after — Haiku reports both states.

**3d. Population  ·  Haiku 4.5 (data), Sonnet 5 (interactables)**

- `GuardPosts` compound section: posts from design §5, verbatim. Haiku.
- Lockpick side rooms: `locked_door.gd` instances + contents (intel panel reuses
  `intel_source.gd` from F1 if built, else a `label` plate). Sonnet.
- Extraction markers (unlabelled, prompt-on-arrival only), VIP spawn + pace waypoints,
  panic room, reinforcement spawns — all as `data/mission_compound.gd`. Haiku.
- Alarm wiring: wall breach → `alert_state.ALARM`; door locks per design §6. Sonnet.

**3e. Stats  ·  Sonnet 5**

`core/mission_stats.gd` (time / kills / alarms / detections) surfaced on the win and lose
screens via the existing `screen_base.gd` pattern. Must land **before** the first Phase 4
playtest so times are recorded.

### Phase 4 — Verification

| Step | Who | Pass condition |
|---|---|---|
| Headless import + full smoketest | Haiku 4.5 | Green |
| Export Linux, boot | Haiku 4.5 | Boots, level selectable |
| Blind runs — one per character, someone who hasn't read the design doc if at all possible; else Gregory playing "wrong" on purpose | Gregory | 5–8 min each, stats screen confirms |
| Mastered runs — Gregory after 3+ attempts per character | Gregory | 45–90s (design §10 estimates 53 / 60 / 67s); each character's line uses their vector; ALARM roughly doubles the Chad time, doesn't end it |
| Feel check | Gregory | Does the mastered run feel like a Cruelty Squad line — movement, timing, a couple of kills, done? Or like a Dishonored sneak? If the latter, the fix is speed (squeeze rate, dash windows, guard loop gaps), not geometry |
| Death loop | Gregory | Die on purpose five times. Time from death to control: < 1s each. Anything slower gets fixed before balance |
| Headshots | Gregory | As the Regular, land ten headshots on patrolling guards. They should one-shot and *feel* like they connect where the crosshair is. Misses that look like hits mean the mesh/collider offset is still wrong |
| Chad overland | Gregory | Play Chad. From the ground, guess which roofs are yours, then try them. Every guess should be right. A roof that looks reachable and isn't gets a ledge or gets made visibly sheer; a roof that looks sheer but is reachable is fine (a secret), as long as it's not the only way |
| Immersion | Gregory | Anything on screen that reads as a stealth gauge gets cut. The only permitted overlays are the existing vitals/abilities, the interaction prompt, and the guard-side "?"/"!" |
| Alarm feel | Gregory | Trip ALARM on purpose as the Regular mid-level. It should feel like "now it's a fight" — not "restart". If it reads as restart, cut reinforcements (§3.5) before anything else |
| Convergence check | Gregory | Play Regular through Chad's post-wall space if reachable — shared space should feel *different* (other side, other timing), not identical |
| Extraction discovery | Gregory | Play each character and note when you realised where "your" extraction was. If nobody finds one blind, the arrival prompt needs a wider trigger or a stronger silhouette — not a label |
| Guard count | Gregory | Add or remove posts by feel; record the final count in the design doc. No number is sacred |
| Findings triage | Opus 5, fresh context, given stopwatch numbers + stats + Gregory's notes | Ranked fixes; geometry fixes go to Sonnet, tuning to Haiku (data only) |

If the mastered run creeps past ~2 min, friction has become tax: fix by widening the
timing windows the mastered player exploits, not by shrinking the level (same rule as the
friction plan).

### Phase 5 — Tone pass  ·  *Fable 5.1*, sign-off *Gregory*

Signage plates, guard barks, briefing card, extraction radio lines, level name, VIP dossier.
Barks go through `audio_synth` (no VO) — so they're on-screen text with a synth blip; keep
them short. **Haiku 4.5** places the plates. Gregory reads everything in-game, not in the doc.

### Phase 6 — Docs  ·  *Haiku 4.5*

Update `CLAUDE.md` layout section (level registry, new sections, camera, stats),
`HANDOFF.md` (level 2 status, timings achieved), the `LevelCompound` header floor plan.
Commit.

---

## 3. Implementation constraints the design must respect (so Phase 3 doesn't bounce it)

### 3.1 Files that will exist after this plan

```
scripts/
  core/       alert_state.gd (F2) · mission_stats.gd · objectives.gd (F1/F3, if built)
  data/       mission_compound.gd (extractions, panic room, reinforcement spawns, tier map)
  world/      levels.gd · level_meridian.gd (renamed) · level_compound.gd · guard_posts_compound.gd
    sections/ sec_gym.gd · sec_cmp_*.gd (one per zone, named in design §2)
    interactables/ (existing three, reused)
tools/        smoketest.gd (extended; split to smoketest_compound.gd if it passes 250 lines)
docs/         LEVEL-compound.md (design) · this file
```

### 3.2 Gating stays two-mechanism, plus a third that is really the second

Interaction gates via `open_methods` omission; crawl gates via collision. The roof vent is
a 1.0m `tunnel()` — Chad can't follow the Regular's vector by construction. Chad's wall
lists `smash` only. The Wizard's gap is a distance no one else's jump + mantle reaches.
**Chad-only mantle chains** (D7) are the collision mechanism in the other direction:
a 2.0m ledge is unreachable at mantle 1.2 and trivial at 2.5. Extractions gated this way
need no script either. **No character checks anywhere.**

### 3.3 Traversal numbers (post-D3)

**Corrected 2026-09-13 after reading the physics** (`movement.gd`, `mantle.gd`,
`characters.gd`, gravity 9.8). Two findings, both load-bearing:

- **Horizontal gaps gate nobody.** Jump apex 1.84m (Chad 2.87), airtime 1.22s: a
  running jump covers ~12.8m (Regular), ~17m (Wizard — 8m plus a 9.1m mid-air dash), ~18.6m (Chad). There is
  no "dash gap" gate class. Gaps are for *exposure* only. (MERIDIAN's vent shaft is
  Wizard-only because of the warded gate in front of it, not the 7m gaps.)
- **D14 — mid-air mantle stacks on jump.** `movement.gd` tries a mantle on every jump
  press, airborne included, and `mantle.gd` measures rise from *current* feet, so real
  reach is apex + mantle: Regular ~3.0m, Chad ~5.4m. **Prerequisite fix, Phase 3a:**
  measure rise from the takeoff floor. Until then, no Chad-only ledge holds.

| | Regular | Wizard | Chad |
|---|---|---|---|
| Crouch capsule | 0.85 | 0.85 | 1.45 |
| Squeeze capsule (D9, NEW) | — | 0.5 | — |
| Jump apex | 1.84 | 1.84 | 2.87 |
| Mantle (post-D14) | 1.2 | 1.2 | 2.5 |
| Running-jump distance | ~12.8 | ~17 (8 + a 9.1m mid-air dash) | ~18.6 |
| Engagement range, quiet | 15m+ suppressed pistol (D9) | 0 — everything is loud | 0 |

Gate classes — by **jump apex**, since that exceeds mantle for everyone:

| Gate | Height | Passes |
|---|---|---|
| Shared step | ≤ 1.6m | all |
| **Forbidden band** | 1.6–2.0m | nobody — unreadable, never build one |
| Chad step | 2.0–2.6m | Chad |
| Sheer | ≥ 3.4m | nobody |
| Crawl | 1.0m headroom | Regular, Wizard |
| Squeeze | 0.6m headroom | Wizard |
| Smash wall | `open_methods = {smash}` | Chad |
| Warded seal | `open_methods = {arcane}` | Wizard |
| Hazard field (NEW, `world/hazard.gd`) | damage/s; the dash's 0.25s i-frames cross it | Wizard clean; Chad tanks; Regular in heavy plate survives |

Regular-only entry is therefore the crawl **plus** roof exposure — the Wizard *can* follow
the vent, and that's allowed by D2; what the Regular alone brings there is a suppressed shot
at the roof patrol from the crate stair. Design §3 restates all of this.

### 3.6 Kit extensions (D9)

Small, data-first, no new systems:

- **Wizard squeeze.** A third capsule height in `verbs.gd` (`squeeze_h: 0.5`); held key
  (suggest holding crouch again, or a dedicated key — Gregory picks in the gym); speed
  ~0.4× walk; mana drain ~8/s so a long squeeze is a real cost and a 60 HP character
  can't hide in a pipe forever. Regular and Chad have no `squeeze_h` and the key does
  nothing for them — collision does the gating, exactly like crawl.
- **Regular silencer.** A loadout choice next to armour: `SUPPRESSED` (noise 0, damage
  ×0.7 → 4 shots on a 50 HP guard) or `LOUD` (noise as today, full damage). Pre-mission
  only. Gives the Regular the one thing nobody else has: a *quiet* kill at range. The
  cost is shots-to-kill and a guard that gets to turn around once.
- **Wizard drawbacks stay.** 60 HP, fireball/bolt/Meteor all emit noise, arcane unlock
  emits 12. The Wizard sneaks by *not being where the guard looks*; the Regular sneaks by
  *removing the guard*. Both use the same crouch corridors and the same DARK tiers.

### 3.7 Chad verticality — authoring rule (D10)

Chad's mantle is 2.5m against everyone else's 1.2m. That gap is a *route generator* where
the level chooses to use it. It's extra options, not coverage — most roofs can stay
unreachable. What matters is that the reachable ones are **readable by eye**:

- **Two silhouettes, no in-betweens.** A Chad-reachable roof has a ledge, sill or box in
  the 1.3–2.4m band leading to it. An unreachable one has a sheer face over 3.5m with
  nothing in the band. Never a 2.6m edge that looks like 2.4m — that's the "constricting"
  feeling, and it's a lie the geometry tells.
- **Nothing signposts it.** To the Regular and Wizard the ledge is a box; to Chad it's a
  step. The player learns the silhouette on run one and reads it everywhere after.
- **Chains, not single steps.** Two or three linked mantles read better and gate harder
  than one tall one.
- **Roofs are places, not corridors.** Some are quiet vantage points — a DARK tier, a
  sightline down onto a courtyard. Others have a guard on them. Design §5 places roof
  guards where a Chad shortcut would otherwise be free.
- **Each shortcut earns its place** by skipping a guard, a door, or a locked-down sector
  under ALARM. Design §4 names what each one skips.
- Every reachable roof has a way down that isn't lethal (soft-lock rule).
- His extraction (D7) is the capstone: a mantle chain the other two can see and can't use.

Smoketest: for every roof the design marks Chad-reachable, a sweep confirms a mantle-able
chain in the band and a non-lethal way down; for every roof marked unreachable, confirms
no edge in the band exists on any face.

### 3.4 Light tiers (D8) — three states, quantised, obvious

Not light sampling. Gray-box has no lighting worth sampling and the tiers must be
*authored* so they're readable. Mechanism:

- `BuildUtils.light_tier(aabb, tier)` places an `Area3D` tagged `PITCH` / `DARK` / `LIT`.
  Zones with no volume default to `LIT`. Volumes don't overlap (same rule as geometry).
- `player.movement.light_tier` is the tier of the volume the player's feet are in.
- `guard_senses._rate()` multiplies by `GuardData.stats()["tier_mul"][tier]`.

Starting numbers (data, tune in Phase 4):

| Tier | `tier_mul` | Effect at vision range 20m, detect_rate as now | Visual |
|---|---|---|---|
| LIT | 1.0 | as today | lamp energy 1.0, floor tint as today |
| DARK | 0.45 | crouched + dark ≈ 0.22× — a guard walking past at 4m for 2s doesn't tip SUSPICIOUS | lamp energy 0.35, floor tint −30% |
| PITCH | 0.1 | effectively hidden unless sprinting *into* a guard (0.1 × sprint_mul); stillness could drop it to 0 if Phase 4 wants Thief rules | no lamp; floor tint −65%; still navigable |

Rules for authoring tiers (design §7 and the smoketest enforce them):

- No critical-path door inside PITCH. PITCH is for *waiting*, not *passing*.
- Tier boundaries coincide with a visible edge — a doorway, a lamp's footprint, a step.
  Never a boundary in the middle of an open floor.
- **No HUD element** (D11). The tier is obvious from the world: floor tint and lamp energy
  differ by tier and the boundaries sit on visible edges. If a playtester can't tell which
  tier they're in, fix the tint contrast, don't add a gauge.
- Guards themselves ignore tiers (they see *out* of DARK as well as *into* it). Keeps the
  rule to one sentence: *your* tier sets how fast you're noticed.

Shootable lamps: Tier 2. Not in scope.

### 3.5 Alarm (D4) — starting estimate

F2 provides the state machine; this is the data this level feeds it, tuned so ALARM is
"now it's a fight," not "restart."

| Trigger | State |
|---|---|
| Guard reaches `detect` 0.35 | SUSPICIOUS (that guard investigates; others unaffected) |
| Guard reaches `detect` 1.0, **or** Chad's wall breach (noise 45), **or** a shot within ~12m of a guard | ALARM |

ALARM consequences:

| Consequence | Starting value | Why this and not more |
|---|---|---|
| Reinforcements | **2** spawn at the two spawn posts *farthest* from the player's current sector, walk to the VIP. Never at the player's back, never inside the target room | 2 × 50 HP = one Meteor, two punch combos, or eight pistol hits. Enough to change the plan, not enough to end it |
| Existing guards | All go ALERT-search toward `last_seen`, not toward the player's true position | Dumb on purpose; the player who moves after being seen escapes |
| Target | Relocates to the panic room (F2), escorted by the nearest guard | Costs the player the short kill, not the mission |
| Doors | **One** door locks: the direct one into the target room. Every character still has their signature way around | Locking more than one turns the level into a key hunt |
| Extractions | **Stay open.** | Closing an extraction under ALARM is the "impossible" feeling; the player's cost is the longer, hotter trip, not a dead end |
| Decay | ALARM → SUSPICIOUS after **60s** with no guard seeing the player; reinforcements stay but return to patrol posts; the door stays locked | Rewards breaking contact; makes stealth-after-a-mistake a real option |
| Repeat | A second ALARM in the same run spawns **1** more, capped at **+3** total | A hard cap is what keeps Chad's run finite |

Expected time cost: a blind Regular who trips ALARM once loses ~90s. Chad, who always
trips it, plays a ~2× run relative to his no-alarm hypothetical — that's his identity,
and 250 HP is the budget. If Phase 4 reports it feels like restart, cut in this order:
reinforcements 2 → 1, decay 60 → 40s, then the door lock.

All of this is a `data/mission_compound.gd` dict; no new logic beyond F2.

---

## 4. Definition of done

- All three characters complete the level via their own entry, blind 5–8 min, mastered 45–90s (the §10 floor; design estimates 53–67s).
- The mastered run reads as a Cruelty Squad line (§1.0); death-to-control under 1s.
- Chad's loud run is completable under ALARM and is the fastest *entry* and the slowest *mission*.
- ALARM feels like a fight, not a restart (Gregory's call in Phase 4).
- The Regular's roof is exposed for a countable window per guard loop.
- The Wizard has at least one place where a mistimed dash cooldown is punished by a sightline.
- Every character can reach at least one extraction; at least one extraction is Chad-only and
  one is crawl-only; none is labelled; the smoketest proves the reachability sets.
- Each vector passes through all three light tiers; no critical-path door sits in PITCH.
- No lockpick door on any critical path.
- The Wizard has a squeeze hole on-route and one optional shortcut; the Regular has a suppressed
  sightline onto at least one shared guard; both solve at least two of the same guards differently.
- Chad has ≥2 unsignposted overland shortcuts; every roof reads correctly by eye as his or not his.
- Headshots one-shot a guard and land where the crosshair is; nothing on the HUD reads as a stealth gauge.
- Completable with the base kit and nothing else.
- Zero unfixed convergence defects in design §12 by the §1.5 test; intended shared spaces are listed.
- Smoketest green; export boots; stats screen shows time / kills / alarms / extraction used.
- Signage and barks are in-voice and Gregory signed them off in-game.

---

## 5. Kits vs. levels — when skill trees start to matter (D13)

**Not yet, and the rule that keeps it that way:**

> Levels are designed against the base kit. Unlocks change *how fast or how safely* a
> route is done, never *whether* it can be done.

So a skill-tree node is always a modifier on an existing verb — cheaper squeeze, longer
dash, faster lockpick, quieter shot, an extra mantle step for Chad — and never a new gate
class. A level never needs a node. That means:

- **Now (level 1):** define the base kit fully (§3.6 is the last addition), build the level
  against it, and lock the base kit numbers when the level ships. Every gate in the level
  is passable by base kit; the smoketest already asserts reachability with base numbers.
- **Trees become necessary at level 3, not before.** You need two shipped levels before a
  tree has enough situations to modify — otherwise nodes are guesses. Design the tree by
  reading the stopwatch data from levels 1–2: the nodes are "the things a mastered player
  wishes were 20% better," and the data tells you what those are.
- **Levels 2+ can be designed before the tree exists** using the same rule. The only
  forward-looking constraint on the level designer is: don't build a gate whose only
  passable configuration is a base-kit number you'd like to change later. (E.g. don't build
  a 7.0m dash gap if a tree node might make the dash 8m — build it 6.5m and let the node
  make it comfortable.)
- **Weapons follow the same rule:** loadout options (like the silencer) are pre-mission
  choices with a trade-off, not power. Anything strictly better than base kit is a
  balance bug.

The data layer is already shaped for this (`characters.gd`, `abilities.gd`, `verbs.gd` —
all dicts). When the tree arrives it reads those dicts and writes modified copies; no level
code changes.

---

## 6. Deferred to later levels (from §0)

- **Cameras as traps** (D6): a static cone that, on confirm, releases a robot enemy instead
  of raising ALARM. New enemy type, new interactable. Own plan when its level is designed.
- **Shootable lamps** that drop a zone from LIT to DARK.
- **Stillness bonus** in PITCH (Thief rule) if Phase 4 wants it.

---

## Sources

- [Postmortem: The Level Design of Dishonored Series — Game Developer](https://www.gamedeveloper.com/design/postmortem-the-level-design-of-dishonored-series)
- [The designers of Dishonored, Bioshock 2 and Deus Ex swap stories — PC Gamer (GDC 2017 roundtable)](https://www.pcgamer.com/the-designers-of-dishonored-bioshock-2-and-deus-ex-swap-stories-about-making-pcs-most-complex-games/)
- [Five pillars of Immersive Sims — Maxim S](https://maximsamoylenko.medium.com/five-pillars-of-immersive-sims-7263167e7258)
- [Cruelty Squad video script / design analysis — coolgames.zip](https://www.coolgames.zip/scripts/crueltysquad.html)
- [Cruelty Squad — Speedrun.com levels & guides](https://www.speedrun.com/cruelty_squad/levels)
- [Metrics — The Level Design Book](https://book.leveldesignbook.com/process/blockout/metrics)
- [Blockout — The Level Design Book](https://book.leveldesignbook.com/process/blockout)
- [How to Graybox / Blockout a 3D Video Game Level — Radiator Blog](https://www.blog.radiator.debacle.us/2017/09/how-to-graybox-blockout-3d-video-game.html)
- [Examining the Essentials of Stealth Game Design — Youssef Khatib (thesis, PDF)](https://www.diva-portal.org/smash/get/diva2:624222/FULLTEXT01.pdf)
- [Stealth Meter — Splinter Cell Wiki](https://splintercell.fandom.com/wiki/Stealth_Meter)
- [Visibility Meter — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Main/VisibilityMeter)
- [Alert Levels — Hitman Wiki](https://hitman.fandom.com/wiki/Alert_Levels)
- [Metal Gear Solid 4 and stealth as more than a playstyle — Game Rant](https://gamerant.com/metal-gear-solid-4-stealth-gameplay-design/)
