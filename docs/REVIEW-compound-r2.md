# REVIEW — HOLLOWAY CAMPUS r2 (Phase 2, loop 2, adversarial)

Reviewed against `PLAN-level-compound.md`, `REVIEW-compound-r1.md` and the repo. **Every
number re-derived from source, not from r1.** r1's physics stand; this pass went after the
things r1 took on trust — the noise system, the capsule, the cone, the helper signatures.

The r1 findings are all correctly discharged. H1 (undercroft ramp), H2 (panic-room release
+ shoot-through window), H3 (G5 to the alley floor), M1 (gatehouse outside the wall), M5
(CSD pair), M6 (toilets DARK), M7 (gallery documented as shared), M8 (west corridor DARK)
and every LOW are in and consistent. H4 and H5 were rulings and are applied as ruled.

What follows is new. The headline: **§0 checked the movement code and not the sensing
code**, and three of the four HIGH findings come from that half of the repo.

---

# HIGH

**N1 — `noise` is a radius in metres, not a magnitude, and nothing compares it to a
threshold. §4.2.2 / §4.3.2 / §6.**

`game.gd:88` — `emit_noise(pos, radius)` — and every caller passes the ability's `noise`
value straight in as that radius (`kit_regular.gd:22`, `kit_chad.gd:35,48`,
`kit_wizard.gd:49,66,114`, `interactable.gd:139`). Guards inside it call `hear_noise()`,
which sets `detect = max(detect, 0.5)` and enters SUSPICIOUS. There is no magnitude, no
threshold, and no LOS check — `distance_to` only, so walls do not attenuate.
`GuardData.hearing_range = 30.0` is dead data; nothing reads it.

Three consequences, in descending order of damage:

1. **The Wizard's signature entry wakes the guard standing next to it.** §4.2.2: "arcane
   … 12 noise. G3 is 6m away through the wall, but 12 is below any threshold worth
   raising." 12 is a **12-metre radius**. G3's lane is x = −25, z [−16, 14]; the warded
   door is at (−31.5, 0, −8). His closest approach is ~6.7m and his whole southern third
   is inside the circle. Unwarding the door sends him to investigate it, at
   `investigate_speed` 4.0, with his meter pre-loaded to 0.5 — on the Wizard's **first
   action**, before he is through the door. This is the one step in his vector that has no
   alternative.
2. **Chad's wall is a 45m circle, not a 30m one.** §4.3.2's "every guard within 30m: G2,
   G4, G5" is read off the unused `hearing_range`. At 45m from (22, 0, 24) the breach also
   catches G7 in the lobby (37m) and G3's north end (~43m), and misses G1 (60m), G9 (48m)
   and G6 — a different set from the one §5 and §6 are balanced against.
3. **Noise raises SUSPICIOUS, never ALARM.** §6's trigger list ("a *loud* shot within 12m
   of a guard"; the cracked wall) describes behaviour F2 must add. Today a pistol shot is
   a 25m circle of investigating guards. That is fine as a design target — F2 is a Phase 3a
   prerequisite — but §6 must say so, and the numbers it hands F2 are currently radii
   wearing magnitudes' clothes.

**Fix (three parts, all cheap):**
- State in §6 that F2 changes `emit_noise(pos, radius)` to `emit_noise(pos, magnitude)`
  with `heard = magnitude >= dist` or an explicit `hearing_range` comparison, and that
  ALARM is raised at a magnitude threshold. Put it in the appendix as NEW alongside
  `alert_state.gd`; it is not free and it is load-bearing for this level.
- Until then, treat every `noise` figure in the doc as metres. Under that reading the ward
  must either drop to ~5 noise as a per-instance override (`WardedSeal` can take the same
  `overrides` dict `LockedDoor.create` does), or G3's south waypoint must move north of
  z = −8 so his lane never enters the circle. The second is better: it keeps the ward's
  cost honest and gives the Wizard a reason to time his own entry.
- Strike "below any threshold worth raising" from §4.2.2. There is no threshold.

**N2 — The Wizard's squeeze cannot be built at `squeeze_h: 0.5` with `BODY_RADIUS 0.4`.
Appendix / §2.6 / §4.2.3.**

Godot's `CapsuleShape3D` constrains height ≥ 2 × radius and enforces it in the setters:
`set_height` silently drops `radius` to `height / 2`, and `set_radius` raises `height`.
`movement.gd:52-61` (`_resize_capsule`) only ever writes `cap.height`. So:

- Setting height 0.5 forces radius 0.4 → **0.25**. The Wizard becomes half as wide.
- Standing back up writes `cap.height = 1.7`, which does **not** restore the radius —
  `set_height` only clamps downward. **The Wizard is permanently 0.5m wide for the rest of
  the run after his first squeeze**, and fits through every 0.6m-wide gap in the level,
  including ones authored as solid.
- Separately, §2.6's squeeze is `tunnel()` at **width 0.8** against a 0.8-diameter capsule:
  zero lateral clearance, 6.8m of it. Even with the radius bug fixed this will jam on
  depenetration.

Note this is exactly why `crouch_h` is 0.85 and not 0.8 — the existing crouch clears the
constraint by 0.05m. The squeeze does not.

**Fix:** the appendix must carry the radius as a second squeeze dimension, not just the
height — `squeeze_h: 0.5, squeeze_r: 0.25`, with `_resize_capsule` writing radius **and**
height in the right order (radius first when shrinking, height first when growing) and
restoring `BODY_RADIUS` on stand-up. Then build squeeze tunnels at **width 1.0**, not 0.8,
and add a smoketest case: after a squeeze-and-stand cycle, the capsule's radius is 0.4
again, and a 0.85 capsule still fails a 0.6m opening.

**N3 — The 1F south window has no floor behind it and cannot be entered. §2.4 / §4.3.5 /
§12.**

The window is (0, 4, −2), "over the void's south edge"; the void is x [−3, 3] with no floor
at y = 4. Chad's route is portico roof (2.4) → window → "a 3m jump to either edge".

The 1.6m rise from the portico roof to the sill is a mantle, and `mantle.gd:77-86` refuses
it: the downward probe runs from `feet + limit + 0.5` to `feet − 1.2` — from y 5.4 down to
y 1.7 — looking for a top surface 0.45m past the wall face. Behind that wall face there is
nothing until the lobby floor at y = 0, well below the probe's bottom. `top.is_empty()` →
`Vector3.INF` → no mantle. And if he jumps it instead (apex 2.87 clears the 4.0 sill), he
enters a 1.0m-wide opening and lands on the void. Either way **the window drops Chad into
the lobby at G7's feet** — the guard §4.3.5 says the route skips.

Worth noting the general rule, because it bites anywhere a doc says "climb in through the
window": a mantle needs a landing surface within `[takeoff_y + 0.25, takeoff_y + limit]`
**0.45m past the lip**, and it ends with `player.velocity = Vector3.ZERO`
(`mantle.gd:41,59`) — you cannot carry momentum through one into a jump.

**Fix:** a 1.0 × 1.2 landing plate at y = 4.0 behind the window, spanning z [−2, −1] at
x [−0.5, 0.5], cantilevered over the void. Chad mantles onto it, stands, then makes the 3m
jump from a standing start to either edge — which is still Chad-only (a Regular's 1.84
apex reaches the plate, but he cannot reach the portico roof at 2.4 to begin with). Add a
case 1 assertion: floor exists at (0, 4, −1.5).

**N4 — G8's loop is 7.0s, not 8.2s, and the AV door is inside his cone for 0.6s of it.
§4.1 (L4) / §5 / §8 / §14.22.**

Two mechanics r1 and r2 both missed:

*The loop.* `guard_brain.gd:52` stops the guard when it is within `ARRIVE_DIST` **0.8** of
the waypoint, so a 5.5m lane is walked as 3.9m legs: 1.5s each. Loop = 1.5 + 3.0 + 1.5 +
1.0 = **7.0s**, under the plan §5 floor of 8s. (`GuardData.waypoint_tolerance` 1.2 exists
but is not what `_patrol` reads.) Every loop in §5 is 1.6m short per leg for the same
reason — G5's legs are 8.2s, not 8.8s; G6's loop is 13.0s, not 14s.

*The cone.* `guard_senses.gd:32` dots the **3D** normalised offset against a **horizontal**
forward. For a target off to the side of a straight lane, the lateral offset is the whole
story. The AV door sits 2m north of G8's lane on a 5.5m lane; a player standing at it
(~1.2m off the lane) is inside dot 0.80 only while the guard is more than ~1.6m away along
x. Walking east from x = −9.8 that is the first **0.65s**; walking west from x = −4.3 it
is the first **0.23s**. The rest of the 7.0s he is either past it or facing away.

So L4 is not a 5.1s window with a 1.1s margin — it is ~6.1 safe seconds out of 7.0, and a
3.0s pick started at any of a dozen moments is free. H4's ruling kept L4 on the strength of
that margin; the margin isn't there. (An overrun into the 0.65s does not ALARM either:
1.26/s × 0.65 = 0.82 detect → SUSPICIOUS, decaying at `lose_rate` 0.5/s.)

**Fix:** the cheap version is to stop trying to price L4 with a cone and price it with
**geometry and a second body** — put G8's east wait where he faces *down* passage W (the
only approach §4.1 allows), or move the AV door onto the corridor's **south** wall at
(−6.5, 4, −2) so the picker stands with his back to the lane at ~0m lateral offset and is
dead centre in the cone on both legs. Either way, lengthen the lane so the loop clears 8s
after the 1.6m `ARRIVE_DIST` haircut: **(−11, 4, −4) ↔ (−3.5, 4, −4)** gives 5.9m legs =
2.3s, loop 8.6s, and still tops out 0.5m short of the void edge for case 22.

And restate the general rule in §5 so the r3 author can apply it everywhere: *a guard on a
straight lane covers his own axis, and only his own axis. Anything more than ~2m lateral is
outside the cone except at long approach range.*

---

# MEDIUM

**M1 — G2's sightline row lists four things his cone never contains. §5.**
Lane (−16, 0, 12) ↔ (14, 0, 12), forward always ±x. Portico (0, −2) is 14m lateral → dot
≈ 0. West exit door (−22, −6) from his west end: 18m lateral, 6m along → dot 0.32.
Refuse-yard gate (16, 19) from his east end: dot 0.27. Only the **gym south doors** (dot
0.89) and **the skip** (dead ahead, 8m) survive — which happily are the two that Chad's
route depends on. **Fix:** trim the row to those two and, if the west exit is meant to be
watched on extraction, that is G3's job (his lane is 3m off it and axis-aligned to it).

**M2 — The crate stair reaches the gym roof without the Chad chain; case 9 fails as
written. §2.4 / §2.5 / §12 / §14.9.**
The link bridge (x [10,16], z [−13.5,−10.5]) has roof **6.6**, and the gym roof is **6.6**
at x = 16 — one continuous surface. The top crate stands at z [−14.5,−13.5], flush against
the bridge, at 7.2 or 8.4. So a Regular who climbs the stair steps *down* onto the bridge
roof and walks to the gym roof, no 6m alley jump. §12's gym-roof row and case 9 ("not via
any ≤ 1.6 chain from the ground") both assume that is impossible. **Fix:** either raise the
bridge roof to 8.0+ (which also removes a free lateral route past G5 at head height), or
own it — rewrite case 9 to "gym roof via the Chad chain, the main roof, **or** the bridge
roof; not from the courtyard or refuse yard by any ≤ 1.6 chain" and add the bridge roof to
§12. The second is more honest and costs nothing; the surface is DARK and leads where the
crate stair already leads.

**M3 — E2's trigger fires from the plant box, one step before the deck. §9 / §14.8.**
`BuildUtils.zone()` is a `SphereShape3D` with `body_entered`. Centre (23, 11.2, −8),
radius 3.5. A player standing on the plant box (top 8.8, x [18,20], z [−9,−7]) has capsule
points as close as (20, 10.5, −8) → **3.08m** from the centre. The extraction fires, and the
final +2.4 Chad-band step — the capstone gate D7 asks for and case 8 asserts — never
happens. **Fix:** radius 2.5 and centre (23, 12.0, −8), or keep 3.5 and centre it at
(24, 12.0, −8). Add to case 8: a capsule standing on the plant box does **not** overlap E2.

**M4 — The squeeze is free. Appendix.**
`squeeze_mana_per_s: 8` against `AbilityData.player().mana_regen` of **18/s**, and
`player.gd:107` regenerates unconditionally. Net **+10 mana/s while squeezing**. Plan §3.6
wanted "a 60 HP character can't hide in a pipe forever"; as specced he refills in there.
**Fix:** either `squeeze_mana_per_s: 26` (net −8/s, so the 2.6s crossing costs ~21) or,
better, suppress regen while squeezing and keep the 8/s — that reads cleaner in the HUD and
does not make the number depend on a global.

**M5 — Case 18 pins the head shape 0.4m below the head. §14.18.**
"a ray at 1.55m hits `head`" (inherited from plan §3a's "~0.22m at 1.55m"). But
`guard_body.gd:24` puts the head **mesh** at y 1.95 (spanning 1.775–2.125), and the body
capsule is height 1.7 centred at 0.9 → it spans 0.05–1.75, so the visible head is entirely
outside the collider today. That *is* the MERIDIAN bug. A smoketest that asserts a head hit
at 1.55 certifies the fix at the wrong height and leaves the mesh/collider offset in place.
Same shapes on `target.gd:31`. **Fix:** case 18 reads "a ray at **1.95m** hits `head`, at
1.2m hits `body`, and the head shape's AABB is inside the head mesh's AABB" — the last
clause is the one that would have caught the original bug.

**M6 — Light-tier volumes overlap by construction; case 12 fails on a naive build. §7 /
§14.12.**
Two declared pairs occupy the same space: the **hall** (LIT, x [−10,6], z [−20,−8], y 4–7)
contains the **gallery** (PITCH, z [−10,−8], y 5.5–7); the **courtyard** (DARK, x [−22,16],
z [−2,24]) contains the **mast disc** (LIT, x [−12,12], z [−2,22]). Case 12 asserts
non-overlap. **Fix:** state the carve explicitly in §7, the way §2.2 already does for the
geometry — hall LIT is z [−20,−10] only; courtyard DARK is the four bands around the disc.
And note that L3's isolator has to *swap* the disc volume's tier at runtime, not delete it,
or the disc becomes untiered (= LIT by default) when it is switched off.

**M7 — The two sentries have no way to face anywhere. §5 (G7, G9) / appendix.**
`GuardPosts` entries are `{"waypoints": [...]}` and nothing else; `guard_brain._patrol`
sets facing only as a side effect of `move_to`, and `guard.stop()` during a wait does not
rotate. A one-waypoint post ends up facing whatever direction it last walked. G7 "faces
south" and G9 "faces east" are load-bearing (G9's back to the landing is the Wizard's whole
step 7). The appendix lists the per-waypoint `wait` as NEW but not this. **Fix:** add
`"facing": Vector3` (or a yaw) to the post dict and have `Guard.setup` apply it when
`waypoints.size() <= 1`. One line in `guard.gd`, and case 1 gains "every sentry post
declares a facing".

**M8 — The shoot-through window needs a collision-layer scheme the repo does not have.
§2.3 / §6 / appendix.**
"rods … on the body-collision layer only: stops a capsule, not a hitscan ray." Nothing in
the project sets `collision_layer` or `collision_mask` on anything — every ray
(`kit_base.gd:40`, `kit_wizard.gd:89`, `projectile.gd:58`, `guard.gd:144`,
`mantle.gd:96`, `movement.gd:105`, `interactor.gd:90`) uses the default mask, and
`BuildUtils.box()` has no layer parameter. **Fix:** list it in the appendix as NEW —
a `BuildUtils.box(..., layer:int = 1)` parameter, a `LAYER_BODY_ONLY` constant, and the
mask set explicitly on the pistol and projectile rays. Also decide, and write down, whether
the **guard's** LOS ray passes the rods: if it does (same mask), G9 and the target can see
the player through the bars, which is probably what you want since they are meant to fire
back; if it does not, the Regular can shoot a target that cannot see him at all.

**M9 — The boiler-house basement is lethal on the return for a light-vest Regular; case 14
would fail. §2.6 / §14.14.**
L3 puts the Regular in the undercroft. The puddle is 6m at 120 dmg/s. Crossing west: heavy
plate 34, light vest 64, street clothes 103 (dead at 100 HP). Past it is the basement,
whose only other exit is the warded door — `arcane` only, from both sides. So a light-vest
Regular who crosses pays 64, finds a door he cannot open, and dies paying 64 to come back.
Case 14 claims a "non-lethal exit usable by **every** operative who can enter it". **Fix:**
either the warded seal opens from the inside with no verb (the same `switch.gd` H2 put on
the panic room — "someone paid for the ward instead of fixing the boiler" writes itself), or
§14.14 is rewritten to exempt the basement explicitly and §2.6 says out loud that the
puddle is one-way for anyone without a dash. The first is better: it turns the puddle into
a Regular shortcut he has to buy armour for, which is a Cruelty Squad decision.

**M10 — Low cover does not hide anyone; `_can_see` targets feet + 1.2m. §4.1.5.**
`guard_senses.gd:35` rays to `player.global_position + Vector3(0, 1.2, 0)` regardless of
stance — 0.35m above a crouched Regular's 0.85 crown. Any cover under 1.2m is transparent
to the LOS test. §4.1.5's "the 0.6 parapet hides a crouch from the alley floor" is not the
mechanism (what actually hides him there is the roof slab edge, and it does so completely).
The claim is harmless here but the rule is not: **do not author any hiding spot in r3 that
depends on cover shorter than 1.2m.** Worth one line in §3 next to the vision-range note,
for the same reason — so nobody "fixes" it later without knowing what it holds up.

---

# LOW

1. **The crate stair's stack count does not close.** §2.2/§4.1.4 say "seven stacks" and
   "seven 1.2 mantles" but list six tops (1.2 … 7.2); the stated footprint z [−17.5, −13.5]
   at 0.5m spacing with 1.0m-deep boxes is exactly seven stacks, whose seventh top would be
   8.4 — the roof itself, making the final mantle a no-op. Case 9's "seven rises of 1.2" is
   right if there are **six** stacks. Pick six and say so.
2. **G3's culvert window is on the wrong leg.** The grate (−25, 0, 6) is *on* his lane, so
   walking north he faces it for 8.5s. The blind window is after he passes it **southbound**:
   ~8.5s of south leg + 1.0s wait ≈ 9.5s, not "behind him for 11s while he walks north".
3. **Every loop in §5 is long by the `ARRIVE_DIST` haircut** (1.6m per leg, ~0.6s). G5 8.2s
   legs / 18.5s loop; G6 13.0s; G2 24.9s; G4 13.0s. Only G8 crosses a threshold (N4).
4. **An unzoned band and an unzoned extraction.** x [16,28], z [8,14] — the canopy and skip
   sit in it — has no entry in §2.2 and no tier in §7. Same for E1's van at (−38, 0, 6),
   which §2.2 puts outside the west alley volume. Case 12 asserts full coverage.
5. **"Courtyard … minus refuse yard" is vacuous** — courtyard is x [−22,16], refuse yard
   x [16,28]. They touch, they never overlap.
6. **The skip is outside the refuse yard.** It spans z [11,13]; the yard is z [14,24] with a
   2.2m fence on its north side. §4.3.3's "two exits: the gate, or the skip" is really
   fence (2.2) → skip (2.2) → canopy, or gate → courtyard → round. Three Chad-band steps,
   not two, and R/W cannot see the skip from inside the yard at all — which weakens §12's
   refuse-gate row ("the skip they find in it is a wall to them"); they don't find it.
7. **`BuildUtils.label()` always billboards and sets `no_depth_test = true`.** §13 wants
   "no billboard for the ones on walls", and eighteen signs rendering through geometry
   across a 90×90 level is its own problem. Needs a `billboard: bool = true` parameter in
   the appendix's NEW list.
8. **The Regular's mastered column sums to 53s** (10+12+6+3+22) against §10's stated
   "~55–65s", the plan's 45s floor and the definition of done's 60–90s. It is inside the
   floor but outside the DoD band; either the row or the DoD should move.
9. **`tunnel()` builds no end caps** (`build_utils.gd:135-153`, and CLAUDE.md says so in
   bold). Case 2 checks sealed above and to the sides but not the ends. Add it — this is a
   bug class the repo has already shipped once.
10. **The main-block parapet at 0.6 is a mantle, not a step.** `movement.STEP_HEIGHT` is
    0.45. §3's "every parapet 0.6 on the main block (a step, not a gate)" should read
    "a mantle, not a gate". The gym roof's 0.4 parapet *is* a step.
11. **§6's ALARM kill through the bars is three shots, not one.** "a suppressed headshot
    through the barred window from the north yard at 4m" — the target is 100 HP
    (`target.gd:8`) and a suppressed headshot is 43.75. It is 2 headshots + 1 body over
    ~0.5s, through a 0.3m gap between rods, while G9 stands in the room. Still viable;
    say what it costs.
12. **672 lines against the plan's ~600 guardrail.** Not a defect, but §15's changelog and
    §12's audit are now the two longest sections in a document Phase 3 reads for numbers.

---

## Things that hold up

Every r1 fix landed and none of them broke something else. The undercroft ramp (0.75) is
legal and the spur geometry closes. The panic room now has three character-shaped entries
and one verbless exit — the cleanest bit of systems design in the document. G5 on the alley
floor is a genuinely countable window and the arithmetic checks out to two decimal places
(0.227/s at 6.8m horizontal, 4.4s to full inside an 8.2s leg), including the part r2 got
right by accident: because `_can_see` dots a 3D offset against a horizontal forward, the
upper stacks fall out of the cone on their own at dot 0.515 — the shape §4.1.4 describes is
real and it is free.

The Chad bands are still sound end to end and the parapet/bridge-roof interaction that
worried me resolves correctly: bridge roof 6.6 → main roof parapet 9.0 is 2.4, inside his
band and outside everyone else's, and the parapet gap is authored at z [−15,−13.5] where
the crates land and nowhere else, which is exactly the 0.5m of care that had to be taken.
`health.gd` has no fall damage, so every drop in the document is free and none of the
soft-lock claims depend on one. Mana budgets clear comfortably (100 max, 18/s regen, against
30 + 15 on the Wizard's critical path). The void remains the best-tuned moment in the level.
The satire is better than r1's and §13 is ready to place.

## Verdict

**Not yet buildable, but nothing needs redesigning — all four HIGHs are local.** N1 is a
systems contract that has to be written down before F2 is built, plus one guard waypoint.
N2 is two data fields and four lines in `_resize_capsule`. N3 is a 1.0 × 1.2 plate. N4 is a
waypoint move and a door move.

The pattern worth naming for r3: **r2 verified itself against the movement code and assumed
the sensing code.** Noise, the cone's 3D-vs-horizontal dot, `ARRIVE_DIST`, sentry facing and
the LOS ray's fixed 1.2m chest all shape the guard timings this document is built out of,
and all five differ from what §5 assumes. Fix the four HIGHs, then re-derive **every window
in §4, §5 and §8** against the two rules in N4 — lanes are walked 1.6m short, and a lane
covers its own axis only. My guess is that two or three more windows move, and that G2 and
G6 end up with shorter lanes or a facing.

MEDIUM and LOW are bookkeeping, with the exception of M3 and M6, which are smoketest cases
that would pass a wrong build.
