# REVIEW — HOLLOWAY CAMPUS r1 (Phase 2, adversarial)

Reviewed against `PLAN-level-compound.md` and the repo. **Physics re-derived from source first.**

## Physics check — §0 is correct

`project.godot:25` g=9.8; `characters.gd` jump_v 6.0 / 7.5. Apex 1.84 / 2.87 ✓. Airtime
1.22 / 1.53 ✓. Run-jump 12.85 (7.0×1.5 sprint) / 8.08 / 18.6 ✓. Finding B confirmed:
`movement.gd:152-158` calls `mantle.try_start()` on every jump press, `mantle.gd:70,84`
measures rise from *current* feet → reach = apex+mantle (3.04 / 5.37). D14 is a real
prerequisite. §4.1's detect math is exact: 1.4×(1−10/34)×0.45×0.45 = 0.200/s → 5.0s ✓.
`health.gd` has **no fall damage**, so every drop below is free. All ledge bands hold.

---

# HIGH

**H1 — The Wizard's vector is impassable. §2.6 / §4.2 step 5.**
The undercroft floor is −3.0; the caretaker hatch at (−16, 0, −9.5) is a **3.0 m rise**.
Post-D14 the Wizard's ceiling is 1.84 (jump) / 1.2 (mantle). He cannot climb out. §14 case 14
asserts "the undercroft's exit is the hatch up — a 0.85 capsule from the spur"; that is false,
and 3.0 sits in the (2.6, 3.4) unbuildable gap. Today it works *only* because of the bug D14
removes. It is also a soft-lock: the squeeze back west is the sole exit.
**Fix:** `ramp()` in the caretaker spur, base (−18, −3.0, −9.5), dir +x, run 4.0, rise 3.0
(0.75 — legal), landing (−14, 0, −9.5) under the hatch.

**H2 — The panic room soft-locks the Regular, and §6 routes him into it. §2.3 / §6.**
Door `{smash, arcane}`; window `{arcane}`; hatch 4.0 m overhead. The Regular's only entry is
the staff-room hatch — a one-way drop into a room he cannot open from inside. §6 names exactly
this as his ALARM answer, and §14 case 14 omits the panic room entirely.
**Fix:** a `switch.gd` release on the door's **inside** face (no verb, opens both leaves), and
state that the barred window is shoot-through, so a suppressed headshot from the north yard is
his ALARM kill and the hatch is a choice rather than a trap.

**H3 — The crate stair has zero exposure. §4.1 step 4 / §5 G5.**
G5's eye is 8.2 m on a **solid 6.6 m roof slab spanning x[16,28]**. A ray from (26, 8.2, −12) to
a crouched climber at (11, 2.6, −19) is at y=4.47 when it reaches x=16 — through his own roof.
From his west waypoint (18, 8.2, 4) it grazes 6.6 at x=16 and is stopped by the 0.4 parapet.
Cone fails too: travelling (18,4)→(26,−12) his forward is (0.447, −0.894); the crate stair
sits at dot 0.766 < 0.80 at the leg's *start* only. Exposure ≈ **0 s of 14 s**, not 7 s. The
plan's "countable window" (§4 definition of done) does not exist.
**Fix:** move the post to the alley floor — G5 waypoints **(13, 0, −19) ↔ (13, 0, 4)** (23 m,
8.8 s/leg, ~19.6 s loop). Walking north he faces the stair head-on: at (13,0,−10) a crouched
Regular on crate 2 (15, 2.8, −18) is 8.7 m out, dot 0.918 ✓ in cone, rate
1.4×(1−8.25/34)×0.45×0.45 = **0.215/s → 4.7 s to detection inside a 8.8 s window**. Countable,
learnable, and the upper crates fall outside his 37° cone — exactly the intended shape.

**H4 — The Regular's own lockpick deletes his showcase line. §4.1 / §8.**
L1 saves the roof (−40 s), L4 saves the void, gallery and hall (−30 s). Every Regular has picks,
so the mastered line is shutter → store → alley → L1 (3 s) → canteen → east stair → L4 (3 s) →
slot → two suppressed headshots. The crate stair, roof, duct, ceiling void and gallery are never
visited. §8's "none is on a critical path" is true and beside the point: they are the *optimal*
path. This is also the feel inversion the plan forbids (§1.0) — the designed line is 40 s of
crouch-crawling and waiting for a pacing target, the shortcut is a Cruelty Squad line.
**Fix:** L1 becomes a push-bar — openable from the kitchen side only (no verb), so it is an
*exit* and a return route, not an entry. Move the AV booth's projection slot behind the void:
put L4's door on the **east** half of the south corridor at (1, 4, −6), reachable only after
crossing the 6 m void, so the Regular's fast kill still costs him G8's window.

**H5 — Rush test: Chad is ~15 s to the hall and ~35–50 s to the win. §4.3 / §10.**
Spawn (0,0,40) → cracked wall (22,0,24) is 27.2 m at 12.16 m/s = 2.2 s + 0.8 s smash. Skip →
canopy → roof → hatch ≈ 6 s. Bridge → east landing → rear door → lectern ≈ 3 s. **~13 s.** The
only thing that stops him is the ALARM relocation he triggers himself and therefore counts on;
the panic room adds ~4 s of walking plus the fight. §10 says 70–85 s mastered; my count is
35–50 s, under the plan's 60 s floor. Between the wall and the target there is nothing but
distance — MERIDIAN's problem in a smaller footprint.
**Fix:** put the cost on the *approach*, not the return. Spawn R1 and R2 into the **north
corridor** (not the panic-room door) so the last 15 m is contested, override the panic-room
door to `{smash: 2.5s}` (`LockedDoor.create` overrides support this), and give the VIP two
escorts. That buys ~20 s inside the fight Chad is built for.

---

# MEDIUM

**M1 — The gatehouse stands in G1's patrol lane.** Gatehouse z[−27,−21] vs north yard
z[−24,−20]: 3 m of it sits in the strip G1 walks at z=−22, between x=−9 and −3. §14 case 19
(mutually visible waypoints) fails. Separately, §2.2 gives it a north window with no sill height
or bars — if it is passable, anyone walks in from the avenue, throws the lever and opens the
gate: a fourth shared entry that collapses all three signatures. **Fix:** gatehouse z[−30,−24]
(wholly outside), door on its south face at (−6, 0, −24) through the wall; window = fixed barred
light, no passage.

**M2 — G8 is unlearnable and ambushes the Wizard's mastered line.** 7 m at 2.6 m/s = 2.7 s/leg,
so §5's "3 s window, 3 s pick" for L4 does not exist. His west turnaround (−12, 4, −4) is 1.5 m
from the west stair top (−13.5, 4, −4) in LIT, which is where §4.2 step 7 surfaces the Wizard:
rate 1.4×(1−1.5/34) = 1.34/s → **0.75 s to full detection**. **Fix:** G8 **(−9, 4, −4) ↔
(2, 4, −4)** — 11 m, 4.2 s/leg, 8.4 s + pauses ≥ 8 s ✓, still covers the void and the AV door,
and frees the stair top and passage W.

**M3 — The puddle costs the Wizard nothing and instantly kills everyone else.** `abilities.gd`
dash: speed **26**, duration 0.35, i-frames 0.25 → the dash covers **9.1 m** and the i-frames
cover **6.5 m**. The puddle is 6 m. Entering at dash start he is out in 6/26 = 0.23 s, inside the
i-frame window: **0 damage, not ~12**. Meanwhile 120 dmg/s kills a 60 HP Wizard in 0.5 s. Binary,
not a cost. **Fix:** extend the hazard to z[−11, −2] (9 m). I-frames undercover it by 2.5 m
→ 0.1 s at dash speed + 0.14 s walking the tail = **~28 damage**, which is what §2.6 claims it is.

**M4 — Six 1.4 m crate rises with ≥2 m lateral offsets cannot be mantled.** `mantle.gd`
limit is 1.2 (< 1.4) and `REACH` is 0.9 m, so each crate is a precision jump-and-land, six
times, and §4.1's "six mantles" is wrong. **Fix:** rises of **1.2 m** (eight crates: 1.2 / 2.4 /
3.6 / 4.8 / 6.0 / 7.2 / 8.4) with lateral offsets ≤ 0.8 m so the mantle probe catches. Still
≤ 1.6, still Chad-irrelevant.

**M5 — The CSD lock costs nothing.** Under ALARM the north corridor reaches the lobby through
the canteen's two doors at (3, 0, −12.5) and (3, 0, −9.5), 3 m apart. **Fix:** lock
(3, 0, −9.5) as well, or move the lock to the west-corridor/north-corridor junction at x=−19.

**M6 — The toilets are a free alarm reset.** PITCH dead end, 10 m from the lobby; crouched
detection there is 1.4×0.45×0.1 ≈ 0.054/s → 18.6 s to notice, against a 60 s decay. **Fix:**
toilets DARK; keep PITCH for spaces with no waiting value (store, refuse yard, undercroft).

**M7 — The gallery is a 1.5 m step from the hall floor.** 5.5 − 4.0 = 1.5 ≤ 1.6, so all three
reach it; §2.4's "reached only from the void grille" and §12's verdict are wrong. **Fix:** either
document it as shared, or a 0.6 m front parapet (lip 6.1 → 2.1 rise = Chad band, R/W blocked,
and the Regular's 1.5 m drop out is unchanged).

**M8 — The Wizard's interior never sees DARK.** PITCH (boiler/undercroft) → LIT (everything
after the hatch). Plan §7 wants all three tiers per vector; the street does not count as his
tool. **Fix:** west corridor + west stair well DARK — boundaries are their doorways, and it
also softens M2.

---

# LOW

1. Volume overlaps (§2 forbids them): west alley x[−36,−28.8] over boiler house x[−34,−28.8];
   alley x[10,16] z[−20,8] over courtyard x[−22,16] z[−2,24].
2. Stair tops land 0.5 m outside their rooms: west (−13.5, 4, −4) and east (4.5, 4, −4) vs south
   corridor x[−13, 4]. North stair run is 6.0, not §2.3's 5.0, and has **no landing plate** at
   y=4.0 between its top (z=−20) and the hall door at (−10, 4, −19).
3. §2.5 still shows the mezzanine ramp at (27,0,−2)→(27,4,−8) although §12 says the fix was
   applied. At x=16 (width 2.4 → x[14.8,17.2]) it clears G4's line at x=18 by only 0.8 m.
4. §4.3 step 4: "drop 2.4 m onto the hatch crate" — crate top 6.2, roof 6.6. It is a 0.4 m step.
5. §4.1: the kitchen (x[3,10]) does not touch the north corridor (x[−19,3]); L1 reaches it via
   the canteen.
6. Refuse-yard fence 2.0 and the outfall lip 2.0 sit on the band boundary with 0.16 m of margin
   over the Regular's apex. Raise both to **2.2**.
7. The skip spans z[12,14]; the canopy ends at z=11 — a 1.0 m gap, not "against". Exceeds
   `REACH` 0.9, so it must be jumped before the mantle. Move the skip to (22, 1.1, 12).
8. §12 omits shared spaces: the gym store / shutter (Regular **and** Wizard — and the shutter is
   time-equal to the ward for him, so his signature entry is optional), the east lane, the
   refuse-yard gate (plain, all three), and the gym roof, which R/W reach by jumping the 6 m
   alley from the main roof at 8.4 down to 6.6.
9. §14 gaps: no case asserts the crate stair is inside some guard's cone for N seconds; case 14
   omits the panic room and mis-states the undercroft; case 19 fails on G1 as built.
10. §3's Regular sprint of 10.5 is right (`sprint_mul` 1.5); the plan's rush figure of 1.6× is
    Chad's, not his.

## Things that hold up

The Chad bands are sound end to end (skip 2.2 → canopy 4.4 → roof 6.6 → plant box 8.8 →
deck 11.2, and parapet 9.0 → deck 11.2 = 2.2 > 1.84). The portico at 2.4 is a genuine
collision gate. E1/E2/E3 reachability is correct and Chad always has E2 and E3 open after the
kill. The void is the best-tuned moment in the level: G8 at 5 m in LIT fills at 1.19/s, so a
0.9 s jump = 1.07 → ALARM and a 0.35 s dash = 0.42 → SUSPICIOUS. Nothing in §9 or §13 reads as
a stealth gauge (D11 clean). Chad's ALARM fight is winnable and tense: five 50 HP guards die to
one punch or one slam each, and he spends ~150 of 250 HP getting through them.

## Verdict

**Buildable after the HIGH fixes — no vector needs redesigning, but two need re-gating.** H1 and
H2 are one-line geometry repairs that happen to be blocking (the Wizard cannot finish his own
route; the Regular can trap himself permanently). H3, H4 and H5 are the same disease in three
places: the level's showcase content is unguarded and therefore optional, so each character's
mastered line drifts to the cheapest door — the Regular to his picks, Chad to a 13 s straight
run. The cure is guard placement and two lock changes, not new geometry: G5 into the alley,
G8 lengthened east, L1 made exit-only, L4 moved behind the void, reinforcements onto Chad's
approach. Re-run the rush and roof-exposure tests after those; everything in MEDIUM and LOW is
bookkeeping the builder can absorb.
