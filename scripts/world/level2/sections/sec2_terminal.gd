class_name Sec2Terminal
extends RefCounted
## Container terminal (west): x[-100,-25], z[-38,20].
##
## A dense container yard with real lanes and cover — not a corridor. The
## west approach to the office runs along z=-14; the vent approach stays
## clear at x[-14,-6], z[-36,-30]. The key-locked storage building (south)
## holds the Harbormaster's routine: the key buys knowledge, never a
## required step. Every gate takes all three verbs.

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_maze(root)
	_build_storage_compound(game, root)
	BuildUtils.label(root, "TERMINAL 7 — CONTAINERS", Vector3(-70, 6.5, -40), Color(1.0, 0.84, 0.37), 48)

static func _container(root: Node3D, pos: Vector3, size: Vector3,
		color: Color, stack: int = 1) -> void:
	# Orientation is baked into the size — never rotate the returned mesh.
	for i in stack:
		Sec2Cover.crate(root, Vector3(pos.x, pos.y + 1.3 + 2.6 * i, pos.z),
			size, color)

static func _build_maze(root: Node3D) -> void:
	var rust := Color(0.48, 0.26, 0.14)
	var blue := Color(0.16, 0.30, 0.44)
	var green := Color(0.20, 0.36, 0.22)
	var gray := Color(0.32, 0.34, 0.36)
	var ew12 := Vector3(12.2, 2.6, 2.4)
	var ns6 := Vector3(2.4, 2.6, 6.1)
	var ew6 := Vector3(6.1, 2.6, 2.4)
	# North row (above the west approach lane).
	_container(root, Vector3(-85, 0, -33), ew12, rust)
	_container(root, Vector3(-62, 0, -33), ew12, blue, 2)
	_container(root, Vector3(-40, 0, -33), ns6, gray)
	# Mid field.
	_container(root, Vector3(-90, 0, -6), ew12, green)
	_container(root, Vector3(-70, 0, 4), ns6, rust, 2)
	_container(root, Vector3(-52, 0, -2), ew12, blue)
	_container(root, Vector3(-32, 0, 6), ns6, gray)
	_container(root, Vector3(-48, 0, -29), ew12, rust)
	_container(root, Vector3(-70, 0, -24), ew6, green)
	# South field.
	_container(root, Vector3(-80, 0, 14), ew12, rust)
	_container(root, Vector3(-58, 0, 16), ns6, blue)
	_container(root, Vector3(-38, 0, 12), ew6, green)

static func _build_storage_compound(game: GrayboxGame, root: Node3D) -> void:
	# A REAL building: x[-46,-34], z[-6,18], 3m walls, roof slab, ONE
	# door on the north wall taking all three verbs or the storage key.
	# Flood-fill verified: with the door closed the interior is unreachable
	# from the exterior.
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
	# North wall split around the 3m door at x [-41.5, -38.5].
	BuildUtils.box(root, Vector3(-43.75, wh * 0.5, z0),
		Vector3(4.5, wh, t), c)
	BuildUtils.box(root, Vector3(-36.25, wh * 0.5, z0),
		Vector3(4.5, wh, t), c)
	# Roof slab.
	BuildUtils.box(root, Vector3(-40, wh + 0.3, 6),
		Vector3(12 + t, 0.6, 24 + t), c)
	var gate := LockedDoor.create(game, root, "STORAGE DOOR",
		Vector3(-40, 1.5, z0), Vector3(3.0, 3.0, 0.6),
		["lockpick", "arcane", "smash", "key:storage_key"])
	gate.exit_side = Vector3(0, 0, 1)  # free exit from inside
	BuildUtils.label(root, "STORAGE — KEY OR VERB",
		Vector3(-40, 3.8, z0), Color(0.85, 0.65, 0.25), 32)
	# Interior: desk with the routine note, crates, a lamp.
	BuildUtils.box(root, Vector3(-40, 0.45, 6),
		Vector3(2.2, 0.9, 1.1), Color(0.42, 0.32, 0.20))
	IntelPickup.create(game, root, "routine", Vector3(-40, 0.9, 6))
	for cp in [Vector3(-44, 0.5, 12), Vector3(-36.5, 0.5, 12),
			Vector3(-44, 0.5, 2), Vector3(-37, 0.5, 14)]:
		Sec2Cover.crate(root, cp, Vector3(2.0, 1.0, 2.0),
			Color(0.40, 0.30, 0.18))
	BuildUtils.lamp(root, Vector3(-40, 2.6, 6), BuildUtils.LAMP_SERVICE)
