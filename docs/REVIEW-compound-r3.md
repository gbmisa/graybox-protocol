# REVIEW — HOLLOWAY CAMPUS r3 (Phase 2, loop 3, adversarial)

**The bands are right.** Gravity 9.8, `jump_v` 6.0/7.5 → apex 1.84/2.87; `mantle_h` 1.2/2.5;
`STEP_HEIGHT` 0.45. §0's table is correct; everything built on it stands.

**r2 is discharged.** Loops re-derived off `ARRIVE_DIST` 0.8 (G1 28.5, G2/G3 23.8, G4/G6 13.1,
G5 18.5, G8 8.5) are all correct, and §4.1.4's cone arithmetic reproduces exactly — stack 2 at
d ≥ 4.16, stack 4 at 6.93, stack 6 at 9.96, 0.21/s at 8.7m. The ward is 9.0m from G3's nearest
lane point against an 8m circle; E2 clears a capsule on the plant box by 3.15m against r 2.5;
the N3 plate and the portico chain probe correctly.

What follows is new. r1 checked movement, r2 checked sensing; **r3's blind spot is the third
dimension and runtime state** — headroom, floor heights, volume *y*-extents, and what a guard
is still doing ninety seconds in.

---

# HIGH

**H1 — The gallery is 1.5m tall; the Regular cannot stand in his own firing position.
§2.4 / §4.1.6–7 / §7 / §12.**
Hall floor 4.0, ceiling 7.0, gallery floor **5.5** → 1.5m against `STAND_H` 1.7 (§7 states it:
`gallery z [-10,-8], y [5.5, 7]`). He drops through the grille at 7.0 standing and lands 0.2m
inside the ceiling slab — depenetration, not a landing — and cannot crouch out of it, arriving
airborne while `_update_stance` only crouches on a held key. The same fault sits under him:
§7's `y [4, 5.5]` beneath the gallery is also 1.5m, so the hall's south strip is unwalkable.
**Fix:** gallery floor **5.0** (a 1.0m step = a mantle, shared band), headroom 2.0, grille drop
2.0; fill `y [4, 5.0]` beneath it **solid** (raked seating) and delete that §7 row. Case: 1.8m
clear above every gallery and hall floor tile.

**H2 — East of the void the corridor is 1.0m wide, and passage E touches it at one point.
§2.4 / §4.3.5.**
Corridor `x [-13, 4]`, void `x [-3, 3]` → the east shelf is `x [3, 4]`, half §3's stated
corridor minimum — and it is where Chad's **2.5m jump off the N3 plate lands**, on the lip of a
4m drop into G7's lobby: the failure N3 was written to remove. Worse, passage E is
`x [4, 10], z [-8, -6]` and the corridor `z [-6, -2]`. They share the point (4, −6) and nothing
else — **no route exists from the south corridor to passage E, the east landing or the
bridge.** **Fix:** floor plate `x [3, 6] × z [-8, -2]` at y 4.0; east stair well to
`x [6, 10]`, ramp base (9, 0, −4) rising west to (6, 4, −4).

**H3 — The barred window's layer scheme is inverted; the rods stop nobody. Appendix / §2.3 /
§6 / §14.16.**
Nothing in the repo sets `collision_layer`/`collision_mask`; every body is Godot's default
**layer 1, mask 1**. The appendix puts the rods on layer 2 and has bodies "keep the default
mask (all)" — the default mask is **1**. A layer-2 rod is invisible to the player's capsule and
to guards: the panic room gains a fourth entry anyone walks through, the ALARM lock means
nothing, case 16's sweep fails. **Fix:** rods on layer 2 **and** `collision_mask = 3` set
explicitly on `Player`, `Guard`, `Target`; rays set `collision_mask = 1` at all seven sites —
`PhysicsRayQueryParameters3D.create` defaults to `0xFFFFFFFF`.

**H4 — A sentry's `facing` is destroyed by the first noise in the level and never returns.
§5 (G7, G9) / appendix / §4.1.7 / §4.2.7–8.**
The appendix applies `facing` in `Guard.setup`. But `hear_noise` → `_suspicious` **rotates the
guard at 1.2 rad/s** for the whole scan; `enter_patrol` only sets the indicator, and `_patrol`
with one waypoint calls `stop()` and never rotates. After one investigation — anywhere inside
any noise radius, and Chad's wall is a 60m circle — G9 faces an arbitrary direction **for the
rest of the run**. His back to the west landing is the Wizard's step 7 and the price of the
Regular's gallery. **Fix:** re-apply `facing` in `enter_patrol()` while
`waypoints.size() <= 1`, not in `setup`. Case: after a `hear_noise` + scan + return to PATROL,
yaw is within 0.05 rad of the declared facing.

**H5 — The culvert outfall has nothing to drop into, and that deletes the Wizard's entry.
§2.2 / §4.1.8 / §9 / §14.8.**
§2.2 puts the west alley and the west yard both at **y 0**, so a lip "2.2m above the alley
floor" is at ground level and **E1's culvert is a two-way 1.0m crawl**. The outfall is at
(≈−33, 6) on the west alley; the warded door is on the *same alley* 19m north. Going up the
alley the Wizard reaches a free, silent, mana-free way in **before** his signature gate — the
collapse test failing — and the Regular's shutter becomes optional. `tunnel()` is horizontal,
so the culvert cannot simply be sloped. **Fix:** sink the alley across z [2, 10] to **y −2.2**
as an outfall pit, ramps back to 0 at both ends, van and E1 at (−38, −2.2, 6).

---

# MEDIUM

**M1 — The crate stair's treads are smaller than the body standing on them. §2.2 / §4.1.4.**
Crates 1.0m deep stepping 0.5m → 0.5m of tread against a 0.8m capsule, and `LANDING_PUSH` is
0.5, so every mantle lands **exactly on the next riser's face** and the clearance ray runs
along that plane. **Fix:** crates 2.0 × **1.5** stepping **1.0** (z [−19.5, −12], parapet gap
z [−13, −11.5]).

**M2 — Six consecutive mantles at exactly the mantle limit. §4.1.4.**
Rises of 1.2 against `limit` 1.2 with `rise > limit` → refusal; 8.4 − 7.2 is
1.2000000000000002 as a double. It survives only on the physics safe margin. **Fix:** seven
stacks rising **1.15** (tops 1.15 … 8.05), roof 8.4 by a 0.35 step-up.

**M3 — L4's window is 4.8s, not 5.5s. §4.1 (L4) / §5 / §8.**
5.5s is G8's east leg (2.27s) + 3.0s wait, but the clock starts when he *clears* the door at
t = 0.46 and ends the moment he turns west — the picker at 0.6m lateral is in his cone from
0.8m out, i.e. immediately. 5.27 − 0.46 = **4.8s** for a 3.8s job: margin **1.0s**.

**M4 — Light-tier volumes still have no *y* extents; case 12 fails. §7 / §14.12.**
M6 carved in *xz* only. Three stacks overlap: gym floor LIT vs gym roof DARK; main block vs
main roof; alley DARK vs bridge interior LIT vs bridge roof DARK at x [10,16], z [−13.5,−10.5].
**Fix:** every §7 row carries `y [lo, hi]`.

**M5 — Case 13 is armour-dependent, and its "= 0" is a one-frame assertion. §14.13.**
"Walking at 6.6 m/s deals ≥ 100" is street clothes only (heavy plate 54). And 6.0m at dash
speed 26 is 0.2308s against 0.25s of i-frames: **~1 physics frame** of margin. **Fix:** puddle
**5.0m**; assert `= 0` for a dash begun within 0.5m of the edge, `dmg_mul 1.0` in the ≥ 100 case.

**M6 — The gatehouse has no stated height and abuts the outside of the 4.0 wall. §2.1–2.2.**
Case 8 fixes its openings, nothing fixes its roof; a 2.4m roof is a Chad step onto a wall top
he can then walk. **Fix:** roof flush at **4.0**, avenue faces sheer, swept by case 6.

**M7 — The hatch crate is 2 × 2 under a 1.6 × 1.6 hole. §2.5 / §4.3.4.**
0.2m of crate top on every side has 0.4m of headroom, and `_find_ledge`'s 1.45m clearance check
refuses the mantle unless `dest` lands inside the hole. **Fix:** hole 2.0 × 2.0.

**M8 — "West foyer, open west to west stair well" is closed by the ramp. §2.3.**
The ramp tops out at x = −13 with `thickness` 1.2 perpendicular; its underside is y 1.66 at
x = −14, 0.86 at x = −15, so ground passage is blocked from x ≈ −16 to −13.7. §2.3 declares an
opening that isn't one. **Fix:** delete it, or move the ramp base to (−17, 0, −4).

---

# LOW

1. Case 3 says squeeze gaps are 0.6 × 1.0; the west-corridor shutter gap is 0.6 × **3.0**.
2. Case 19 must exempt one-waypoint posts — G7 and G9 have no loop to put in [8s, 40s].
3. §4.1.7's 0.045/s assumes crouched; standing on a 2.0m gallery (H1) it is 0.10/s. §2.6's
   "wade = 108" is likewise street clothes (heavy plate 38).
4. §4.2.4: the dash from z = −17 ends 0.1m inside the run's south wall; he stops at −8 *beside*
   the spur mouth. The duct floor (8.4) and the void's top (8.0) don't meet.
5. `_suspicious` spins the guard at 1.2 rad/s for 3.0s and holds until `detect < 0.15`. No
   window in §4/§5 is priced against an investigating guard.
6. 767 lines against the ~600 guardrail; §15 going on acceptance still leaves ~730.

---

## What holds up

Convergence passes on re-test and §12 missed no shared space; collapse passes once H5 is fixed.
Tier coverage is complete in *xz* and every vector touches all three. The soft-lock sweep is
clean. Chad's ALARM trace recounts to ~176 of 250 and is genuinely losable at the smash. L1, L4
and G5's stair are real countable windows. Nothing reads as a Dishonored sneak.

## Verdict

**Buildable after the HIGH fixes; no vector needs redesigning.** All five are local: one floor
height (H1), a floor plate and a stair moved 2m (H2), a mask value (H3), one line moved from
`setup` to `enter_patrol` (H4), one sunken alley segment (H5). H1 and H2 are geometry Phase 3
hits on its first walk; H3 and H4 would have shipped as "the AI is weird".

One point for the arbitration rather than the author: **the rush test passes only because of
F2.** Chad reaches the hall ~16s from spawn with nothing in the way; the level's answer is that
the target left at t = 0. F2's flee behaviour is not a consequence system here, it is the only
pacing gate on the fastest character — so it must be built and tuned **before** the first Chad
stopwatch, not alongside it.
