# HOLLOWAY CAMPUS — Level 1 Design (r4)

Vandermeer Institute for Applied Consent, Holloway Campus. Formerly Holloway Road Primary
School. Night. One target, three ways in, three ways out.

Written against `docs/PLAN-level-compound.md` (decisions D1–D13) and the physics in
`movement.gd` / `mantle.gd` / `characters.gd`. Revised against `REVIEW-compound-r1.md`,
`REVIEW-compound-r2.md` and `REVIEW-compound-r3.md`; every r3 finding is accounted for in
§15. Axes: **x east,
z south, y up.** All numbers on a 0.5m grid. Builder may shift a wall ±0.5m; adjacency,
gate heights and light tiers are the contract.

## 0. Two physics findings that shape everything below

**A. Horizontal gaps gate nobody.** Gravity 9.8, `jump_v` 6.0 (Chad 7.5) → apex 1.84m
(Chad 2.87m), airtime 1.22s (1.53s). Running-jump distance: Regular ~12.8m, Wizard ~17m
(an 8m walking jump plus a 9.1m mid-air dash — the dash zeroes `velocity.y` for 0.35s),
Chad ~18.6m. So there is **no dash-gap gate in this level**; horizontal gaps are used only
for *exposure*. The dash's routing value is its 0.25s of i-frames — the energised puddle,
§2.6. *(Plan D1, §1.5, §3.3 and Phase 3c corrected to match, r3; MERIDIAN's vent shaft is
Wizard-only because of the warded gate, not the gaps.)*

**B. Mid-air mantle stacks on jump.** `movement.gd:152-158` calls `mantle.try_start()`
on every jump press, airborne included, and `mantle.gd` measures rise from *current* feet,
so real reach is apex + mantle: Regular ~3.0m, Chad ~5.4m. **Prerequisite fix (D14):**
measure mantle rise from the takeoff floor. Then the honest bands, used everywhere below
and swept by §14:

| Band | Rise | Who | Rule |
|---|---|---|---|
| Shared step | ≤ 1.6m | all (jump apex 1.84 / mantle 1.2) | crates, kerbs, stairs-as-ramps |
| **Forbidden** | 1.6–2.0m | nobody, on purpose | unreadable — never build a ledge here |
| Chad step | 2.0–2.6m | Chad (apex 2.87 / mantle 2.5) | his overland, his extraction |
| Sheer | ≥ 3.4m | nobody | perimeter wall 4.0, "not your roof" faces |

**C. The sensing code (r2 review).** Five facts from `guard_brain.gd` / `guard_senses.gd` /
`game.gd` shape every window below: a guard stops **0.8m short** of each waypoint, so every
lane is walked **1.6m short**; the cone dots a **3D** offset against a **horizontal** forward,
so a lane covers **its own axis only** (a thing L metres off it enters the cone only from
> 2.65 × L away along it — dot 0.80 ≈ 37°); the LOS ray targets **feet + 1.2** in any
stance; `noise` is a **radius in metres**, no threshold, no walls (§6); and a one-waypoint
sentry has **no facing** unless given one — and **loses it permanently on its first
investigation** unless the facing is re-applied on the way back to PATROL (H4: `_suspicious`
spins the guard at 1.2 rad/s, `enter_patrol` only changes the indicator, and `_patrol` with
one waypoint calls `stop()` and never rotates).

**D. Standing room is a gate too (r3).** `STAND_H` is 1.7 and the player arrives at most
places airborne, where nothing crouches him. **Every walkable surface in this document has
≥ 1.8m of clear headroom** unless it is a declared crawl (1.0) or squeeze (0.6). Two spaces
failed this in r3 and both are fixed in §2.4 (H1).

## 1. Briefing and tone

**Level name:** HOLLOWAY CAMPUS
**Target:** Dr. Aurelio Vandermeer, Chief Consent Officer
**Card copy (select screen):**

> HOLLOWAY CAMPUS — A primary school until the council sold it for a pound. Now it scores
> your neighbourhood's *behavioural credit*. Tonight the Chief Consent Officer hosts the
> Q3 Gratitude Audit in the old assembly hall. Attendance is mandatory. His is optional.

**Briefing (in-voice, ~150 words):**

> Vandermeer built the Consent Score on a school playground and the playground is still
> there, floodlit, with a sign about running. Every tenant east of the ring road has a
> number now and the number decides whether the bins get collected. He's presenting the
> quarter's figures to the people who paid for them. Assembly hall, first floor, 21:00.
> Compliance staff on site, contracted, armed, underpaid — they'll shoot you because the
> incident form is shorter than the one for letting you go. Perimeter's a four-metre
> wall with a *STRUCTURAL REVIEW PENDING* notice on it. Old boiler house on the west side
> is warded — someone paid for that instead of fixing the boiler. Get in however you get
> in. When it's done, leave by whatever's open. Nobody's coming for you and the car has
> somewhere else to be at 21:40. Try not to make it a school shooting. It's a school.

The satire is legible because the world pushes back: the signage is the institution
describing itself honestly by accident.

## 2. Footprint and zones

Compound wall: **x [-28, 28], z [-24, 24]**, height **4.0**, thickness 0.8, sheer on all
faces except Chad's cracked section. Whole level ≈ 90 × 90 including the streets; the
compound is 56 × 48 — smaller than MERIDIAN's 60 × 50 tower.

Player spawn **(0, 0, 40)** on the south service road. Night: default exterior tier DARK.

### 2.1 Plan view (y = 0, north up)

```
                  z=-40 ─── AVENUE (E3 car at (0,0,-34)) ───────────────
z=-30         ┌────────┐
              │GATEHOUSE│ (lever; barred window north)   ▲ GATE x[-3,3]
z=-24 ════════╧═══╤════╧═══════════════════════════════╧════════════════╪═══
       │      door (-6,-24)   NORTH YARD  (LIT)   G1 ◄──────────►       │
z=-20 ─┼─┬────────────┬─┬────┬────────────────┬──────┬───────────┬──────┤
  W    │W│PANIC ROOM  │N│REC-│  KITCHEN   L1 ► │            │STORE │  E
  E    │C│(contin-    │S│ORDS│  (10,-19)       │  ALLEY     │(PITCH│  A
  S    │O│uity suite) │T│(L2)│                 │  x[10,16]  │ 1.0m │  S
  T    │R├────────────┴─┴────┴────────┐        │  (DARK)    │shutt-│  T
  (DK) │R│      NORTH CORRIDOR G6     │CANTEEN │  G5 ▲      │er ►  │
z=-11  │I├────┬──────────┬──CSD──┬────┤        │     ▼ crate├──────┤  L
  Y    │D│CARE│ TOILETS  │passage│    │        │       stair│      │  A
  A    │O│(L3)│ (DARK)   │       │    │        │       ▲▲▲  │ GYM  │  N
z=-8   │R├────┴───┬──────┴──┬────┴────┤        │            │ G4   │  E
  G3   │ │W.STAIR │  LOBBY  │E.STAIR  │        │            │      │
z=-2   └─┴────────┴───┬─┬───┴─────────┘        └────────────┤      │ (DARK)
   ◄►             PORTICO (Chad 2.4)                        │      │
                                COURTYARD                   │      │
                    ▓ floodlight mast (0,10) → LIT x[-12,12] ├──────┤z=8
                                                      CANOPY 4.4   │
                    G2 ◄──────────────────────────►  ┌──────────────┤z=11
                                                    │ SKIP 2.2 ▓   │
   culvert grate (-25,6) E1 ►                       │ REFUSE YARD  │
                                                    │  (PITCH)     │
z=24 ═══════════════════════════════════════════════╪═══▓▓▓▓═══════╧═══
                                              CRACKED WALL x[20,24] [smash]
z=32 ───────────────── SOUTH SERVICE ROAD ── spawn (0,0,40) ─────────────────
       x=-28    -22  -19 -13 -10  -3  3  4   10       16         28
```

### 2.2 Volumes (no two overlap; "minus" carves the smaller one out)

| Zone | Extent (x, z) | Floors | Tier | Notes |
|---|---|---|---|---|
| South road | x [-44, 44], z [32, 46] | 0 | DARK | spawn; a parked minibus "HOLLOWAY CAMPUS — CONSENT IN MOTION" as cover at (8, 0, 36) |
| Verge | z [24.8, 32] | 0 | DARK | between road and south wall |
| West alley | x [-40, -28.8], z [-24, 32] **minus the boiler house** | 0, **dipping to -2.2 over z [4, 12]** | DARK | **Outfall pit (H5):** the alley floor ramps down to -2.2 across the full width over z [0, 4], holds -2.2 over z [4, 12], and ramps back up over z [12, 16] (rise 2.2 / run 4.0 = 0.55). The culvert outfall is a 1.0m hole in the compound wall's west face at (-28.8, 0, 6) — **its lip is y 0, i.e. 2.2m above the pit floor**, which is what makes E1 exit-only. E1 van at **(-38, -2.2, 6)**, on the pit floor; open to the west |
| Boiler house | x [-34, -28.8], z [-18, -8] | 0 → ramp down to -3.0 | PITCH | **warded door on the west face at (-34, 0, -13)**, opening onto the alley's 2m strip. Inside: ramp down into the flooded basement; the squeeze mouth at (-28.8, -3, -17.5) |
| East lane | x [28.8, 36], z [-24, 32] | 0 | DARK | leads to the gym shutter |
| Avenue | x [-20, 20], z [-40, -24.8] **minus the gatehouse** | 0 | DARK | E3 car at (0, 0, -34), headlights on |
| Gatehouse | x [-9, -3], z [-30, -24] | 0, **roof 4.0** | LIT | **outside the wall**; its south wall *is* the compound wall. **Roof flush with the wall top at 4.0 and every avenue face sheer** — no ledge in any band, or it is a Chad step onto a wall he can then walk (M6). Door (-6, 0, -24) through the wall into the north yard — the only way in. Lever at (-6, 1.0, -28). North window: fixed, barred, no passage |
| North yard | x [-28, 28], z [-24, -20] | 0 | LIT | wall floods; 4m service strip; nothing in G1's lane |
| West yard | x [-28, -22], z [-20, 24] | 0 | DARK | culvert grate (-25, 0, 6); smoking shelter (R3) at (-25, 0, 16) |
| Courtyard | x [-22, 16], z [-2, 24] | 0 | DARK bands, LIT disc | mast at (0, 0, 10): LIT disc x [-12, 12], z [-2, 22]; DARK is the three bands around it (§7) |
| Refuse yard | x [16, 28], z [11, 24] | 0 | PITCH | **2.2m** fence on its west and north sides (Chad band); the north fence runs along z = 11 under the canopy's south edge; plain gate at (16, 0, 19); the skip stands inside, against the north fence |
| **Gym forecourt** | x [16, 28], z [8, 11] | 0 | DARK | the strip under the canopy, in front of the gym's south doors (was unzoned) |
| Alley | x [10, 16], z [-20, -2] | 0 | DARK | G5's lane x = 13; crate stair **z [-20, -13.5]** (M1); bridge overhead z [-13.5, -10.5]; opens south into the courtyard's DARK east band |
| **Main block** | x [-22, 10], z [-20, -2] | 0 / 4.0 / roof 8.4 | LIT interiors except as §7 | parapet to 9.0; hall ceiling 7.0 with a 1.0m void to 8.0 |
| **Gym** | x [16, 28], z [-20, 8] | 0 / mezz 4.0 / roof 6.6 | LIT; store PITCH | parapet 0.4; east wall *is* the compound wall |

### 2.3 Main block, ground floor (y = 0, ceiling 3.6, slab to 4.0)

| Room | x | z | Doors / openings |
|---|---|---|---|
| West corridor | [-22, -19] | [-20, -2] | **DARK.** West exit (-22, 0, -6) to west yard, plain; **security shutter** across at z = -11, floor to ceiling, with a **0.6m gap** under it (squeeze) — it splits the corridor: the south half holds the west exit, the caretaker door and the stair foot; the north half only the north-corridor junction |
| Panic room | [-19, -13] | [-20, -14] | reinforced door south (-16, 0, -14): `{smash: 2.5s/45 noise, arcane: 0.6s/40 mana/12 noise}` (per-verb override on `LockedDoor.create`); **interior release** on its inside face — a `switch.gd`, no verb, opens the door; barred window north (-16, 1.5, -20) 1.6×1.6: a `WardedSeal` (`{arcane}`) to open, and **shoot-through** — 0.1m rods at 0.4m spacing on **collision layer 2** (bodies collide with it, rays do not — appendix); ceiling hatch (see 1F) |
| North stair well | [-13, -10] | [-20, -14] | ramp base (-11.5, 0, -14) rising **north** to (-11.5, 4.0, -18.5), run 4.5; **landing plate** y 4.0 at z [-20, -18.5]; enter from the north corridor at the foot; exits by the hall's north door |
| Records (L2) | [-10, 3] | [-20, -14] | door (-3, 0, -14) `{lockpick: 3.0s}` |
| Kitchen | [3, 10] | [-20, -14] | servery door to canteen (6, 0, -14); **east service door (10, 0, -19) to alley `{lockpick: 3.0s}` = L1** (north of the crate stair) |
| North corridor | [-19, 3] | [-14, -11] | open west into west corridor; door east (3, 0, -12.5) to canteen; **CSD** south at (0, 0, -11): security door that **locks on ALARM** |
| Caretaker (L3) | [-19, -13] | [-11, -8] | door (-19, 0, -9.5) from west corridor `{lockpick: 3.0s}`; **floor opening** x [-17.5, -14], full width — the undercroft ramp rises through it (§2.6); **MAST ISOLATOR** switch on the west wall |
| Toilets | [-13, -3] | [-11, -8] | door (-8, 0, -8) from west foyer; dead end, **DARK** |
| CSD passage | [-3, 3] | [-11, -8] | north = CSD; south open to lobby; door east (3, 0, -9.5) to canteen — **second security door, locks on ALARM** with the CSD (the pair seals the north side from the lobby side) |
| Canteen | [3, 10] | [-14, -8] | doors: north corridor, CSD passage, kitchen; south door (7, 0, -8) to east stair passage |
| West foyer | [-13, -3] | [-8, -2] | open east to lobby. **No west opening** (M8): the west stair's ramp tops out at x = -13 and its underside is y 1.66 at x = -14, 0.86 at x = -15 — the well is entered at its *foot* from the west corridor, and nowhere else |
| Lobby | [-3, **2**] | [-8, -2] | **double height to 8.0** (the void, now 5.0m — H2); portico door south (0, 0, -2) |
| **Riser block** | [2, 4] | [-8, -2] | **solid y [0, 4]** — services cupboard, no door. It carries the 1F floor that joins the void's east shelf to passage E (H2) |
| West stair well | [-19, -13] | [-6, -2] | **DARK.** Ramp base (-18, 0, -4) rising **east** to (-13, 4.0, -4), topping out on the south corridor's west edge; enter at the foot from west corridor |
| East stair well | [4, 10] | [-6, -2] | ramp base (9, 0, -4) rising **west** to (4, 4.0, -4), topping out on the south corridor's east edge; enter at the foot via passage x [4, 10], z [-8, -6] from the canteen door |

Ground floor tiles without gaps across z [-8, -2]: foyer [-13, -3] · lobby [-3, 2] · riser
block [2, 4] · east stair well [4, 10].

Ramps (`BuildUtils.stairs()`, width 2.4, 8 treads): west/east rise 4.0 over run 5.0 (0.8);
north 4.0 over 4.5 (0.89); undercroft 3.0 over 4.0 (0.75). All under 1.0.

### 2.4 Main block, first floor (y = 4.0)

| Room | x | z | Doors / openings |
|---|---|---|---|
| **Assembly hall** | [-10, 6] | [-20, -8] | floor 4.0, **ceiling 7.0**, void above to 8.0. Main doors west (-10, 4, -11) plain; rear door east (6, 4, -14) plain; north-stair door (-10, 4, -19) plain, off the stair landing. Lectern at (-6, 4, -16). **Gallery**: strip z [-10, -8], floor **5.0** — a 1.0m step from the hall floor (a mantle; anyone already in the hall climbs it) and the landing point under the void grille at (-2, 7.0, -9). **Headroom 2.0** to the 7.0 ceiling (H1). **The volume beneath it, z [-10, -8], y [0, 5.0], is solid** — raked seating, not floor: the hall's walkable floor ends at z = -10, because 1.5m of headroom under a gallery is not a room |
| Staff room ("Wellness Suite") | [-19, -13] | [-20, -14] | door (-16, 4, -14) from west landing; **floor hatch** (-16, 4, -17): 1.0×1.0 hole under a 1.0m-high duct box entered from its south side → drops 4.0m into the panic room |
| West landing | [-19, -10] | [-14, -8] | connects: staff room door (-16, 4, -14), hall main doors (-10, 4, -11), passage W south. The north stair does *not* open here — it tops out at z = -18.5 inside its well and exits through the hall's north door |
| Passage W | [-13, -10] | [-8, -6] | landing ↔ south corridor; its interior is behind the corridor's north wall; its mouth is x [-13, -10] at z = -6 |
| AV booth (L4) | [-10, -3] | [-8, -6] | door **(-9, 4, -6)** `{lockpick: 3.0s}` on the south corridor's north wall, 1.0m east of passage W's mouth (N4); **projection slot** 1.2 wide × 0.4 tall at (-6.5, 5.4, -8) into the hall |
| South corridor | [-13, 4] | [-6, -2] | **the void** at x [**-3, 2**] over the lobby: **5.0m** gap, no rail, no floor — still unwalkable, still the dash showcase, and it leaves a **2.0m east shelf** at x [2, 4] instead of r3's 1.0m lip (H2). West arm x [-13, -3] is 10m. West stair top at (-13, 4, -4), east stair top at (4, 4, -4); **south window** (0, 4, -2) 1.0 × 2.0 open, over the void's south edge, with a **landing plate** 1.0 × 1.2 at y 4.0 behind it — x [-0.5, 0.5], z [-3.2, -2], cantilevered over the void (N3): from the portico roof (2.4) the sill is a 1.6 mantle onto the plate, then a **2.5m standing jump west** to the corridor's west arm. **West only** — the east shelf is 1.5m away but is reached by the east stair or passage E, and the jump that matters is the one onto the side Chad's route continues on |
| Passage E | [**2**, 10] | [-8, -6] | south corridor ↔ east landing. Its floor over x [2, 4] sits on the §2.3 riser block; it meets the corridor along z = -6 over x [2, 4] — **a 2.0m mouth, not r3's single point** (H2) |
| East landing | [6, 10] | [-20, -8] | hall rear door; **bridge door (10, 4, -12)** |
| Link bridge | [10, 16] | [-13.5, -10.5] | enclosed, floor 4.0, roof **6.6 — walkable, DARK, continuous with the gym roof** (M2); lands on gym mezzanine at (16, 4, -12) |

Roof (walk y = 8.4, parapet to 9.0, ≤ 0.3 thick): **vent intake hood** at (6, 8.4, -12),
2×1.4×2, opening on its west face 1.0m tall; the duct runs west 4m **with its floor at 8.4**
and 1.0m headroom to a slab hole at (2, -12), where it **drops 0.4m** onto the hall ceiling
void's floor at 8.0 (void 8.0 → 7.0). A crouched 0.85 capsule clears both. **Parapet gap** on the east face at
z [-15, -13.5] where the crate stair lands. Plant room (work light, LIT) at x [-8, -2],
z [-18, -14], height 2.0 — scenery and a sightline block.

### 2.5 Gym

| Part | Extent | Notes |
|---|---|---|
| Store | x [16, 28], z [-20, -14], PITCH | **roller shutter** on the east wall at (28, 0, -17), 3.0 wide, **jammed 1.0m open** (`tunnel()` 1.0 × 3.0 through the 0.8 wall, end-capped); inner door to gym floor (22, 0, -14); west door (16, 0, -17) to alley |
| Floor | x [16, 28], z [-14, 8], LIT | south doors (22, 0, 8) to the forecourt; **mezzanine ramp along the west wall**: base (17.5, 0, -2) rising north to (17.5, 4.0, -8), width 2.4 → x [16.3, 18.7]; G4's lane runs beside it at x = 20 |
| Mezzanine | x [16, 28], z [-14, -8], y 4.0 | bridge door (16, 4, -12); **hatch crate** at (22, 4, -11): 2 × **2.2** × 2 (Chad step from the mezzanine), top 6.2 — a 0.4m step below the roof hatch |
| Roof | y 6.6, parapet 0.4 (≤ 0.3 thick), DARK, **no post** | **hatch** hole (22, -11) **2.0×2.0** through the slab — the full footprint of the hatch crate below it, or the mantle's 1.45m clearance check refuses any landing outside the hole (M7); plant box at (19, 6.6, -8) 2 × **2.2** × 2 → top 8.8; **helipad deck** x [20, 26], z [-12, -4], **solid y [9.5, 11.2]** on four legs, "H" painted — the plant box abuts its west face |
| Canopy | x [18, 26], z [8, 11], **solid y [3.0, 4.4]** | over the south doors, on posts; the solid depth is the fascia the mantle's chest probe needs (§3) |
| Skip | (22, 1.1, 12), 3 × **2.2** × 2 | spans z [11, 13] **inside the refuse yard**, against its north fence; the canopy's south face (z = 11) is 0.5m past the fence line — inside the 0.9 probe |

Chad's chain: skip 2.2 → canopy 4.4 (+2.2) → gym roof 6.6 (+2.2) → plant box 8.8 (+2.2)
→ deck 11.2 (+2.4). Every step in the Chad band. From the **main roof** (8.4, parapet 9.0)
a Regular's running jump clears the 6m alley down onto the gym roof (6.6) and reaches the
plant box (+0.4 over 9m) but not the deck (+2.2 from the parapet > 1.84 apex). Chad can
jump parapet → deck — legal. The small two also reach the gym roof by the **bridge roof**
(§2.4): from the crate stair's top stack (6.9) a **0.3 step down**, then 6m east — the same place
the crate stair already leads, DARK, watched by G5's lane from below at 0.2/s (M2).

### 2.6 Undercroft (y = -3.0, headroom 2.2, PITCH)

Plant tunnel under the main block's west edge: **west run** x [-22, -19], z [-20, -8];
**caretaker spur** x [-19, -13], z [-11, -8] off its east side. The squeeze from the
boiler-house basement enters the run's **north end** at (-22, -3, -17.5): a `tunnel()`
**0.6m tall × 1.0m wide** (N2), 6.8m long, under the west yard, end-capped.
**Energised puddle** at z [**-16.5, -11.5**]: **5m**, **95 dmg/s**, signed in glowing red at
both ends — it lies *between the squeeze and the spur*, so it is the Wizard's gate and on
nobody's return path (M9). The squeeze mouth at z = -17.5 leaves **1.0m of dry run-up** to
its north edge.

*The dash.* 9.1m in 0.35s with i-frames over the first **6.5m**, so 5m of puddle is crossed
in 0.19s against a 0.25s window: **0 damage for any dash begun within 1.0m of the north
edge** (M5 — r3's 6m puddle left one physics frame of margin and was a coin-flip). You exit
at z = -11.5, half a metre short of the spur mouth, and run on into the wall at z = -8 beside
it.

*Walking it.* Street clothes 0.76s × 95 = **72** — a 60 HP Wizard dies in it, which is what
makes the dash the answer. In light vest he lives on **7 HP**, in heavy plate on 24, at 0.88
and 0.70 speed for the rest of the run: that is a dare with a story attached, not a route.

*The Regular's look (author correction — see §15).* He comes down L3's ramp into the spur and
finds the puddle immediately north of it, with nothing beyond but 3.5m of floor and a 0.6m
hole. Sprinting: street clothes **45**, light vest 33, heavy plate 23 — so the **round trip
is 90 / 66 / 46 of his 100** and is survivable in every loadout. r3 costed this at 120 dmg/s
over 6m, which killed a street-clothes Regular on the way back: a dead end with no
non-lethal exit, exactly what §14.14 forbids. 95 over 5m fixes it without softening the
Wizard's gate. No isolator —
the dash is the answer, armour is a viewing ticket, and Chad can't get here.

**Way out (H1):** the spur is 3.0m below the caretaker's cupboard — sheer for everyone
post-D14. A **ramp** in the spur: base (-18, -3.0, -9.5), dir +x, run 4.0, rise 3.0 (0.75),
landing (-14, 0, -9.5) on the cupboard floor, through the slab opening in §2.3.

Extractions and undercroft are **not** linked (the culvert is separate).

## 3. Metrics table

| | Regular | Wizard | Chad | Source |
|---|---|---|---|---|
| Stand / crouch / squeeze | 1.7 / 0.85 / — | 1.7 / 0.85 / **h 0.5, r 0.25 NEW** (N2) | 1.7 / 1.45 / — | `verbs.gd`; `BODY_RADIUS` 0.4 |
| Walk speed × armour | 7.0 × {1.0, 0.88, 0.70} | 6.6 × same | 7.6 × same | `characters.gd`, `armors.gd` |
| Sprint | 10.5 (×1.5) | none | 12.2 (×1.6) — the plan's "rush test" 1.6× is his figure, not the Regular's | `characters.gd` |
| Jump apex | 1.84 | 1.84 | 2.87 | g 9.8 |
| Running-jump distance | ~12.8 | **~17** (8 + 9.1 mid-air dash) | ~18.6 | §0 |
| Mantle (post-D14) | 1.2 | 1.2 | 2.5 | `verbs.gd`; chest probe at +0.9, reach 0.9, top probe 0.45 past the lip, `mantle_time` 0.3; ends at velocity zero |
| Effective ledge band | ≤ 1.6 | ≤ 1.6 | ≤ 2.6 | §0 |
| Crawl / squeeze gap | 1.0 / — | 1.0 / 0.6 × 1.0 wide | — | |
| Quiet engagement | suppressed pistol 17.5 dmg, headshot ×2.5 = 44; 0.25s cd; 0 noise. Guard (50): two shots. **Target (100, `target.gd`): three** | none — all spells emit noise (dash **4**) | none | **NEW loadout row** |
| Loud engagement | pistol 25 / hs 62.5, **25 noise** | fireball 35 AoE, bolt 70 (20 noise each), Meteor 90 (45) | punch 55 (guard: one; target: two), slam 60 AoE r 5.5, **8s cd**, 30 noise | `abilities.gd` |
| Dash | — | 0.35s, speed 26 (9.1m), 0.25s i-frames (6.5m), 1.2s cd, 15 mana | — | `abilities.gd` |
| Interaction verbs | lockpick 3.0s, **0 noise** | arcane: door 0.6s / 30 mana / 12 noise; **ward 0.6s / 25 mana / 8 noise** | smash: door 0.4s / 45 noise; **wall 0.8s / 60 noise** | `locked_door.gd`, `warded_seal.gd`, `breakable_wall.gd` |
| Guard | vision 34m, cone ±37° (dot 0.80, **3D offset vs horizontal forward**), detect 1.4/s × (1 − d/34), crouch ×0.45, sprint ×1.6, lose 0.5/s, 50 HP, 22 dmg, aim 0.55s, patrol 2.6 m/s, **stops 0.8 short of each waypoint**, **1.0s wait**; LOS ray to **feet + 1.2**; hears any noise whose radius reaches him, no walls | | | `guard_data.gd`, `guard_brain.gd`, `guard_senses.gd`, `game.gd` |

Doors 1.2 × 2.4; corridors ≥ 3.0 wide — **one exception, the void's east shelf at 2.0m,
which is a landing, not a corridor** (§2.4); ramps rise/run ≤ 0.89; crawl gaps exactly 1.0;
squeeze exactly 0.6 tall × 1.0 wide; main-block parapets 0.6 (**a mantle, not a gate** —
step-up is 0.45) and every parapet ≤ 0.3 thick so the mantle's top probe (0.45 past the
lip) lands on the roof. **Every Chad-band ledge is solid at +0.9 above its approach floor**
— the mantle's chest probe must hit something; crates and walls are, slabs on posts are
not, hence the canopy's and deck's solid depth (§2.5). **No hiding spot depends on cover
under 1.2m** — the LOS ray aims at feet + 1.2 in any stance; roof edges and walls hide,
parapets don't. **Every walkable surface has ≥ 1.8m of clear headroom** (§0-D) unless it is
a declared crawl or squeeze; you arrive at most of them airborne and nothing crouches you.
**No ledge rise equals a mantle limit** — 1.2 against `limit` 1.2 fails on `rise > limit`
once floating point is involved (8.4 − 7.2 = 1.2000000000000002), so shared chains rise 1.15
and Chad's rise 2.2–2.4. **Any chain of stacked boxes leaves ≥ 1.0m of tread** — the body is
0.8m across and `LANDING_PUSH` puts you 0.5m onto each one. **Vision range 34m covers the
whole courtyard** — intended; interiors rely on walls. Flagged so nobody "fixes" any of these.

## 4. The three vectors

Format: step → what happens; `(R/W/C)` = what the other two get here: **X** blocked,
**~** can follow badly, **=** can follow. Guard timings use §0-C: lanes 1.6m short,
axis-only cones.

### 4.1 THE REGULAR — "Deliveries"

1. Spawn (0, 0, 40) → east along the road → east lane at (30, 0, 30) → north to the gym
   shutter (28, 0, -17). DARK the whole way. 90m. (W = · C =)
2. **Shutter, jammed at 1.0m.** Crouch through. `tunnel()` 1.0 × 3.0. (W = · **C X** — 1.45)
3. Gym store, PITCH. G4 sees through the inner door (22, -14) only from his north stop,
   and PITCH × crouch ≈ 0.1 × 0.45 × rate — effectively invisible. The west door (16, -17)
   opens 3m east of **G5's lane**: from inside the store, wait for his north stop. (W = · C X)
4. **Alley, DARK.** Crate stair on the main block's east face x [10, 12]: **six stacks**,
   each 2.0 × **1.5**, tops **1.15 · 2.30 · 3.45 · 4.60 · 5.75 · 6.90**, stepping **1.0m**
   south from z [-20, -18.5] (stack 1) to z [-15, -13.5] (stack 6), which is where the
   **parapet gap** is and where the bridge's north face stops. Then a **1.5m jump** through
   the gap onto the roof (8.4) — the mantle declines it at `limit` 1.2 and `movement.gd`
   falls through to an ordinary jump, apex 1.84. **Six rises of 1.15 and one jump** (M1,
   M2: r3's 0.5m treads were narrower than the 0.8m body and its rises sat exactly on the
   mantle limit). 1.0m treads — ~5s clean.
   **Exposure, countable:** G5 walks z = -18.2 ↔ 3.2 at x = 13, 8.2s a leg + 1.0s stops,
   2.0m off the stacks. Height pushes you *out* of the 3D dot, so each stack enters his cone
   only beyond its own range: stack 2 at **4.1m** along the lane, stack 4 at **6.7m**,
   stack 5 at **8.1m**, stack 6 at **9.6m**. Two windows fall out of that:
   - *He turns south (his back to stacks 1–2, everything else too steep).* Stack 6 re-enters
     his cone when he reaches z = -4.7 — **5.2s** into the leg. That is the climb window,
     against a ~5s climb.
   - *He walks north.* Stack 6 leaves his cone at the same point, so the top of the stair is
     only exposed in the **first 3.0s** of his north leg, the bottom for 6.7s.
   Caught on top at 9.8m in DARK, crouched: 1.4 × (1 − 9.8/34) × 0.45 × 0.45 = **0.20/s →
   5.0s to full**. A 5s clock, not a detection. Or remove him: two suppressed shots
   (44 + 17.5) from the store doorway at 3m while his back is turned.
   (W = · C = — only *up*, nothing for him at the top)
5. **Main roof, DARK, unwatched.** What hides a crouch here is the **roof edge**, not the
   0.6 parapet (§3): from the alley floor G5's LOS to a chest at 9.6 clips the wall at
   x = 10 anywhere inside ~18m; from his far south end the gap's lip is visible at
   0.1/s. Vent intake hood at (6, -12), 1.0m opening on its west face. (W = · **C X**)
6. Duct, 4m, PITCH → slab hole → **ceiling void** over the hall, 1.0m, PITCH → the
   **grille at (-2, 7.0, -9)** drops you **2.0m** onto the **gallery** (5.0), which has 2.0m
   of headroom — you land standing, because nothing crouches you in mid-air (H1). (W = · C X)
7. **Gallery, PITCH.** The hall below is LIT. Target paces (-6, -16) ↔ (2, -16), 8–12m
   away. G9 stands outside the main doors facing east: the gallery *is* in his cone and
   his ray passes under the lintel, but PITCH holds it — **crouched** 1.4 × 0.71 × 0.45 × 0.1 =
   0.045/s (22s to full); **standing**, 0.10/s (10s). Either way it is 20× the 0.5s of
   shooting, and the gallery is now tall enough to stand in, so this is a choice rather than
   a consequence of the ceiling. **Three suppressed shots** (two
   headshots + one body ≥ 100) or two loud headshots, which G9 hears. (W ~ — here too if
   he took the vent, but every shot he has is loud · C X)
8. Extract: drop **1.0m** off the gallery into the hall → main doors → west landing →
   passage → south corridor → west stair → ground west corridor (DARK) → west exit (-22, -6)
   → west yard, DARK, G3's loop → **culvert grate (-25, 0, 6)** → 1.0m tunnel 8m west,
   level → **outfall at (-28.8, 0, 6)**, a hole in the wall's west face whose lip is
   **2.2m above the outfall pit** (§2.2, H5) → drop → van (E1) on the pit floor at -2.2.
   The 2.2m lip is a Chad step nobody who fits the culvert can climb, so E1 stays exit-only;
   the pit's own ramps at z [0, 4] and [12, 16] keep it out of the soft-lock list. **G3's window:** the grate is *on* his axis,
   the exit door 3m off it (in his cone from > 4m along the lane). Leave the door as he
   passes it northbound: the grate has his back for the rest of that leg + his stop,
   **9.2s**; the walk is 12.4m (1.8s) and the crawl-in ~1s. (W = · C X)
   *Alternative:* north yard → gatehouse door → lever → gate (E3), LIT, G1.

**Lockpick rewards — the optimal line, and what it costs (H4):**
- **L1** (10, 0, -19), alley side, 2.2m off G5's axis: in his cone only from > 2.9m along
  the lane — nearly all of his north leg (DARK, 0.56/s at 4m: **1.8s** to full), never from
  his north stop. Window: he stops at z = -18.2 (t 0); leave the store, cross the lane
  **behind** him at z = -17, 2m to the door, pick, in — **4.3s** inside his stop + south leg
  + stop = **10.2s**. Inside: kitchen → canteen → **north corridor** (G6, LIT) → north stair
  → hall's north door. The canteen door is *on G6's axis*: enter as he walks west (his
  back, 5.5s) and outrun him to the stair foot (1.4s at sprint), or two suppressed shots
  from the door. Saves the roof (~40s) for two timed windows and a guard.
- **L2** Records: the audit schedule tells a blind player where the target is *and* where
  he'll run. **L3**: mast isolator drops the courtyard to DARK; the ramp down shows him the
  puddle and the squeeze — a view, not a route (§2.6).
- **L4** AV booth: an 8–12m suppressed shot through the projection slot, no hall, no void.
  Approach from **passage W** only (the east stair lands you behind G8 at his west end).
  **Priced by G8's body, not his cone** (N4): he walks the corridor's north side 1m off the
  door, so you cannot be at it while he passes; pressed to the wall you are 0.6m off his
  axis, which puts you in his cone from **0.8m** out — i.e. the instant he turns west, at
  4.7m, LIT, **0.83s** to full. **Window (M3): 4.8s, not 5.5s** — it opens when he *clears*
  the door at t = 0.46, not when he leaves his west stop, and closes when he turns at
  t = 5.27 (east leg 2.27 + 3.0s wait). Job: out behind him, 1m, pick 3.0, in 0.3 = **3.8s.
  Margin 1.0s.** Still the Regular's best kill, and now the margin is the real one.

### 4.2 THE WIZARD — "Decommissioned"

1. Spawn → west along the road → west alley (-32, 0, 30) → north **through the outfall pit**
   (down its south ramp at z [12, 16], past the van at -2.2, up the north ramp at z [0, 4] —
   the first thing he walks past is an extraction he has no reason to recognise), then round
   the boiler house's south face into the **6m strip at x [-40, -34]** → the door on its
   **west face (-34, 0, -13)**. DARK. 80m. (R = · C =)
2. **WARDED DOOR** — `WardedSeal`, `{arcane: 0.6s, 25 mana, 8 noise}`. 8 is an **8m
   circle** (§6): G3's lane at x = -25 is 9m east of it and never inside — nobody hears
   the ward. Prompt for others: "REQUIRES ARCANE". (**R X · C X**)
3. Boiler house, PITCH. Ramp down to the flooded basement at -3.0, signed "ENERGISED — DO
   NOT ENTER — TICKET #4471". The **squeeze** is behind the boiler on the east wall at
   (-28.8, -3, -17.5): 0.6 × 1.0, 6.8m. Hold crouch again; 0.4× walk (2.64 m/s, 2.6s);
   8 mana/s with **no regen while squeezed** (M4) — ~21 mana. (R X · C X)
4. **Undercroft west run, PITCH.** You are at its north end with 1.0m of dry floor. Head
   south: at z = -16.5 the **energised puddle** begins — 5m of it. **Dash from its edge**:
   9.1m in 0.35s, i-frames over the first 6.5m — you are out at 0.19s against a 0.25s
   window, so **0 damage with 1.0m of slack on where you start it** (M5), and you run out
   at z = -11.5, half a metre short of the spur. Standing in it is 95/s and walking it is 72
   of your 60. The dash's 4 noise is a 4m circle; G3's nearest lane point is 5.6m away in
   3D (`emit_noise` measures 3D distance, and you are 3m down). (R ~ · C X)
5. Caretaker spur → **ramp up** (rise 3.0 over 4.0) through the floor opening into the
   caretaker's cupboard (L3 from the inside — the mast isolator is right here, free). Door
   onto the ground **west corridor, DARK.** (R ~ · C X)
6. Choice: north under the shutter (0.6 squeeze — the only way north on this corridor
   without the lobby; it lands you behind G6's west turnaround), or **south 3m to the west
   stair.** Mastered line: the stair. (R = · C =)
7. West stair (DARK well) → top (-13, 4, -4) on the **south corridor, LIT.** **G8** walks
   the corridor's north side, x = -10.2 ↔ -4.3, and faces **east** for 5.3s of every 8.5s
   (2.3s leg + 3.0s at the void) and **west** for 3.3s. Facing west from his west stop he
   looks down the stair's upper half at 2.8–5m in DARK: 1.9s to full standing, 4s
   crouched. Surface while he faces east; 2.5m into passage W (its mouth is 2m north of
   the stair top) → **west landing.** Stay inside the passage, not in its mouth — the mouth
   is in his cone for 1.7s of his west leg. **G9** stands at the hall main doors facing
   east into the hall — his back to the landing. (R = · C =)
8. Kill G9 quietly? Impossible — everything is loud. Charged bolt from the passage (70,
   one-shots him at a headshot; noise → G6 below and G8 investigate); fireball at G9 *and*
   through the doors at the target; or walk past him — a sentry facing away, 3m from the
   passage. **The Wizard's play is tempo**: bolt G9, dash through the doors, fireball the
   target, dash out the rear door before G8 arrives. (R ~ · C ~)
9. Extract: rear door → east landing → **bridge** → gym mezzanine → ramp (beside G4's
   lane) → gym floor → south doors → forecourt → courtyard (LIT — unless L3's isolator was
   thrown) → west yard → culvert (E1). Or north stair → north corridor → shutter squeeze →
   west corridor → west exit → E1. Or E3. (R = · C X for the culvert)

**Why this is the Wizard's:** two collision gates only he passes (0.6 squeeze) plus one
verb gate (arcane), and the only free way across the puddle. He arrives from the *west*
at ground level under the target, through the building's dark half (PITCH → DARK → LIT).
Mana on the critical path: 25 + 21 + 15 = 61 of 100, with regen between. The Regular
arrives from *above*; Chad from the *south and east* with the building awake.

**Dash-as-routing elsewhere:** the void (§2.4) is a 5m gap anyone can jump. G8's back is
to it for his west-facing 3.3s (free); for his east-facing 5.3s he is 1.3–8m from it in
LIT at up to 1.28/s: a 0.8s jump → 1.0 → ALARM, a 0.35s dash (i-frames, 4 noise) → 0.45 →
SUSPICIOUS. The dash is the insurance on a mistimed crossing, not the crossing.

### 4.3 GIGA CHAD — "Structural Review"

1. Spawn → 22m east along the road → the **cracked wall** x [20, 24] at z = 24.
   `BreakableWall`, `{smash: 0.8s, 60 noise}`. Others: "REQUIRES BRUTE FORCE". (**R X · W X**)
2. **ALARM at t = 0.** The wall is an ALARM trigger in its own right (§6); its 60 noise is
   a 60m circle that reaches every guard in the level anyway. `alert_state` → ALARM:
   target flees to the panic room escorted by G9 (~10s); the CSD pair locks; **R1 and R2
   spawn at the two ends of the north corridor** and hold it.
3. **Refuse yard, PITCH.** Two exits: the gate west into the courtyard (LIT centre, G2
   coming), or **the skip (2.2)** at (22, 12) inside the yard against its north fence →
   **canopy (4.4)** → **gym roof (6.6)**. G2 reaches the fence line from his east stop
   (13.2, 12) in ~1.5s at chase speed and fires up at the canopy: the first 22 of the run.
   To the Regular the skip is a wall. (R X · W X)
4. **Overland:** gym roof, DARK, **empty** (no post — §5). Sprint to the **hatch** at
   (22, -11): a 0.4m step down onto the hatch crate (6.2) → mezzanine → bridge door →
   **link bridge** → east landing → hall rear door. The hall is **empty** — the target left
   at t = 0. ~13s from the wall. (R ~ via the mezzanine ramp from the gym floor · W ~ same)
5. **Ground alternative:** courtyard → portico (0, -2). **Portico roof 2.4** → 1.6 mantle
   onto the **landing plate** behind the 1F south window (N3) → **2.5m standing jump west**
   onto the corridor's west arm (x ≤ -3, 10m of floor) → south corridor (1F). West, not
   "either edge": the west arm is where passage W and the hall are, and r3's east lip was
   1.0m wide over a 4m drop into G7's lap (H2). The east shelf is 1.5m the other way and
   2.0m wide now, but it leads to passage E and the bridge, not to the target. Skips G7 in
   the lobby (the plate is outside his cone, 4m above him) and both stairs; G8 at the void's
   west edge sees the plate at ~4m — under ALARM he is already shooting. (R X · W X)
6. Hall → north-stair door (-10, 4, -19) → down → **north corridor: 16m, LIT, straight,**
   G6 patrolling it and R1 + R2 already at its ends firing down it (22 / 1.1s each, 0.55s
   telegraphs). The **panic room door (-16, -14)** is 4.5m west of the stair foot:
   **smash 2.5s** — stationary, back to the corridor. Inside, **G9 and the target fire the
   instant the door drops.** The slam is an **8s cooldown — one per fight**: the stair
   foot (G6 + whoever closed) or the room, not both. Punch: a guard in one, the target in
   two. (R ~ hatch from the staff room · W ~ window from the north yard)
7. Extract: the corridor's other exits are the CSD pair (locked), L1 (no picks) and the
   window (warded). So: north stair → hall → rear door → bridge → mezzanine → hatch crate
   (2.2, his band) → roof → plant box → **deck (E2)**, ~25s, nobody else can follow. Or:
   1F south window → plate → portico roof → courtyard → alley → **north yard** → gatehouse
   door (-6, -24) → lever → **gate (E3)**, ~45s; G1 is ALERT-searching, the gatehouse is
   empty.

**Chad always plays the ALARM variant:** fastest entry, hardest mission, 250 HP as the
budget. Mastered line: skip → canopy → roof → hatch → bridge → hall → north stair → the
corridor → breach → back the same way to the deck.

## 5. Guards

Nine posts plus three reinforcement spawns. Loop = legs at 2.6 m/s over the lane **minus
1.6m** (`ARRIVE_DIST` 0.8 at each end) + 1.0s stops (`guard_brain.gd`); "stops at" gives
the real turnaround points. Facing is direction of travel; sentries carry an explicit
**`facing`** (NEW — appendix). Count is a start (D5).

**Two rules for every window below (N4):** a guard on a straight lane covers **his own
axis, and only his own axis** — a thing L metres off it enters his cone only when he is
more than 2.65 × L away along the lane; and every loop is **1.6m shorter** than the lane.

| # | Post | Waypoints (stops at) | Loop | Tier | Covers | Blind spot & why |
|---|---|---|---|---|---|---|
| G1 | North yard | (-18, 0, -22) ↔ (18, 0, -22) (x = -17.2 / 17.2) | 28.5s | LIT | his axis z = -22: the gate, gatehouse door, panic-room window and alley mouth are all ≤ 2m off it — in his cone from > 5m along it, i.e. on approach | the **gatehouse interior** — outside the wall, one door, he never goes in; the west yard, which turns the corner |
| G2 | Courtyard | (-16, 0, 12) ↔ (14, 0, 12) (x = -15.2 / 13.2) | 23.8s | LIT/DARK | his axis z = 12 across the disc; **the skip and the yard's north fence, dead ahead 8–9m from his east stop**; the gym south doors (4m off axis) from > 10m out (M1) | the portico (14m off axis), the west exit door and the refuse-yard gate — never in his cone; **the alley** (behind the main block's corner); the refuse yard's interior (PITCH, fence); **the mast's own base at (0, 0, 10)**, 2m off his axis — it breaks his lane's LOS for anyone standing behind it, the one piece of hard cover inside the LIT disc |
| G3 | West yard | (-25, 0, -16) ↔ (-25, 0, 14) (z = -15.2 / 13.2) | 23.8s | DARK | the culvert grate (on axis); the west exit door (3m off axis) from > 4m along the lane on both legs; the boiler-house side of the wall (can't see through it) | **the grate for 9.2s after he passes it northbound** (the rest of that leg + his stop); the door for the 4m either side of it |
| G4 | Gym floor | (20, 0, -12) ↔ (20, 0, 4) (z = -11.2 / 3.2) | 13.1s | LIT | store inner door (dot 0.81 from his north stop — barely), south doors from his south stop, the mezzanine ramp (1.3–3.7 off axis) on approach | **the mezzanine itself** (4m up, outside his cone), the store (PITCH) |
| G5 | **Alley floor** | (13, 0, -19) ↔ (13, 0, 4) (z = -18.2 / 3.2) | 18.5s (8.2s/leg) | DARK | the crate stair, but only at range — each stack enters his cone beyond its own distance (§4.1.4: stack 2 at 4.1m, stack 4 at 6.7m, stack 5 at 8.1m, stack 6 at 9.6m), so the *top* of the stair is covered only in the first 3.0s of his north leg; the store's west door and L1 (2.2–3m off axis) from > 3–4m along it; the courtyard's NE corner on his south leg | **everything behind him for 8.2s a leg**; **the whole stair for the first 5.2s after he turns south** — it is too steep to be in his cone until he has walked 13.5m away from it; **L1 and the store door from his north stop** (0.8m along, off axis); the main roof (roof edge); the bridge's underside |
| G6 | North corridor | (-18, 0, -12.5) ↔ (-2, 0, -12.5) (x = -17.2 / -2.8) | 13.1s | LIT | the canteen door and the west junction (on axis); the CSD, panic-room door, stair foot and records door (1.5 off axis) on approach | the **caretaker's cupboard door** (west corridor, round the corner); the stair foot for 3.2s a loop (after he passes it westbound + his stop) — then 0.85s to full from 5.7m |
| G7 | Lobby **sentry** | (0, 0, -6), **facing +z (south)** | — | LIT | portico door (on axis, 4m); the lobby floor | the **void and the plate above** (dot ≤ 0.65 — he never looks up 4m); the foyer and CSD passage (behind / beside) |
| G8 | South corridor (1F), **north side** | (-11, 4, -5) ↔ (-3.5, 4, -5) (x = -10.2 / -4.3); **waits 3.0s at the void end, 1.0s west** | 8.5s | LIT | **facing east 5.3s**: the void from 1.3m, the east stair top (8.3m, on axis). **Facing west 3.3s**: the west stair's upper half (2.8–5m, DARK), passage W's mouth from > 2.65m along (1.7s of the leg), the AV door from 4.7m — 0.83s to full | **the AV door for 4.8s a loop** (from clearing it at t = 0.46 to turning west at 5.27 — M3; the picker is priced by his body, §4.1 L4); **passage W's interior** (behind the corridor's north wall); the stair top and the void while he faces the other way |
| G9 | Hall doors **sentry** | (-11.5, 4, -11), **facing +x (east)** through the doors | — | LIT | the hall's east half and the lectern's east end (the lectern itself is at dot 0.74 — outside); the gallery (dot 0.97, LOS under the lintel) at **0.045/s — PITCH holds it** | **the landing behind him**, the passage, the hall's west half beside him |

**Sentry facing is a state, not a spawn parameter (H4).** `facing` must be re-applied every
time a one-waypoint post returns to PATROL, not once in `Guard.setup`: `_suspicious` rotates
the guard at 1.2 rad/s for the whole scan, `enter_patrol` only changes the indicator, and
`_patrol` with one waypoint calls `stop()` and never turns. Applied at setup only, G7's and
G9's facings survive exactly until the first noise anywhere in their radius — and Chad's wall
is a 60m circle. G9's back to the landing is the Wizard's step 7 and the price of the
Regular's gallery, so this is load-bearing twice over.

**Investigating guards are not priced anywhere below.** A guard who hears something walks to
it at 4.0 m/s, then spins at 1.2 rad/s for 3.0s and keeps spinning until `detect < 0.15`. Every
window in §4, §5 and §8 assumes PATROL. Once anything has been heard, the windows are gone
until he is back on his lane — which is the intended consequence of noise, but Phase 4 should
not read the tables as if it were not.

G8's 3.0s east wait is the one non-default patrol wait in the level (NEW — appendix). His
lane runs the corridor's **north side** so the AV door is priced by his body and his west
leg, not by a cone that never contains it; the void keeps its 1.3m margin (case 22).
**No gym-roof post:** the roof is Chad's chain, priced by G2 at the fence under ALARM; a
post up there saw nothing through its own slab (r1 H3); and a DARK roof overlooking G2's
and G5's loops is the observation point (plan §1.1) for the two who arrive by the bridge
roof or the alley jump.

**Reinforcement spawns:** **R1** north corridor west end (-18, 0, -12.5) · **R2** north
corridor east end (2, 0, -12.5) · **R3** west-yard shelter (-25, 0, 16). Policy (this
level's data, NEW): first ALARM spawns R1 + R2; a second spawns R3; cap +3; any R-post
within 8m of the player at trigger is swapped for R3 (never at the player's back). R1/R2
hold the corridor's ends and fire down it; R3 walks to the panic room door.

**Sightlines that matter, and the two solutions per shared guard (plan §1.5):**
- Regular: G5 → crate stair (a ~5s climb inside the **5.2s** after he turns south; a 5.0s
  clock at 9.8m if the north leg catches you on top) and L1 (4.3s inside a 10.2s window) —
  or two suppressed shots from the store doorway; G6 → the corridor (enter on his west leg
  and outrun him, or two shots from the canteen door); G8 → L4 (3.8s inside **4.8s**);
  G3 → culvert grate (9.2s window).
- Wizard: nobody until the west corridor (DARK); G6 — the shutter squeeze into the
  corridor's west end behind his turnaround; G8 — the stair top during his east-facing
  5.3s (1.9s to full if not), or the void behind his back for 3.3s; G9's back. The exposed
  moment is *after* the kill: the courtyard under the mast if he extracts via the gym.
- Chad: G2 at the fence; G4 if he goes through the gym; G6 + R1 + R2 in the corridor; G9 +
  the target behind the door. G1 has left the north yard (ALERT-search).

## 6. Alarm — this level's data for F2

**Noise contract (N1).** `emit_noise(pos, radius)` is exactly that: an ability's `noise` is
a **radius in metres**; every living guard inside it goes SUSPICIOUS at meter ≥ 0.5 and
investigates at 4.0 m/s — no magnitude, no threshold, no walls; `hearing_range` is unread.
The level is authored to that: **no quiet-path noise circle contains a guard lane point**
(ward 8m vs G3's axis 9.0m away; puddle dash 4m vs 5.6m — `emit_noise` measures **3D**
distance, so the undercroft's 3m of depth counts; case 24). F2 adds one rule on top
and changes nothing underneath: a noise **≥ 25** (loud pistol, slam, smash, Meteor, the
wall) with a guard inside **12m** raises ALARM. NEW — appendix.

Triggers: any guard `detect` = 1.0; **the cracked wall** (an event, not its noise); a
*loud* shot within 12m of a guard (suppressed = 0). SUSPICIOUS at 0.35 as today.

| Consequence | Value |
|---|---|
| Target | flees hall → north-stair door → down → north corridor → **panic room**, escorted by G9 (F2/F4 flee behaviour); ~10s. Both are armed and fire at the doorway the instant the door opens |
| Doors that lock | the **CSD pair** — (0, 0, -11) and (3, 0, -9.5), both sides, no verb. Everything else stays open. Under ALARM the panic room is reached by: north stair (from the hall) → north corridor → door `{smash 2.5s, arcane}`; **staff-room hatch** (crawl, 4.0m drop); **barred window** (arcane to open; shoot-through for anyone with a gun — and the layer scheme that makes it shoot-through is **not** the one r3 wrote: see the appendix, H3). The **interior release** opens the door from inside — nobody is trapped |
| Reinforcements | R1 + R2 into the north corridor's ends (R3 on a second ALARM; cap +3; any post within 8m of the player → R3) |
| Existing guards | ALERT-search toward `last_seen` |
| Extractions | all stay open |
| Decay | ALARM → SUSPICIOUS after 60s unseen; reinforcements return to R-posts; the CSD pair stays locked |

**Loud Chad check (§0 acceptance), recounted (H5):** wall (0.8s) → skip / canopy / roof:
G2 at the fence, ~1 hit (**22**) → hatch → bridge → hall (empty) → north stair → corridor:
G6 + R1 + R2, three guns at 22 / 1.1s with 0.55s telegraphs. Slam at the foot, punch the
rest: ~3 hits (**66**). Smash 2.5s with any survivor behind him: ~2 hits (**44**). Door
drops: G9 + target fire at once, slam on cooldown, punch both (target takes two): ~2 hits
(**44**). **~176 of 250** clean. A Chad who smashes with the corridor uncleared takes
three guns for 2.5s ≈ 150 there alone and dies at the door. Losable, winnable, one slam.

**Blind Regular who trips ALARM once:** from the gallery he watches the target leave. His
way: drop → main doors → landing → staff room → hatch → panic room (25m, quiet) → three
suppressed shots → out by the **interior release** (the DARK west corridor is 3m past the
junction). If he was outside when it tripped: through the **barred window** from the north
yard at 4m — the target is 100 HP, so that is **two suppressed headshots and a body shot
(~0.5s) through 0.3m gaps, with G9 in the room firing back**. Viable either way; neither
is a trap.

## 7. Light tiers

Authoring rule from the plan: three tiers, boundaries on visible edges, no critical-path
door inside PITCH. Guards ignore their own tier. Volumes never overlap: where a tier sits
inside another, the outer one is **carved** as stated (M6).

**Every volume carries a *y* range (M4).** r3 carved only in *xz*, which left three stacks
overlapping — gym floor under gym roof, main block under main roof, and the alley under the
bridge under the bridge roof at x [10, 16], z [-13.5, -10.5]. A tier volume is an AABB and
case 12 tests it as one, so the third dimension is part of the contract, not an implied one.

| Volume | Tier | Boundary is… |
|---|---|---|
| All streets, lanes, verge, west yard, gym forecourt — y [0, 12] (the alley pit's floor is -2.2, so the west alley is y [-2.2, 12]) | DARK | the compound gate/doors |
| Alley x [10, 16], z [-20, -2], y [0, 12] **minus the bridge interior** (x [10, 16], z [-13.5, -10.5], y [4, 6.6]) — so the alley floor under the bridge and the bridge roof above it are both DARK, and only the enclosed bridge is LIT | DARK | the bridge's soffit and its roof lip |
| North yard | LIT | the wall floods; the corner into the west yard (a wall edge) |
| Courtyard mast disc x [-12, 12], z [-2, 22] | LIT | a painted line on the ground ("NO RUNNING") and the mast's light pool; **L3's isolator swaps this volume's tier to DARK at runtime** — swaps, never deletes, or the disc falls back to untiered (= LIT) |
| Courtyard DARK bands: x [-22, -12] z [-2, 24]; x [12, 16] z [-2, 24]; x [-12, 12] z [22, 24] | DARK | the painted line |
| Refuse yard | PITCH | its fence; the broken lamp on the gym's south-east corner ("TICKET #4472") |
| Boiler house, undercroft, squeeze | PITCH | the warded door |
| Gym store | PITCH | the store door frames (both) |
| Gym floor + mezzanine x [16, 28], z [-14, 8], **y [0, 6.6]**; bridge interior x [10, 16], z [-13.5, -10.5], **y [4, 6.6]** | LIT | |
| Gym roof x [16, 28], z [-14, 8], **y [6.6, 12]**; main roof x [-22, 10], z [-20, -2], **y [8.4, 12]**. The **bridge roof** needs no row of its own — it is inside the alley's DARK volume above, which is why that one is carved rather than floored at y 4 | DARK | |
| **West corridor, west stair well** | **DARK** | their doorways: the west exit, the caretaker door, the junction into the north corridor, the stair top onto the south corridor |
| Toilets | **DARK** | its door — a dead end must not be a free alarm reset (M6) |
| Assembly hall: x [-10, 6], z [-20, **-10**], y [4, 7]. **No under-gallery volume** — z [-10, -8] below y 5.0 is solid now (H1) | LIT | the gallery's front edge at z = -10 |
| Duct (y [8.4, 9.4]), ceiling void (y [7, 8]), **gallery** (x [-10, 6], z [-10, -8], **y [5.0, 7]**) | PITCH | the grille; the gallery's front edge (the hall is LIT below) |
| Other main block interiors | LIT | |
| Gatehouse | LIT | |

Each vector passes all three: Regular DARK → PITCH (store) → DARK → PITCH (void) → LIT (hall
by sightline); Wizard DARK → PITCH → **DARK** (west corridor) → LIT; Chad DARK → PITCH
(refuse) → DARK (roof) → LIT (corridor). Critical-path doors in PITCH: none — the shutter is
on the lane side, the warded door in the alley, the store's doors are the boundary itself.
PITCH is kept for spaces with no waiting value (store, refuse yard, undercroft).

## 8. Lockpick rooms (optional, Regular's multipliers)

| | Where | What's inside | Saves | Costs | Others reach it? |
|---|---|---|---|---|---|
| L1 | Kitchen east door (10, 0, -19), alley side | a ground-floor way in: kitchen → canteen → north corridor → north stair → hall's north door | the roof (~40s) | G5's window: 4.3s of work inside his 10.2s north-stop + south-leg window, 1.8s to detection if his north leg catches you; then G6's corridor: his west leg, or two suppressed shots | no |
| L2 | Records (-3, 0, -14), north corridor | wall board: "Q3 GRATITUDE AUDIT — ASSEMBLY HALL 21:00 · CONTINUITY: AMBER → SUITE G.04 (N. CORRIDOR)". Intel: target room and panic room | blind search time (~90s) | G6's corridor | no |
| L3 | Caretaker's cupboard (-19, 0, -9.5) | **MAST ISOLATOR** → courtyard disc goes DARK; the ramp down to the undercroft (the puddle — a view of the Wizard's way in, not a route) | courtyard crossings for everyone after | reaching the west corridor | the Wizard, from below (his route) — the one allowed exception |
| L4 | AV booth (-9, 4, -6), south corridor | the projection slot into the hall at 5.4m: an 8–12m suppressed shot on the target at the lectern | the void, the gallery, the hall (~30s) | G8's **4.8s** window for a 3.8s job (margin **1.0s** — M3), in LIT, from passage W, with a 0.83s clock on the overrun | no |

None is on any critical path. L4 is the Regular's best kill; L1 is his fastest entry. Both
are the optimal line and both are timed windows, not free doors.

## 9. Objective loop and stats

`objectives.gd` states: **INFILTRATE → LOCATE → KILL → EXTRACT**. LOCATE completes on
line of sight to the target or on reading L2. No second leg (F3) in level one.

Extractions, unlabelled, `BuildUtils.zone()` spheres — entering wins:

| | Where | Radius | Gate | Who |
|---|---|---|---|---|
| E1 | Van **(-38, -2.2, 6)**, on the outfall pit floor | 3.5 | culvert 1.0m crawl from the west yard grate; the outfall's lip is y 0, **2.2m above the pit floor** = exit-only (H5 — r3 put the pit floor at y 0, which made the culvert a two-way door and the Wizard's ward optional) | Regular, Wizard |
| E2 | Helipad deck, centre **(23, 12.0, -8)** | **2.5** (M3 — a capsule on the plant box is 3.35 from it; 3.5 would fire from there) | Chad chain (§2.5) | Chad |
| E3 | Car (0, 0, -34), avenue | 3.5 | gate lever in the gatehouse, entered from the north yard | all |

Diegetic hints only: the van's engine idles (synth loop, 15m), the deck has a painted H
and a beacon blink, the car's headlights are on. The HUD says nothing. Stats on win/lose:
**time, kills, alarms raised, times detected (guard hit 1.0), extraction used, loadout.**

## 10. Timing

| Phase | Regular blind / mastered | Wizard blind / mastered | Chad blind / mastered |
|---|---|---|---|
| Approach + entry | 60 / 10 | 45 / 9 | 20 / 3 |
| Find the way up/in | 70 / 12 (crates inside one G5 leg) | 60 / 12 (squeeze, puddle, ramp) | 40 / 8 (skip chain, G2's shot) |
| Locate | 80 / 6 (roof → vent → gallery) | 70 / 8 (corridor → stair → landing) | 60 / 8 (hall empty → north stair) |
| Kill | 30 / 3 | 40 / 6 (G9, target, tempo) | 60 / 20 (corridor, 2.5s smash, room) |
| Extract | 90 / 22 (west yard, G3 wait, culvert) | 80 / 25 (gym or west, courtyard) | 90 / 28 (back up the chain to the deck) |
| **Total** | **5.5 min / ~53s** | **5 min / ~60s** | **4.5 min / ~67s** |

Ratios ≈ 5×. The Regular's mastered sum is **53s**; the plan's definition of done now
reads 45–90s (the §10 floor), so the row stands and Phase 4's stopwatch decides (L8). If it
comes in under 45 the lever is G5's loop, not geometry. The L1 line is ~10s faster than the
roof only when both windows are hit; a miss is an ALARM, not a slower run. Chad's blind run
is short but bloody — count deaths in stats.

## 11. Replayability

| Run | Who | What you spend from the last run | What you learn for the next |
|---|---|---|---|
| 1 | Regular | nothing | the building's shape from above; where the target stands; that a wall says "structural review"; that there's a warded door you couldn't open |
| 2 | Chad | the target's room — which is now empty when you get there, because you were loud | the panic room, the CSD, the north stair; that the skip by the canopy goes somewhere; that the hall has a rear door and a bridge |
| 3 | Wizard | the panic room location (so an accidental ALARM isn't fatal); the bridge; the gym as an exit | the undercroft and the puddle; that the caretaker's cupboard has a switch; that G9's back is to the landing |
| 4+ | any | everything — now it's a time | L1's and L4's windows (Regular), the deck jump from the main-roof parapet (Chad), the void behind G8's back (Wizard) |

Each run is a different character, not a faster version of the same one: Chad's run *is*
the alarm tutorial, the Wizard's the interior tutorial, the Regular's the overview.

## 12. Convergence audit (§1.5 test: different side / time / sightline?)

| Shared space | Who, from where | Verdict |
|---|---|---|
| **Gym store / shutter** | Regular (signature); Wizard optionally — 0.85 fits the 1.0 shutter | Intended (D2). For the Wizard it leads to the crate stair, the roof and a gallery where every shot he has is loud; his own door is closer to spawn and ends behind G9. The signature stays optimal for him. |
| **East lane** | Regular's approach; anyone can walk it | Intended: a DARK dead end whose only door is 1.0m — nothing for Chad, a detour for the Wizard. |
| **Alley** | Regular from the store's west door at the north end, 3m off G5's lane, DARK, timed to his north stop; Chad/Wizard from the courtyard's south mouth, walking up to 18m of G5's own axis into his face | Intended. Same space, opposite ends, opposite halves of G5's loop: a 10.2s window with a 4.7s detection clock for the Regular; a 20m walk under a guard, a suppressed kill, or a fight for anyone else. |
| **Crate stair / main roof / bridge roof** | Regular; anyone else who bothers | Intended. Nothing up there for Chad (1.0m vent). The Wizard following it is D2. The bridge roof is where the stair already leads, one step down (M2). |
| **Gym roof** | Chad from the skip chain; Regular/Wizard by the bridge roof from the crate stair, or by jumping the 6m alley from the main roof (8.4 → 6.6) | Intended: for the small two it comes *after* the crate stair is paid for, is DARK, and leads down the hatch (a 0.4 step) to the mezzanine and the bridge — the hall's *east* side, not their own. The plant box (+2.2) and the deck stay Chad's. |
| **Refuse-yard gate** | plain, all three: Chad from the wall, the others from the courtyard | Intended: a PITCH dead end for R/W; the skip they find in it is a wall to them. |
| **Hall** | Regular from above (gallery, and the gallery is a **1.0m step** from the floor — a mantle, so anyone in the hall can climb it), Wizard from the west doors, Chad from the east (rear door) under ALARM | Intended: three sides, and Chad's version has no target in it. The cheap way onto the gallery is through the LIT hall past G9 — that is its price. |
| **West landing / passage W** | Wizard (from the west stair); Regular only for L4, from the same stair | Passes: same side, but the Regular's version is a timed pick beside G8's body and the Wizard's is a walk behind G9. |
| **North corridor** | Wizard (if he squeezes north, west end), Regular (via L1, east end via the canteen), Chad (under ALARM, from the stair foot, into R1 + R2) | Different times, different doors, different guards. Passes. |
| **Gym floor / mezzanine / bridge** | Chad (overland, from the roof hatch); Regular/Wizard via the store or south doors and the ramp | Intended, priced: the ramp runs beside G4's lane (x = 20) for its whole length, so the bridge is a loud-ish alternative to the east landing, not a faster one. |
| **Courtyard** | Chad (always); Wizard/Regular on extraction | Intended. It's LIT, it's the "pay to cross" space, and L3 turns the light off. |
| **Panic room** | all, under ALARM | Three different entries (door / hatch / window), each one character's, and one exit for all (the release). Passes. |
| **Portico → 1F window** | Chad only (2.4) | Not shared. |
| **Void** (5.0m) | Wizard (dash), Chad (jump), Regular (jump) | Shared on purpose; free behind G8's back (3.3s), lethal for a 0.8s jump in his east-facing 5.3s, survivable for a 0.35s dash. Passes. |
| **Void's east shelf / passage E** | Regular and Wizard from the east stair; Chad only if he ignores his own route | Intended, and now actually connected (H2): 2.0m of shelf and a 2.0m mouth into passage E. It leads to the bridge and the gym — the hall's far side — so it is a way *out*, not a second way in. |

Zero unfixed defects.

## 13. Signage, barks, radio

**Signage** (Label3D plates, in-world; wall-mounted ones with `billboard: false` — appendix):

1. Gate: `VANDERMEER INSTITUTE FOR APPLIED CONSENT · HOLLOWAY CAMPUS · (formerly Holloway Road Primary, 1911–2019)`
2. South wall, on the crack: `STRUCTURAL REVIEW PENDING — Q3 2019 · DO NOT LEAN`
3. Courtyard ground: `NO RUNNING · NO SHOUTING · NO UNSCORED BEHAVIOUR`
4. Mast: `YOUR LIGHT IS PROVIDED BY A PARTNERSHIP`
5. Boiler house: `DECOMMISSIONED · HEXLOCK™ ARCANE PERIMETER SOLUTIONS · YOUR SAFETY IS WARDED`
6. Boiler house interior: `ENERGISED — DO NOT ENTER — TICKET #4471 (OPEN 31 MONTHS)`
7. Gym shutter: `SHUTTER FAULT — TICKET #4472 · PLEASE USE MAIN ENTRANCE` (there is no main entrance)
8. Gym: `WELLNESS HANGAR · MANDATORY OPTIONAL SESSIONS TUESDAYS`
9. Lobby: `WELCOME. YOUR VISIT HAS BEEN SCORED.`
10. Toilets: `GENDER-NEUTRAL · CONSENT-VERIFIED · NO LOITERING (LOITERING IS SCORED)`
11. Records door: `RECORDS — AUTHORISED PERSONNEL · IF YOU CAN READ THIS YOU ARE AUTHORISED`
12. Panic room: `CONTINUITY SUITE G.04 · IN THE EVENT OF AN EVENT`
13. Panic room, inside, by the release: `DOOR RELEASE · FOR USE ONCE THE EVENT HAS CONCLUDED`
14. Assembly hall: `Q3 GRATITUDE AUDIT · ATTENDANCE IS ITS OWN REWARD`
15. Staff room: `WELLNESS SUITE · FORMERLY STAFF ROOM · FORMERLY YEAR 6`
16. Helipad deck: `H · EXECUTIVE CONTINUITY ONLY`
17. Refuse yard: `LIGHT OUT — TICKET #4472 — DUPLICATE OF #4472`
18. Portico: `PLEASE WAIT TO BE SCORED`

**Guard barks** (on-screen text + synth blip):

- Patrol: `"Bins Thursday. If your number's good."` · `"He said 'gratitude' four times in the briefing. Four."` · `"They scored the caretaker. Caretaker's gone."`
- Suspicious: `"That's not a scored noise."` · `"Ticket that. Ticket everything."` · `"If that's the boiler I'm not paid for the boiler."`
- Alert: `"CONTACT — non-consenting!"` · `"Continuity! Get him to G.04!"` · `"Shoot first, the form's shorter."`
- Alert, Chad's wall: `"THE WALL — it was on the review!"`

**Radio (extraction):**
- E1/E3: `"Fine. Get in. Don't tell me the number."`
- E2: `"Executive continuity confirmed. That's you now."`

## 14. Smoketest cases (`tools/smoketest_compound.gd`)

Each phrased as an assertion. Sweeps use the §0 bands and post-D14 mantle rules.

1. Floor under every guard waypoint (G8's are (-11, 4, -5) and (-3.5, 4, -5)), every
   R-post, the south-window plate at (0, 4, -2.6), and every route waypoint (three lists,
   ~40 points). **Every one-waypoint post declares a `facing`.**
2. Crawl gaps measure 1.0: gym shutter, culvert, roof duct, staff-room hatch duct. Sealed
   above, to the sides **and at both ends** (raycast the surrounding 2m at 1.1–2.0m finds
   solid; `tunnel()` builds no end caps).
3. Squeeze gaps measure **0.6 tall**: the boiler-house tunnel 1.0 wide, the west-corridor
   shutter gap the corridor's full **3.0** width (it is a gap under a shutter, not a hole —
   r3's "0.6 × 1.0" could not describe it). Both sealed above and at the ends.
4. **Regular's entry blocks Chad:** the capsule sweep at 1.45m fails the shutter tunnel.
5. **Wizard's entry blocks Regular and Chad:** the boiler-house door has only `arcane`;
   the squeeze tunnel fails a 0.85 capsule.
6. **Chad's entry blocks Regular and Wizard:** the wall has only `smash`; and from the
   verge, no edge on the south wall is ≤ 1.6 (sheer check).
7. **Band audit:** every ledge on every marked Chad chain (skip, canopy, gym roof, plant
   box, deck, hatch crate, portico, refuse-yard fence) has rise in [2.0, 2.6] from its
   approach floor **and is solid at approach floor + 0.9 on its approach face** (the
   mantle's chest probe). Every crate-stair stack rises exactly **1.15** and leaves **≥ 1.0m
   of tread** (M1, M2); the last step to the roof is a **1.5m jump**, not a mantle.
   **No ledge anywhere has rise in (1.6, 2.0), and no ledge rise equals a mantle limit
   (1.2 or 2.5) to within 0.02** — `rise > limit` fails on floating point.
8. **Extraction reachability:** E1 by a 0.85 capsule from the west yard, not by 1.45; the
   outfall lip is **2.2 above the pit floor at (-33, -2.2, 6)** and no edge from the pit to
   the lip is ≤ 1.6, so the culvert is exit-only; both pit ramps are ≤ 0.89 rise/run. E2 deck − plant box ∈ [2.0, 2.6]; deck − main
   parapet ≥ 2.0; **a 1.7 capsule anywhere on the plant box does not overlap E2's sphere.**
   E3 by all once the gate is open; the gatehouse has no opening on its avenue faces.
9. **Roof reachability:** main roof via the crate stair (**six rises of 1.15 and a 1.5m jump
   through the parapet gap**); gym roof via the Chad chain, the main roof, **or the bridge
   roof** (a 0.3 step down from stack 6 at 6.9) — and not from the courtyard, forecourt or
   refuse yard by any ≤ 1.6 chain.
10. Every enclosed volume has a lamp *or* is a declared PITCH volume with a lamp at ≤ 0.2
    energy (navigable, not a void).
11. No critical-path door lies inside a PITCH volume.
12. Every light-tier volume is non-overlapping **as an AABB, y included** (M4) — the three
    stacks r3 left overlapping are gym floor/gym roof, main block/main roof and
    alley/bridge/bridge roof — and the hall/gallery and disc/band carves of §7 hold. Every
    zone in §2.2 is covered, the gym forecourt and E1's van at -2.2 included; the west
    corridor, west stair well and toilets are DARK.
13. The hazard volume spans exactly z [**-16.5, -11.5**] in the west run and nothing else.
    At **95 dmg/s**: a walk at 6.6 m/s with `dmg_mul 1.0` deals **≥ 70** (lethal to 60 HP);
    a dash begun anywhere in the **1.0m** of dry floor north of it deals **= 0** and ends at
    z ≈ -11.5 (M5 — stating the armour, because a heavy-plate wade is 36, and giving the
    dash a metre of slack, because r3's 6m puddle left one physics frame). A Regular's
    sprinting **round trip** is ≤ 90 in every loadout, so the north ledge is not a
    damage-locked dead end.
14. **Soft-lock sweep:** refuse yard, boiler-house basement, undercroft, **the outfall pit**,
    panic room, gallery, every roof (bridge roof included), the deck, the gatehouse, the
    store — each has a non-lethal exit usable by every operative who can enter it (basement:
    Wizard only, out by the squeeze or the open ward; undercroft: the spur ramp, the puddle
    on nobody's way back, and the north ledge affordable both ways in every loadout — case
    13; outfall pit: its two ramps; panic room: the release; gallery: the 1.0m drop).
    **Damage counts as a lock:** a space whose only exit costs more HP than the operative who
    can reach it has left is a soft-lock, whatever the collision says.
15. ALARM lockdown never seals a region: with the CSD pair locked, every room is still
    reachable by every operative who could reach it before (north corridor via the north
    stair; the canteen pocket via the east stair).
16. Panic room under ALARM: reachable by all three (door: smash 2.5s / arcane; hatch: 0.85
    capsule, 4.0 drop; window: arcane); a ray with **`collision_mask = 1`** from
    (-16, 1.95, -22) through the window reaches (-16, 1.95, -16), **and a 0.85 capsule sweep
    on the same line is blocked** — the second half only passes if the bodies' mask includes
    layer 2 (H3), so this case is the one that catches the inverted scheme; the release opens
    the door from inside with no verbs.
17. The main roof parapet gap exists at z [-15, -13.5] and nowhere else.
18. Headshot regression (D12): a ray at **1.95m** hits `head`, at 1.2m hits `body`, and
    **the head shape's AABB lies inside the head mesh's AABB** (guard and target — the
    mesh/collider offset is the MERIDIAN bug); 25 × 2.5 kills a 50 HP guard.
19. G-post loops: every **two-waypoint** guard's waypoints are mutually visible (no wall
    between) — guards walk straight lines — and every loop, **computed on the lane minus
    1.6m** plus waits, is in [8s, 40s]. **One-waypoint sentries are exempt from both**: G7
    and G9 have no lane and no loop, and asserting a loop time on them fails the case, not
    the level.
20. Every extraction zone is > 20m from spawn and no label node contains "EXTRACT", "VAN",
    "HELI", or "CAR".
21. **Crate-stair exposure is countable:** from G5's lane at z ∈ [-10, -4] facing north,
    stack 2's top (11, 2.4, -16.5) is inside his cone (dot ≥ 0.80) with clear LOS; from
    z ∈ [-13, -9] stacks 5–6 are outside it. G5's south leg is ≥ 8s.
22. G8's east waypoint waits 3.0s and his east stop is ≥ 0.5 from the void edge.
23. **Squeeze capsule (N2):** after a squeeze-and-stand cycle the capsule reads radius 0.4,
    height 1.7; a 0.85 × 0.4 capsule fails a 0.6m opening; a 0.5 × 0.25 capsule passes a
    0.6 × 1.0 one.
24. **Quiet-path noise (N1):** for the ward (8m) and the puddle dash (4m), no waypoint or
    lane segment of any G-post lies inside the circle — measured in **3D**, as `emit_noise`
    does.
25. **Headroom (H1, §0-D):** a vertical ray from every walkable surface in the route lists
    and every guard waypoint finds nothing for **1.8m**, except where the point is tagged
    `crawl` (1.0) or `squeeze` (0.6). The gallery floor (5.0), the whole hall floor, the
    undercroft (2.2) and the duct-to-void step are all in the list. This case is the general
    form of the bug H1 found twice in one room.
26. **Declared openings are openings (H2):** for every adjacency in §2.3 and §2.4, the two
    volumes share an edge at least **1.2m** long, and a 0.85 capsule walks between them.
    Named starts: south corridor (3.5, 4, -4) → passage E (8, 4, -7); west foyer is asserted
    **not** to connect west to the stair well (M8).
27. **Collision layers (H3):** `Player`, `Guard` and `Target` have `collision_mask` 3; the
    barred window's rods have `collision_layer` 2 and nothing else does; every ray query in
    `kit_base`, `kit_wizard`, `projectile`, `guard.ray`, `mantle`, `movement` and
    `interactor` sets `collision_mask = 1`. Godot's default mask is **1, not all**, which is
    what made r3's scheme a no-op.
28. **Sentry facing survives an investigation (H4):** drive a sentry through
    `hear_noise` → SUSPICIOUS → 3.0s scan → `enter_patrol`, then assert its yaw is within
    0.05 rad of its declared `facing`. Fails against an implementation that only applies
    facing in `Guard.setup`.
29. **The gatehouse is not a ladder (M6):** its roof is 4.0, flush with the wall top, and no
    face on the avenue side has an edge in [1.3, 2.6] from the avenue floor.

## Appendix — new data this level asks for

- `verbs.gd`: `squeeze_h: 0.5`, **`squeeze_r: 0.25`** on the Wizard. `movement.gd`
  `_resize_capsule` writes **radius and height** — radius first when shrinking, height
  first when growing (Godot clamps `radius ≤ height / 2` in the setters) — and restores
  `BODY_RADIUS` on stand-up. `characters.gd` / `abilities.gd`: `squeeze_speed_mul: 0.4`,
  `squeeze_mana_per_s: 8`, and `player._regen_mana` **skips while squeezed** (M4).
- Loadout: `SUPPRESSED {damage_mul 0.7, noise 0}` / `LOUD {1.0, 25}` for the Regular.
- `guard_data.gd`: `headshot_mul: 2.5`, `tier_mul: {LIT 1.0, DARK 0.45, PITCH 0.1}`.
- `guard_posts.gd` / `guard_brain.gd` / `guard.gd`: optional per-waypoint `wait` (default
  1.0) — G8's east end at 3.0; **`facing` (yaw) on a post** — G7, G9 (M7). **Applied in
  `enter_patrol()`, not `Guard.setup` (H4):** `Guard` stores the post's `facing`, and while
  `waypoints.size() <= 1` the PATROL branch of `guard_brain._patrol` calls
  `guard.face(facing, delta)` instead of only `stop()`. Setup-only application is undone
  permanently by `_suspicious`'s 1.2 rad/s scan the first time the sentry hears anything.
- `core/alert_state.gd` (F2): `emit_noise(pos, radius)` keeps its radius semantics and
  gains the ALARM rule — radius ≥ 25 with a guard inside 12m; `hearing_range` struck or
  used as the cap (N1, §6).
- `data/mission_compound.gd`: extractions (**E1 at (-38, -2.2, 6) r 3.5**, E2 at
  (23, 12.0, -8) r 2.5, E3 at (0, 0, -34) r 3.5), panic room (door
  override `{smash: {time: 2.5}}`), R-posts + spawn policy `{first: [R1, R2], repeat: [R3],
  cap: 3, min_dist: 8}`, the CSD pair, decay 60s, tier volumes (carved per §7; the disc's
  tier is swapped by the isolator), hazard volume.
- `world/hazard.gd` (NEW, small): Area3D, damage/s to the player **through
  `player.take_damage`, so armour and i-frames both apply**. The puddle is **95 dmg/s** over
  z [-16.5, -11.5].
- `world/interactables/switch.gd` (NEW, small): mast isolator, gate lever, panic-room
  release — an Interactable with no verb requirement that fires a game event.
- **Collision layers (M8, corrected by H3):** `BuildUtils.box(..., layer: int = 1)` and a
  `LAYER_BODY_ONLY = 2` constant; the barred window's rods are layer 2 **and nothing else in
  the level is**. r3 wrote "bodies keep the default mask (all)" — **Godot's default
  `collision_mask` is 1, not all**, and nothing in this repo has ever set one, so a layer-2
  rod would have been invisible to every capsule in the game and the barred window would
  have stopped nobody. So: **`collision_mask = 3` set explicitly on `Player`, `Guard` and
  `Target`**, and **every ray query sets `collision_mask = 1`** — pistol (`kit_base.gd`),
  bolt, projectile, guard LOS (`guard.ray`), mantle, step-up, interactor;
  `PhysicsRayQueryParameters3D.create` defaults to `0xFFFFFFFF`, so all seven sites need the
  line, not just the pistol. Then the rods stop capsules and nothing else. Decided: the
  guard's LOS ray passes the rods too, so G9 and the target see and shoot back through the
  bars.
- `BuildUtils.label(..., billboard: bool = true)`; wall plates pass `false` and keep depth
  test on (L7).

## 15. Changelog

**r1 → r2, r2 → r3**: superseded. `REVIEW-compound-r2.md` confirms every r1 finding
discharged; `REVIEW-compound-r3.md` confirms every r2 finding discharged and re-derives the
loop and cone arithmetic from source. Both tables are dropped here, which is the ~35 lines
L12 promised back.

**r3 → r4** — all five HIGH, all eight MEDIUM, all six LOW applied. **DEV** marks a fix that
differs from the review's suggestion; author corrections are at the end.

**Length, honestly: 890 lines against the plan's ~600 guardrail, and r4 went up, not down.**
Dropping both old changelog tables gave back ~35 lines and the fixes spent more than that,
because each one carries its own *why* inline so Phase 3 does not re-litigate it. Two things
bring it back under: this table goes when r4 is accepted (~25 lines), and the inline
justifications in §2 and §4 collapse into the changelog once nobody needs them (~150). Both
are bookkeeping moves to make *after* the build starts, not before — the numbers are what
Phase 3 reads, and none of them is padding.

| ID | What changed | Where |
|---|---|---|
| H1 | Gallery floor 5.5 → **5.0** (a 1.0m step, a mantle), headroom 2.0, grille drop 2.0; the volume beneath it is **solid** so the hall floor ends at z = -10 and §7's 1.5m under-gallery row is deleted. New general rule §0-D and case 25: **1.8m of clear headroom on every walkable surface**, because you arrive airborne and nothing crouches you | §0-D, §2.4, §3, §4.1.6–8, §7, §12, §14.25 |
| H2 | Void narrowed to x [-3, 2] (**5.0m**, still unwalkable); lobby to x [-3, 2]; new **solid riser block** x [2, 4], z [-8, -2], y [0, 4]; **passage E widened to x [2, 10]**, meeting the corridor along a 2.0m edge instead of a single point. East shelf is 2.0m. **DEV:** the review moved the east stair to x [6, 10], which would have forced its ramp to rise 4.0 over 3.0 — steeper than `floor_max_angle`. Widening the shelf onto a riser block gets the same landing and the same connection with the stair untouched. Chad's plate jump is now **west only**, which is the side his route continues on | §2.3, §2.4, §3, §4.3.5, §12, §14.26 |
| H3 | Layer scheme corrected: rods layer 2 **and `collision_mask = 3` on Player / Guard / Target**, rays mask 1 at all seven sites. Godot's default mask is 1, not all, so r3's rods would have stopped nothing. Case 16 strengthened to assert the capsule sweep is *blocked*; new case 27 | §2.3, §6, §14.16, §14.27, appendix |
| H4 | `facing` applied in **`enter_patrol()`** while `waypoints.size() <= 1`, not in `Guard.setup`. `_suspicious` spins the guard at 1.2 rad/s, so setup-only facing dies on the sentry's first investigation — and G9's back to the landing is load-bearing for two vectors. New case 28, and §0-C says so | §0-C, §5, §14.28, appendix |
| H5 | **Outfall pit:** the west alley dips to y **-2.2** over z [4, 12] with 0.55 ramps at either end; the culvert stays level and its lip is y 0, i.e. 2.2m above the pit floor. E1's van moves to (-38, -2.2, 6). r3 had both the alley and the yard at y 0, which made the culvert a two-way door the Wizard meets *before* his ward — the collapse test failing | §2.2, §4.1.8, §4.2.1, §9, §14.8, appendix |
| M1 | Crate stair: crates 2.0 × **1.5** stepping **1.0** (tread 1.0 against a 0.8m body and a 0.5m `LANDING_PUSH`), footprint z [-20, -13.5] | §2.2, §4.1.4, §14.7 |
| M2 | Crate-stair rises 1.2 → **1.15**, and the last step to the roof is a **1.5m jump**, not a seventh mantle. No ledge rise now equals a mantle limit (8.4 − 7.2 = 1.2000000000000002 > 1.2). Exposure re-derived: stack 2 at 4.1m, stack 4 at 6.7m, stack 5 at 8.1m, stack 6 at 9.6m; **5.2s window after G5 turns south**, 3.0s exposure at the top of his north leg, 0.20/s at 9.8m | §3, §4.1.4, §5, §14.7, §14.9 |
| M3 | L4's window is **4.8s** (it opens when G8 clears the door at t = 0.46, not at his west stop), margin **1.0s** | §4.1, §5, §8 |
| M4 | Every §7 volume carries a *y* range; the three overlapping stacks named | §7, §14.12 |
| M5 | Puddle 6m → **5m** at z [-16.5, -11.5] with 1.0m of dry run-up, so the dash has a metre of slack instead of one physics frame. Case 13 names the armour | §2.6, §4.2.4, §14.13, appendix |
| M6 | Gatehouse roof **4.0**, flush with the wall top, avenue faces sheer; new case 29 | §2.2, §14.29 |
| M7 | Roof hatch 1.6 × 1.6 → **2.0 × 2.0**, the hatch crate's full footprint | §2.5 |
| M8 | West foyer's west opening deleted — the ramp's underside closes it anyway (y 1.66 at x = -14). **DEV:** the review offered moving the ramp base to (-17, 0, -4); that is rise 4.0 over run 4.0 = 1.0, at the `floor_max_angle` limit. Deleting the opening costs nothing, since no route used it | §2.3, §14.26 |
| L1–L6 | Case 3 re-worded for the 3.0m shutter gap; case 19 exempts sentries; the duct's 0.4m drop onto the void floor stated; §4.1.7 gives both stances; the dash's end position and the 6m alley strip corrected; §5 gains a paragraph saying **no window in the document is priced against an investigating guard**; the mast is listed as G2's one piece of hard cover; both changelog tables dropped | §2.4, §4.1.7, §4.2.1, §4.2.4, §5, §14.3, §14.19, §15 |
| — | **Author corrections not in the review.** The **puddle's damage drops 120 → 95 dmg/s**: at 120 over 6m a street-clothes Regular who crossed to look at the squeeze paid 69 out and 69 back on 100 HP and died on the return, so the run's north ledge was a dead end with no non-lethal exit — §14.14 forbids exactly that, and r3 had costed the crossing at walking speed rather than sprint, which hid it. At 95 over 5m his round trip is 90 / 66 / 46 by loadout, a light-vest Wizard who walks it lives on 7 HP, and a street-clothes Wizard still dies in it, so the gate holds. Case 14 gains the general rule: **damage counts as a lock.** Also: `hazard.gd` must deal damage through `player.take_damage` so armour applies; §6's noise distances are 3D because `emit_noise` uses `distance_to`. | §2.6, §4.2.4, §6, §14.13–14, appendix |
