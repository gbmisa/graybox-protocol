class_name SecCmpMain1F
extends RefCounted
## Main block, first floor. Floor y 4.0 (slab 0.4, its underside is the
## ground floor's ceiling); every wall runs 4.0 -> 8.0, the roof deck's
## underside, so no room shares air with another over its walls.
##
## Room grid:
##   Assembly hall   x [-10, 6]  z [-20, -8]   ceiling 6.85-7.0 (roof file);
##                                              gallery z [-10,-8] at 5.0
##   Staff room      x [-19,-13] z [-20,-14]   hatch duct drops into panic room
##   N-stair landing x [-13,-10] z [-20,-18.5] exits by the hall's north door
##   West landing    x [-19,-10] z [-14, -8]   G9 at the hall's main doors
##   Passage W       x [-13,-10] z [ -8, -6]   open mouth south
##   AV booth (L4)   x [-10, -3] z [ -8, -6]   projection slot into the hall
##   South corridor  x [-13,  4] z [ -6, -2]   void x [-3, 2] over the lobby
##   Passage E       x [  2, 10] z [ -8, -6]   2.0m mouth onto the shelf
##   East landing    x [  6, 10] z [-20, -8]   bridge door east (shell)
##   West strip      x [-22,-19] z [-20, -2]   over the west corridor; fire-
##                                              escape door west, door east
##                                              onto the west landing (z -9.5)
##
## The lobby void is closed by a full slab: the lobby is a normal 3.6m room.
##
## Shafts with no floor: the north stair (x [-13,-10] z [-18.5,-14]), the west
## stair (x [-19,-13] z [-8,-2]), the east stair (x [4,10] z [-6,-2]) and the
## lobby void (x [-3,2] z [-8,-2]). Each gets a wall wherever a floor would
## otherwise run off into it.

const FLOOR_Y := 4.0
const TOP := 8.0
const SLAB_T := 0.4
const WALL_T := 0.3

static func build(root: Node3D, game: GrayboxGame) -> void:
	_floors(root)
	_hall(root)
	_rooms(root)
	_lights(root)

static func _floors(root: Node3D) -> void:
	var c := BuildUtils.FLOOR
	BuildUtils.plate(root, -10, 6, -20, -10, FLOOR_Y, SLAB_T, c)   # hall, N of gallery
	BuildUtils.slab_with_hole(root, Vector3(-16, FLOOR_Y - SLAB_T * 0.5, -17),
		Vector2(6, 6), Vector2(-16, -17), Vector2(1.0, 1.0), SLAB_T, c)  # staff rm + hatch
	BuildUtils.plate(root, -13, -10, -20, -18.5, FLOOR_Y, SLAB_T, c)  # N-stair landing
	BuildUtils.plate(root, -19, -10, -14, -8, FLOOR_Y, SLAB_T, c)     # west landing
	BuildUtils.plate(root, -13, -10, -8, -6, FLOOR_Y, SLAB_T, c)      # passage W
	BuildUtils.plate(root, -10, -3, -8, -6, FLOOR_Y, SLAB_T, c)       # AV booth
	BuildUtils.plate(root, 2, 10, -8, -6, FLOOR_Y, SLAB_T, c)         # passage E
	BuildUtils.plate(root, 6, 10, -20, -8, FLOOR_Y, SLAB_T, c)        # east landing
	BuildUtils.plate(root, -13, -3, -6, -2, FLOOR_Y, SLAB_T, c)       # corridor W arm
	BuildUtils.plate(root, 2, 4, -6, -2, FLOOR_Y, SLAB_T, c)          # east shelf
	# Cantilevered plate behind the south window, over the void (N3).
	BuildUtils.plate(root, -0.5, 0.5, -3.2, -2, FLOOR_Y, 0.3, c)
	# The south corridor's floor runs unbroken across the lobby: this slab is the
	# lobby's ceiling seen from below and the corridor floor from above. (It was
	# a void, then a railed catwalk — "a bridge instead of a plane".)
	BuildUtils.plate(root, -3, 2, -8, -2, FLOOR_Y, SLAB_T, c)

static func _vz(root: Node3D, x: float, z0: float, z1: float, openings: Array) -> void:
	WallUtils.wall(root, "z", x, z0, z1, FLOOR_Y, TOP, WALL_T, BuildUtils.WALLPAPER, openings)

static func _hx(root: Node3D, z: float, x0: float, x1: float, openings: Array) -> void:
	WallUtils.wall(root, "x", z, x0, x1, FLOOR_Y, TOP, WALL_T, BuildUtils.WALLPAPER, openings)

## Gallery: a 1.0m step up from the hall floor (a mantle for everyone), solid
## underneath. Walls run past the ceiling to 8.0, which is what closes the
## 1.0m crawl void above the hall on all four sides.
static func _hall(root: Node3D) -> void:
	BuildUtils.plate(root, -10, 6, -10, -8, 5.0, 1.4, BuildUtils.FLOOR)
	_vz(root, -10, -20, -8, [
		WallUtils.door(-19.2, FLOOR_Y, 1.3),       # north-stair door, off the landing
		WallUtils.door(-11.0, FLOOR_Y),            # main doors, G9's post
	])
	_vz(root, 6, -20, -8, [WallUtils.door(-14.0, FLOOR_Y)])   # rear door
	_hx(root, -8, -10, 6, [WallUtils.hole(-7.1, -5.9, 5.3, 5.9)])   # projection slot
	WallUtils.block(root, -7.5, -4.5, FLOOR_Y, FLOOR_Y + 1.0, -17.7, -16.7,
		Color(0.34, 0.28, 0.22))   # lectern, north of the target's lane

static func _rooms(root: Node3D) -> void:
	# Staff room: west, east, south (door onto the west landing).
	_vz(root, -19, -20, -14, [])
	_vz(root, -13, -20, -14, [])
	_hx(root, -14, -19, -13, [WallUtils.door(-16, FLOOR_Y)])
	_hatch_duct(root)
	# West landing: west wall; guard over the north stair shaft; south guard
	# over the west stair shaft, leaving passage W's mouth open.
	_vz(root, -19, -14, -8, [WallUtils.door(-9.5, FLOOR_Y)])   # from the west strip
	_hx(root, -14, -13, -10, [])
	_hx(root, -8, -19, -13, [])
	# West stair shaft's west side, above the west corridor's ceiling.
	_vz(root, -19, -8, -2, [])
	# Passage W and the AV booth.
	_vz(root, -13, -8, -6, [])
	_vz(root, -10, -8, -6, [])
	_vz(root, -3, -8, -6, [])
	_hx(root, -6, -10, -3, [WallUtils.door(-9.0, FLOOR_Y)])   # AV door (L4)
	# Passage E: west wall facing the void, south guard over the east stair.
	_vz(root, 2, -8, -6, [])
	_hx(root, -6, 4, 10, [])

## 1.0m-tall duct box over the staff-room hatch, open to the south. A crawl
## gate: Chad's 1.45m crouch does not fit under the lid.
static func _hatch_duct(root: Node3D) -> void:
	var c := BuildUtils.METAL
	WallUtils.block(root, -16.7, -15.3, 5.0, 5.2, -17.7, -15.8, c)   # lid
	WallUtils.block(root, -16.7, -16.5, FLOOR_Y, 5.0, -17.7, -15.8, c)
	WallUtils.block(root, -15.5, -15.3, FLOOR_Y, 5.0, -17.7, -15.8, c)
	WallUtils.block(root, -16.7, -15.3, FLOOR_Y, 5.0, -17.7, -17.5, c)

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-4, 6.4, -14), Vector3(2, 6.4, -18), Vector3(-16, 7.0, -16),
		Vector3(-14.5, 7.0, -11), Vector3(-11.5, 7.0, -7), Vector3(-6.5, 7.0, -7),
		Vector3(6, 7.0, -7), Vector3(8, 7.0, -14), Vector3(-8, 7.0, -4),
		Vector3(3, 7.0, -4),
	], BuildUtils.LAMP_FLUORO, 2.0, 14.0)
