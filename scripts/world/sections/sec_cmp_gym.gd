class_name SecCmpGym
extends RefCounted
## Gym, x [16, 28] z [-20, 8]. Ground 0, mezzanine 4.0, roof walk 6.6. Every
## wall runs ground to roof; the east wall is the compound wall's z [-20, 8]
## stretch at its full 0.8 thickness, carrying the jammed shutter.
##
##   Store      z [-20,-14] PITCH, ceiling 3.6. Shutter east (crawl 1.0 x 3.0),
##              door west to the alley, door south to the gym floor.
##   Floor      z [-14, 8] LIT, double height. South doors to the forecourt;
##              mezzanine ramp up the west wall; G4's lane at x 20.
##   Mezzanine  y 4.0 over z [-20,-8]. Bridge door west; the hatch crate
##              (2.2, Chad's step) under the roof hatch.
##   Roof       6.6, parapet 0.4. Hatch 2.0 x 2.0 over the crate; plant box
##              (+2.2) and the helipad deck (+2.4) — Chad's chain to E2.
## The canopy and skip belong to `sec_cmp_yards`.

const WALL_T := 0.4
const MEZZ_Y := 4.0
const ROOF_Y := 6.6
const ROOF_T := 0.3

static func build(root: Node3D, game: GrayboxGame) -> void:
	_walls(root)
	_store(root)
	_floor(root)
	_mezzanine(root)
	_roof(root)
	_deck(root)
	_lights(root)

static func _walls(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var e := WALL_T * 0.5
	BuildUtils.plate(root, 16, 28, -20, 8, 0, 1.0, BuildUtils.FLOOR)
	WallUtils.wall(root, "x", -20, 16 - e, 28, 0, ROOF_Y, WALL_T, c)
	WallUtils.wall(root, "x", 8, 16 - e, 28, 0, ROOF_Y, WALL_T, c, [
		WallUtils.door(22.0, 0.0, 2.0, 2.6),
	])
	WallUtils.wall(root, "z", 16, -20, 8, 0, ROOF_Y, WALL_T, c, [
		WallUtils.door(-17.0),
		WallUtils.door(-12.0, MEZZ_Y, 1.6),
	])
	# East: the compound wall itself, 0.8 thick, x [28, 28.8].
	WallUtils.wall(root, "z", 28.4, -20.4, 8.4, 0, ROOF_Y, 0.8, c, [
		WallUtils.hole(-18.5, -15.5, 0.0, 1.0),
	])
	BuildUtils.tunnel(root, Vector3(29.6, 0, -17), Vector3(27.4, 0, -17), 1.0, 3.0,
		BuildUtils.METAL)

## Store/floor partition with the inner door; ceiling is the mezzanine floor.
static func _store(root: Node3D) -> void:
	WallUtils.wall(root, "x", -14, 16, 28, 0, MEZZ_Y - 0.4, WALL_T, BuildUtils.WALL, [
		WallUtils.door(22.0, 0.0, 1.6),
	])
	BuildUtils.box(root, Vector3(26.5, 0.6, -19), Vector3(1.6, 1.2, 1.2), BuildUtils.CRATE)

## Mezzanine ramp up the west wall; props kept off G4's lane at x = 20.
static func _floor(root: Node3D) -> void:
	BuildUtils.ramp(root, Vector3(17.5, 0, -2), Vector3(0, 0, -1), 6.0, 4.0, 2.4,
		BuildUtils.CONCRETE)
	for spot in [Vector3(25, 0, 2), Vector3(24.5, 0, -4), Vector3(25.5, 0, 5.5)]:
		BuildUtils.box(root, spot + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4),
			BuildUtils.METAL)

static func _mezzanine(root: Node3D) -> void:
	BuildUtils.plate(root, 16, 28, -20, -8, MEZZ_Y, 0.4, BuildUtils.FLOOR)
	# Low rail along the balcony edge, leaving the ramp's landing open.
	BuildUtils.box(root, Vector3(23.35, MEZZ_Y + 0.5, -8.1), Vector3(9.3, 1.0, 0.15),
		BuildUtils.METAL)
	BuildUtils.box(root, Vector3(22, MEZZ_Y + 1.1, -11), Vector3(2, 2.2, 2),
		BuildUtils.CRATE)

## One slab over the whole footprint with the 2.0 x 2.0 hatch — the hatch
## crate's full footprint, or the mantle's landing check refuses it (M7).
## The west parapet stops where the bridge roof joins, so the two are one
## surface.
static func _roof(root: Node3D) -> void:
	BuildUtils.slab_with_hole(root, Vector3(22, ROOF_Y - ROOF_T * 0.5, -6),
		Vector2(12.8, 28.8), Vector2(22, -11), Vector2(2.0, 2.0), ROOF_T,
		BuildUtils.WALL_DARK)
	var c := BuildUtils.METAL
	var y0 := ROOF_Y
	var y1 := ROOF_Y + 0.4
	WallUtils.wall(root, "x", -20, 15.85, 28.15, y0, y1, 0.3, c)
	WallUtils.wall(root, "x", 8, 15.85, 28.15, y0, y1, 0.3, c)
	WallUtils.wall(root, "z", 28.0, -20, 8, y0, y1, 0.3, c)
	WallUtils.wall(root, "z", 16, -20, 8, y0, y1, 0.3, c, [
		WallUtils.hole(-13.5, -10.5, y0, y1),
	])
	BuildUtils.box(root, Vector3(19, ROOF_Y + 1.1, -8), Vector3(2, 2.2, 2),
		BuildUtils.CRATE)   # plant box, top 8.8

## Helipad deck x [20, 26] z [-12, -4], solid y [9.5, 11.2] on four legs; the
## plant box abuts its west face, so Chad's chest probe finds the fascia.
static func _deck(root: Node3D) -> void:
	for leg in [Vector3(20.4, 0, -4.4), Vector3(25.6, 0, -4.4),
			Vector3(20.4, 0, -11.6), Vector3(25.6, 0, -11.6)]:
		BuildUtils.box(root, leg + Vector3(0, (ROOF_Y + 9.5) * 0.5, 0),
			Vector3(0.3, 9.5 - ROOF_Y, 0.3), BuildUtils.METAL)
	WallUtils.block(root, 20, 26, 9.5, 11.2, -12, -4, BuildUtils.CONCRETE)
	var paint := Color(0.9, 0.9, 0.85)
	for x in [21.8, 24.2]:
		BuildUtils.box(root, Vector3(x, 11.22, -8), Vector3(0.5, 0.04, 3.0), paint, false)
	BuildUtils.box(root, Vector3(23, 11.22, -8), Vector3(1.9, 0.04, 0.5), paint, false)

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(22, 5.8, -3), Vector3(22, 5.8, 4), Vector3(19, 3.2, -11),
		Vector3(25, 3.2, -11),
	], BuildUtils.LAMP_FLUORO, 2.2, 14.0)
	BuildUtils.lamp(root, Vector3(22, MEZZ_Y + 1.8, -15), BuildUtils.LAMP_FLUORO, 1.6, 10.0)
	BuildUtils.lamp(root, Vector3(22, 2.6, -17), BuildUtils.LAMP_SERVICE, 0.2, 6.0)
