# Phase 2 revision — paste everything below the line into a fresh chat

First: `/clear`, then `/model claude-fable-5-1`, then paste.

---

You are the author of `docs/LEVEL-compound.md` (HOLLOWAY CAMPUS), returning to revise it
after an adversarial review. Plan §2: the author revises, the reviewer re-checks. You are
not re-reviewing your own work and you are not defending it — you are applying findings.

Read, in this order:
1. `docs/REVIEW-compound-r1.md` — the findings. 5 HIGH, 8 MEDIUM, 10 LOW.
2. `docs/LEVEL-compound.md` — your design, the thing you are editing.
3. `docs/PLAN-level-compound.md` — §0 decisions, §1.5 convergence rule, §3.3 bands, §3.5 alarm.
4. `CLAUDE.md` — repo invariants.

The review verified the physics against the source before trusting your §0. It holds:
apex 1.84 / 2.87, airtime 1.22 / 1.53, run-jump 12.85 / 8.08 / 18.6, mid-air mantle stacking
confirmed at `movement.gd:152-158` + `mantle.gd:70-85`, no fall damage anywhere. Your bands
are sound. Do not re-derive them.

## Gregory's calls — these OVERRIDE the review where they differ

The review proposed fixes for H4, H5, M3 and M7 that were design decisions, not defects.
Gregory has ruled. Where the review's suggested fix conflicts with the four below, **the
ruling wins** and the review's wording is superseded.

**H4 — the Regular's picks stay the optimal line, but they stop being free.**
Do *not* make L1 exit-only and do *not* move L4. Keep both where they are. The cost is time
standing still in a sightline, and the H3 and M2 guard fixes create it:
- L1 at (10, 0, −17) is 3.6 m off G5's new alley lane. A 3.0 s stationary pick, crouched in
  DARK at that range, is spotted in **1.8 s** — so it only fits the 8.8 s window while G5
  walks south. Write that window into §4.1 and §8 as the price of the 40 s saving.
- L4 on G8's corridor: a 3.0 s pick inside a 4.2 s leg, in LIT. State the margin.
`lockpick` is noise 0.0 in `locked_door.gd`, so exposure is the only lever. Use it; do not
invent a pick-noise value.

**H5 — Chad is the short bloody run, but it must be losable.** Apply:
- R1 and R2 spawn into the **north corridor** (16 m, LIT, straight — guards firing down it at
  22 dmg / 1.1 s), not at the panic-room door.
- Panic-room door overridden to `{smash: 2.5s}` (`LockedDoor.create` supports per-verb
  overrides) — he is stationary and exposed with guards behind him.
- G9 and the target fire the instant the door drops.
- Slam is an 8 s cooldown: he gets one per fight, not three. Say so in §6.
Recount §6's loud-Chad check and §10's Chad row honestly against this. Target: ~170–200 of
250 HP spent in street clothes, losable if he stands in the corridor.

**M3 — the puddle is a gate, not a toll. Accepted as designed.** The dash zeroes
`velocity.y` and skips gravity for 0.35 s; at speed 26 it covers 9.1 m with 6.5 m of i-frames,
so the Wizard crosses a 6 m puddle for **0 damage**. Keep the 6 m puddle and 120 dmg/s. Fix
only the arithmetic: §2.6's "~12 damage" becomes **0**, and §14 case 13's "dashing deals ≤ 20"
becomes **= 0**. Keep the Regular-in-heavy-plate crossing at 38 damage — that is the version
with a cost, and it is the interesting one. Separately: §3's "Wizard running-jump ~8.0 m" is
wrong once he can dash mid-air — the real figure is ~17 m. Nothing in the level depends on it;
correct the table.

**M7 — leave the gallery reachable from the hall floor.** The 1.5 m step stays. The cheap way
up means walking into the LIT hall past G9 first, and that is the cost. Do not add a parapet.
Correct §2.4 (delete "reached only from the void grille"), §12's hall row, and §14 case 14 to
say so.

## Apply, without re-litigating

**HIGH — all five are blocking.** H1 and H2 are the two that make routes impossible or fatal:
- **H1**: the Wizard cannot climb 3.0 m out of the undercroft. Add the ramp in the caretaker
  spur, base (−18, −3.0, −9.5), dir +x, run 4.0, rise 3.0, landing (−14, 0, −9.5). Fix §14
  case 14's false claim about the hatch.
- **H2**: the panic room one-way-traps the Regular. Interior release on the door (a `switch.gd`
  with no verb requirement), and state the barred window is shoot-through so his ALARM kill is
  a suppressed headshot from the north yard rather than a one-way drop. Add the panic room to
  §14 case 14.
- **H3**: G5's roof post sees nothing. Move him to the alley floor:
  **(13, 0, −19) ↔ (13, 0, 4)**, 23 m, 8.8 s/leg, ~19.6 s loop. This **rewrites** §5's
  sightline table and §12's alley row — do not patch them, rebuild both. Decide whether the
  gym roof still needs a post at all now that E2's approach is unwatched, and say why either way.
- **H4, H5**: per Gregory's calls above.

**MEDIUM — all eight, as written in the review**, except M3 and M7 above. M2's G8 fix
(−9, 4, −4) ↔ (2, 4, −4) is load-bearing for H4 — apply it exactly.

**LOW — all ten.** Bookkeeping: volume overlaps, stair-top offsets and the missing north-stair
landing, the stale mezzanine-ramp coordinates in §2.5, the "2.4 m drop" that is 0.4 m, the
kitchen/north-corridor adjacency, the two 2.0 m band-edge ledges → 2.2, the skip's 1 m gap,
§12's four omitted shared spaces, §14's three gaps, the sprint figure.

## Constraints

- Keep the document under ~600 lines (plan §1). This is a revision, not an expansion — if a
  fix makes a section longer, find the compensating cut.
- Every number stays on a 0.5 m grid. Every new value traces to `verbs.gd` / `characters.gd` /
  `abilities.gd` / `guard_data.gd`, or is flagged NEW in §3 and the appendix.
- Do not edit `PLAN-level-compound.md`. Your §0 already notes that the plan's §3.3 "dash gap"
  row should be struck; leave that to Gregory and mention it in the changelog.
- Do not add a HUD element, a detection meter or a stealth gauge (D11).
- No character checks anywhere — gates are verbs or collision (plan §3.2).

## Output

Rewrite `docs/LEVEL-compound.md` in place. Then append a short **§15 Changelog** — one line per
finding ID, what changed, and the section it landed in. Mark anything you deliberately did not
apply with the reason; the reviewer will check those first.

Opus 5 then re-reviews in a fresh context. Cap is one more loop after this, then Gregory
arbitrates.
