class_name SecAppEstate
extends RefCounted
## The approach, southern half (z [112, 196]): where the level starts and the
## campus is still a glow and a billboard over the rooftops.
##
##   Spawn street  x [-14, 14]  z [172, 196]  bus stop; HOLLOWAY HOUSE (28m
##                 tower) west with an open lobby; garages east — one bay is
##                 open straight through to a hidden back strip; a bin gets
##                 you onto the garage roofs (a jump, not a mantle).
##   Estate yard   z [140, 172]  playground, burnt-out car, planters, G-A1.
##                 One working lamp, at the subway mouth.
##   Ring road     z [112, 138]  a 4m embankment across the whole width.
##                 Three ways through it:
##                   subway    x [-1.5, 1.5], 3m tall, PITCH, a sentry at
##                             the far mouth looking straight down it
##                   over      crate steps at the east end onto the LIT deck,
##                             G-A3 walking it, drop off the north face
##                   culvert   x [-31, -29], a 1.0m crawl nobody signposts
##
## Outer walls for the whole approach (z [46, 196]) live here too.

const TOP := 4.0          # embankment / road deck
const BOUND_H := 8.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	BuildUtils.plate(root, -44, 44, 112, 196, 0, 1.0, BuildUtils.STREET)
	_bounds(root)
	_tower(root)
	_garages(root)
	_yard(root)
	_embankment(root)
	_lights(root)

## Whole-approach boundary, down to the canal bed.
static func _bounds(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	WallUtils.block(root, -44.4, -44.0, -3.0, BOUND_H, 46, 196.4, c)
	WallUtils.block(root, 44.0, 44.4, -3.0, BOUND_H, 46, 196.4, c)
	WallUtils.block(root, -44.4, 44.4, -1.0, BOUND_H, 196.0, 196.4, c)

## HOLLOWAY HOUSE: 28m of tenancy, lit windows, a lobby you can walk into.
static func _tower(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	WallUtils.block(root, -44, -24, 0, 28, 172, 196, c)
	WallUtils.block(root, -24, -14, 0, 28, 188, 196, c)
	WallUtils.block(root, -24, -14, 0, 28, 172, 178, c)
	WallUtils.block(root, -24, -14, 3.6, 28, 178, 188, c)
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(1.0, 0.82, 0.5)
	lit.emission_enabled = true
	lit.emission = Color(1.0, 0.78, 0.45)
	lit.emission_energy_multiplier = 1.4
	var rng := RandomNumberGenerator.new()
	rng.seed = 4471
	for floor_i in range(2, 9):
		for z in [174.0, 177.0, 180.0, 183.0, 186.0, 189.0, 192.0]:
			if rng.randf() < 0.45:
				var w := BuildUtils.box(root, Vector3(-13.97, floor_i * 3.0 + 0.8, z),
					Vector3(0.05, 1.0, 1.4), Color.WHITE, false)
				w.material_override = lit
	BuildUtils.lamp(root, Vector3(-19, 3.0, 183), BuildUtils.LAMP_FLUORO, 1.2, 8.0)

## Five bays; bay 3 (z [182, 186]) is open front and back. Roofs 2.6.
static func _garages(root: Node3D) -> void:
	var c := BuildUtils.WALL
	WallUtils.block(root, 14, 28, 0, 2.6, 174, 182, c)
	WallUtils.block(root, 14, 28, 0, 2.6, 186, 196, c)
	WallUtils.block(root, 14, 28, 2.4, 2.6, 182, 186, c)
	for z in [176.0, 180.0, 188.0, 192.0]:
		BuildUtils.box(root, Vector3(13.97, 1.1, z), Vector3(0.05, 2.1, 3.4),
			Color(0.36, 0.30, 0.26), false)   # shut roller doors
	BuildUtils.box(root, Vector3(13.2, 0.55, 177), Vector3(1.0, 1.1, 1.4),
		Color(0.16, 0.30, 0.18))              # the bin
	BuildUtils.box(root, Vector3(24, 0.6, 184), Vector3(3.6, 1.2, 1.8), BuildUtils.METAL)
	# Back strip x [28, 44]: out through bay 3, over a 1.0 fence into the yard.
	WallUtils.block(root, 28, 44, 0, 1.0, 171.9, 172.1, BuildUtils.WALL_DARK)

static func _yard(root: Node3D) -> void:
	var low := BuildUtils.WALL_DARK
	WallUtils.wall(root, "x", 172, -14, 28, 0, 1.0, 0.3, low, [
		WallUtils.hole(-2, 2, 0, 1.0),
	])
	# Playground: frame and slide.
	for p in [Vector3(-24, 0, 158), Vector3(-20, 0, 158), Vector3(-24, 0, 162),
			Vector3(-20, 0, 162)]:
		BuildUtils.box(root, p + Vector3(0, 1.1, 0), Vector3(0.15, 2.2, 0.15), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(-22, 2.25, 160), Vector3(4.3, 0.12, 4.3), BuildUtils.METAL)
	BuildUtils.ramp(root, Vector3(-17.5, 0, 160), Vector3(-1, 0, 0), 2.4, 2.2, 1.0,
		BuildUtils.CRATE)
	# Cover.
	BuildUtils.box(root, Vector3(10, 0.7, 152), Vector3(2.0, 1.4, 4.4), Color(0.14, 0.12, 0.11))
	for p in [Vector3(-8, 0, 148), Vector3(6, 0, 162), Vector3(22, 0, 146),
			Vector3(-30, 0, 146), Vector3(30, 0, 160)]:
		BuildUtils.box(root, p + Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 2.4), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(-36, 1.5, 152), Vector3(6, 3.0, 6), BuildUtils.METAL)  # substation

## Solid 4m bank with the subway and culvert cut through it, crate steps at
## the east end, guard rails along both edges of the deck.
static func _embankment(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	WallUtils.block(root, -44, -31, 0, TOP, 112, 138, c)
	WallUtils.block(root, -31, -29, 1.0, TOP, 112, 138, c)       # culvert roof
	WallUtils.block(root, -29, -1.5, 0, TOP, 112, 138, c)
	WallUtils.block(root, -1.5, 1.5, 3.0, TOP, 112, 138, c)      # subway roof
	WallUtils.block(root, 1.5, 44, 0, TOP, 112, 138, c)
	BuildUtils.plate(root, -44, 44, 112, 138, TOP + 0.02, 0.02, BuildUtils.STREET)
	for z in [112.2, 137.8]:
		WallUtils.block(root, -44, 44, TOP, TOP + 1.0, z - 0.1, z + 0.1, BuildUtils.METAL)
	for x in [-20.0, 0.0, 20.0]:
		BuildUtils.box(root, Vector3(x, TOP + 0.03, 125), Vector3(4.0, 0.02, 0.2),
			Color(0.8, 0.8, 0.7), false)
	BuildUtils.box(root, Vector3(22, TOP + 1.2, 121), Vector3(2.2, 2.4, 5.0),
		Color(0.25, 0.28, 0.40))                                  # compliance van
	var tops := [1.15, 2.30, 3.45]
	for i in 3:
		var t: float = tops[i]
		BuildUtils.box(root, Vector3(33 + i * 2.0, t * 0.5, 138.75), Vector3(2.0, t, 1.5),
			BuildUtils.CRATE)
	BuildUtils.box(root, Vector3(-32.4, 0.5, 139.2), Vector3(1.4, 1.0, 1.0), Color(0.16, 0.30, 0.18))

static func _lights(root: Node3D) -> void:
	BuildUtils.lamp(root, Vector3(0, 4.5, 142), Color(1.0, 0.85, 0.6), 2.0, 9.0)
	BuildUtils.lamp(root, Vector3(0, 2.6, 125), BuildUtils.LAMP_SERVICE, 0.25, 6.0)
	BuildUtils.lamp(root, Vector3(-8, 3.0, 192), BuildUtils.LAMP_SERVICE, 0.8, 8.0)
	for x in [-30.0, -10.0, 10.0, 30.0]:
		BuildUtils.lamp(root, Vector3(x, TOP + 5.0, 125), Color(1.0, 0.75, 0.4), 2.2, 14.0)
	# Bus stop.
	BuildUtils.box(root, Vector3(-8, 2.3, 193), Vector3(3.0, 0.1, 1.4), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(-9.4, 1.15, 193), Vector3(0.1, 2.3, 1.4), BuildUtils.METAL)
