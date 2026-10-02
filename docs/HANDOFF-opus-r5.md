# HANDOFF → Opus 5.5 (written by Sonnet 5.5, after playtest rounds 5a/5b, 2026-10-01)

Gregory plays, then reacts in one terse paragraph. He is the final judge. Nothing below was
playtested by an assistant — only the five headless suites and a few screenshots. Read
`docs/NEXT-SESSION.md` for the standing rules (they still apply), then this.

## What I did (all suites 0 problems: smoketest, _compound, _compound_systems, _nav, _civilians)

**Playtest 5a (his words in quotes):**
- "Some of the cars are really small" → `Props.vehicle` scale cap 1.3 → 1.75 (the kit scale);
  roofs stay ≤ 1.58m (the systems test needs ≤ 1.6, a jumpable step). Tall vehicles (van,
  truck, delivery) are still height-capped and may still look small — if he repeats it, raise
  the jump instead of the cap (see "Jump numbers").
- "The alarm is very overbearing" → siren −9dB (was +4), range 90m, pitch 440–640Hz, softer
  overtone (`alarm_siren.gd`, `AudioSynth.siren`).
- "Gravity feels off… stay in the air a really long time" → player gravity is its own
  constant, `PLAYER_GRAVITY` 24 (×1.35 falling) in `movement.gd`; `jump_v` re-tuned so apex
  heights are unchanged (Regular 1.84m, Chad 2.85m): `characters.gd` 9.2 / 11.7. Airtime
  ~1.22s → ~0.75s. Guards/projectiles still use project gravity 9.8.
- "traffic cone is very chode-like" → I guessed the lying-down `car/cone-flat` on the road
  deck and removed it. Unconfirmed; ask which if he repeats it.

**Playtest 5b:**
- "Alarm doesn't do anything other than make noise and move the target" → on ALARM every
  guard not already fighting (except G9) goes SUSPICIOUS toward the player's position
  (`MissionCompound._converge`); reinforcements now R1+R2+R4 (R4 portico, R5 courtyard rear on
  later alarms), cap 5; civilians panic; the kill feed says so.
- "Guards run straight into a wall" → real navigation. `GuardNav` bakes a navmesh from the
  level's static colliders at mission start (~0.45s), `NavWalker` follows it, `Guard.move_to`
  uses it. Locked/opened `RemoteDoor`s trigger a debounced async rebake, so after ALARM the
  CSD doors really are walls to guards (test: 7.4m route → 37.7m). Alerted guards with no
  line of sight keep pathing instead of strafing on the spot.
- "Guards are not modeled; make civilians; Cruelty Squad" → `Humanoid` (crude garish box
  people on limb pivots, walks/swings, panic arms-up), used by guards, the target and
  `Civilian`. 20 civilians (`CivilianPostsCompound`): they wander, scream satire lines,
  run from gunfire/alarm/kills, and panic spreads person to person; killable, no penalty
  (Cruelty Squad doesn't score the dead), "Bystander down" in the feed, `stats.civilians`.
  `Gore`: blood burst on hit, big burst + persistent stain on kill (cap 60 stains).
- "Not enough verticality, very wide open, target too straightforward" → only a first cut:
  `SecCmpLanes` — estate yard split by two 2.3m walls with gaps at opposite ends (zigzag,
  A1's lane inside, a crate stair over each wall), and courtyard container stacks (rises 1.15,
  tops 4.6) flanking the portico approach with a catwalk joining them. Mantle-tested.

## Cruelty Squad research (what the real game does; sources: Fandom wiki, Wikipedia, Steam guide)

Targets marked on the HUD; enemies passive until they notice you (eye icon — **we do not use
HUD detection indicators, Gregory's rule**); *silenced weapons alert nobody, unsilenced alert
everyone nearby*; armoured enemies are immune until an armour-piercing hit breaks the armour;
heavy weapons slow you; kicking surfaces/walls (and baton hits) **propel you** — kick + jump is
the signature movement tech; four implant slots (head/chest/arms/legs); organs harvested from
corpses are sold on a live stock market for money between missions; health comes from
implants, eating cooked giblets, or eating corpses ("Power in Misery" mode after repeated
deaths); no penalty for killing civilians; 19 sandbox missions, every one with several
routes; HQ hub between missions; fishing; secret levels via paintings.
Vanilla-feel gaps in our build, in the order I would do them:
1. **Kick** (key, ~0.4s cooldown): shoves guards/civilians/props, and kicking a wall/floor
   launches the player — the movement tech that makes verticality *fun*. Put it in `player/`
   as a verb; it must not be character-gated by script (rule 4).
2. **Corpses as a resource**: corpses persist (now 6s guards / 10s civilians — lengthen),
   an interact verb harvests an organ (visual + inventory count); eating a corpse restores a
   little health (no regen otherwise — rule 7; make it Cruelty Squad-grim, not free).
3. **Limb/gib damage**: headshots already exist; add a gib on overkill (chunks from
   `Humanoid` limbs flying), and bleeding on the player (HP drain until bandaged/eaten).
4. **Noise rules**: silenced = no `emit_noise`; unsilenced pistol/other = loud radius. The
   Regular's pistol is suppressed today; a loud second weapon (shotgun) makes it a choice.
5. **Armoured guards** (break-armour mechanic) as a later-level enemy type.
6. **Money/stock market/implants** are meta-progression — Gregory said skill trees come
   ~level 3 and he adds "my own touches" after vanilla; do NOT build the meta layer now.

## Level work for you (this is where he is least satisfied)

His complaint: **too wide open, too little vertical, the target is a straight walk, and
alarm makes it easier, not harder.** What I did is a first cut in two areas. Do the same
treatment — and think harder about *shape*, not just walls — in: the ring-road deck (88m
wide, one lane), the allotments, the terrace backs, the campus north/west yards, the
canal banks. Principles that work in this engine:
- Zigzag with 4–5m gaps + a climbable shortcut (1.15 rises) = a lane *and* a vertical
  option. Every rise ≤ 1.15 (mantle limit 1.2, jump apex 1.84; 1.6–2.0 is forbidden).
- Make the **alarm cost the player geometry**: lockdown shutters that close shortcuts on
  ALARM (a `RemoteDoor` + `GuardNav.request_rebake()` already works), or open new
  reinforcement doors. Right now ALARM only locks the CSD pair.
- The target: his hall is one straight shot from the portico. Subdivide the ground floor
  (offices, a records maze), and make `FLEE_PATH` longer / branching, or relocate him to a
  panic room that needs a different way in than the lobby. Keep G.04's hatch route legal.
- Guards at height can't path down (nav doesn't know crates/mantles) — don't put a patrol on
  a catwalk you also expect it to chase from.
Validate with `smoketest_nav` (add paths), `_compound_systems` (add `_ledge_from` cases like
`_check_lanes`), and `xvfb-run … tools/shot.gd -- views.txt`.

## Verify / known risks (be honest with Gregory about these)

- **Jump numbers changed.** Apex is the same, airtime ~40% shorter, so *horizontal* jump
  range fell (sprint 10.5 m/s → ~7.5m, was ~12.8m). Level jumps are ≤ 5–7m so should hold
  (alley 1.5m, billboard/overbridge 3m, void 5m) — **but sweep them**, and fix the physics
  table at the top of `docs/LEVEL-compound.md` §0 (it still quotes 9.8/6.0/1.22s).
- **Nav caveats:** baked once + rebaked on door changes only; agent r=0.4, climb 0.4, so
  guards never use crates, mantles or crawl gaps (<1.8m headroom). Props with collision in a
  doorway narrow it (the barrier at (0,173.5) leaves 1.0m each side of the 4m fence gap).
  The bake is on the main thread at start; rebakes are async. If the mission load hitches on
  slower machines, bake async and let guards fall back to straight lines meanwhile
  (`GuardNav.path` already returns empty before ready).
- **Visuals unseen in play**: `Humanoid` proportions/colours (screenshot only), gore,
  container colours. Civilian barks are my guesses at satire — tune the voice.
- Civilian spots are validated (floor + capsule room); wander routes between two points
  aren't swept for obstacles.
- Corpses: guard corpses now last 6s (was 1.5s).
- Still uncommitted (everything since `4c9be91`). Commit only when asked.

## New files
`scripts/enemies/{civilian,guard_nav,nav_walker}.gd`, `scripts/world/{humanoid,civilian_posts_compound}.gd`,
`scripts/world/sections/sec_cmp_lanes.gd`, `scripts/fx/gore.gd`, `tools/smoketest_{nav,civilians}.gd`.
New `class_name`s need `godot --headless --path . --import` once before tests parse.
