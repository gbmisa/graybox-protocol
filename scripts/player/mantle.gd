class_name PlayerMantle
extends Node
## Climbing over ledges. Triggered by jump while facing an obstacle.
##
## The reach limit is per-operative (VerbData.mantle_height): everyone gets
## 1.2m so ordinary crates stay climbable, but Chad reaches 2.5m, which is what
## opens his overland routes to him alone.
##
## Rise is measured from the floor you last stood on, not from your feet, so a
## grab at the top of a jump reaches no higher than one from the ground (D14).
## Without that, every mantle stacked on the jump apex and Chad's 2.5m band
## was really 5.4m — every roof lied about whose it was.
##
## Thin obstacles — fences, rails — have no top to stand on: the climb vaults
## them and lands on the far side instead.

const CHEST_H := 0.9
const REACH := 0.9
const MIN_RISE := 0.25
const LEDGE_INSET := 0.45   # how far past the lip to probe for the top
const LIP_INSET := 0.1      # a second probe right on the lip, for fences
const LANDING_PUSH := 0.5   # how far onto the ledge you end up...
const LANDING_PUSH_FAR := 0.85   # ...or this far, if a parapet is in the way
const RISE_EPS := 0.001
const OVERHEAD := 0.85      # a ledge is empty this far above its lip (parapets are 0.6)

var player: Player

var _active: bool = false
var _elapsed: float = 0.0
var _duration: float = 0.3
var _from: Vector3
var _to: Vector3

func setup(p_player: Player) -> void:
	player = p_player
	_duration = float(AbilityData.player()["mantle_time"])

func is_active() -> bool:
	return _active

## Returns true if a climb started, so the caller can skip a normal jump.
func try_start() -> bool:
	if _active:
		return false
	var dest := _find_ledge()
	if dest == Vector3.INF:
		return false
	_active = true
	_elapsed = 0.0
	_from = player.global_position
	_to = dest
	player.velocity = Vector3.ZERO
	AudioSynth.play(player.game, "mantle")
	return true

func tick(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	# Rise first, then swing forward — climbing over the lip rather than
	# sliding diagonally through it.
	var y_t := clampf(t * 1.6, 0.0, 1.0)
	var xz_t := clampf((t - 0.35) / 0.65, 0.0, 1.0)
	xz_t = xz_t * xz_t * (3.0 - 2.0 * xz_t)
	player.global_position = Vector3(
		lerpf(_from.x, _to.x, xz_t),
		lerpf(_from.y, _to.y, y_t),
		lerpf(_from.z, _to.z, xz_t))
	if t >= 1.0:
		_active = false
		player.velocity = Vector3.ZERO

# ------------------------------------------------------------ detection ---
## Returns the landing position, or Vector3.INF when there is nothing to climb.
func _find_ledge() -> Vector3:
	var limit := VerbData.mantle_height(player.char_id)
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return Vector3.INF
	fwd = fwd.normalized()
	var feet := player.global_position
	var base_y := minf(feet.y, player.movement.last_floor_y)
	# 1. Is there something directly in front at chest height?
	var chest := feet + Vector3(0, CHEST_H, 0)
	var wall := _ray(chest, chest + fwd * REACH)
	if wall.is_empty():
		return Vector3.INF
	var wall_point: Vector3 = wall["position"]
	# 2. Find the top, a little way past the lip.
	var top_y := _top_at(wall_point + fwd * LEDGE_INSET, base_y, limit)
	if _in_band(top_y - base_y, limit):
		# The floor found past the wall is only a ledge if the wall ends near it.
		if _wall_continues(wall_point, fwd, top_y):
			return Vector3.INF
		return _landing(wall_point, fwd, top_y)
	# 3. Nothing to stand on there: a fence or rail? Vault it.
	var lip_y := _top_at(wall_point + fwd * LIP_INSET, base_y, limit)
	if not _in_band(lip_y - base_y, limit):
		return Vector3.INF
	if _wall_continues(wall_point, fwd, lip_y):
		return Vector3.INF
	return _vault(wall_point, fwd, lip_y, base_y)

## A fence, a crate or a parapet ends within OVERHEAD of its top. A building
## wall goes on above — and at 0.3m thick it looks like a thin ledge from the
## side, so a floor behind it (F10, the ground floor) looked climbable: standing
## on a crate and jumping at the main block's east wall carried you through it.
func _wall_continues(wall_point: Vector3, fwd: Vector3, top_y: float) -> bool:
	var above := Vector3(wall_point.x, top_y + OVERHEAD, wall_point.z)
	return not _ray(above - fwd * 0.3, above + fwd * 0.5).is_empty()

func _in_band(rise: float, limit: float) -> bool:
	return rise >= MIN_RISE and rise <= limit + RISE_EPS

## Height of the first surface below the reach limit at `at`, or -INF.
func _top_at(at: Vector3, base_y: float, limit: float) -> float:
	var probe := Vector3(at.x, base_y + limit + 0.5, at.z)
	var top := _ray(probe, probe - Vector3(0, limit + 1.2, 0))
	return -INF if top.is_empty() else (top["position"] as Vector3).y

## Standing spot on the ledge, pushed further in if the near spot would put
## the capsule inside a parapet.
func _landing(wall_point: Vector3, fwd: Vector3, ledge_y: float) -> Vector3:
	for push in [LANDING_PUSH, LANDING_PUSH_FAR]:
		var dest := Vector3(wall_point.x, ledge_y + 0.05, wall_point.z) + fwd * float(push)
		if _fits(dest):
			return dest
	return Vector3.INF

## Over a thin obstacle to the floor behind it, which must be no higher than
## the lip and no more than 3m below where you started.
func _vault(wall_point: Vector3, fwd: Vector3, lip_y: float, base_y: float) -> Vector3:
	for push in [0.8, 1.1]:
		var over := Vector3(wall_point.x, lip_y + 0.1, wall_point.z) + fwd * float(push)
		var down := _ray(over, over - Vector3(0, lip_y - base_y + 3.0, 0))
		if down.is_empty():
			continue
		var dest: Vector3 = (down["position"] as Vector3) + Vector3(0, 0.05, 0)
		if dest.y < lip_y - 0.3 and _fits(dest):
			return dest
	return Vector3.INF

## Does a crouched capsule fit at `dest`?
func _fits(dest: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = VerbData.BODY_RADIUS * 0.9
	shape.height = maxf(VerbData.crouch_height(player.char_id), shape.radius * 2.0)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), dest + Vector3(0, shape.height * 0.5 + 0.02, 0))
	q.exclude = [player.get_rid()]
	q.collision_mask = VerbData.BODY_MASK
	return player.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	q.collision_mask = VerbData.BODY_MASK
	return player.get_world_3d().direct_space_state.intersect_ray(q)
