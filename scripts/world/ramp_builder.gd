class_name RampBuilder
extends RefCounted
## Sloped walkable surfaces, built as a wedge rather than a rotated box.
##
## A rotated box of any thickness pokes its lower corner out past the top of
## the stair — horizontally, by thickness × sin(slope) — and the west stair's
## did exactly that through the foyer wall (G12, "something sticking out of
## the wall"). This wedge is cut vertically at the top and tapers to nothing
## at the base, so nothing it builds lies outside the stair's own footprint
## or below its base. Mesh and collider are the same six points, so what you
## see is exactly what you walk on.

## `dir` is unit and axis-aligned. The wedge's back face drops `thickness`
## below the top edge (never more than the rise, so the underside never dips
## below the base).
static func build(parent: Node3D, base: Vector3, dir: Vector3, run_total: float,
		rise_total: float, width: float, color: Color, treads: int,
		thickness: float) -> StaticBody3D:
	var side := Vector3(-dir.z, 0, dir.x) * (width * 0.5)
	var top := base + dir * run_total + Vector3(0, rise_total, 0)
	var drop := minf(thickness, absf(rise_total))
	var low := top - Vector3(0, drop, 0)
	if rise_total < 0.0:
		# A descending ramp: the base is the high end.
		low = base - Vector3(0, drop, 0)
	var body := StaticBody3D.new()
	body.position = base
	parent.add_child(body)
	var pts := PackedVector3Array([
		base + side, base - side, top + side, top - side, low + side, low - side])
	for i in pts.size():
		pts[i] -= base
	var cs := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = _prism(pts)
	mi.material_override = BuildUtils.mat(color)
	body.add_child(mi)
	if treads > 1:
		_treads(body, top - base, side, treads)
	return body

## Triangular prism from the six points above: 0/1 base, 2/3 top, 4/5 low.
static func _prism(p: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var quads := [[0, 2, 3, 1], [2, 4, 5, 3], [4, 0, 1, 5]]
	var center := Vector3.ZERO
	for v in p:
		center += v
	center /= float(p.size())
	for q in quads:
		_quad(st, p[q[0]], p[q[1]], p[q[2]], p[q[3]], center)
	_tri(st, p[0], p[2], p[4], center)
	_tri(st, p[1], p[3], p[5], center)
	st.generate_normals()
	return st.commit()

## Winds each face outward, whichever way the ramp runs.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		center: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot(a - center) < 0.0:
		var t := b
		b = c
		c = t
	# Godot's front faces are clockwise as seen from outside.
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, center: Vector3) -> void:
	_tri(st, a, b, c, center)
	_tri(st, a, c, d, center)

## Non-colliding lines across the slope so it still reads as a staircase.
static func _treads(body: StaticBody3D, rise_run: Vector3, side: Vector3,
		count: int) -> void:
	var lip := BuildUtils.mat(Color(0.16, 0.17, 0.20))
	var flat := Vector3(rise_run.x, 0, rise_run.z)
	var angle := atan2(rise_run.y, flat.length())
	for i in range(1, count):
		var f := float(i) / float(count)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(side.length() * 2.0, 0.05, 0.09)
		mi.mesh = bm
		mi.material_override = lip
		body.add_child(mi)
		mi.position = rise_run * f + Vector3(0, 0.02, 0)
		mi.basis = Basis.looking_at(flat.normalized(), Vector3.UP) \
			* Basis(Vector3.RIGHT, angle)
