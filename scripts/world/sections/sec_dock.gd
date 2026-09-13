class_name SecDock
extends RefCounted
## GIGA CHAD'S ROUTE — in through the side of the building.
##
##   DOCK SHUTTER [smash]  ->  loading dock
##   ->  COLLAPSED WALL [smash, Chad only]  ->  freight bay
##   ->  container stacks, climbed by 2.3m mantles
##   ->  mezzanine (y = 6)
##
## Both gates are the loudest events in the game and there is no quiet way to
## take this route. The short path and the high guard count are the trade: the
## building knows you are here from the first hit, and 250 HP is the budget for
## the fight that starts.
##
## Extent: dock x [30, 70], z [2, 40]. Freight bay x [8, 30], z [-26, 10].

const WALL_H := 8.0
const WALL_T := 0.8

## Two 2.3m rises: above everyone else's 1.2m mantle limit, inside Chad's 2.5m.
const CONTAINERS := [
	{"pos": Vector3(23, 0, -2), "size": Vector3(5.0, 2.3, 5.0)},
	{"pos": Vector3(17, 0, -3), "size": Vector3(5.0, 4.6, 5.0)},
	{"pos": Vector3(12, 0, -2), "size": Vector3(4.0, 5.6, 4.0)},
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	_dock(root, game)
	_breach(root, game)
	_freight_bay(root)
	_containers(root)
	_lights(root)
	BuildUtils.label(root, "LOADING DOCK", Vector3(50, 9, 28),
		Color(1.0, 0.52, 0.18), 40)

## The freight bay is fully enclosed; the container stack needs to be lit from
## above or the climb is invisible.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(50, 6, 32), Vector3(40, 6, 14), Vector3(62, 6, 0),
		Vector3(46, 6, -10),
	], BuildUtils.LAMP_SERVICE, 2.4, 22.0)
	BuildUtils.lamps(root, [
		Vector3(14, 5, -20), Vector3(26, 5, -14), Vector3(18, 5.4, -3),
		Vector3(11, 5, -8),
	], BuildUtils.LAMP_SERVICE, 2.4, 15.0)

static func _dock(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL
	var y := WALL_H * 0.5
	# The dock runs deep enough (to z = -16) to reach the stretch of tower wall
	# the collapsed section sits in. Its west side is the tower for z < 10 and
	# the shared courtyard wall above that.
	BuildUtils.box(root, Vector3(70, y, 12), Vector3(WALL_T, WALL_H, 56), c)
	BuildUtils.box(root, Vector3(50, y, -16), Vector3(40, WALL_H, WALL_T), c)
	# South face with the shutter gap at x [46, 54].
	BuildUtils.box(root, Vector3(38, y, 40), Vector3(16, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(62, y, 40), Vector3(16, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(50, 6.5, 40), Vector3(8, 3, WALL_T), c)
	LockedDoor.create(game, root, "DOCK SHUTTER",
		Vector3(50, 2.5, 40), Vector3(8, 5, WALL_T), ["smash"])
	# Dock furniture — pallets and a truck bed to fight around.
	BuildUtils.box(root, Vector3(60, 1.4, 30), Vector3(8, 2.8, 3), BuildUtils.METAL)
	for spot in [Vector3(40, 0, 30), Vector3(56, 0, 14), Vector3(66, 0, 8)]:
		BuildUtils.box(root, spot + Vector3(0, 0.9, 0), Vector3(2.4, 1.8, 2.4),
			BuildUtils.CRATE)

static func _breach(root: Node3D, game: GrayboxGame) -> void:
	BreakableWall.create(game, root, "COLLAPSED WALL",
		Vector3(30, 2.25, -8), Vector3(1.2, 4.5, 7))
	BuildUtils.label(root, "STRUCTURALLY UNSOUND",
		Vector3(34, 6, -8), Color(1.0, 0.52, 0.18), 30)

## x [8, 30], z [-26, 0]. The north side is closed by the vent shaft's back
## wall, so the freight bay and the Wizard's shaft never connect below the
## mezzanine.
static func _freight_bay(root: Node3D) -> void:
	var c := BuildUtils.WALL
	# West partition, with a plain doorway through to the tower ground floor
	# at z [-21, -18]. Without it the bay is sealed except a 2.3m mantle, so
	# anyone who is not Chad and drops in from the mezzanine is soft-locked —
	# no way out and no way to die. The doorway costs nothing in route terms:
	# the container climb still gates the way up, so reaching the bay from the
	# ground floor gets you a room and nothing else.
	BuildUtils.box(root, Vector3(8, 3, -23.5), Vector3(WALL_T, 6, 5), c)
	BuildUtils.box(root, Vector3(8, 3, -9), Vector3(WALL_T, 6, 18), c)
	BuildUtils.box(root, Vector3(8, 4.5, -19.5), Vector3(WALL_T, 3, 3), c)
	BuildUtils.box(root, Vector3(19, 3, -26), Vector3(22, 6, WALL_T), c)
	for spot in [Vector3(26, 0, -22), Vector3(11, 0, -16), Vector3(20, 0, -10)]:
		BuildUtils.box(root, spot + Vector3(0, 1.0, 0), Vector3(2.6, 2.0, 2.6),
			BuildUtils.CRATE)

static func _containers(root: Node3D) -> void:
	var tints := [Color(0.42, 0.30, 0.24), Color(0.30, 0.36, 0.42),
		Color(0.40, 0.38, 0.26)]
	for i in range(CONTAINERS.size()):
		var c: Dictionary = CONTAINERS[i]
		var size: Vector3 = c["size"]
		var pos: Vector3 = c["pos"]
		BuildUtils.box(root, pos + Vector3(0, size.y * 0.5, 0), size,
			tints[i % tints.size()])
	BuildUtils.label(root, "FREIGHT STACK — CLIMB",
		Vector3(17, 7, -2), Color(1.0, 0.52, 0.18), 30)
