# Phase 2 launch — paste everything below the line into a fresh chat

First: `/clear`, then `/model claude-opus-5`, then paste.

---

You are the Phase 2 adversarial reviewer for a Godot 4 immersive-sim level. Fresh context on
purpose — you did not write the design and you should try to break it.

This is **loop 3** — the last before Gregory arbitrates. Read, in this order, and nothing
else first:
1. `docs/PLAN-level-compound.md` — the process plan. §0 holds the decisions (D1–D14), §1.5 the
   convergence rule, §3.3 the gate bands, §3.5 the alarm numbers. Phase 2 is your brief.
2. `docs/REVIEW-compound-r2.md` — the previous loop's findings (4 HIGH, 10 MEDIUM, 12 LOW).
3. `docs/LEVEL-compound.md` — the design under review (r3). §0 states the physics and
   sensing facts the whole design depends on; **§15 lists every r2 finding, the ones marked
   DEV where the author departed from your suggested fix, and the author's own corrections —
   check those first.**
4. `CLAUDE.md` — repo invariants.

Then verify the claims yourself before trusting them. Movement: `scripts/player/movement.gd`,
`scripts/player/mantle.gd`, `scripts/data/characters.gd`, `scripts/data/verbs.gd`,
`project.godot` (gravity). Sensing — r2 found the design had never checked it:
`scripts/enemies/guard_brain.gd`, `scripts/enemies/guard_senses.gd`, `scripts/enemies/guard.gd`,
`scripts/enemies/guard_body.gd`, `scripts/core/game.gd` (`emit_noise`), `scripts/data/guard_data.gd`.
Costs: `scripts/world/interactables/warded_seal.gd`, `locked_door.gd`, `breakable_wall.gd`.
Helpers: `scripts/world/build_utils.gd`. If the design's jump/mantle numbers are wrong, every
ledge band is wrong — say so first.

**Do not edit any file.** Research and report only.

Run every acceptance test in the plan's Phase 1 table (§ column, 14 rows) against the design,
then the Phase 2 attacks:

- **Collapse test** — is there one *entry* everyone would take if they could? Is any
  signature entry slower than a shared alternative for its own character?
- **Rush test** — 7.6 m/s, sprint 1.6×, running-jump 18m, no gates respected: straight-line
  spawn → target time. If under 40s and nothing stops it, the level has MERIDIAN's problem.
- **Roof exposure** — from G5's loop, how many seconds per loop is the crate stair visible,
  at what distance, in which tier? Compute detect time with `guard_data.gd` numbers. Is it
  countable and learnable, or trivial / impossible?
- **Wizard cooldown** — where does a mistimed dash (1.2s cd) leave him, and who sees it?
  The puddle: is 120 dmg/s with 0.25s i-frames in a 0.35s dash actually ~12 damage, or does
  dash speed make the exposed distance different? Find dash speed in `abilities.gd`.
- **Chad under ALARM** — trace wall → deck with the alarm data in design §6. Count guards
  met, shots taken (22 dmg, 1.1s cd, 0.55s telegraph). Winnable? Tense? Or a restart?
- **Extraction test** — for each of E1/E2/E3, who can physically reach it, and does the
  gate hold by collision only? Can Chad *always* reach one after the kill, under ALARM?
- **Tier test** — walk each vector and list the light tier per step. Any PITCH pocket that
  trivialises a guard? Any vector with no DARK moment?
- **Soft-lock sweep** — every pit, roof, side room, the undercroft, the gallery, the deck,
  the refuse yard, the gatehouse. Who can enter, and can they leave?
- **Band audit** — every ledge in the design: is its rise ≤1.6, in [2.0, 2.6], or ≥3.4?
  Flag anything in (1.6, 2.0) or (2.6, 3.4). Include parapets, the portico, the outfall lip,
  the hatch crate, every crate on the crate stair, the skip/canopy/roof/plant-box/deck chain.
- **Adjacency audit** — the room tables in §2.3/§2.4: does every door connect two rooms
  that actually touch? Does every ramp's top land beside a floor at its height? Can a guard
  loop's two waypoints see each other (guards walk straight lines)?
- **Lockpick rule** — is any lockpick door on a critical path for anyone, including under
  ALARM?
- **Convergence** — re-run §1.5's test on every shared space in design §12; also look for
  shared spaces the author didn't list.
- **Feel** — does any part read as a slow Dishonored / Splinter Cell sneak rather than a
  Cruelty Squad line (plan §1.0)? Does anything on screen amount to a stealth gauge (D11)?

Output: a findings list ranked **HIGH / MEDIUM / LOW**. Each finding: what's wrong, where
(section + coordinates), why it matters, and a concrete fix in numbers or geometry — not
"reconsider". Then a one-paragraph verdict: is this buildable as-is, after the HIGH fixes,
or does it need a redesign of one vector? Keep the whole report under 1500 words. Write it
to `docs/REVIEW-compound-r3.md`.
