class_name PlayerMantle
extends Node
## Climbing over ledges. Triggered by jump while facing an obstacle.
##
## The reach limit is per-operative (VerbData.mantle_height): everyone gets
## 1.2m so ordinary crates stay climbable, but Chad reaches 2.5m, which is what
## opens the container stacks and dock ledges on his route to him alone.

const CHEST_H := 0.9
const REACH := 0.9
const MIN_RISE := 0.25
const LEDGE_INSET := 0.45   # how far past the lip to probe for the top
const LANDING_PUSH := 0.5   # how far onto the ledge you end up

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
	# 1. Is there something directly in front at chest height?
	var chest := feet + Vector3(0, CHEST_H, 0)
	var wall := _ray(chest, chest + fwd * REACH)
	if wall.is_empty():
		return Vector3.INF
	var wall_point: Vector3 = wall["position"]
	# 2. Find its top by probing downward from above the reach limit.
	var probe := Vector3(wall_point.x, feet.y + limit + 0.5, wall_point.z) \
		+ fwd * LEDGE_INSET
	var top := _ray(probe, probe - Vector3(0, limit + 1.2, 0))
	if top.is_empty():
		return Vector3.INF
	var ledge_y: float = (top["position"] as Vector3).y
	var rise := ledge_y - feet.y
	if rise < MIN_RISE or rise > limit:
		return Vector3.INF
	# 3. Make sure the operative actually fits standing on it.
	var dest := Vector3(wall_point.x, ledge_y + 0.05, wall_point.z) \
		+ fwd * LANDING_PUSH
	var clearance := VerbData.crouch_height(player.char_id)
	if not _ray(dest + Vector3(0, 0.1, 0), dest + Vector3(0, clearance, 0)).is_empty():
		return Vector3.INF
	return dest

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(q)
