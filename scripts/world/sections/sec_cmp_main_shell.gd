class_name SecCmpMainShell
extends RefCounted
## Main block envelope: the four exterior walls, ground to roof deck (0 -> 8.4),
## every opening cut through them, and the portico. Built as one piece so no
## floor's walls stop short of the next floor — the Gate A walk found sky
## between the 1F walls (7.0) and the roof underside, and every one of those
## slots was a wall owned by the wrong file.
##
## Openings, and who they are for:
##   north  panic-room barred window (-16, 0.7..2.3) — the Wizard's ward
##   west   west exit (-22, z -6) — plain door into the west yard
##   east   L1 canteen service door (z -12, under the bridge) — lockpick; the
##          bridge door directly above it on 1F. r4 put L1 at z -19, behind
##          the first crate stack.
##   south  portico door (x 0); 1F south window (x 0, 4.0..6.0) — Chad's plate
##
## Portico: roof 2.4 on two solid piers, so Chad's chest probe has a face to
## find at +0.9 (a roof on posts would pass it straight through).

const TOP := 8.4
const T := 0.3
const X0 := -22.0
const X1 := 10.0
const Z0 := -20.0
const Z1 := -2.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL
	var e := T * 0.5
	WallUtils.wall(root, "x", Z0, X0 - e, X1 + e, 0, TOP, T, c, [
		WallUtils.hole(-16.8, -15.2, 0.7, 2.3),
	])
	WallUtils.wall(root, "x", Z1, X0 - e, X1 + e, 0, TOP, T, c, [
		WallUtils.door(0.0),
		WallUtils.hole(-0.5, 0.5, 4.0, 6.0),
	])
	WallUtils.wall(root, "z", X0, Z0 + e, Z1 - e, 0, TOP, T, c, [
		WallUtils.door(-6.0),
	])
	WallUtils.wall(root, "z", X1, Z0 + e, Z1 - e, 0, TOP, T, c, [
		WallUtils.door(-12.0),
		WallUtils.door(-12.0, 4.0),
	])
	_portico(root)

static func _portico(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	WallUtils.block(root, -2.5, -1.5, 0.0, 2.0, Z1 + T * 0.5, 0.5, c)
	WallUtils.block(root, 1.5, 2.5, 0.0, 2.0, Z1 + T * 0.5, 0.5, c)
	WallUtils.block(root, -2.5, 2.5, 2.0, 2.4, Z1 + T * 0.5, 0.5, c)
	BuildUtils.lamp(root, Vector3(0, 1.9, -1.0), BuildUtils.LAMP_FLUORO, 1.2, 6.0)
