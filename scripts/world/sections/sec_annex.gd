class_name SecAnnex
extends RefCounted
## THE SCORING ANNEX DISTRICT — where the Consent Score is computed, north of
## the avenue. r6 built it as a 40x22 yard; r7: "I was expecting the second
## area to be at least 4x bigger, giving the player a head on approach". Now
## x [-34, 34] z [-106, -40], ~5x, walled 6m:
##
##   CONSENT WAY   z [-76, -40], road x [-6, 6]: straight from the checkpoint
##                 gap (x [-3, 3] in the avenue's north wall) to the annex's
##                 front door, floodlit (LIT), the building and its giant
##                 score screen dead ahead the whole way. Built to be walked
##                 up under fire: planters, jersey barriers, a guard booth,
##                 two vans, a nest at the steps. N1 checkpoint, N2 the road,
##                 N3 the booth, N4 the steps.
##   WEST YARD     x [-34, -18]: staff car park, the Regular's crawl under the
##                 south wall at x [-15.6, -14.4] (from the avenue, PITCH), a
##                 portacabin, the generator pen (PITCH), a container stack.
##                 N9 walks it.
##   EAST STRIP    x [6, 18]: the site office; the site hoarding along x 18.2
##                 with the SITE ACCESS gap at z [-62, -58].
##   BUILDING      x [-18, 18] z [-96, -76]: SecAnnexBuilding.
##   SITE          x [18.4, 34]: the surveillance tower going up and the long
##                 platforming route over it: SecAnnexSite.
##   BACK STRIP    z [-106, -96]: service road, bins, a lorry. N10.
##
## Alarm posts are deep (SecAlarm): the hall, the 1F west office, the back
## strip's far end. A guard on Consent Way has a long run to any of them.

const X0 := -34.0
const X1 := 34.0
const Z0 := -106.0
const Z1 := -40.0
const WALL_H := 6.0
const CRAWL_X := -15.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_ground_and_walls(root)
	_crawl(root)
	_consent_way(root)
	_west_yard(root)
	_east_strip(root)
	_back_strip(root)
	_lights(root)
	_signs(root)

static func _ground_and_walls(root: Node3D) -> void:
	# The site (x > 18.4) lays its own ground, with the excavation cut out.
	BuildUtils.plate(root, X0, 18.4, Z0, Z1, 0, 1.0, BuildUtils.STREET)
	var c := BuildUtils.WALL_DARK
	var y := WALL_H * 0.5
	BuildUtils.box(root, Vector3(X0 - 0.2, y, (Z0 + Z1) * 0.5), Vector3(0.4, WALL_H, Z1 - Z0), c)
	BuildUtils.box(root, Vector3(X1 + 0.2, y, (Z0 + Z1) * 0.5), Vector3(0.4, WALL_H, Z1 - Z0), c)
	BuildUtils.box(root, Vector3(0, y, Z0 - 0.2), Vector3(X1 - X0 + 0.8, WALL_H, 0.4), c)
	# South wall = the avenue's north wall: the checkpoint gap x [-3, 3], and
	# a 1.0m crawl under it at CRAWL_X.
	var zs := Z1 - 0.2
	WallUtils.block(root, X0 - 0.4, CRAWL_X - 0.6, 0, WALL_H, zs - 0.2, zs + 0.2, c)
	WallUtils.block(root, CRAWL_X - 0.6, CRAWL_X + 0.6, 1.0, WALL_H, zs - 0.2, zs + 0.2, c)
	WallUtils.block(root, CRAWL_X + 0.6, -3.0, 0, WALL_H, zs - 0.2, zs + 0.2, c)
	WallUtils.block(root, 3.0, X1 + 0.4, 0, WALL_H, zs - 0.2, zs + 0.2, c)

## The crawl: a 1.0m tunnel through the wall's foot, 2m long, capped, from
## the avenue's dark west end into the car park.
static func _crawl(root: Node3D) -> void:
	BuildUtils.tunnel(root, Vector3(CRAWL_X, 0, -39.0), Vector3(CRAWL_X, 0, -41.4), 1.0, 1.2,
		BuildUtils.CONCRETE)

# ------------------------------------------------------------ consent way ---
static func _consent_way(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	# Kerbs either side of the road (low; a step, not a wall).
	for x in [-6.2, 6.2]:
		BuildUtils.box(root, Vector3(x, 0.08, -58.0), Vector3(0.3, 0.16, 34.0), c)
	# Checkpoint chicane at the gap: two offset barrier runs, and the arm.
	WallUtils.block(root, -3.0, 0.8, 0, 1.0, -43.3, -42.7, c)
	WallUtils.block(root, -0.8, 3.0, 0, 1.0, -45.8, -45.2, c)
	BuildUtils.box(root, Vector3(0, 1.0, -40.8), Vector3(5.6, 0.08, 0.08), Color(0.9, 0.2, 0.15), false)
	_sandbags(root, -9.0, -5.0, -44.6, -44.0)
	_sandbags(root, -9.0, -8.4, -45.9, -44.6)
	# Planters along both verges: 0.8 high, crouch cover, clear of the kerbs.
	for z in [-50.0, -58.0, -66.0]:
		for x in [-9.0, 9.0]:
			WallUtils.block(root, x - 0.8, x + 0.8, 0, 0.8, z - 0.8, z + 0.8, Color(0.30, 0.31, 0.28))
	# Jersey barriers staggered across the road at the half-way mark: cover
	# for walking up it, never a wall across it.
	for b in [[-5.0, -1.5, -62.0], [1.0, 4.5, -64.5], [-4.0, -0.5, -69.0]]:
		WallUtils.block(root, b[0], b[1], 0, 1.05, b[2] - 0.3, b[2] + 0.3, c)
	# Guard booth on the west verge: a hut with a window over the road.
	var bx0 := -11.5
	var bx1 := -8.5
	WallUtils.wall(root, "x", -60.0, bx0, bx1, 0, 2.6, 0.15, BuildUtils.WALL)
	WallUtils.wall(root, "x", -57.0, bx0, bx1, 0, 2.6, 0.15, BuildUtils.WALL, [WallUtils.door(-10.0)])
	WallUtils.wall(root, "z", bx1, -60.0, -57.0, 0, 2.6, 0.15, BuildUtils.WALL,
		[WallUtils.hole(-59.4, -57.6, 1.0, 2.0)])
	WallUtils.wall(root, "z", bx0, -60.0, -57.0, 0, 2.6, 0.15, BuildUtils.WALL)
	BuildUtils.plate(root, bx0 - 0.2, bx1 + 0.2, -60.2, -56.8, 2.8, 0.2, BuildUtils.WALL_DARK)
	# The nest at the front steps, open to the door behind it.
	_sandbags(root, 3.0, 7.0, -72.6, -72.0)
	_sandbags(root, 6.4, 7.0, -74.4, -72.6)
	# Lamp posts down both kerbs.
	for z in [-46.0, -54.0, -62.0, -70.0]:
		for x in [-7.0, 7.0]:
			BuildUtils.box(root, Vector3(x, 3.0, z), Vector3(0.16, 6.0, 0.16), BuildUtils.METAL)

static func _sandbags(root: Node3D, x0: float, x1: float, z0: float, z1: float) -> void:
	WallUtils.block(root, x0, x1, 0, 1.0, z0, z1, Color(0.42, 0.38, 0.27))

# -------------------------------------------------------------- west yard ---
static func _west_yard(root: Node3D) -> void:
	# Portacabin (guards' mess): a closed box, a roof to get onto from the
	# container next to it.
	WallUtils.block(root, -33.6, -28.0, 0, 2.7, -66.0, -62.0, Color(0.55, 0.58, 0.50))
	# Generator pen: two sets behind a waist-high wall, humming.
	WallUtils.block(root, -33.6, -26.0, 0, 1.2, -70.4, -70.0, BuildUtils.CONCRETE)
	WallUtils.block(root, -26.4, -26.0, 0, 1.2, -80.0, -70.4, BuildUtils.CONCRETE)
	WallUtils.block(root, -33.0, -29.5, 0, 1.6, -78.0, -74.5, Color(0.20, 0.30, 0.22))
	SecCmpExits.engine_loop(root, Vector3(-31, 0.8, -76),
		"res://assets/audio/scifi/engineCircular_000.ogg", -12.0)
	# Container stack: two on the ground, one across them (2.5 / 5.0).
	var rust := Color(0.55, 0.22, 0.14)
	var teal := Color(0.14, 0.42, 0.44)
	WallUtils.block(root, -32.0, -26.0, 0, 2.5, -92.0, -89.6, rust)
	WallUtils.block(root, -32.0, -26.0, 0, 2.5, -87.0, -84.6, teal)
	WallUtils.block(root, -31.0, -28.6, 2.5, 5.0, -92.0, -86.0, rust)
	WallUtils.block(root, -26.0, -24.6, 0, 1.25, -92.0, -89.6, BuildUtils.CRATE)   # the step up

# ------------------------------------------------------------- east strip ---
static func _east_strip(root: Node3D) -> void:
	# Site office: a portacabin, a roof at 2.7 looking over the hoarding.
	WallUtils.block(root, 12.0, 17.4, 0, 2.7, -50.0, -45.0, Color(0.85, 0.80, 0.55))
	WallUtils.block(root, 10.6, 12.0, 0, 1.2, -47.0, -45.4, BuildUtils.CRATE)   # step to its roof
	# Hoarding along x 18.2: plywood, 2.4 high, the SITE ACCESS gap.
	var ply := Color(0.62, 0.52, 0.36)
	WallUtils.block(root, 18.0, 18.4, 0, 2.4, -76.0, -62.0, ply)
	WallUtils.block(root, 18.0, 18.4, 0, 2.4, -58.0, Z1 - 0.4, ply)

# ------------------------------------------------------------- back strip ---
static func _back_strip(root: Node3D) -> void:
	for x in [-14.0, -10.0, 9.0]:
		WallUtils.block(root, x, x + 1.4, 0, 1.3, -105.6, -104.4, Color(0.12, 0.30, 0.16))
	WallUtils.block(root, -4.0, 4.0, 0, 3.2, -105.8, -103.4, Color(0.70, 0.70, 0.72))  # lorry box
	WallUtils.block(root, 4.0, 6.4, 0, 2.4, -105.8, -103.4, Color(0.25, 0.30, 0.55))   # its cab
	# Fence from the building's NE corner to the north wall, gap at z [-102, -99].
	WallUtils.block(root, 18.0, 18.4, 0, 2.4, -99.0, -96.0, BuildUtils.METAL)
	WallUtils.block(root, 18.0, 18.4, 0, 2.4, Z0, -102.0, BuildUtils.METAL)

# ----------------------------------------------------------------- lights ---
static func _lights(root: Node3D) -> void:
	# Consent Way is floodlit: you walk up it seen.
	for z in [-46.0, -54.0, -62.0, -70.0]:
		BuildUtils.lamps(root, [Vector3(-7, 6.2, z), Vector3(7, 6.2, z)],
			BuildUtils.LAMP_FLUORO, 1.4, 12.0)
	BuildUtils.lamp(root, Vector3(-10, 2.4, -58.5), BuildUtils.LAMP_FLUORO, 0.6, 5.0)
	BuildUtils.lamp(root, Vector3(-4, 4.0, -43), BuildUtils.LAMP_FLUORO, 1.8, 12.0)
	# The yards are not.
	BuildUtils.lamps(root, [Vector3(-26, 4.0, -50), Vector3(-26, 4.0, -88)],
		BuildUtils.LAMP_SERVICE, 0.5, 10.0)
	BuildUtils.lamps(root, [Vector3(-12, 4.0, -101), Vector3(10, 4.0, -101)],
		BuildUtils.LAMP_SERVICE, 0.5, 10.0)
	BuildUtils.lamp(root, Vector3(14, 3.4, -52), BuildUtils.LAMP_SERVICE, 0.5, 8.0)

static func _signs(root: Node3D) -> void:
	var gold := Color(1.0, 0.75, 0.31)
	SecCmpDressing.plate_sign(root, "CHECKPOINT\nHAVE YOUR NUMBER READY",
		Vector3(-7, 1.6, -43.97), 0.0, gold)
	SecCmpDressing.plate_sign(root, "CONSENT WAY\nWALK TOWARD THE SCORE",
		Vector3(-9.0, 1.4, -49.18), 0.0, gold)
	SecCmpDressing.plate_sign(root, "STAFF PARKING\nSPACES ALLOCATED BY SCORE",
		Vector3(-20, 1.6, -40.62), PI, SecCmpDressing.PLATE)
	SecCmpDressing.plate_sign(root, "SITE ACCESS\nHARD HATS · HI-VIS · CONSENT",
		Vector3(17.95, 1.9, -63.0), -PI / 2.0, SecCmpDressing.WARN)
	SecCmpDressing.plate_sign(root, "GUARDS' MESS\nKNOCK. YOU ARE BEING SCORED ON IT.",
		Vector3(-28.0 + 0.05, 1.8, -64.0), PI / 2.0, SecCmpDressing.PLATE)
