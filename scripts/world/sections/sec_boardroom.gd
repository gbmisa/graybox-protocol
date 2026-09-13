class_name SecBoardroom
extends RefCounted
## The target floor at y = 12, x [-30, 30], z [-40, -24].
##
## Three doors in the south wall, one per operative, each at the head of its
## own stair. They sit in a row so you always see the two routes you cannot
## take — the hard gates explain themselves instead of reading as broken
## geometry.
##
##   x -24  SERVER ACCESS      [lockpick]  REGULAR
##   x   0  WARDED DOOR        [arcane]    WIZARD
##   x  22  REINFORCED PANEL   [smash]     CHAD
##
## The drop chute at x [22, 30], z [-40, -34] falls to the ground floor and is
## the way back out: a one-way exit, since nothing climbs 12m.

const FLOOR_Y := 12.0
const WALL_H := 6.0
const T := 0.8

static func build(root: Node3D, game: GrayboxGame) -> Vector3:
	_floor(root)
	_south_wall(root, game)
	_furniture(root)
	_chute(root)
	_lights(root)
	BuildUtils.label(root, "BOARDROOM", Vector3(0, 16.5, -30),
		BuildUtils.RED, 44)
	# North of the table, which occupies z [-34, -30].
	return Vector3(0, FLOOR_Y, -27.5)

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(0, 16.5, -30), Vector3(-18, 16.5, -34),
		Vector3(16, 16.5, -28), Vector3(-24, 16.5, -26),
	], BuildUtils.LAMP_FLUORO, 2.4, 24.0)
	# Down the chute, so the drop reads as a route rather than a pit.
	BuildUtils.lamps(root, [
		Vector3(26, 10, -37), Vector3(26, 3, -37),
	], BuildUtils.GREEN, 1.8, 10.0)

static func _floor(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, -30, 30, -34, -24, FLOOR_Y, 0.6, c)
	BuildUtils.plate(root, -30, 22, -40, -34, FLOOR_Y, 0.6, c)  # cut for chute

static func _south_wall(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL
	var mid := FLOOR_Y + WALL_H * 0.5
	# Solid runs between the three doorways.
	BuildUtils.box(root, Vector3(-28, mid, -24), Vector3(4, WALL_H, T), c)
	BuildUtils.box(root, Vector3(-12, mid, -24), Vector3(20, WALL_H, T), c)
	BuildUtils.box(root, Vector3(11, mid, -24), Vector3(18, WALL_H, T), c)
	BuildUtils.box(root, Vector3(27, mid, -24), Vector3(6, WALL_H, T), c)
	# Headers above each doorway.
	BuildUtils.box(root, Vector3(-24, 16.5, -24), Vector3(4, 3, T), c)
	BuildUtils.box(root, Vector3(0, 17, -24), Vector3(4, 2, T), c)
	BuildUtils.box(root, Vector3(22, 17, -24), Vector3(4, 2, T), c)
	LockedDoor.create(game, root, "SERVER ACCESS",
		Vector3(-24, 13.5, -24), Vector3(4, 3, T), ["lockpick"])
	WardedSeal.create(game, root, "WARDED DOOR",
		Vector3(0, 14, -24), Vector3(4, 4, T))
	BreakableWall.create(game, root, "REINFORCED PANEL",
		Vector3(22, 14, -24), Vector3(4, 4, 1.0))

static func _furniture(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(0, FLOOR_Y + 0.5, -32), Vector3(16, 1, 4),
		Color(0.34, 0.28, 0.22))
	for x in [-6.0, 0.0, 6.0]:
		for z in [-29.0, -35.0]:
			BuildUtils.box(root, Vector3(x, FLOOR_Y + 0.6, z),
				Vector3(1.2, 1.2, 1.2), BuildUtils.METAL)
	# Glass curtain wall along the north face — cover-free, all sightline.
	BuildUtils.box(root, Vector3(-20, FLOOR_Y + 1.2, -38),
		Vector3(14, 2.4, 0.6), BuildUtils.PIPE)

static func _chute(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	BuildUtils.box(root, Vector3(21.6, 6, -37), Vector3(0.8, 24, 6), c)
	BuildUtils.box(root, Vector3(26, 6, -33.6), Vector3(8, 24, 0.8), c)
	BuildUtils.label(root, "EMERGENCY CHUTE — DOWN",
		Vector3(26, FLOOR_Y + 2, -35), BuildUtils.GREEN, 30)
