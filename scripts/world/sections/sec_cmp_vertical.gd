class_name SecCmpVertical
extends RefCounted
## Playtest r6: "add more verticality and make the level generally more
## complex". Four new levels, each a route rather than scenery, and each tied
## into the wall-top network (the compound wall's top, 4.0, already joins the
## overbridge, the boiler-house roof and the gatehouse roof):
##
##   Car-park deck   avenue (outside the north wall), x [6, 19.8] z [-39.8,
##                   -24.8], top 3.0 on pillars, delegates' cars parked under
##                   it. Ramp up its west side x [3.6, 6] from z -26 (ground)
##                   to -37. Its south edge meets the wall: a 1.0 mantle onto
##                   the wall top and down into the north yard — the way back
##                   from the avenue (the old rubble stair is gone).
##   West gantry     west yard, along the compound wall's inner face, x [-28,
##                   -26.6] z [-14, 18], top 3.0. Stairs at both ends (north
##                   foot z -19.4, south foot z 23.4). Over G3's lane (x -25)
##                   with 1.6m to spare; a 1.0 mantle onto the wall top and
##                   out over the west alley. The smoking-shelter roof (2.48)
##                   is a hop onto it.
##   Podium          courtyard SW corner, x [-21.6, -13.9] z [19, 23.6], top
##                   2.85 on pillars, benches underneath; stair up its east
##                   end from x -9.4. North edge is a 0.6 wall — crouch cover
##                   over the courtyard. 1.15 mantle onto the south wall top
##                   and out to the verge.
##   Plant room top  main roof: steel stair from the deck (8.4) at x 2 up to
##                   the plant room's top (10.4); a water tank on a plinth
##                   at 11.55 (one mantle) is the highest perch on campus.
##                   Sentry G10 holds the plant room top.
##
## Every rise here is <= 1.15, every stair is a ramp, and nothing new sits on
## a patrol lane (G1 z -22, G2 z 12, G3 x -25, R5 z 18 x [-10, 10]).

const DECK_Y := 3.0
const GANTRY_Y := 3.0
const PODIUM_Y := 2.85
const ROOF_Y := 8.4
const PLANT_TOP := 10.4
const TANK_Y := 11.55

static func build(root: Node3D, game: GrayboxGame) -> void:
	_car_park(root)
	_gantry(root)
	_podium(root)
	_plant_room_top(root)
	_roof_units(root)

# -------------------------------------------------------------- car park ---
static func _car_park(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, 6.0, 19.8, -39.8, -24.8, DECK_Y, 0.3, c)
	BuildUtils.plate(root, 3.6, 6.0, -39.8, -37.0, DECK_Y, 0.3, c)
	BuildUtils.ramp(root, Vector3(4.8, 0, -26.0), Vector3(0, 0, -1), 11.0, DECK_Y,
		2.4, c, 12)
	for x in [6.3, 13.0, 19.5]:
		for z in [-39.5, -32.2, -25.2]:
			BuildUtils.box(root, Vector3(x, (DECK_Y - 0.3) * 0.5, z),
				Vector3(0.4, DECK_Y - 0.3, 0.4), c)
	# Kerb along the open west edge north of the ramp, so it reads as an edge.
	BuildUtils.box(root, Vector3(6.05, DECK_Y + 0.15, -31.0), Vector3(0.1, 0.3, 12.0),
		BuildUtils.GOLD, false)
	BuildUtils.lamp(root, Vector3(13, DECK_Y - 0.5, -32), BuildUtils.LAMP_SERVICE, 1.0, 9.0)
	BuildUtils.lamp(root, Vector3(13, DECK_Y + 2.4, -30), BuildUtils.LAMP_SERVICE, 0.8, 10.0)
	_sign(root, "DELEGATE PARKING\nYOUR VEHICLE HAS BEEN ASSESSED",
		Vector3(19.7, DECK_Y + 1.6, -33), -PI / 2.0)

# ---------------------------------------------------------------- gantry ---
static func _gantry(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.plate(root, -28.0, -26.6, -14.0, 18.0, GANTRY_Y, 0.25, m)
	BuildUtils.stairs(root, Vector3(-27.3, 0, -19.4), Vector3(0, 0, 1),
		6, 0.5, 0.9, 1.4, m)
	BuildUtils.stairs(root, Vector3(-27.3, 0, 23.4), Vector3(0, 0, -1),
		6, 0.5, 0.9, 1.4, m)
	for z in [-11.0, -5.0, 1.0, 7.0, 13.0]:
		BuildUtils.box(root, Vector3(-26.8, (GANTRY_Y - 0.25) * 0.5, z),
			Vector3(0.15, GANTRY_Y - 0.25, 0.15), BuildUtils.PIPE)
	# Handrail: drawn, not solid — a solid rail is a vault, and the gantry is
	# meant to be dropped off anywhere.
	BuildUtils.box(root, Vector3(-26.65, GANTRY_Y + 1.0, 2.0), Vector3(0.05, 0.05, 32.0),
		BuildUtils.PIPE, false)
	for z in [-14.0, -6.0, 2.0, 10.0, 18.0]:
		BuildUtils.box(root, Vector3(-26.65, GANTRY_Y + 0.5, z), Vector3(0.05, 1.0, 0.05),
			BuildUtils.PIPE, false)
	BuildUtils.lamps(root, [Vector3(-27.6, GANTRY_Y + 2.0, -8),
		Vector3(-27.6, GANTRY_Y + 2.0, 10)], BuildUtils.LAMP_SERVICE, 0.5, 7.0)

# ---------------------------------------------------------------- podium ---
static func _podium(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, -21.6, -13.9, 19.0, 23.6, PODIUM_Y, 0.3, c)
	BuildUtils.stairs(root, Vector3(-9.4, 0, 20.3), Vector3(-1, 0, 0),
		5, PODIUM_Y / 5.0, 0.9, 2.0, c)
	for x in [-21.3, -17.7, -14.2]:
		for z in [19.3, 23.5]:
			BuildUtils.box(root, Vector3(x, (PODIUM_Y - 0.3) * 0.5, z),
				Vector3(0.4, PODIUM_Y - 0.3, 0.4), c)
	# Crouch cover along the courtyard edge.
	WallUtils.block(root, -21.6, -13.9, PODIUM_Y, PODIUM_Y + 0.6, 19.0, 19.2, c)
	BuildUtils.lamp(root, Vector3(-17.7, PODIUM_Y - 0.6, 21.3), BuildUtils.LAMP_SERVICE,
		0.5, 6.0)
	_sign(root, "APPLAUSE PODIUM\nENTHUSIASM IS AUDITED",
		Vector3(-17.7, PODIUM_Y + 1.6, 23.55), PI)

# ------------------------------------------------------- plant room top ---
static func _plant_room_top(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.stairs(root, Vector3(2.0, ROOF_Y, -16.0), Vector3(-1, 0, 0),
		4, 0.5, 1.0, 2.0, m)
	# A solid plinth, not a platform on stilts: the mantle needs a face at
	# chest height to grab, and a floating slab has none.
	WallUtils.block(root, -7.8, -4.6, PLANT_TOP, TANK_Y, -17.8, -14.2, m)
	BuildUtils.box(root, Vector3(-6.6, TANK_Y + 1.2, -16.6), Vector3(2.0, 2.4, 2.0),
		Color(0.30, 0.34, 0.30))
	BuildUtils.lamp(root, Vector3(-3.5, PLANT_TOP + 2.0, -15.0), BuildUtils.LAMP_SERVICE,
		0.5, 7.0)
	_sign(root, "POTABLE CONSENSUS\nDO NOT DRINK", Vector3(-6.6, TANK_Y + 1.4, -15.55), 0.0)

static func _sign(root: Node3D, text: String, pos: Vector3, yaw: float) -> void:
	SecCmpDressing.plate_sign(root, text, pos, yaw, Color(1.0, 0.85, 0.3))

## Plant units on the main roof (8.4): cover and a hop circuit. Heights step
## 0.6 / 1.15 / 1.8 so each is a jump or a mantle from the last. Clear of the
## duct mouth (x 7, z -12), the crate-stair gap (x 10, z [-15, -13.5]), the
## scaffold and fire-escape arrivals, and the plant room's stair (x [-2, 2]).
static func _roof_units(root: Node3D) -> void:
	var r := 8.4
	var units := [
		[-17.0, -14.5, -17.5, -15.5, 0.6], [-14.0, -12.5, -17.5, -15.5, 1.15],
		[-11.5, -10.0, -17.5, -16.0, 1.8], [-18.5, -16.5, -9.5, -7.5, 1.15],
		[-14.5, -12.5, -8.0, -6.5, 0.6], [4.0, 6.0, -18.5, -16.5, 1.15],
		[7.0, 8.5, -7.5, -5.5, 0.6], [-9.0, -7.5, -6.5, -5.0, 1.15],
	]
	for u in units:
		WallUtils.block(root, u[0], u[1], r, r + float(u[4]), u[2], u[3], Color(0.36, 0.38, 0.36))
