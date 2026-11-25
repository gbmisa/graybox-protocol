class_name SecAnnexBuilding
extends RefCounted
## The Scoring Annex itself, at the head of Consent Way (SecAnnex). r7 size:
## x [-18, 18] z [-96, -76], ground / 1F (4.0) / roof (8.0).
##
##   ground   LOBBY x [-6, 6] z [-82, -76]: front door (x 0, 2.4 wide) under a
##            canopy (3.2), reception desk off the door line. SECURITY x
##            [-18, -6]: the CCTV wall (score screens). STAIR HALL x [6, 18]:
##            the stair rises east along z -78.6, x 7 -> 15, to the 1F.
##            Partition z -82 with doors at x -10, 0, 10 into the HALL x
##            [-18, 18] z [-96, -82]: rack rows for cover (N11), alarm post
##            in its NW corner. Doors out: west (z -86) to the west yard,
##            east (z -80) onto the site, north (x 6) to the back strip.
##   1F       FRONT CORRIDOR z [-80, -76], windows over Consent Way (N5).
##            OFFICES x [-18, -6] (alarm post), ANTEROOM x [-6, 6] z [-84,
##            -80] -> SERVER ROOM x [-6, 6] z [-96, -84] (N6) with the SCORE
##            SERVER on its north wall; EAST OFFICE x [6, 18] z [-96, -80],
##            the roof ladder in its NE corner.
##   roof     parapet 0.5; a gap at the east edge z [-95.6, -94.4] where the
##            site's last plank lands (SecAnnexSite). N7 watches the Way.

const X0 := -18.0
const X1 := 18.0
const Z0 := -96.0
const Z1 := -76.0
const F1 := 4.0
const ROOF := 8.0
const T := 0.3
const SERVER_Z := -95.5

static func build(root: Node3D, game: GrayboxGame) -> void:
	_shell(root)
	_slabs(root)
	_ground(root)
	_first_floor(root)
	_server(root)
	_roof(root)
	_lights(root)
	_signs(root)

static func _shell(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var W := WallUtils
	var front_windows := []
	for x in [-14.0, -9.5, 9.5, 14.0]:
		front_windows.append(W.hole(x - 1.0, x + 1.0, F1 + 1.0, F1 + 2.4))
	W.wall(root, "x", Z1, X0, X1, 0, ROOF, T, c, [W.door(0.0, 0.0, 2.4)] + front_windows)
	W.wall(root, "x", Z0, X0, X1, 0, ROOF, T, c, [W.door(6.0)])
	W.wall(root, "z", X0, Z0, Z1, 0, ROOF, T, c, [W.door(-86.0)])
	W.wall(root, "z", X1, Z0, Z1, 0, ROOF, T, c, [W.door(-80.0),
		W.hole(-92.0, -88.0, F1 + 1.0, F1 + 2.2)])
	# Canopy over the front door, high enough for a guard's head (2.3+).
	BuildUtils.plate(root, -4.0, 4.0, -76.0 + T * 0.5, -73.0, 3.2, 0.2, BuildUtils.WALL_DARK)

static func _slabs(root: Node3D) -> void:
	var f := BuildUtils.FLOOR
	BuildUtils.plate(root, X0, X1, Z0, Z1, 0.05, 0.3, f)
	# 1F, open over the stair x [7, 15] z [-79.4, -77.8].
	BuildUtils.plate(root, X0, X1, Z0, -79.4, F1, 0.3, f)
	BuildUtils.plate(root, X0, 7.0, -79.4, Z1, F1, 0.3, f)
	BuildUtils.plate(root, 15.0, X1, -79.4, Z1, F1, 0.3, f)
	BuildUtils.plate(root, 7.0, 15.0, -77.8, Z1, F1, 0.3, f)
	BuildUtils.ramp(root, Vector3(7.0, 0, -78.6), Vector3(1, 0, 0), 8.0, F1, 1.5,
		BuildUtils.CONCRETE, 12)

# ----------------------------------------------------------------- ground ---
static func _ground(root: Node3D) -> void:
	var c := BuildUtils.WALLPAPER
	var W := WallUtils
	W.wall(root, "x", -82.0, X0, X1, 0, F1, 0.2, c,
		[W.door(-10.0), W.door(0.0, 0.0, 2.4), W.door(10.0)])
	W.wall(root, "z", -6.0, -82.0, Z1, 0, F1, 0.2, c, [W.door(-79.0)])
	W.wall(root, "z", 6.0, -82.0, Z1, 0, F1, 0.2, c, [W.door(-80.5)])
	# Reception desk, west of the door line.
	WallUtils.block(root, -5.0, -1.6, 0, 1.1, -80.2, -79.4, BuildUtils.CRATE)
	# Security: the CCTV wall — every screen is the Score's (Surveillance).
	for i in 6:
		var x := -16.5 + float(i % 3) * 1.6
		Surveillance.screen(root, Vector3(x, 1.4 + float(i / 3) * 0.9, -81.85), 0.0,
			["YARD", "WAY", "SITE", "HALL", "ROOF", "YOU"][i] + "\nLIVE", Vector2(1.3, 0.7))
	WallUtils.block(root, -17.0, -12.0, 0, 0.8, -80.0, -79.2, BuildUtils.CRATE)
	# Hall racks: three rows, aisles at every door and down the middle.
	for z in [-85.5, -89.5, -93.0]:
		for xs in [[-16.5, -12.0], [-8.5, -2.0], [2.0, 4.5], [7.5, 9.0], [11.5, 16.5]]:
			WallUtils.block(root, xs[0], xs[1], 0, 2.2, z - 0.35, z + 0.35, Color(0.12, 0.13, 0.16))

# --------------------------------------------------------------------- 1F ---
static func _first_floor(root: Node3D) -> void:
	var c := BuildUtils.WALLPAPER
	var W := WallUtils
	W.wall(root, "x", -80.0, X0, X1, F1, ROOF, 0.2, c,
		[W.door(-12.0, F1), W.door(0.0, F1), W.door(12.0, F1)])
	W.wall(root, "z", -6.0, Z0, -80.0, F1, ROOF, 0.2, c, [W.door(-90.0, F1)])
	W.wall(root, "z", 6.0, Z0, -80.0, F1, ROOF, 0.2, c, [W.door(-90.0, F1)])
	W.wall(root, "x", -84.0, -6.0, 6.0, F1, ROOF, 0.2, c, [W.door(0.0, F1)])
	# Rail along the stair opening, drawn (a solid rail is a vault).
	BuildUtils.box(root, Vector3(11.0, F1 + 1.0, -79.4), Vector3(8.0, 0.05, 0.05), BuildUtils.PIPE, false)
	# Offices: desks in rows, off the door lines.
	for x in [-15.5, -11.5, -8.5]:
		for z in [-84.0, -88.0, -92.5]:
			WallUtils.block(root, x - 0.8, x + 0.8, F1, F1 + 0.8, z - 0.5, z + 0.5, BuildUtils.CRATE)
	for x in [9.0, 13.0]:
		WallUtils.block(root, x - 0.8, x + 0.8, F1, F1 + 0.8, -86.0, -85.0, BuildUtils.CRATE)
	# Corridor barricade: desks on end by the windows, off the walking line.
	WallUtils.block(root, -3.0, 2.0, F1, F1 + 1.0, -76.9, -76.3, BuildUtils.CRATE)
	# The roof ladder: east office NE corner, up a board through the hatch,
	# climbing facing south so the top steps you onto the roof.
	Ladder.create(root, Vector3(15.0, F1, -94.76), ROOF, PI)

static func _server(root: Node3D) -> void:
	for x in [-3.0, 3.0]:
		for z in [-87.0, -91.0]:
			WallUtils.block(root, x - 0.45, x + 0.45, F1, F1 + 2.2, z - 1.4, z + 1.4,
				Color(0.10, 0.11, 0.14))
	var srv := BuildUtils.box(root, Vector3(0.0, F1 + 1.3, SERVER_Z), Vector3(2.0, 2.6, 0.7),
		Color(0.08, 0.08, 0.10))
	srv.add_to_group("score_server")
	var glow := BuildUtils.box(root, Vector3(0.0, F1 + 1.7, SERVER_Z + 0.37), Vector3(1.7, 1.2, 0.04),
		Color.WHITE, false)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.6, 0.2)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.55, 0.15)
	m.emission_energy_multiplier = 1.6
	glow.material_override = m
	glow.add_to_group("score_server_glow")

# ------------------------------------------------------------------- roof ---
static func _roof(root: Node3D) -> void:
	var p := BuildUtils.WALL_DARK
	# Roof slab, with the ladder's hatch at x [14.5, 15.5] z [-95.85, -94.7].
	BuildUtils.plate(root, X0 - 0.15, X1 + 0.15, -94.7, Z1 + 0.15, ROOF, 0.3, p)
	BuildUtils.plate(root, X0 - 0.15, 14.5, Z0 - 0.15, -94.7, ROOF, 0.3, p)
	BuildUtils.plate(root, 15.5, X1 + 0.15, Z0 - 0.15, -94.7, ROOF, 0.3, p)
	BuildUtils.plate(root, 14.5, 15.5, Z0 - 0.15, Z0 + T * 0.5, ROOF, 0.3, p)
	var y0 := ROOF
	var y1 := ROOF + 0.5
	WallUtils.block(root, X0 - 0.15, X1 + 0.15, y0, y1, Z0 - 0.15, Z0 + 0.15, p)
	WallUtils.block(root, X0 - 0.15, X1 + 0.15, y0, y1, Z1 - 0.15, Z1 + 0.15, p)
	WallUtils.block(root, X0 - 0.15, X0 + 0.15, y0, y1, Z0, Z1, p)
	WallUtils.block(root, X1 - 0.15, X1 + 0.15, y0, y1, Z0, -95.6, p)
	WallUtils.block(root, X1 - 0.15, X1 + 0.15, y0, y1, -94.4, Z1, p)
	# Plant boxes: cover for the roof fight.
	for b in [[-12.0, -9.0, -92.0, -89.5], [-2.0, 2.0, -91.0, -88.0], [8.0, 11.0, -88.0, -85.5]]:
		WallUtils.block(root, b[0], b[1], ROOF, ROOF + 1.4, b[2], b[3], Color(0.36, 0.38, 0.36))

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [Vector3(0, 3.2, -79), Vector3(-12, 3.2, -79), Vector3(12, 3.2, -79)],
		BuildUtils.LAMP_FLUORO, 1.2, 9.0)
	BuildUtils.lamps(root, [Vector3(-10, 3.2, -89), Vector3(0, 3.2, -89), Vector3(10, 3.2, -89)],
		BuildUtils.LAMP_FLUORO, 1.4, 11.0)
	BuildUtils.lamps(root, [Vector3(-10, F1 + 3.0, -78), Vector3(10, F1 + 3.0, -78),
		Vector3(-12, F1 + 3.0, -88), Vector3(0, F1 + 3.0, -90), Vector3(12, F1 + 3.0, -88),
		Vector3(0, F1 + 3.0, -82)], BuildUtils.LAMP_FLUORO, 1.2, 9.0)
	BuildUtils.lamps(root, [Vector3(-8, ROOF + 2.0, -86), Vector3(8, ROOF + 2.0, -86)],
		BuildUtils.LAMP_SERVICE, 0.4, 10.0)
	BuildUtils.lamp(root, Vector3(0, 3.0, -74.5), BuildUtils.LAMP_FLUORO, 1.6, 9.0)

static func _signs(root: Node3D) -> void:
	var gold := Color(1.0, 0.75, 0.31)
	SecCmpDressing.plate_sign(root, "SCORING ANNEX\nWHERE YOUR CONSENT IS COUNTED",
		Vector3(0, 3.6, -75.83), 0.0, gold)
	SecCmpDressing.plate_sign(root, "SERVER ROOM\nTHE SCORE LIVES HERE. SO DO YOU.",
		Vector3(0, F1 + 2.8, -83.88), 0.0, gold)
	SecCmpDressing.plate_sign(root, "DO NOT UNPLUG\nTHE SCORE CANNOT BE UNPLUGGED\nPLEASE DO NOT TEST THIS",
		Vector3(0, F1 + 3.1, SERVER_Z + 0.37), 0.0, Color(1.0, 0.4, 0.3))
	SecCmpDressing.plate_sign(root, "SECURITY\nWE SEE YOU SEEING US",
		Vector3(-6.12, 2.6, -78.0), -PI / 2.0, SecCmpDressing.PLATE)
	# The giant screen over the door: what you walk toward up Consent Way.
	Surveillance.screen(root, Vector3(0, 6.0, Z1 + 0.2), 0.0,
		"COLLECTIVE CONSENT SCORE\n412 ▼", Vector2(7.0, 2.6))
