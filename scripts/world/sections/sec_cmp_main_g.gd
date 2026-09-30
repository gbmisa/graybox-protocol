class_name SecCmpMainG
extends RefCounted
## Main block, ground floor. x [-22, 10], z [-20, -2], ceiling 3.6 — the
## underside of `sec_cmp_main_1f`'s slab, plus a ceiling of its own over the
## west corridor, which has no first floor above it. Exterior walls are
## `sec_cmp_main_shell`'s; interactable doors fill the gaps cut here and are
## placed by `MissionCompound`.
##
## Room grid, west to east:
##   West corridor   x [-22,-19]  z [-20,-2]   DARK; security shutter at z -11
##                                              with a 0.6m squeeze under it
##   Panic room      x [-19,-13]  z [-20,-14]  reinforced door south; barred
##                                              window north; hatch above
##   North stair     x [-13,-10]  z [-20,-14]  open to the north corridor
##   Records (L2)    x [-10,  3]  z [-20,-14]  lockpick door
##   Kitchen         x [  3, 10]  z [-20,-14]  servery to the canteen
##   North corridor  x [-19,  3]  z [-14,-11]  CSD south, canteen east
##   Caretaker (L3)  x [-19,-13]  z [-11, -8]  ramp up from the undercroft
##   Toilets         x [-13, -3]  z [-11, -8]  DARK dead end
##   CSD passage     x [ -3,  3]  z [-11, -8]  open south to the lobby
##   Canteen         x [  3, 10]  z [-14, -8]  L1 east to the alley
##   West foyer      x [-13, -3]  z [ -8, -2]  open east to the lobby
##   Lobby           x [ -3,  2]  z [ -8, -2]  double height; portico south
##   Riser block     x [  2,  4]  z [ -8, -2]  solid, carries the 1F shelf
##   West/East stair x [-19,-13] / [4,10]  z [-8,-2]
##
## The undercroft ramp climbs WEST through the caretaker's floor and lands
## beside his door — r4 had it land on the far side of its own hole, a metre
## from nothing, with the door on the other side of the drop.

const CEIL := 3.6
const WALL_T := 0.3

static func build(root: Node3D, game: GrayboxGame) -> void:
	_floor(root)
	_walls(root)
	_shutter(root)
	_ramps(root)
	_lights(root)

## Continuous slab minus the strip the undercroft ramp rises through; the
## west corridor's own ceiling; and the solid riser block under the 1F shelf.
static func _floor(root: Node3D) -> void:
	BuildUtils.slab_with_hole(root, Vector3(-6, -0.5, -11), Vector2(32, 18),
		Vector2(-16.2, -8.975), Vector2(3.6, 1.65), 1.0, BuildUtils.FLOOR)
	BuildUtils.plate(root, -22, -19, -20, -2, 4.0, 0.4, BuildUtils.FLOOR)
	WallUtils.block(root, 2, 4, 0, CEIL, -8, -2, BuildUtils.WALL)

static func _vz(root: Node3D, x: float, z0: float, z1: float, openings: Array) -> void:
	WallUtils.wall(root, "z", x, z0, z1, 0, CEIL, WALL_T, BuildUtils.WALL, openings)

static func _hx(root: Node3D, z: float, x0: float, x1: float, openings: Array) -> void:
	WallUtils.wall(root, "x", z, x0, x1, 0, CEIL, WALL_T, BuildUtils.WALL, openings)

static func _walls(root: Node3D) -> void:
	# Walls along z, west to east.
	_vz(root, -19, -20, -14, [])                                  # corridor | panic
	_vz(root, -19, -11, -8, [WallUtils.door(-9.1)])               # caretaker door (L3)
	_vz(root, -13, -20, -14, [])                                  # panic | stair
	_vz(root, -13, -11, -8, [])                                   # caretaker | toilets
	_vz(root, -13, -8, -2, [])                                    # stair well | foyer (M8)
	_vz(root, -10, -20, -14, [])                                  # stair | records
	_vz(root, -3, -11, -8, [])                                    # toilets | CSD
	_vz(root, 3, -20, -14, [])                                    # records | kitchen
	_vz(root, 3, -14, -11, [WallUtils.door(-12.5)])               # canteen door N
	_vz(root, 3, -11, -8, [WallUtils.door(-9.5)])                 # second CSD
	# Walls along x, north to south.
	_hx(root, -14, -19, -13, [WallUtils.door(-16, 0, 1.6)])       # panic reinforced door
	_hx(root, -14, -10, 3, [WallUtils.door(-3)])                  # records door (L2)
	_hx(root, -14, 3, 10, [WallUtils.door(6)])                    # kitchen servery
	_hx(root, -11, -19, -3, [])                                   # corridor | caretaker, toilets
	_hx(root, -11, -3, 3, [WallUtils.door(0, 0, 1.6)])            # CSD
	_hx(root, -8, -19, -13, [])                                   # caretaker | stair well
	_hx(root, -8, -13, -3, [WallUtils.door(-8)])                  # toilets door
	_hx(root, -8, 3, 10, [WallUtils.door(7)])                     # canteen south door

## Floor-to-ceiling shutter across the corridor, stopping 0.6m short of the
## floor: the Wizard's squeeze into the corridor's north half.
static func _shutter(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(-20.5, 2.1, -11), Vector3(3.0, 3.0, WALL_T),
		BuildUtils.METAL)

## Stairs are ramps (CLAUDE.md): 2.4 wide, 8 treads, rise/run under 0.9.
static func _ramps(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.stairs(root, Vector3(-11.5, 0, -14), Vector3(0, 0, -1),
		8, 0.5, 0.5625, 2.4, c)
	BuildUtils.stairs(root, Vector3(-18, 0, -4), Vector3(1, 0, 0),
		8, 0.5, 0.625, 2.4, c)
	BuildUtils.stairs(root, Vector3(9, 0, -4), Vector3(-1, 0, 0),
		8, 0.5, 0.625, 2.4, c)

## LIT interiors get full fluorescents; the west corridor, west stair well and
## toilets are DARK and get one weak service lamp each, so the tier reads.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-16, 3.0, -17), Vector3(-11.5, 3.0, -16), Vector3(-3, 3.0, -17),
		Vector3(6, 3.0, -17), Vector3(-8, 3.0, -12.5), Vector3(6, 3.0, -11),
		Vector3(-16, 3.0, -10.3), Vector3(0, 3.0, -9.5), Vector3(-8, 3.0, -5),
		Vector3(0, 3.0, -5), Vector3(7, 3.0, -7),
	], BuildUtils.LAMP_FLUORO, 2.0, 12.0)
	BuildUtils.lamps(root, [
		Vector3(-20.5, 3.0, -16), Vector3(-20.5, 3.0, -5), Vector3(-8, 3.0, -9.5),
		Vector3(-16, 3.0, -5),
	], BuildUtils.LAMP_SERVICE, 0.5, 8.0)
