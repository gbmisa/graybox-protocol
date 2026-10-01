class_name SecCmpMainRoof
extends RefCounted
## Main block roof and the Regular's way down through it.
##
##   Roof deck      walk 8.4, slab 0.4 (underside 8.0), parapet 0.6 tall and
##                  0.3 thick — a mantle, not a gate. Gaps where the climbs
##                  top out: east z [-15, -13.5] (crate stair), south x
##                  [-18, -16.2] (scaffold), west z [-3, -2] (fire escape).
##   Duct           1.0m tall, 1.2m wide, on the deck at z -12 from its open
##                  mouth at x 7 west to x 2; the last 1.2m of its floor is a
##                  hole in the slab. Chad's crouch does not fit.
##   Ceiling void   between the hall ceiling (top 7.0) and the slab (8.0):
##                  exactly 1.0m, PITCH. The duct hole drops 1.4m into it.
##   Grille         a 1.2m hole in the hall ceiling over the gallery at
##                  (-2, -9.2): drop 2.0m onto the gallery floor (5.0).
##   Plant room     x [-8, -2] z [-18, -14], 2.0 tall — a sightline block.

const ROOF_Y := 8.4
const SLAB_T := 0.4
const PARAPET_H := 0.6
const PARAPET_T := 0.3
const HALL_CEIL_TOP := 7.0
const DUCT_Z := -12.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_hall_ceiling(root)
	_deck(root)
	_parapet(root)
	_duct(root)
	_plant_room(root)
	_lights(root)

## 0.15 thick so the gallery keeps 1.85m of headroom below and the void keeps
## a full 1.0m above.
static func _hall_ceiling(root: Node3D) -> void:
	BuildUtils.slab_with_hole(root, Vector3(-2, HALL_CEIL_TOP - 0.075, -14),
		Vector2(16, 12), Vector2(-2, -9.2), Vector2(1.2, 1.2), 0.15,
		BuildUtils.WALL_DARK)
	# Grille frame, so the hole reads from the gallery below.
	for x in [-2.65, -1.35]:
		BuildUtils.box(root, Vector3(x, HALL_CEIL_TOP - 0.2, -9.2),
			Vector3(0.1, 0.1, 1.3), BuildUtils.METAL, false)

static func _deck(root: Node3D) -> void:
	BuildUtils.slab_with_hole(root, Vector3(-6, ROOF_Y - SLAB_T * 0.5, -11),
		Vector2(32.3, 18.3), Vector2(2.6, DUCT_Z), Vector2(1.2, 1.2), SLAB_T,
		BuildUtils.WALL_DARK)

static func _parapet(root: Node3D) -> void:
	var c := BuildUtils.METAL
	var y0 := ROOF_Y
	var y1 := ROOF_Y + PARAPET_H
	WallUtils.wall(root, "x", -20, -22.15, 10.15, y0, y1, PARAPET_T, c)
	WallUtils.wall(root, "x", -2, -22.15, 10.15, y0, y1, PARAPET_T, c, [
		WallUtils.hole(-18.0, -16.2, y0, y1),    # scaffold top
	])
	WallUtils.wall(root, "z", -22, -20, -2, y0, y1, PARAPET_T, c, [
		WallUtils.hole(-3.0, -2.0, y0, y1),      # fire escape top
	])
	WallUtils.wall(root, "z", 10, -20, -2, y0, y1, PARAPET_T, c, [
		WallUtils.hole(-15.0, -13.5, y0, y1),
	])

## Built by hand rather than with `tunnel()`, whose floor box would cover the
## drop hole in the deck.
static func _duct(root: Node3D) -> void:
	var c := BuildUtils.METAL
	var y0 := ROOF_Y
	var y1 := ROOF_Y + 1.0
	WallUtils.block(root, 1.8, 7.0, y1, y1 + 0.2, DUCT_Z - 0.8, DUCT_Z + 0.8, c)
	WallUtils.block(root, 1.8, 7.0, y0, y1, DUCT_Z - 0.8, DUCT_Z - 0.6, c)
	WallUtils.block(root, 1.8, 7.0, y0, y1, DUCT_Z + 0.6, DUCT_Z + 0.8, c)
	WallUtils.block(root, 1.8, 2.0, y0, y1, DUCT_Z - 0.6, DUCT_Z + 0.6, c)
	# Intake cowl around the mouth, so it reads as a vent from the gap.
	WallUtils.block(root, 7.0, 7.3, y0 + 1.0, y0 + 1.4, DUCT_Z - 1.0, DUCT_Z + 1.0, c)

static func _plant_room(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(-5, ROOF_Y + 1.0, -16), Vector3(6, 2.0, 4),
		BuildUtils.WALL)
	BuildUtils.lamp(root, Vector3(-5, ROOF_Y + 2.4, -13.6), BuildUtils.LAMP_SERVICE,
		0.8, 7.0)

## The deck is DARK and the void PITCH: one faint lamp each, enough to
## navigate, not enough to read as lit.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-16, ROOF_Y + 2, -6), Vector3(4, ROOF_Y + 2, -6),
	], BuildUtils.LAMP_SERVICE, 0.5, 12.0)
	BuildUtils.lamps(root, [
		Vector3(1, HALL_CEIL_TOP + 0.6, -12), Vector3(-2, HALL_CEIL_TOP + 0.6, -10),
	], BuildUtils.LAMP_SERVICE, 0.25, 4.0)
