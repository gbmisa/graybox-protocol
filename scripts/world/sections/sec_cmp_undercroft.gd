class_name SecCmpUndercroft
extends RefCounted
## Undercroft, floor -3.0, ceiling -0.8 (2.2 headroom), PITCH. The Wizard's
## way in: boiler house -> squeeze -> west run -> puddle -> spur -> ramp up
## into the caretaker's cupboard. The puddle's damage is `Hazard`, placed by
## `MissionCompound`; this file only paints it.
##
##   Boiler house  x [-34,-28.8] z [-18,-8], outside the compound wall. Walls
##                 and roof at 4.0, flush with the wall top — at r4's 2.2 it
##                 was a Chad step onto the wall. Warded door west (z -13);
##                 ramp down to the flooded basement at -3.0.
##   Squeeze       0.6 x 1.0 tunnel, (-28.8, -17.5) -> (-22, -17.5), capped
##                 above at both mouths.
##   West run      x [-22,-19] z [-20,-8]; puddle z [-16.5,-11.5].
##   Spur          x [-19,-13] z [-11,-8]: a walkway along its north side to
##                 the east end, then a ramp climbing WEST (base x -14.4,
##                 top x -18) through the caretaker's floor to beside his door.

const Y := -3.0
const CEIL_Y := -0.8
const WALL_T := 0.4
const BOILER_TOP := 4.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_boiler_house(root)
	_squeeze(root)
	_west_run(root)
	_spur(root)
	_lights(root)

static func _boiler_house(root: Node3D) -> void:
	var c := BuildUtils.WALL
	BuildUtils.plate(root, -34, -28.8, -18, -8, Y, 1.0, BuildUtils.CONCRETE)
	BuildUtils.ramp(root, Vector3(-30, Y, -13), Vector3(-1, 0, 0), 4.0, 3.0, 3.0,
		BuildUtils.CONCRETE)
	# The warded door (-34, z -13) is walled up while level one is
	# Regular-only; the basement is a view from the undercroft, not a route.
	WallUtils.wall(root, "z", -34, -18.2, -7.8, Y, BOILER_TOP, WALL_T, c)
	WallUtils.wall(root, "x", -18, -34, -28.8, Y, BOILER_TOP, WALL_T, c)
	WallUtils.wall(root, "x", -8, -34, -28.8, Y, BOILER_TOP, WALL_T, c)
	# East side is the compound wall above ground; below it, a wall of its
	# own with the squeeze mouth cut in.
	WallUtils.wall(root, "z", -28.8, -18, -8, Y, 0.0, WALL_T, c, [
		WallUtils.hole(-18.0, -17.0, Y, Y + 0.6),
	])
	BuildUtils.plate(root, -34.2, -28.6, -18.2, -7.8, BOILER_TOP, 0.3, BuildUtils.WALL_DARK)
	# The boiler, with the squeeze behind it.
	BuildUtils.box(root, Vector3(-31.2, Y + 1.2, -16.4), Vector3(2.4, 2.4, 2.0),
		BuildUtils.PIPE)

static func _squeeze(root: Node3D) -> void:
	BuildUtils.tunnel(root, Vector3(-28.8, Y, -17.5), Vector3(-22, Y, -17.5),
		0.6, 1.0, BuildUtils.CONCRETE)

static func _west_run(root: Node3D) -> void:
	var c := BuildUtils.WALL
	BuildUtils.plate(root, -22, -19, -20, -8, Y, 1.0, BuildUtils.CONCRETE)
	BuildUtils.plate(root, -22.2, -18.8, -20.2, -7.8, CEIL_Y, 0.3, BuildUtils.WALL_DARK)
	WallUtils.wall(root, "z", -22, -20.2, -7.8, Y, CEIL_Y, WALL_T, c, [
		WallUtils.hole(-18.0, -17.0, Y, Y + 0.6),
	])
	WallUtils.wall(root, "x", -20, -22, -19, Y, CEIL_Y, WALL_T, c)
	WallUtils.wall(root, "x", -8, -22, -19, Y, CEIL_Y, WALL_T, c)
	WallUtils.wall(root, "z", -19, -20, -11, Y, CEIL_Y, WALL_T, c)
	# Energised water: glowing red, signed at both ends by the mission.
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.9, 0.12, 0.08)
	water.emission_enabled = true
	water.emission = Color(1.0, 0.15, 0.05)
	water.emission_energy_multiplier = 1.6
	var puddle := BuildUtils.box(root, Vector3(-20.5, Y + 0.02, -14),
		Vector3(3, 0.04, 5), Color.RED, false)
	puddle.material_override = water

static func _spur(root: Node3D) -> void:
	var c := BuildUtils.WALL
	BuildUtils.plate(root, -19, -13, -11, -8, Y, 1.0, BuildUtils.CONCRETE)
	BuildUtils.slab_with_hole(root, Vector3(-16, CEIL_Y, -9.5), Vector2(6, 3),
		Vector2(-16.2, -8.975), Vector2(3.6, 1.65), 0.3, BuildUtils.WALL_DARK)
	WallUtils.wall(root, "x", -11, -19, -13, Y, CEIL_Y, WALL_T, c)
	WallUtils.wall(root, "x", -8, -19, -13, Y, CEIL_Y, WALL_T, c)
	WallUtils.wall(root, "z", -13, -11, -8, Y, CEIL_Y, WALL_T, c)
	BuildUtils.ramp(root, Vector3(-14.4, Y, -8.9), Vector3(-1, 0, 0), 3.6, 3.0, 1.4,
		BuildUtils.CONCRETE, 6)

## PITCH: navigable, barely. The puddle's glow does most of the work.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-31, 2.5, -11), Vector3(-20.5, -1.2, -19),
		Vector3(-14, -1.2, -10.2),
	], BuildUtils.LAMP_SERVICE, 0.3, 7.0)
	BuildUtils.lamp(root, Vector3(-20.5, -2.0, -14), Color(1.0, 0.2, 0.1), 1.2, 6.0)
