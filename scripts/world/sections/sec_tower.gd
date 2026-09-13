class_name SecTower
extends RefCounted
## The shared shell: Meridian Tower's exterior walls and its ground slab.
##
## The three routes all cut through this envelope at different points, so the
## openings are cut here rather than in the route sections:
##   south face  vent shaft mouth   x [-2, 26],  y [0, 6]     WIZARD
##   east face   collapsed wall     z [2.5, 9.5], y [0, 4.5]  CHAD
##   ground slab stairwell shaft    x [-30, -18], z [-20, -8] REGULAR
##
## Footprint x [-30, 30], z [-40, 10]. Shell spans y [-4, 18].

const Y_BOTTOM := -4.0
const Y_TOP := 18.0
const T := 0.8

static func build(root: Node3D, _game: GrayboxGame) -> void:
	_shell(root)
	_ground_slab(root)
	_lights(root)

## The ground floor is sealed on all sides and gets no daylight at all. It is
## on the way out for every operative (chute -> north exit) and on the way in
## for the Regular (stairwell), so it cannot be a black void.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-24, 4, -14), Vector3(-8, 4, -6), Vector3(-16, 4, -30),
		Vector3(0, 4, -37), Vector3(24, 4, -36), Vector3(-4, 4, 4),
	], BuildUtils.LAMP_SERVICE, 2.2, 20.0)

static func _shell(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var h := Y_TOP - Y_BOTTOM
	var mid := (Y_TOP + Y_BOTTOM) * 0.5
	BuildUtils.box(root, Vector3(-30, mid, -15), Vector3(T, h, 50), c)
	_north_face(root, c, h, mid)
	_south_face(root, c, h, mid)
	_east_face(root, c, h, mid)

## Solid except a ground-level emergency exit at x [-4, 4], y [0, 3]. The drop
## chute lands just inside it, so the way out after the kill does not mean
## retracing the route in.
static func _north_face(root: Node3D, c: Color, h: float, mid: float) -> void:
	BuildUtils.box(root, Vector3(-17, mid, -40), Vector3(26, h, T), c)
	BuildUtils.box(root, Vector3(17, mid, -40), Vector3(26, h, T), c)
	BuildUtils.box(root, Vector3(0, -2, -40), Vector3(8, 4, T), c)
	BuildUtils.box(root, Vector3(0, 10.5, -40), Vector3(8, 15, T), c)

## Solid except the vent shaft mouth the Wizard climbs through.
static func _south_face(root: Node3D, c: Color, h: float, mid: float) -> void:
	BuildUtils.box(root, Vector3(-16, mid, 10), Vector3(28, h, T), c)
	BuildUtils.box(root, Vector3(28, mid, 10), Vector3(4, h, T), c)
	BuildUtils.box(root, Vector3(12, -2, 10), Vector3(28, 4, T), c)
	BuildUtils.box(root, Vector3(12, 12, 10), Vector3(28, 12, T), c)

## Solid except the recess the collapsed wall sits in, z [-11.5, -4.5].
static func _east_face(root: Node3D, c: Color, h: float, mid: float) -> void:
	BuildUtils.box(root, Vector3(30, mid, -25.75), Vector3(T, h, 28.5), c)
	BuildUtils.box(root, Vector3(30, mid, 2.75), Vector3(T, h, 14.5), c)
	BuildUtils.box(root, Vector3(30, -2, -8), Vector3(T, 4, 7), c)
	BuildUtils.box(root, Vector3(30, 11.25, -8), Vector3(T, 13.5, 7), c)

## Ground floor, cut for the service stairwell coming up from the undercroft
## at x [-30, -18], z [-8, 8].
static func _ground_slab(root: Node3D) -> void:
	var c := BuildUtils.FLOOR
	BuildUtils.plate(root, -30, 30, -40, -8, 0.0, 1.0, c)
	BuildUtils.plate(root, -18, 30, -8, 8, 0.0, 1.0, c)
	BuildUtils.plate(root, -30, 30, 8, 10, 0.0, 1.0, c)
