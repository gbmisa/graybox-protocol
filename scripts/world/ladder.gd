class_name Ladder
extends RefCounted
## A ladder (r7: the construction site is "accessible by ladder or
## staircase"). Not a body of its own: two rails and rungs drawn against a
## face, plus a climb zone registered here that `PlayerMovement` checks.
##
## In the zone, holding forward climbs at CLIMB_SPEED, back climbs down, and
## nothing held hangs on. Jump kicks you off backwards. The zone runs 1.1m
## past the top so you climb until your feet clear the deck, and holding
## forward then walks you onto it.
##
## `base` is the foot of the ladder on the ground, `yaw` the way a climber
## faces (0 = north, -z; PI = south; PI/2 = west; -PI/2 = east) — i.e. the
## ladder is on the face in front of him, and the deck he steps onto at the
## top lies beyond that face. A solid board is built behind the rungs up to
## `top_y` so there is always a face to climb against (and nothing to walk
## under by holding forward).

const CLIMB_SPEED := 3.6
const WIDTH := 0.7
const COLOR := Color(0.85, 0.65, 0.10)

static var zones: Array[AABB] = []

## Called once per level build: the zones are the level's, not the class's.
static func clear() -> void:
	zones.clear()

static func create(root: Node3D, base: Vector3, top_y: float, yaw: float) -> void:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var side := Vector3(fwd.z, 0, -fwd.x)
	var h := top_y - base.y
	BuildUtils.box(root, base + fwd * 0.06 + Vector3(0, h * 0.5, 0),
		side.abs() * (WIDTH + 0.3) + fwd.abs() * 0.1 + Vector3(0, h, 0), Color(0.30, 0.26, 0.20))
	for s in [-1.0, 1.0]:
		var p: Vector3 = base + side * (WIDTH * 0.5 * s) + Vector3(0, (h + 1.0) * 0.5, 0)
		BuildUtils.box(root, p, Vector3(0.06, h + 1.0, 0.06), COLOR, false)
	var rung := Vector3(absf(side.x) * WIDTH + 0.04, 0.04, absf(side.z) * WIDTH + 0.04)
	var y := 0.3
	while y < h + 0.9:
		BuildUtils.box(root, base + Vector3(0, y, 0), rung, COLOR, false)
		y += 0.3
	# The zone: the ladder's footprint, a body's depth out from the face.
	var c := base - fwd * 0.35
	var half := side.abs() * (WIDTH * 0.5 + 0.1) + fwd.abs() * 0.45
	zones.append(AABB(Vector3(c.x - half.x, base.y - 0.1, c.z - half.z),
		Vector3(half.x * 2.0, h + 1.2, half.z * 2.0)))

## Is a body standing at `feet` on a ladder?
static func at(feet: Vector3) -> bool:
	for z in zones:
		if z.has_point(feet + Vector3(0, 0.2, 0)):
			return true
	return false
