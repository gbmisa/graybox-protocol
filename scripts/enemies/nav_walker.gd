class_name NavWalker
extends RefCounted
## Follows a navmesh path toward a goal for whoever owns it (a guard, a
## civilian). Repaths twice a second or when the goal moves; with no navmesh it
## steers straight at the goal.
##
## `steer()` adds what a path alone does not: room between colleagues (eight
## alerted guards used to walk into the same point and stand in a clump), and
## a way out when the body stops making progress — a sidestep and a fresh
## path, instead of pressing into a door jamb or another guard forever.

const SEPARATION := 1.1          # metres: push off anyone closer than this
const STUCK_SPEED := 0.25        # fraction of the wanted speed that counts as stuck
const STUCK_TIME := 0.5
const DETOUR_TIME := 0.6
## A path corner counts as reached this close. At 0.6 a guard turned early and
## walked diagonally into the jamb of the doorway he was heading through.
const CORNER := 0.35

var _path: PackedVector3Array = PackedVector3Array()
var _i: int = 0
var _age: float = 99.0
var _goal: Vector3 = Vector3.INF
var _stuck: float = 0.0
var _detour: float = 0.0
var _detour_dir := Vector3.ZERO

## The next point to steer at.
func step(body: Node3D, target: Vector3, delta: float) -> Vector3:
	_age += delta
	if _age > 0.5 or _goal.distance_to(target) > 1.5:
		_age = 0.0
		_goal = target
		_path = GuardNav.path(body.get_world_3d(), body.global_position, target)
		_i = 1
	while _i < _path.size():
		var d := _path[_i] - body.global_position
		d.y = 0.0
		if d.length() > CORNER:
			return _path[_i]
		_i += 1
	return target

## A flat unit direction toward `target`: the path, pushed off `others`, and
## bent sideways for a moment whenever `body` has been stuck.
func steer(body: CharacterBody3D, target: Vector3, speed: float, delta: float,
		others: Array) -> Vector3:
	var real := body.get_real_velocity()
	if Vector2(real.x, real.z).length() < speed * STUCK_SPEED:
		_stuck += delta
	else:
		_stuck = maxf(0.0, _stuck - delta)
	var dir := step(body, target, delta) - body.global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		dir = target - body.global_position
		dir.y = 0.0
	dir = dir.normalized()
	if _stuck > STUCK_TIME:
		_stuck = 0.0
		_detour = DETOUR_TIME
		_detour_dir = _free_side(body, dir)
		_age = 99.0     # repath from wherever the sidestep leaves us
	if _detour > 0.0:
		_detour -= delta
		dir = (dir * 0.35 + _detour_dir).normalized()
	var push := Vector3.ZERO
	for o in others:
		var n := o as Node3D
		if n == body or n == null or not is_instance_valid(n) or not n.get("alive"):
			continue
		var away := body.global_position - n.global_position
		away.y = 0.0
		var d := away.length()
		if d < SEPARATION and d > 0.001:
			push += away / d * (SEPARATION - d) / SEPARATION
	if push != Vector3.ZERO:
		dir = (dir + push * 1.5).normalized()
	return dir

## A sidestep that isn't into the thing he's stuck on: left or right, whichever
## is clear (probed 10cm up, off the floor seams), else straight back.
func _free_side(body: CharacterBody3D, dir: Vector3) -> Vector3:
	var probe := body.global_transform.translated(Vector3.UP * 0.1)
	var side := Vector3(-dir.z, 0.0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
	for c in [side, -side]:
		if not body.test_move(probe, c * 0.5):
			return c
	return -dir
