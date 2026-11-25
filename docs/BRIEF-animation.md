# BRIEF — game-loop timing and animation, applied to this repo

Read this before touching movement feel, the viewmodel, `Humanoid`, guard/civilian
animation, or anything that smooths a value over time. Researched 2026-10-16;
class names below were checked against **this machine's Godot 4.7.2** with
`ClassDB.class_exists` (all present). Godot's docs for 4.6+ IK are thin: check
properties headlessly (`ClassDB.class_get_property_list`) rather than guessing.

## 1. Where this repo stands (as of r9)

- **Everything moves in `_physics_process` at 60 Hz** (`player.gd:99`, `guard.gd:98`;
  the viewmodel ticks from the player). **Physics interpolation is off**
  (`project.godot [physics]` has only gravity). On a 60 Hz screen that's fine; on a
  120/144 Hz screen the camera and viewmodel update 60 times a second and judder.
  If Gregory ever says "stutters" or "not smooth", start here (section 2).
- **Smoothing is `lerp(a, b, delta * k)`** in `player/viewmodel.gd`,
  `player/movement.gd`, `fx/atmosphere.gd`, `fx/trip_zone.gd`. That form changes
  with frame rate (section 3). It's harmless while everything is locked to the
  60 Hz physics tick, and wrong the day anything moves to `_process`.
- **People** (`world/humanoid.gd`): a bare `AnimationPlayer` with `_play(name,
  blend)` crossfades. `animate(speed)` picks idle/walk/jog/sprint by speed
  thresholds and sets `speed_scale` from speed. Clips: idle, walk, jog, sprint,
  pistol_idle, aim, cower, talk, death. Bones used: `Head`, `hand_r`. No root
  motion: the navmesh drives position (good, see section 6).
- **Viewmodel** (`player/viewmodel.gd`): fully procedural. ADS blend, sway from
  mouse delta, stride-locked bob, a dip, and recoil kick. No authored clips.

## 2. The game loop: fixed tick, rendered frames

- Fiedler, "Fix Your Timestep": simulate at a fixed dt, render as fast as you can,
  and **interpolate the rendered state between the last two physics states**.
  Otherwise motion stutters whenever the frame rate isn't a multiple of the tick.
  Cap the accumulated frame time (he uses 0.25s) to avoid the spiral of death.
- Godot does this for you since 4.4: **Project Settings > Physics > Common >
  Physics Interpolation**. Rules once it's on:
  - Write body/node transforms **only in `_physics_process`**. Writing an
    interpolated node's transform in `_process` gives wrong positions and jitter.
  - Call `reset_physics_interpolation()` after a teleport (respawn, grapple snap,
    `Props` placement after `_ready`), or it visibly slides from the old spot.
  - **Mouse look is the classic exception.** A first-person camera fed by mouse
    input feels laggy when interpolated. The usual fix: interpolate the body, but
    apply yaw/pitch to the camera every rendered frame (in `_process` / `_input`)
    and set `physics_interpolation_mode = OFF` on the camera and on the
    viewmodel's SubViewport camera. Test with `Engine.max_fps = 144` and judge by
    eye, or ask Gregory. Screenshots can't show judder.
  - Raising `physics_ticks_per_second` to 120/144 is the cheap workaround. It
    costs CPU (guards, nav, raycasts all run per tick) and changes nothing that's
    tuned per tick. Prefer interpolation.
- **Don't flip this on as a drive-by.** It touches every moving thing. Do it as
  its own task, run all suites, and ask Gregory to play.

## 3. Frame-rate-independent smoothing

Freya Holmér, "Lerp smoothing is broken": `a = lerp(a, b, k * dt)` converges
differently at different frame rates. Use exponential decay:

```gdscript
## Frame-rate-independent lerp. `rate` = 1/seconds-ish; higher = snappier.
static func damp(a, b, rate: float, dt: float):
	return lerp(a, b, 1.0 - exp(-rate * dt))
```

(`lerpf`/`Vector3.lerp`/`Quaternion.slerp` take the same weight.) To keep the
**current feel** when converting `lerp(a, b, delta * c)` tuned at 60 Hz:
`rate = -60 * ln(1 - c / 60)`. For example `c = 18` (viewmodel `_dip`) gives
rate ≈ 21.4, and `c = 8` (sway) gives ≈ 8.6. At a fixed 60 Hz the result is
identical, so the change is safe, and it stops mattering what the frame rate is.
Put `damp` somewhere shared (e.g. `scripts/core/`) instead of copying it.

## 4. Procedural first-person animation (the viewmodel)

The industry pattern for procedural weapons is **damped springs, one per channel,
driven by impulses**:

```gdscript
# Semi-implicit Euler spring: stable at 60 Hz for stiffness up to a few hundred.
var pos := Vector3.ZERO
var vel := Vector3.ZERO
func spring_tick(target: Vector3, stiffness: float, damping: float, dt: float) -> void:
	vel += ((target - pos) * stiffness - vel * damping) * dt
	pos += vel * dt
# fire():    vel += Vector3(0, 0.02, 0.12) * kick   # impulse, not a set position
# landing:   vel += Vector3(0, -0.15, 0) * fall_speed_factor
```

- Critical damping is `damping = 2 * sqrt(stiffness)`. Go below it for wobble
  (recoil "settle"), at it for sway.
- Keep **separate springs** for recoil, sway and landing so each tunes alone.
  Sum the offsets at the end, as `tick()` already composes position from terms.
  Don't fake recoil with sine bob. Impulses stack correctly on rapid fire
  (SMG), and sines don't.
- Procedural reloads and equips are fine and match the Cruelty Squad look: dip the
  gun out of view, a rotation, back up. Drive them from `WeaponReload` timings so
  the art never disagrees with the logic. **Logic owns the timing; animation
  displays it.**
- Tuning numbers go in `data/weapons.gd` per the repo rules, not in the
  viewmodel.
- `viewmodel.gd` is at 250 lines. A spring helper must be its own file
  (e.g. `player/vm_spring.gd`).

## 5. Character animation (`Humanoid`)

**Current approach is OK for this game.** It's cheap, crude, and readable.
Upgrade only for a visible problem:

| Symptom | Fix |
|---|---|
| Pop when speed crosses a threshold (walk→jog) | `AnimationTree` with a **BlendSpace1D** on speed (walk 1.5, jog 3.6, sprint 5.5). |
| Feet slide | `speed_scale = actual_speed / clip_authored_speed`. Measure each clip's authored speed once and store it. No clamp, or a wide one. |
| Gun/aim pose replaces the legs | Upper/lower split: `AnimationNodeBlend2` with a bone filter (spine up = aim, legs = locomotion). |
| Hit reactions feel nothing / or stun-lock | **Additive** flinch (`AnimationNodeAdd2` / OneShot with add), weight scaled by damage, **zero crossfade in**. It must never cancel the guard's aim/fire state (core rule 8: the telegraph stays visible). |
| Guards don't seem to *see* you | `LookAtModifier3D` on `Head` → target node, `use_angle_limitation`, `duration` for ease. Cheap and very readable. Fits the "watching eyes" satire. |

AnimationTree rules if you adopt it:
- Once a tree drives an `AnimationPlayer`, **never call `play()` on that
  player**. It conflicts and jitters. Use `travel()` / `transition_request` /
  parameters.
- `tree.active = true` (default off). Gameplay state lives in `GuardBrain` /
  `Civilian`. The tree only presents it. Don't put game logic in transitions
  (no `auto_advance` on interactive states).
- `death` is terminal. Keep it a one-shot that ends the tree's work, or swap to a
  ragdoll (`PhysicalBoneSimulator3D` exists in 4.7) if Gregory wants physics
  bodies. That's a feature decision; ask.

Skeleton modifiers available on 4.7.2 (all children of `Skeleton3D`, run after
animation, in child order):
- 4.4: `LookAtModifier3D` (one-bone aim), `RetargetModifier3D`.
- 4.5: `SpringBoneSimulator3D` (hair, straps, hat bounce), `BoneConstraint3D`
  family (`AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D`).
- 4.6: IK is back. `TwoBoneIK3D` (deterministic. Feet on stairs/ramps, hand
  on a rail), `ChainIK3D` → `SplineIK3D`, `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`.
  Pair fast IK with `LimitAngularVelocityModifier3D` or bones snap. Constraint
  targets can be any `Node3D`. `SkeletonIK3D` still exists but is the deprecated
  path.
- Foot IK on our stairs: the stairs are ramps (invariant), so feet float on
  risers' tread lines only visually. Low priority unless Gregory points at it.

## 6. Crowds and cost

- `AnimationPlayer`s are CPU-bound. ~100 skinned characters with basic rigs can
  already lag (GodotCon 2026 talk). Holloway Road has guards + civilians + target.
- Cheap wins, in order: pause the player for characters off-screen or far away
  (`VisibleOnScreenNotifier3D`, or a distance check in the root's tick). Lower
  the update rate for distant ones (`callback_mode_process = MANUAL` and
  `advance(dt * n)` every n ticks). Fewer bones (`tools/blender/people_lowpoly.py`
  decimates faces, not bones).
- We have no root motion, so pausing a far character's animation never stops it
  moving. Keep it that way: the navmesh owns position.
- `AnimationTree` costs more than a bare player. Another reason not to convert
  civilians unless they show a problem.

## 7. Game feel: how impact reads

- One satisfying hit is **5-8 small responses within ~100 ms**: sound, flash,
  particles, knockback, shake, a flinch, a HUD tick. Exaggerate briefly, return to
  rest. The repo already has most pieces (`Impact`, `Gore.gib`, `Humanoid.flash`,
  knockback in `PlayerWeapons`). When something "doesn't feel like it hit", check
  which layers are missing before tuning damage.
- **Hitstop** is 2-5 frames. In Godot, `Engine.time_scale = 0` then restore via
  `get_tree().create_timer(t, true, false, true)` (last arg = ignore time scale),
  or the timer never fires. Use sparingly: the kick and the shotgun at close range
  are the candidates. It also freezes guards and audio pitch, so test the alarm
  and sirens after.
- Telegraphs are animation too: the guard's 0.55s aim must read on the body
  (`aim` clip + head look-at), not just via the tracer.
- **Style:** Cruelty Squad, not mocap. Snappy, few frames, overshoot, ugly on
  purpose. Short crossfades (0.1-0.2s), springs over eased tweens. Don't polish
  toward realism.

## 8. Verifying animation work

- Headless suites can't judge motion. They can assert state: the clip name
  `Humanoid._current`, the spring returning to rest, `time_scale` restored,
  no `play()` after the tree is active.
- `tools/shot.gd` / `play_shot.gd` show one pose. For motion, take several frames
  at fixed ticks, but judder and feel only show up live. **Say "unverified, needs
  Gregory to play"** for any feel change, per the standing rule.
- New `Tween.tween_await(signal)` (4.7) is handy for intro/comic sequencing.

## Sources

- Fiedler, *Fix Your Timestep!*: https://gafferongames.com/post/fix_your_timestep/
- Godot docs, *Using physics interpolation*: https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html
- Camera jitter with interpolation (forum): https://forum.godotengine.org/t/camera-jitter-with-physics-interpolation/112186
- *Improved lerp smoothing* (exp decay): https://www.gamedeveloper.com/programming/improved-lerp-smoothing-
- Godot, *Inverse kinematics returns to Godot 4.6*: https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/
- Godot 4.6 release: https://godotengine.org/releases/4.6/ · 4.7 release: https://godotengine.org/releases/4.7/
- Godot docs, *Using AnimationTree*: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- Crowds of rigged characters (forum): https://forum.godotengine.org/t/performance-of-crowds-of-animated-rigged-characters-in-3d/130409
- GodotCon 2026, *1000 rigged AnimationPlayers in 3D*: https://talks.godotengine.org/godotcon-ams-2026/talk/RXLHDR/
- *The role of animations in hit effects*: https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects
- Additive hit reactions (New Vegas mod write-up): https://nexusmods.com/newvegas/mods/89682
- Spring recoil (Roblox devforum): https://devforum.roblox.com/t/recoil-using-springs/1495471
