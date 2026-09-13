class_name SecUndercroft
extends RefCounted
## THE REGULAR'S ROUTE — service level at y = -4.
##
##   culvert (1.0m crawl)  ->  descent  ->  undercroft
##   ->  MAINTENANCE DOOR [lockpick | arcane]
##   ->  boiler room  ->  stairwell  ->  mezzanine (y = 6)
##
## Also holds the sump outflow: a crawl-only extraction, so the two operatives
## who fit down here get an exit Chad can never reach.
##
## Extent: x [-60, -16], z [-16, 36], floor top y = -4.

const FLOOR_Y := -4.0
const CEIL_Y := 0.0
const WALL_T := 0.6

static func build(root: Node3D, game: GrayboxGame) -> void:
	_shell(root)
	_maintenance_wall(root, game)
	_boiler_room(root)
	_sump(root, game)
	_stairwell(root)
	_lights(root)
	BuildUtils.label(root, "UNDERCROFT", Vector3(-38, -1.5, 30),
		Color(0.35, 0.70, 1.0), 40)

## Fully enclosed with no daylight, so it is pitch black without these. The
## stairwell gets its own so the way up is visible from across the floor —
## it was reported as "not connected" when it was merely invisible.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-50, -1.4, 28), Vector3(-50, -1.4, 18),
		Vector3(-52, -1.4, 6), Vector3(-44, -1.4, -2),
		Vector3(-36, -1.4, 10), Vector3(-30, -1.4, -14),
		Vector3(-22, -1.4, 2),
	], BuildUtils.LAMP_SERVICE, 2.4, 15.0)
	BuildUtils.lamps(root, [
		Vector3(-24, -1.0, -14), Vector3(-24, 3.0, -12),
	], BuildUtils.LAMP_FLUORO, 2.6, 13.0)
	BuildUtils.lamp(root, Vector3(-66, -3.2, -6), BuildUtils.GREEN, 1.6, 9.0)

static func _shell(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(-38, FLOOR_Y - 0.5, 7),
		Vector3(44, 1, 58), BuildUtils.FLOOR)
	var c := BuildUtils.WALL
	var y := FLOOR_Y + 2.0
	# West wall, split around the sump crawl opening at z [-7, -5].
	BuildUtils.box(root, Vector3(-60, y, 15.5), Vector3(WALL_T, 4, 41), c)
	BuildUtils.box(root, Vector3(-60, y, -14.5), Vector3(WALL_T, 4, 15), c)
	BuildUtils.box(root, Vector3(-60, FLOOR_Y + 2.5, -6),
		Vector3(WALL_T, 3, 2), c)          # caps the crawl at 1.0m
	# South wall, split around the descent ramp arriving at x [-52.3, -47.7].
	BuildUtils.box(root, Vector3(-56.15, y, 36), Vector3(7.7, 4, WALL_T), c)
	BuildUtils.box(root, Vector3(-31.85, y, 36), Vector3(31.7, 4, WALL_T), c)
	BuildUtils.box(root, Vector3(-38, y, -22), Vector3(44, 4, WALL_T), c)
	BuildUtils.box(root, Vector3(-16, y, 7), Vector3(WALL_T, 4, 58), c)

## A dividing wall with the one door through it. Everything north of here is
## behind a lock.
static func _maintenance_wall(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL
	BuildUtils.box(root, Vector3(-56, FLOOR_Y + 2, 22), Vector3(8, 4, WALL_T), c)
	BuildUtils.box(root, Vector3(-32, FLOOR_Y + 2, 22), Vector3(32, 4, WALL_T), c)
	BuildUtils.box(root, Vector3(-50, CEIL_Y - 0.5, 22), Vector3(4, 1, WALL_T), c)
	LockedDoor.create(game, root, "MAINTENANCE DOOR",
		Vector3(-50, FLOOR_Y + 1.5, 22), Vector3(4, 3, WALL_T),
		["lockpick", "arcane"])

static func _boiler_room(root: Node3D) -> void:
	var pipe := BuildUtils.PIPE
	# Boilers and standing pipework: cover in a space with no room to retreat.
	for spot in [Vector3(-54, 0, 8), Vector3(-46, 0, 2), Vector3(-52, 0, -8)]:
		BuildUtils.box(root, spot + Vector3(0, FLOOR_Y + 1.4, 0),
			Vector3(3, 2.8, 3), BuildUtils.METAL)
	for x in [-58.0, -44.0, -30.0]:
		BuildUtils.box(root, Vector3(x, FLOOR_Y + 2, 14),
			Vector3(0.5, 4, 0.5), pipe, false)
	for spot in [Vector3(-38, 0, 18), Vector3(-24, 0, 4), Vector3(-34, 0, -10)]:
		BuildUtils.box(root, spot + Vector3(0, FLOOR_Y + 0.9, 0),
			Vector3(2, 1.8, 2), BuildUtils.CRATE)

## Crawl-only extraction. The 1.0m tunnel is the whole gate.
##
## BuildUtils.tunnel() builds floor, ceiling and sides but no end caps, so this
## needs one: without it the tunnel opened onto nothing and you walked out of
## the world. The trigger sits inside the tunnel, short of the cap.
static func _sump(root: Node3D, game: GrayboxGame) -> void:
	BuildUtils.tunnel(root, Vector3(-60, FLOOR_Y, -6), Vector3(-76, FLOOR_Y, -6),
		1.0, 1.6, BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(-76.2, FLOOR_Y + 0.5, -6),
		Vector3(0.4, 1.8, 2.4), BuildUtils.CONCRETE)
	BuildUtils.label(root, "EXTRACTION — SUMP OUTFLOW",
		Vector3(-70, FLOOR_Y + 1.4, -6), BuildUtils.GREEN, 28)
	BuildUtils.zone(root, game, "sump", Vector3(-74, FLOOR_Y + 0.4, -6), 2.2)

## Switchback stairs climbing the full 10m from the service level to the
## mezzanine, through the shaft cut in the tower's ground and mezzanine slabs
## at x [-30, -18], z [-8, 8]. Two flights side by side sharing a landing at
## each end, so the run reaches solid floor at the top.
static func _stairwell(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.stairs(root, Vector3(-27, FLOOR_Y, -5), Vector3(0, 0, 1),
		10, 0.5, 1.0, 5.0, c)
	BuildUtils.plate(root, -30, -18, 5, 8, 1.0, 0.5, c)            # turn landing
	BuildUtils.stairs(root, Vector3(-21, 1.0, 5), Vector3(0, 0, -1),
		10, 0.5, 1.4, 5.0, c)
	# Top landing removed: the flight now runs to z -9, landing directly on
	# the main floor plate (z -34..-8). The old separate landing plate left
	# a seam that trapped climbers at the top.
	BuildUtils.label(root, "SERVICE STAIR", Vector3(-24, -2, 0),
		Color(0.35, 0.70, 1.0), 32)
