# Graybox Protocol — Making the Level Take Longer Than a Minute

## Context

Wave B landed and the level is playable. It is also completable in **under 60 seconds by any
character on a blind first run**, which is 5–15x faster than estimated.

The estimate was wrong for an instructive reason. Movement is 7–7.6 m/s with no stamina, and
the longest route is ~350m, so pure travel is ~50s — that part was calculated correctly. It was
then padded 10x for learning, stealth, combat and route-finding, **none of which exist**:

- **Nothing makes you stop.** You can sprint the entire route. The only mandatory pauses are
  two door channels totalling 5.5 seconds.
- **Nothing makes stealth worth doing.** Being seen has no consequence you cannot outrun, and
  guards are slower than you.
- **Nothing is hidden.** The target's floor is labelled `BOARDROOM` in metre-high text, the
  extractions are labelled, the routes are labelled. There is zero information gating — the
  whole solution is visible from spawn.
- **The target is one unarmoured man** who dies in two hits and does not react.

This is the same finding as "not fun", stated precisely. Short runs are not the bug: Cruelty
Squad runs *are* 60–90 seconds. The bug is that a **blind** run is also 60 seconds, so there is
nothing to learn, nothing to master, and no reason to replay as anyone else. Three routes are
currently three ways to speedrun an already-solved problem.

**The goal is a gap, not a longer walk.** Adding geometry adds travel time to both runs and
changes nothing.

### Target

| | Blind first run | Mastered run |
|---|---|---|
| Duration | **5–8 min** | **60–90 s** |

All four friction mechanisms go in, each owned by a different operative so they produce
genuinely different play rather than four coats of the same paint.

---

## The four mechanisms

### F1. Information gating — the target's location is unknown  ·  *favours THE REGULAR*

The target occupies **one of three rooms** on the boardroom floor, chosen per run. Remove the
`BOARDROOM` signage. You learn which room from any of:

- **Floor directory** on the mezzanine — a wall panel, free to read, but out on the open plate
- **Server terminal** in the server room — behind the Regular's existing `[lockpick]` door
- **Guard chatter** — stay within ~6m of a patrolling pair, unseen, for ~8s

Randomisation is what preserves the skill gap: a mastered player cannot memorise the answer,
only the fastest way to *obtain* it. The Regular's route already runs through the server room,
so intel is nearly free for him and a detour for everyone else.

Without intel you can still search all three rooms — slow, and searching is loud.

### F2. Lockdown on alert — being seen costs minutes  ·  *punishes CHAD by design*

Introduce a building-wide alert level, distinct from individual guard states:

| Level | Trigger | Effect |
|---|---|---|
| CALM | — | as now |
| SUSPICIOUS | a guard investigates | patrols tighten, chatter stops (intel source closes) |
| ALARM | a guard confirms sight, or a breach | **target relocates to the panic room**; sector doors lock; reinforcements spawn at chokepoints |

Alarm is the single biggest time cost — it converts a 60s run into a 4-minute one, because the
panic room needs a different approach than the boardroom. **This is what makes stealth
instrumental rather than optional**: you stay unseen to keep the target where you can reach him
and the short route open, not for a score bonus.

Chad's breaches are unavoidably loud, so Chad essentially *always* plays the lockdown version.
That is his identity made real — he cannot be quiet, so he plays the hard variant and 250 HP is
the budget for it. His route needs a viable loud path into the panic room.

### F3. Second leg — the job is not done at the kill  ·  *favours THE WIZARD*

The target carries a case. After the kill you must reach a **terminal on another floor** to
wipe the records before extracting, forcing a return trip through a now-hostile building.

The Wizard's dash and vertical mobility make the second leg cheapest for him — his kit is
built for repositioning under fire, which is exactly what the return leg is.

Keep it to one extra stop. Two would read as a fetch-quest checklist.

### F4. The target is a real encounter  ·  *favours GIGA CHAD*

The target gains **two bodyguards** (armoured, higher HP, aggressive) and flees toward the
panic room when the alert hits ALARM. Killing him before he seals himself in is a genuine
fight.

Chad's slam answers a clustered group outright. The Regular and Wizard have to isolate or
burst. This is also the one mechanism that gives Meteor an obvious best use.

---

## Where the time comes from

| Phase | Blind | Mastered |
|---|---|---|
| Approach and entry | 45 s | 12 s |
| Obtain intel | 90 s | 10 s (grabbed en route) |
| Reach the target floor | 60 s | 20 s |
| Locate + kill through bodyguards | 90 s | 12 s |
| Second leg to the terminal | 60 s | 15 s |
| Extract | 45 s | 15 s |
| **Total** | **~6.5 min** | **~85 s** |

An alerted blind run adds 2–3 minutes on top. A mastered run that triggers ALARM roughly
triples — which is the pressure that makes the mastered run feel earned.

---

## Implementation shape

Respect the existing structure: data in `data/`, one responsibility per file, **nothing over
250 lines**, and add a smoke-test case for each new failure mode.

**New files**

| File | Purpose |
|---|---|
| `core/objectives.gd` | Objective state machine: intel → locate → kill → wipe → extract |
| `core/alert_state.gd` | Building alert level, lockdown, reinforcement triggers |
| `data/mission_data.gd` | Candidate target rooms, intel sources, alert thresholds, timings |
| `world/interactables/intel_source.gd` | Directory panel and terminal, reusing `Interactable` |
| `enemies/bodyguard.gd` | Guard subclass: armoured, no patrol, sticks to the target |

**Modified**

- `sec_boardroom.gd` — three candidate rooms plus a panic room; drop the giant label
- `target.gd` — flee-to-panic-room behaviour on ALARM
- `game.gd` — route guard events into `alert_state`; own the objective machine
- `hud_feed.gd` — show the current objective and the building alert level
- `guard_posts.gd` — reinforcement spawn points per sector
- `sec_mezzanine.gd` — the floor directory; chatter patrol pairs

**Sequencing.** F2 (alert + lockdown) is the spine — F1's intel sources close on alert, F4's
target flees on alert, and F3's return leg is only interesting because the building is hostile.
Build F2 first, then F1, F4, F3.

---

## Model allocation

| Task | Model | Why |
|---|---|---|
| F2 alert state machine + lockdown | **Opus 5** | Cross-cutting: touches guards, target, doors, objectives. Ordering and edge cases matter. |
| F2 reinforcement placement | **Sonnet 5** | Data entry into `guard_posts.gd` once the spawn contract exists. |
| F1 intel sources | **Sonnet 5** | New `Interactable` subclass against an established pattern. |
| F1 target-room randomisation | **Opus 5** | Must stay readable and fair; interacts with the panic room and all three routes. |
| F3 second leg + terminal siting | **Opus 5** | Placement decides whether the return trip is interesting or just backtracking. |
| F4 bodyguards | **Sonnet 5** | Guard subclass with different stats; the AI already exists. |
| F4 target flee behaviour | **Opus 5** | Timing against the alert and the panic-room route is a balance call. |
| HUD objective + alert readout | **Sonnet 5** | Panel work against `hud_panel.gd`. |
| Removing signage, tuning passes | **Haiku 4.5** | Mechanical. |
| Barks, chatter, directory copy | **Fable 5.1** | F1's guard chatter is a writing feature as much as a mechanic. |
| Smoke-test cases | **Sonnet 5** | Extending `tools/smoketest.gd` against clear assertions. |

---

## Verification

Extend `tools/smoketest.gd`:

- **Every target room is reachable by every operative**, in both CALM and ALARM states — the
  new failure mode is a randomised room that one route cannot get to once doors lock.
- **The panic room has a viable approach for each route**, including a loud one for Chad.
- **At least one intel source is obtainable on each route** without leaving that route.
- **Lockdown never seals the player in** — no combination of locked doors creates a region with
  no exit for the operative who can reach it.

**Timed by hand, which is the only real test:** run each operative blind-ish and stopwatch it,
then run each optimally. The plan succeeds if the blind run lands 5–8 min and the mastered run
60–90 s. If the mastered run creeps past ~2 min the friction has become tax rather than skill,
and the fix is to make intel faster to obtain, not to shrink the level.
