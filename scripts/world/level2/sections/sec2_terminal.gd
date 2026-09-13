class_name Sec2Terminal
extends RefCounted
## Container terminal (west district): x[-100,-25], z[-60,25].
##
## A container maze with real lanes and cover, the Wizard's dash line to the
## office roof, and a key-locked storage building (south) holding the
## Harbormaster's routine — the key buys knowledge, never a required step.
##
## Dash line (axis z=-26, all tops at 3.6):
##   ramp  (-58,0,-26) -> (-46,3.6,-26)   walkable approach
##   P1    x[-46,-40], z[-31,-21]          first roof
##   9.0m dash east ->
##   P2    x[-31,-25], z[-31,-21]          second roof
##   9.0m dash east -> office west wall (x=-16), land on the roof
## Both gaps are unjumpable (empirically ~7m max) and dashable (9.1m level
## dash). The corridor x[-60,-14], z[-32,-20] is kept clear of containers.

const DASH_TOP := 3.6
const DASH_Z := -26.0

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_maze(root)
	_build_dash_line(root)
	_build_storage_compound(game, root)
	_build_cover(root)
	BuildUtils.label(root, "TERMINAL 7 — CONTAINERS", Vector3(-70, 6.5, -40), Color(1.0, 0.84, 0.37), 48)

static func _container(root: Node3D, pos: Vector3, size: Vector3,
		color: Color, stack: int = 1) -> void:
	# Note: BuildUtils.box does not rotate collision, so orientation is
	# baked into the size — never rotate the returned mesh.
	for i in stack:
		BuildUtils.box(root, Vector3(pos.x, pos.y + 1.3 + 2.6 * i, pos.z),
			size, color)

static func _build_maze(root: Node3D) -> void:
	var rust := Color(0.48, 0.26, 0.14)
	var blue := Color(0.16, 0.30, 0.44)
	var green := Color(0.20, 0.36, 0.22)
	var gray := Color(0.32, 0.34, 0.36)
	var ew12 := Vector3(12.2, 2.6, 2.4)
	var ns6 := Vector3(2.4, 2.6, 6.1)
	var ew6 := Vector3(6.1, 2.6, 2.4)
	# North lanes (above the dash corridor).
	_container(root, Vector3(-80, 0, -45), ew12, rust)
	_container(root, Vector3(-80, 0, -38), ew12, blue, 2)
	_container(root, Vector3(-58, 0, -50), ns6, green)
	_container(root, Vector3(-35, 0, -45), ew12, gray)
	_container(root, Vector3(-45, 0, -38), ns6, rust)
	# South lanes (below the dash corridor).
	_container(root, Vector3(-60, 0, 0), ew12, blue)
	_container(root, Vector3(-75, 0, 8), ns6, green, 2)
	_container(root, Vector3(-90, 0, -10), ew12, rust)
	_container(root, Vector3(-55, 0, 18), ns6, gray)
	_container(root, Vector3(-35, 0, 15), ns6, blue)
	_container(root, Vector3(-70, 0, -12), ew6, green)
	_container(root, Vector3(-85, 0, 20), ew12, gray)

static func _build_dash_line(root: Node3D) -> void:
	var plat := Color(0.42, 0.44, 0.48)
	# Walkable ramp: 12m run, 3.6m rise, 3m wide, heading east onto P1.
	BuildUtils.ramp(root, Vector3(-58, 0, DASH_Z), Vector3(1, 0, 0),
		12.0, DASH_TOP, 3.0, plat)
	# P1 (6m) and P2 (13m, generous): 1.2m thick slabs, tops at 3.6.
	# Gaps are 5.5m — just beyond the 4.74m jump range, so the 9.1m dash
	# is required but the landing is huge: no precision braking.
	BuildUtils.box(root, Vector3(-43, DASH_TOP - 0.6, DASH_Z),
		Vector3(6.0, 1.2, 10.0), plat)
	BuildUtils.box(root, Vector3(-28, DASH_TOP - 0.6, DASH_Z),
		Vector3(13.0, 1.2, 10.0), plat)
	# Legs so the platforms don't float.
	for px in [-45.0, -41.0, -33.0, -29.0, -25.0, -22.0]:
		BuildUtils.box(root, Vector3(px, 1.2, DASH_Z), Vector3(0.6, 2.4, 0.6),
			BuildUtils.PIPE)
	for px in [-30.0, -26.0]:
		BuildUtils.box(root, Vector3(px, 1.2, DASH_Z), Vector3(0.6, 2.4, 0.6),
			BuildUtils.PIPE)
	# Edge chevrons: the line reads as a dash line, not decoration.
	BuildUtils.label(root, "DASH >", Vector3(-43, DASH_TOP + 0.8, DASH_Z), Color(0.72, 0.40, 1.0), 40)
	BuildUtils.label(root, "DASH >", Vector3(-28, DASH_TOP + 0.8, DASH_Z), Color(0.72, 0.40, 1.0), 40)

static func _build_storage_compound(game: GrayboxGame, root: Node3D) -> void:
	# A REAL building: x[-46,-34], z[-6,18], 3m walls, roof slab, ONE
	# key-locked door on the north wall. Flood-fill verified: with the door
	# closed the interior is unreachable from the exterior.
	# Inside: the Harbormaster's routine (optional intel, on a desk) — the
	# key buys knowledge of the target's patrol, never a required step.
	var c := Color(0.36, 0.34, 0.30)
	var x0 := -46.0
	var x1 := -34.0
	var z0 := -6.0
	var z1 := 18.0
	var t := 0.5
	var wh := 3.0
	# South, east, west walls: solid runs.
	BuildUtils.box(root, Vector3(-40, wh * 0.5, z1),
		Vector3(12 + t, wh, t), c)
	BuildUtils.box(root, Vector3(x0, wh * 0.5, 6),
		Vector3(t, wh, 24 + t), c)
	BuildUtils.box(root, Vector3(x1, wh * 0.5, 6),
		Vector3(t, wh, 24 + t), c)
	# North wall split around the 3m key door at x [-41.5, -38.5].
	BuildUtils.box(root, Vector3(-43.75, wh * 0.5, z0),
		Vector3(4.5, wh, t), c)
	BuildUtils.box(root, Vector3(-36.25, wh * 0.5, z0),
		Vector3(4.5, wh, t), c)
	# Roof slab.
	BuildUtils.box(root, Vector3(-40, wh + 0.3, 6),
		Vector3(12 + t, 0.6, 24 + t), c)
	var gate := LockedDoor.create(game, root, "STORAGE DOOR",
		Vector3(-40, 1.5, z0), Vector3(3.0, 3.0, 0.6), ["key:storage_key"])
	gate.exit_side = Vector3(0, 0, 1)  # free exit from inside
	BuildUtils.label(root, "STORAGE — KEY REQUIRED",
		Vector3(-40, 3.8, z0), Color(0.85, 0.65, 0.25), 32)
	# Interior: desk with the routine note, crates, a lamp.
	BuildUtils.box(root, Vector3(-40, 0.45, 6),
		Vector3(2.2, 0.9, 1.1), Color(0.42, 0.32, 0.20))
	IntelPickup.create(game, root, "routine", Vector3(-40, 0.9, 6))
	for cp in [Vector3(-44, 0.5, 12), Vector3(-36.5, 0.5, 12),
			Vector3(-44, 0.5, 2), Vector3(-37, 0.5, 14)]:
		BuildUtils.box(root, cp, Vector3(2.0, 1.0, 2.0),
			Color(0.40, 0.30, 0.18))
	BuildUtils.lamp(root, Vector3(-40, 2.6, 6), BuildUtils.LAMP_SERVICE)

static func _build_cover(root: Node3D) -> void:
	# Low cover on the two ground lanes the vectors actually walk: the
	# Regular's east approach and Chad's lane to the west door. Kept off
	# guard patrol lines and out of the dash flight corridor.
	var crate := Color(0.44, 0.32, 0.20)
	for cp in [Vector3(55, 1.0, -22), Vector3(45, 1.0, -28),
			Vector3(35, 1.0, -20), Vector3(28, 1.0, -27),
			Vector3(-50, 1.0, -20), Vector3(-40, 1.0, -29),
			Vector3(-27, 1.0, -19)]:
		BuildUtils.box(root, cp, Vector3(2.0, 2.0, 2.0), crate)
