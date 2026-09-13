class_name BuildUtils
extends RefCounted
## Geometry helpers shared by every level section. Materials are cached by
## color so the whole compound reuses a handful of StandardMaterial3D
## instances instead of one per box.

## Shared graybox palette. Each surface role gets one value so the compound
## reads as one building rather than a pile of differently-tinted boxes.
const GROUND := Color(0.13, 0.14, 0.16)
const STREET := Color(0.17, 0.18, 0.21)
const WALL := Color(0.32, 0.33, 0.36)
const WALL_DARK := Color(0.24, 0.25, 0.29)
const FLOOR := Color(0.28, 0.29, 0.33)
const CONCRETE := Color(0.38, 0.39, 0.42)
const CRATE := Color(0.45, 0.36, 0.26)
const METAL := Color(0.30, 0.34, 0.40)
const PIPE := Color(0.22, 0.26, 0.30)
const GOLD := Color(1.0, 0.84, 0.37)
const GREEN := Color(0.20, 1.0, 0.35)
const RED := Color(1.0, 0.25, 0.25)

## Interior lighting. There is no global illumination, so any enclosed space
## with no lamp in it renders as a black void — every interior needs its own.
const LAMP_FLUORO := Color(0.82, 0.90, 1.00)   # offices, mezzanine
const LAMP_SERVICE := Color(1.00, 0.86, 0.62)  # undercroft, plant, dock
const LAMP_ARCANE := Color(0.72, 0.45, 1.00)   # the Wizard's shaft

static var _mats: Dictionary = {}

static func mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		_mats[key] = m
	return _mats[key]

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color,
		collide: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		parent.add_child(body)
	return mi

## A point light. Shadows are off deliberately — the level carries ~30 of
## these and shadowed omnis are the expensive kind.
static func lamp(parent: Node3D, pos: Vector3, color: Color,
		energy: float = 2.0, reach: float = 14.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = reach
	l.shadow_enabled = false
	parent.add_child(l)
	return l

## Places a lamp at each of `spots`, saving a loop in every section.
static func lamps(parent: Node3D, spots: Array, color: Color,
		energy: float = 2.0, reach: float = 14.0) -> void:
	for p in spots:
		lamp(parent, p, color, energy, reach)

static func label(parent: Node3D, text: String, pos: Vector3, color: Color,
		font_size: int = 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.modulate = color
	l.font_size = font_size
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 12
	parent.add_child(l)
	return l

## One rectangular piece of floor, given by its edges rather than a centre and
## size. Floors with several openings in them are far easier to read and edit
## as a list of explicit rectangles than as nested hole-cutting calls, so the
## mezzanine, ground slab, boardroom and roof are all built this way.
## `y_top` is the walking surface; the slab hangs below it.
static func plate(parent: Node3D, x0: float, x1: float, z0: float, z1: float,
		y_top: float, thickness: float, color: Color) -> void:
	if x1 - x0 <= 0.01 or z1 - z0 <= 0.01:
		return
	box(parent, Vector3((x0 + x1) * 0.5, y_top - thickness * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, thickness, z1 - z0), color)

## A floor slab with a single rectangular opening, built as four boxes around
## the gap. For more than one opening, use `plate` instead.
## `center` is the slab centre including its y; extents are on the XZ plane.
static func slab_with_hole(parent: Node3D, center: Vector3, size: Vector2,
		hole_center: Vector2, hole_size: Vector2, thickness: float,
		color: Color) -> void:
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	var x0 := hole_center.x - hole_size.x * 0.5
	var x1 := hole_center.x + hole_size.x * 0.5
	var z0 := hole_center.y - hole_size.y * 0.5
	var z1 := hole_center.y + hole_size.y * 0.5
	var y := center.y
	# North and south bands span the full width; east and west fill the rest.
	_band(parent, color, thickness, y,
		center.x - hx, center.x + hx, center.z - hz, z0)
	_band(parent, color, thickness, y,
		center.x - hx, center.x + hx, z1, center.z + hz)
	_band(parent, color, thickness, y, center.x - hx, x0, z0, z1)
	_band(parent, color, thickness, y, x1, center.x + hx, z0, z1)

static func _band(parent: Node3D, color: Color, thickness: float, y: float,
		x0: float, x1: float, z0: float, z1: float) -> void:
	if x1 - x0 <= 0.01 or z1 - z0 <= 0.01:
		return
	box(parent, Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5),
		Vector3(x1 - x0, thickness, z1 - z0), color)

## An axis-aligned crawl passage: floor, ceiling and two side walls enclosing
## an opening exactly `interior_h` tall. Crawl gaps are built at 1.0m, which
## the Regular and Wizard clear at 0.85m crouched and Chad does not at 1.45m.
## `from` and `to` are floor-level centre points and must share x or z.
static func tunnel(parent: Node3D, from: Vector3, to: Vector3,
		interior_h: float, width: float, color: Color) -> void:
	var along_x: bool = absf(to.x - from.x) >= absf(to.z - from.z)
	var length := from.distance_to(to)
	var mid := (from + to) * 0.5
	var wall := 0.4
	var span := Vector3(length, wall, width + wall * 2.0) if along_x \
		else Vector3(width + wall * 2.0, wall, length)
	# floor and ceiling
	box(parent, mid + Vector3(0, -wall * 0.5, 0), span, color)
	box(parent, mid + Vector3(0, interior_h + wall * 0.5, 0), span, color)
	# side walls — lifted to straddle the opening, mirrored left and right
	var side := Vector3(length, interior_h, wall) if along_x \
		else Vector3(wall, interior_h, length)
	var lift := Vector3(0, interior_h * 0.5, 0)
	var lateral := Vector3(0, 0, (width + wall) * 0.5) if along_x \
		else Vector3((width + wall) * 0.5, 0, 0)
	box(parent, mid + lift + lateral, side, color)
	box(parent, mid + lift - lateral, side, color)

## A staircase from `base` heading in `dir` (unit, axis-aligned).
##
## Built as a smooth ramp with tread lines drawn on it, NOT as a stack of step
## boxes. Godot's CharacterBody3D has no step-up behaviour, so a 0.5m riser is
## a vertical wall to it — a real staircase would have to be jumped, one step
## at a time. Keep rise/run under 1.0 so the slope stays below the 45 degree
## floor_max_angle, or it stops counting as floor and you slide back down.
static func stairs(parent: Node3D, base: Vector3, dir: Vector3, steps: int,
		rise: float, run: float, width: float, color: Color) -> void:
	ramp(parent, base, dir, run * float(steps), rise * float(steps), width,
		color, steps)

## A sloped surface rising `rise_total` over `run_total`. Mesh and collider are
## the same rotated box, so what you see is exactly what you walk on.
static func ramp(parent: Node3D, base: Vector3, dir: Vector3,
		run_total: float, rise_total: float, width: float, color: Color,
		treads: int = 0, thickness: float = 1.2) -> void:
	var length := sqrt(run_total * run_total + rise_total * rise_total)
	var angle := atan2(rise_total, run_total)
	var along_x: bool = absf(dir.x) > 0.5
	var body := StaticBody3D.new()
	if along_x:
		body.rotation.z = angle * signf(dir.x)
	else:
		body.rotation.x = -angle * signf(dir.z)
	var size := Vector3(length, thickness, width) if along_x \
		else Vector3(width, thickness, length)
	parent.add_child(body)
	# Drop the box along its own (rotated) up axis so its top face is the walking surface.
	var mid := base + dir * (run_total * 0.5) + Vector3(0, rise_total * 0.5, 0)
	body.position = mid - body.transform.basis.y * (thickness * 0.5)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	body.add_child(mi)
	if treads > 1:
		_treads(body, length, width, thickness, treads, along_x)

## Non-colliding lines across the ramp so it still reads as a staircase.
static func _treads(body: StaticBody3D, length: float, width: float,
		thickness: float, count: int, along_x: bool) -> void:
	var step := length / float(count)
	var lip := Color(0.16, 0.17, 0.20)
	for i in range(1, count):
		var offset := -length * 0.5 + step * float(i)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.09, 0.05, width) if along_x \
			else Vector3(width, 0.05, 0.09)
		mi.mesh = bm
		mi.material_override = mat(lip)
		mi.position = Vector3(offset, thickness * 0.5, 0) if along_x \
			else Vector3(0, thickness * 0.5, offset)
		body.add_child(mi)

## Extraction trigger. Fires game.on_extraction_entered(zone_name).
static func zone(parent: Node3D, game: GrayboxGame, zone_name: String,
		pos: Vector3, radius: float) -> void:
	var a := Area3D.new()
	a.position = pos
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = radius
	cs.shape = sp
	a.add_child(cs)
	parent.add_child(a)
	a.body_entered.connect(
		func(body: Node3D) -> void:
			if body.is_in_group("player"):
				game.on_extraction_entered(zone_name)
	)
