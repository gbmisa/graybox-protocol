class_name Sec2Warehouse
extends RefCounted
## The impound warehouse: x[-96,-64], z[-40,-14], 3.5m walls, no roof.
## Chad's vector: BREACH the west wall [smash], cross the seized-goods
## crate maze, exit the east personnel door toward the office.
##
## The crate maze is the warehouse's identity — dense 2m lanes, not the
## terminal's tall container stacks. The two warehouse guards patrol through
## the east-door corridor, so the breach noise pulls them across Chad's exit.

const X0 := -96.0
const X1 := -64.0
const Z0 := -40.0
const Z1 := -14.0
const WALL_H := 3.5
const WALL_T := 0.5

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_walls(game, root)
	_build_crate_maze(root)
	IntelPickup.create(game, root, "seized", Vector3(-80, 0, -20))
	BuildUtils.label(root, "IMPOUND WAREHOUSE", Vector3(-80, 5.0, -27), Color(1.0, 0.84, 0.37), 48)
	BuildUtils.lamp(root, Vector3(-80, 5.5, -27), BuildUtils.LAMP_SERVICE)

static func _build_walls(game: GrayboxGame, root: Node3D) -> void:
	var c := Color(0.38, 0.36, 0.32)
	var cx := (X0 + X1) * 0.5
	var cz := (Z0 + Z1) * 0.5
	var w := X1 - X0
	var d := Z1 - Z0
	# North and south walls (full runs).
	BuildUtils.box(root, Vector3(cx, WALL_H * 0.5, Z0), Vector3(w, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(cx, WALL_H * 0.5, Z1), Vector3(w, WALL_H, WALL_T), c)
	# East wall with a 1.5m personnel gap at (-64,0,-27).
	var ez := -27.0
	for seg in [[Z0, ez - 0.75], [ez + 0.75, Z1]]:
		var z0: float = seg[0]
		var z1: float = seg[1]
		BuildUtils.box(root, Vector3(X1, WALL_H * 0.5, (z0 + z1) * 0.5),
			Vector3(WALL_T, WALL_H, z1 - z0), c)
	BuildUtils.box(root, Vector3(X1, 2.6, ez), Vector3(WALL_T, 0.5, 1.9), c)
	# West wall: split around the 3m breach panel at z [-28.5, -25.5].
	var bz := -27.0
	for seg in [[Z0, bz - 1.5], [bz + 1.5, Z1]]:
		var z0: float = seg[0]
		var z1: float = seg[1]
		BuildUtils.box(root, Vector3(X0, WALL_H * 0.5, (z0 + z1) * 0.5),
			Vector3(WALL_T, WALL_H, z1 - z0), c)
	# The breach: smash panel in the west wall gap. Loud (60m noise via SMASH_METHOD).
	var breach := BreakableWall.create(game, root, "WAREHOUSE WEST WALL",
		Vector3(X0, 1.5, -27), Vector3(0.6, 3.0, 3.0))
	breach.exit_side = Vector3(1, 0, 0)  # free exit from inside
	BuildUtils.label(root, "EAST EXIT", Vector3(X1 + 0.8, 2.6, ez), Color(0.35, 1.0, 0.45), 28)

static func _build_crate_maze(root: Node3D) -> void:
	# Seized-goods crates, 2m cubes in maze rows. The direct west-east line
	# (z=-27) weaves: breach (-96,-27) -> lanes -> east door (-64,-27).
	var crate := Color(0.45, 0.33, 0.20)
	var crate2 := Color(0.36, 0.28, 0.18)
	var rows := [
		[[-90, -34], [-86, -34], [-78, -34], [-74, -34], [-70, -34]],
		[[-90, -28], [-74, -28]],
		[[-90, -22], [-82, -22], [-78, -22], [-70, -22]],
		[[-86, -17], [-78, -17]],
	]
	var alt := false
	for row in rows:
		for cp in row:
			alt = not alt
			BuildUtils.box(root, Vector3(cp[0], 1.0, cp[1]),
				Vector3(2.0, 2.0, 2.0), crate if alt else crate2)
	# A stacked pair for silhouette variety.
	BuildUtils.box(root, Vector3(-82, 3.0, -30), Vector3(2.0, 2.0, 2.0), crate)
