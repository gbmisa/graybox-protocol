class_name Sec2Warehouse
extends RefCounted
## The impound warehouse: x[-96,-64], z[-58,-38], 3.5m walls.
##
## A seized-goods crate maze — dense interior cover on the west approach,
## not a required route. One three-verb door on the north wall; an open
## 1.5m personnel gap on the east wall. The seized-goods log and Manifest
## 12-C sit on crate tops (optional intel).

const X0 := -96.0
const X1 := -64.0
const Z0 := -58.0
const Z1 := -38.0
const WALL_H := 3.5
const WALL_T := 0.5

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_walls(game, root)
	_build_crate_maze(root)
	# Both notes sit on crate tops (2.0m), never floating.
	IntelPickup.create(game, root, "seized", Vector3(-82, 2.0, -46))
	IntelPickup.create(game, root, "manifest12c", Vector3(-78, 2.0, -52))
	BuildUtils.label(root, "IMPOUND WAREHOUSE", Vector3(-80, 5.0, -48), Color(1.0, 0.84, 0.37), 48)
	BuildUtils.lamp(root, Vector3(-80, 5.5, -48), BuildUtils.LAMP_SERVICE)

static func _build_walls(game: GrayboxGame, root: Node3D) -> void:
	var c := Color(0.38, 0.36, 0.32)
	# North wall (z=-58) with a 2m three-verb door at (-80,0,-58).
	BuildUtils.box(root, Vector3(-88.5, WALL_H * 0.5, Z0),
		Vector3(15.0, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(-71.5, WALL_H * 0.5, Z0),
		Vector3(15.0, WALL_H, WALL_T), c)
	var door := LockedDoor.create(game, root, "WAREHOUSE DOOR",
		Vector3(-80, 1.5, Z0), Vector3(2.0, 3.0, 0.6),
		["lockpick", "arcane", "smash"])
	door.exit_side = Vector3(0, 0, 1)  # free exit from inside
	# South wall: solid run.
	BuildUtils.box(root, Vector3(-80, WALL_H * 0.5, Z1),
		Vector3(32.0, WALL_H, WALL_T), c)
	# West wall: solid run.
	BuildUtils.box(root, Vector3(X0, WALL_H * 0.5, -48),
		Vector3(WALL_T, WALL_H, 20.0), c)
	# East wall (x=-64) with an open 1.5m personnel gap at (-64,0,-48).
	BuildUtils.box(root, Vector3(X1, WALL_H * 0.5, -53.375),
		Vector3(WALL_T, WALL_H, 9.25), c)
	BuildUtils.box(root, Vector3(X1, WALL_H * 0.5, -42.625),
		Vector3(WALL_T, WALL_H, 9.25), c)
	BuildUtils.box(root, Vector3(X1, 3.0, -48),
		Vector3(WALL_T, 1.0, 1.5), c)  # header over the gap

static func _build_crate_maze(root: Node3D) -> void:
	var crate := Color(0.45, 0.33, 0.20)
	var crate2 := Color(0.36, 0.28, 0.18)
	var rows := [
		[[-90, -54], [-86, -54], [-82, -54], [-74, -54], [-70, -54]],
		[[-90, -46], [-82, -46], [-74, -46]],
		[[-90, -40], [-82, -40], [-78, -40], [-70, -40]],
		[[-86, -52], [-78, -52], [-70, -52]],
	]
	var alt := false
	for row in rows:
		for cp in row:
			alt = not alt
			Sec2Cover.crate(root, Vector3(cp[0], 1.0, cp[1]),
				Vector3(2.0, 2.0, 2.0), crate if alt else crate2)
	# A stacked pair for silhouette variety.
	Sec2Cover.crate(root, Vector3(-82, 3.0, -46), Vector3(2.0, 2.0, 2.0),
		crate)
