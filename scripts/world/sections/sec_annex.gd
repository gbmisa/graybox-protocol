class_name SecAnnex
extends RefCounted
## THE SCORING ANNEX — playtest r6's new area and the secondary objective.
## North of the avenue, behind what was its north wall: where the Consent
## Score is actually computed. Wipe the server (SecondaryScore) and the
## billboard over the south road goes dark with it.
##
## Yard x [-20, 20] z [-62, -40], walled 6m. Two ways in from the avenue:
##   Checkpoint   a gate gap x [-3, 3] in the old north wall, a chicane of
##                barriers, a floodlit sandbag nest (N1) — the front door.
##   Crawl        a 1.0m gap under the wall at x [14, 15.2], under the car-
##                park deck, into the dark dock. The Regular's way.
## Building x [-14, 6] z [-58, -46], two floors (0 / 4.0), roof 8.0:
##   ground  hall, open plan, racks for cover. Doors: south (x -4) on the
##           checkpoint, west (z -56) on the generator strip, east (z -57) on
##           the dock, north (x -1) on the back strip. A ramp up the west wall
##           x [-13.7, -12.2] z [-53.8, -46.3] to the 1F landing.
##   1F      landing x [-14, -12] z [-58, -54] -> office x [-12, -4] z [-58,
##           -50] -> corridor z [-50, -46] (desk barricade at its east end);
##           server room x [-4, 6] z [-58, -50] with the SCORE SERVER on its
##           north wall. Three doors into it: corridor (x 1), office (z -54),
##           and the fire stair (east, z -54.8).
##   roof    by the fire stair's second flight; N5 watches the checkpoint.
## Fire stair, dock side: flight 1 x [6.3, 7.8] rises north z -46 -> -53.5 to
## a landing at 4.0 (server room door); flight 2 x [7.8, 9.3] rises south
## z -53.5 -> -48.5 (0.8, steep) to a landing at 8.0 and the roof.
## Dock x [8, 20]: containers for cover, a sandbag nest facing west over the
## yard with its back to the crawl.
## Generator x [-19.5, -16.5] z [-57, -52], humming, PITCH.

const F1 := 4.0
const ROOF := 8.0
const T := 0.3
const X0 := -14.0
const X1 := 6.0
const Z0 := -58.0
const Z1 := -46.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_yard(root)
	_shell(root)
	_floors(root)
	_first_floor(root)
	_fire_stair(root)
	_checkpoint(root)
	_dock(root)
	_generator(root)
	_lights(root)
	_signs(root)

static func _yard(root: Node3D) -> void:
	BuildUtils.plate(root, -20, 20, -62, -40.0, 0, 1.0, BuildUtils.STREET)
	var c := BuildUtils.WALL_DARK
	var h := 6.0
	BuildUtils.box(root, Vector3(-20.2, h * 0.5, -51.2), Vector3(0.4, h, 22.4), c)
	BuildUtils.box(root, Vector3(20.2, h * 0.5, -51.2), Vector3(0.4, h, 22.4), c)
	BuildUtils.box(root, Vector3(0, h * 0.5, -62.2), Vector3(40.8, h, 0.4), c)

# ----------------------------------------------------------------- shell ---
static func _shell(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var W := WallUtils
	W.wall(root, "x", Z1, X0, X1, 0, ROOF, T, c, [
		W.door(-4.0),
		[-10.0, -8.0, 5.0, 6.4], [0.0, 2.0, 5.0, 6.4],      # 1F corridor windows
	])
	W.wall(root, "x", Z0, X0, X1, 0, ROOF, T, c, [W.door(-1.0)])
	W.wall(root, "z", X0, Z0, Z1, 0, ROOF, T, c, [W.door(-56.0)])
	W.wall(root, "z", X1, Z0, Z1, 0, ROOF, T, c, [W.door(-57.0), W.door(-54.8, F1)])

static func _floors(root: Node3D) -> void:
	var f := BuildUtils.FLOOR
	BuildUtils.plate(root, X0, X1, Z0, Z1, 0.0, 0.3, f)
	# 1F slab, cut where the ramp comes up the west wall.
	BuildUtils.plate(root, -12.0, X1, Z0, Z1, F1, 0.3, f)
	BuildUtils.plate(root, X0, -12.0, Z0, -54.0, F1, 0.3, f)
	BuildUtils.ramp(root, Vector3(-12.95, 0, -46.3), Vector3(0, 0, -1), 7.5, F1, 1.5,
		BuildUtils.CONCRETE, 10)
	# Roof and parapet; the gap at the east end is where the fire stair lands.
	BuildUtils.plate(root, X0 - 0.15, X1 + 0.15, Z0 - 0.15, Z1 + 0.15, ROOF, 0.3,
		BuildUtils.WALL_DARK)
	var p := BuildUtils.WALL_DARK
	WallUtils.block(root, X0 - 0.15, X1 + 0.15, ROOF, ROOF + 0.5, Z0 - 0.15, Z0 + 0.15, p)
	WallUtils.block(root, X0 - 0.15, X0 + 0.15, ROOF, ROOF + 0.5, Z0, Z1, p)
	WallUtils.block(root, X0 - 0.15, X1 + 0.15, ROOF, ROOF + 0.5, Z1 - 0.15, Z1 + 0.15, p)
	WallUtils.block(root, X1 - 0.15, X1 + 0.15, ROOF, ROOF + 0.5, Z0, -49.0, p)
	# Server racks on the ground floor: cover in rows, clear of every door.
	for z in [-55.5, -52.0]:
		for x in [-9.0, -5.0, 2.0]:
			BuildUtils.box(root, Vector3(x, 1.1, z), Vector3(2.4, 2.2, 0.7), Color(0.12, 0.13, 0.16))

# --------------------------------------------------------------------- 1F ---
static func _first_floor(root: Node3D) -> void:
	var c := BuildUtils.WALLPAPER
	var W := WallUtils
	W.wall(root, "z", -12.0, Z0, -50.0, F1, ROOF, T, c, [W.door(-56.0, F1)])   # landing | office
	W.wall(root, "x", -50.0, -12.0, X1, F1, ROOF, T, c, [W.door(-8.0, F1), W.door(1.0, F1)])
	W.wall(root, "z", -4.0, Z0, -50.0, F1, ROOF, T, c, [W.door(-54.0, F1)])  # office | server
	# Rail along the stair opening, drawn (a solid rail is a vault).
	BuildUtils.box(root, Vector3(-12.0, F1 + 1.0, -50.0), Vector3(0.05, 0.05, 8.0),
		BuildUtils.PIPE, false)
	# Server room: racks and the server itself, glowing.
	for x in [-2.0, 4.0]:
		BuildUtils.box(root, Vector3(x, F1 + 1.1, -53.0), Vector3(0.7, 2.2, 3.0),
			Color(0.10, 0.11, 0.14))
	var srv := BuildUtils.box(root, Vector3(1.0, F1 + 1.3, -57.4), Vector3(3.0, 2.6, 0.9),
		Color(0.08, 0.08, 0.10))
	srv.add_to_group("score_server")
	var glow := BuildUtils.box(root, Vector3(1.0, F1 + 1.6, -56.93), Vector3(2.6, 1.2, 0.04),
		Color.WHITE, false)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.6, 0.2)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.55, 0.15)
	m.emission_energy_multiplier = 2.0
	glow.material_override = m
	glow.add_to_group("score_server_glow")
	# Office desks, and the corridor barricade: desks on their sides by the
	# windows, clear of the corridor's walking line (z -48).
	for x in [-10.0, -6.5]:
		BuildUtils.box(root, Vector3(x, F1 + 0.4, -53.0), Vector3(1.6, 0.8, 0.8), BuildUtils.CRATE)
	WallUtils.block(root, 2.5, 5.7, F1, F1 + 1.0, -47.3, -46.7, BuildUtils.CRATE)

# ------------------------------------------------------------- fire stair ---
static func _fire_stair(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.ramp(root, Vector3(7.05, 0, -46.0), Vector3(0, 0, -1), 7.5, F1, 1.5, m, 10)
	BuildUtils.plate(root, X1 + 0.15, 9.3, -56.0, -53.5, F1, 0.3, m)
	BuildUtils.ramp(root, Vector3(8.55, F1, -53.5), Vector3(0, 0, 1), 5.0, ROOF - F1, 1.5, m, 8)
	BuildUtils.plate(root, X1 - 0.15, 9.3, -48.5, -46.0, ROOF, 0.3, m)

# ------------------------------------------------------------- checkpoint ---
static func _checkpoint(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	# Chicane: two barrier runs, offset, so the gate is walked in an S.
	WallUtils.block(root, -3.0, 0.8, 0, 1.0, -43.3, -42.7, c)
	WallUtils.block(root, -0.8, 3.0, 0, 1.0, -45.8, -45.2, c)
	# Sandbag nest by the hall door, open to the building.
	_sandbags(root, -9.0, -5.0, -44.6, -44.0)
	_sandbags(root, -9.0, -8.4, -45.9, -44.6)    # open east, toward the door
	# The barrier arm, drawn: it does not stop anyone.
	BuildUtils.box(root, Vector3(0, 1.0, -40.8), Vector3(5.6, 0.08, 0.08), Color(0.9, 0.2, 0.15), false)
	BuildUtils.lamp(root, Vector3(-4, 4.0, -43), BuildUtils.LAMP_FLUORO, 2.4, 12.0)

static func _sandbags(root: Node3D, x0: float, x1: float, z0: float, z1: float) -> void:
	WallUtils.block(root, x0, x1, 0, 1.0, z0, z1, Color(0.42, 0.38, 0.27))

# ------------------------------------------------------------------- dock ---
static func _dock(root: Node3D) -> void:
	var rust := Color(0.55, 0.22, 0.14)
	var teal := Color(0.14, 0.42, 0.44)
	WallUtils.block(root, 12.0, 18.0, 0, 2.3, -51.0, -48.6, rust)
	WallUtils.block(root, 12.0, 15.0, 2.3, 4.6, -51.0, -48.6, teal)
	WallUtils.block(root, 13.0, 19.0, 0, 2.3, -58.5, -56.1, teal)
	# Nest facing west over the yard — its back is to the crawl's mouth.
	_sandbags(root, 11.4, 12.0, -46.0, -42.0)
	BuildUtils.lamp(root, Vector3(15, 3.0, -53), BuildUtils.LAMP_SERVICE, 0.6, 8.0)

# -------------------------------------------------------------- generator ---
static func _generator(root: Node3D) -> void:
	WallUtils.block(root, -19.5, -16.5, 0, 1.6, -57.0, -52.0, Color(0.20, 0.30, 0.22))
	SecCmpExits.engine_loop(root, Vector3(-18, 0.8, -54.5),
		"res://assets/audio/scifi/engineCircular_000.ogg", -14.0)

# ----------------------------------------------------------------- lights ---
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [Vector3(-8, 3.2, -52), Vector3(2, 3.2, -52)],
		BuildUtils.LAMP_FLUORO, 1.6, 10.0)
	BuildUtils.lamps(root, [Vector3(-8, F1 + 3.0, -54), Vector3(1, F1 + 3.0, -54),
		Vector3(-4, F1 + 3.0, -48)], BuildUtils.LAMP_FLUORO, 1.4, 9.0)
	BuildUtils.lamp(root, Vector3(-13, F1 + 2.4, -56), BuildUtils.LAMP_SERVICE, 0.6, 6.0)
	BuildUtils.lamp(root, Vector3(7.5, F1 + 2.4, -55), BuildUtils.LAMP_SERVICE, 0.6, 7.0)
	BuildUtils.lamp(root, Vector3(-4, ROOF + 2.0, -52), BuildUtils.LAMP_SERVICE, 0.4, 9.0)

static func _signs(root: Node3D) -> void:
	var gold := Color(1.0, 0.75, 0.31)
	SecCmpDressing.plate_sign(root, "SCORING ANNEX\nWHERE YOUR CONSENT IS COUNTED",
		Vector3(-4, 3.0, -45.83), 0.0, gold)
	SecCmpDressing.plate_sign(root, "SERVER ROOM\nTHE SCORE LIVES HERE. SO DO YOU.",
		Vector3(1.0, F1 + 2.8, -49.83), 0.0, gold)
	SecCmpDressing.plate_sign(root, "CHECKPOINT\nHAVE YOUR NUMBER READY",
		Vector3(-7, 1.6, -43.97), 0.0, gold)
	SecCmpDressing.plate_sign(root, "DO NOT UNPLUG\nTHE SCORE CANNOT BE UNPLUGGED\nPLEASE DO NOT TEST THIS",
		Vector3(1.0, F1 + 3.0, -56.9), 0.0, Color(1.0, 0.4, 0.3))
