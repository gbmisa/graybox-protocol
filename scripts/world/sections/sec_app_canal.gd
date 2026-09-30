class_name SecAppCanal
extends RefCounted
## The approach, northern half (z [46, 112]): the canal, the allotments and
## the terrace backs, ending at the south road with the campus in full view.
##
##   Towpath     z [100, 112]  bench, a compliance hut (east) with the audit
##               rota pinned inside — read it and you know where he'll be.
##   Canal       z [92, 100]   bed at -2.5, banks sheer. Crossings:
##                 footbridge   x [-2, 2], LIT — the obvious one
##                 narrowboat   x [-30, -18], jump bank -> cabin roof -> bank
##                 the bed      down the west slipway (south bank), under the
##                              bridge in the dark, up the east slipway
##   Allotments  z [70, 92]    1.0 fences (vault them), sheds; a water butt
##                 gets you onto one shed roof to look over the terraces.
##   Terraces    z [52, 62]    6m blocks with three alleys and one house with
##                 both doors open; back walls 1.0; front pavement z [46, 52].

const BED := -2.5

static func build(root: Node3D, game: GrayboxGame) -> void:
	_ground(root)
	_canal(root)
	_towpath(root)
	_allotments(root)
	_terraces(root)
	_lights(root)

static func _ground(root: Node3D) -> void:
	var c := BuildUtils.STREET
	BuildUtils.plate(root, -36, 44, 100, 112, 0, 1.0, c)       # towpath
	BuildUtils.plate(root, -44, -36, 105, 112, 0, 1.0, c)
	BuildUtils.plate(root, -44, 44, 46, 87, 0, 1.0, BuildUtils.GROUND)
	BuildUtils.plate(root, -44, 36, 87, 92, 0, 1.0, BuildUtils.GROUND)

static func _canal(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, -44, 44, 92, 100, BED, 1.0, c)
	# Banks solid down to the bed, so they read as walls and hide no void.
	WallUtils.block(root, -44, 36, BED, -1.0, 91.0, 92.0, c)
	WallUtils.block(root, -36, 44, BED, -1.0, 100.0, 101.0, c)
	WallUtils.block(root, 35, 36, BED, -1.0, 87, 92, c)
	WallUtils.block(root, -36, -35, BED, -1.0, 100, 105, c)
	# Slipways: west one up to the towpath, east one up to the allotments.
	BuildUtils.ramp(root, Vector3(-40, BED, 100), Vector3(0, 0, 1), 5.0, -BED, 8.0, c, 5)
	BuildUtils.ramp(root, Vector3(40, BED, 92), Vector3(0, 0, -1), 5.0, -BED, 8.0, c, 5)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.10, 0.16, 0.20, 0.7)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.1
	var w := BuildUtils.box(root, Vector3(0, BED + 0.35, 96), Vector3(88, 0.02, 8),
		Color.WHITE, false)
	w.material_override = water
	# Footbridge.
	BuildUtils.plate(root, -2, 2, 91.5, 100.5, 0, 0.3, BuildUtils.METAL)
	for x in [-2.0, 2.0]:
		WallUtils.block(root, x - 0.05, x + 0.05, 0, 1.0, 91.5, 100.5, BuildUtils.METAL)
	# The narrowboat, THE GRATEFUL: hull, cabin.
	WallUtils.block(root, -30, -18, BED, -0.9, 94, 98, Color(0.14, 0.22, 0.16))
	WallUtils.block(root, -27, -20, -0.9, 0.3, 94.4, 97.6, Color(0.40, 0.18, 0.14))

static func _towpath(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(-10, 0.25, 108), Vector3(2.4, 0.5, 0.6), BuildUtils.CRATE)
	# Compliance hut: open to the west, roof on, rota inside.
	var c := BuildUtils.WALL
	WallUtils.block(root, 20, 26, 0, 2.6, 110, 110.2, c)
	WallUtils.block(root, 20, 26, 0, 2.6, 103.8, 104, c)
	WallUtils.block(root, 25.8, 26, 0, 2.6, 104, 110, c)
	WallUtils.block(root, 19.8, 26.2, 2.6, 2.8, 103.8, 110.2, c)
	BuildUtils.box(root, Vector3(24.5, 0.45, 107), Vector3(1.6, 0.9, 2.4), BuildUtils.CRATE)

static func _allotments(root: Node3D) -> void:
	var f := BuildUtils.WALL_DARK
	WallUtils.wall(root, "x", 81, -44, 44, 0, 1.0, 0.1, f, [
		WallUtils.hole(-14, -12, 0, 1.0), WallUtils.hole(10, 12, 0, 1.0)])
	for x in [-22.0, 0.0, 22.0]:
		WallUtils.block(root, x - 0.05, x + 0.05, 0, 1.0, 72, 90, f)
	for s in [[-30, 74], [6, 84], [28, 74]]:
		var x0: float = s[0]
		var z0: float = s[1]
		WallUtils.block(root, x0, x0 + 4, 0, 2.4, z0, z0 + 4, Color(0.34, 0.27, 0.20))
	BuildUtils.box(root, Vector3(10.6, 0.5, 86), Vector3(0.9, 1.0, 0.9), Color(0.15, 0.25, 0.35))
	BuildUtils.box(root, Vector3(-16, 0.9, 76), Vector3(0.2, 1.8, 0.2), BuildUtils.CRATE)  # scarecrow

## Blocks x [-44,-22] [-18,-12] [-8,-2] [2,18] [22,44]; alleys at x -20, 0,
## 20; the house at x [-12, -8] is hollow with both doors open.
static func _terraces(root: Node3D) -> void:
	var c := Color(0.30, 0.24, 0.22)
	for b in [[-44, -22], [-18, -12], [-8, -2], [2, 18], [22, 44]]:
		WallUtils.block(root, b[0], b[1], 0, 6, 52, 62, c)
	WallUtils.block(root, -12, -8, 3.2, 6, 52, 62, c)
	for z in [52.15, 61.85]:
		WallUtils.wall(root, "x", z, -12, -8, 0, 3.2, 0.3, c, [WallUtils.door(-10.0)])
	for x in [-38.0, -30.0, -14.0, 8.0, 14.0, 28.0, 36.0]:
		WallUtils.block(root, x - 0.05, x + 0.05, 0, 1.0, 62, 68, BuildUtils.WALL_DARK)
	WallUtils.wall(root, "x", 68, -44, 44, 0, 1.0, 0.1, BuildUtils.WALL_DARK, [
		WallUtils.hole(-22, -18, 0, 1.0), WallUtils.hole(-2, 2, 0, 1.0),
		WallUtils.hole(18, 22, 0, 1.0), WallUtils.hole(-11, -9, 0, 1.0)])

static func _lights(root: Node3D) -> void:
	BuildUtils.lamp(root, Vector3(0, 3.0, 96), Color(1.0, 0.85, 0.6), 2.0, 8.0)
	BuildUtils.lamp(root, Vector3(23, 2.2, 107), BuildUtils.LAMP_FLUORO, 1.2, 6.0)
	BuildUtils.lamp(root, Vector3(-10, 2.6, 57), BuildUtils.LAMP_SERVICE, 0.6, 6.0)
	BuildUtils.lamps(root, [Vector3(-20, 4.0, 49), Vector3(20, 4.0, 49)],
		Color(1.0, 0.75, 0.4), 1.0, 12.0)
