class_name Props
extends RefCounted
## Set dressing from the CC0 Kenney kits in `assets/models/` (ASSETS.md).
##
## Every kit models at its own scale and pivots wherever its author liked, so
## `place` normalises both: `pos` is the floor point under the prop's centre,
## and a kit's default scale turns its units into metres. Pass `scale` to
## override per prop.
##
## Collision is one box round the model's bounds — enough to stand on a car,
## hide behind a skip, and stop a bullet. Small clutter passes `collide =
## false` so it never snags the player or a patrol.

const DIR := "res://assets/models/%s.glb"

## Kit -> metres per model unit.
const KIT_SCALE := {
	"car": 1.75,
	"retro_urban": 3.0,
	"survival": 2.6,
	"furniture": 2.0,
	"city_commercial": 14.0,
	"city_industrial": 9.0,
	"city_suburban": 9.0,
}

static var _scenes: Dictionary = {}

## `id` is "kit/model", e.g. "car/sedan". Yaw in degrees, 0 = model as
## authored (Kenney vehicles face +z). `max_h` caps the finished height in
## metres (the scale shrinks to fit); `exact` builds collision from the mesh
## itself instead of one box — a truck's cab is not its cargo box.
static func place(parent: Node3D, id: String, pos: Vector3, yaw_deg: float = 0.0,
		scale: float = 0.0, collide: bool = true, max_h: float = 0.0,
		exact: bool = false) -> Node3D:
	var ps := _scene(id)
	if ps == null:
		return null
	var model := ps.instantiate() as Node3D
	var box := bounds(model, Transform3D.IDENTITY)
	var s := scale if scale > 0.0 else float(KIT_SCALE.get(id.get_slice("/", 0), 1.0))
	if max_h > 0.0 and box.size.y * s > max_h:
		s = max_h / box.size.y
	var holder := Node3D.new()
	holder.name = id.get_slice("/", 1)
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw_deg)
	holder.scale = Vector3.ONE * s
	parent.add_child(holder)
	holder.add_child(model)
	_lit(model)
	# Bottom-centre of the bounds onto the holder's origin.
	model.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z)
	if collide and box.size.length() > 0.01:
		var body := StaticBody3D.new()
		holder.add_child(body)
		if exact:
			_mesh_collision(body, model)
		else:
			var cs := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = box.size
			cs.shape = shape
			cs.position = Vector3(0, box.size.y * 0.5, 0)
			body.add_child(cs)
	return holder

## A parked vehicle at the kit's natural scale — no height cap, so a van is
## as tall as it looks — with collision built from the bodywork's own mesh, so
## the hitbox is the geometry (you can stand on a bonnet, walk under nothing,
## and a shot hits what you see).
const VEHICLE_SCALE := 1.4   # one scale for all, so a van stays taller than a sedan

static func vehicle(parent: Node3D, id: String, pos: Vector3, yaw_deg: float = 0.0,
		scale: float = VEHICLE_SCALE) -> Node3D:
	return place(parent, id, pos, yaw_deg, scale, true, 0.0, true)

## Some Kenney kits ship unshaded materials (the retro-urban trees, lamp
## posts): full-bright in a night level, and blooming. Make them take light.
static var _lit_cache: Dictionary = {}

static func _lit(model: Node3D) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i) as StandardMaterial3D
			if m == null or m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			if not _lit_cache.has(m):
				var d := m.duplicate() as StandardMaterial3D
				d.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				d.roughness = 0.9
				_lit_cache[m] = d
			(mi as MeshInstance3D).set_surface_override_material(i, _lit_cache[m])

## A tree: the trunk collides, the canopy does not. The whole tree used to be
## one box, so a tree beside the deck-access stair walled it off.
static func tree(parent: Node3D, id: String, pos: Vector3, yaw_deg: float,
		scale: float) -> Node3D:
	var t := place(parent, id, pos, yaw_deg, scale, false)
	if t == null:
		return null
	# Sized in model units: the holder's scale carries it to metres.
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.3 / t.scale.x
	shape.height = 3.0 / t.scale.x
	cs.shape = shape
	cs.position = Vector3(0, 1.5 / t.scale.x, 0)
	body.add_child(cs)
	t.add_child(body)
	return t

## One trimesh per mesh of `model`, in the model's own space (the holder's
## scale carries it to metres).
static func _mesh_collision(body: StaticBody3D, model: Node3D) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var cs := CollisionShape3D.new()
		cs.shape = m.mesh.create_trimesh_shape()
		cs.transform = _rel(model, m)
		body.add_child(cs)

## `m`'s transform relative to the holder (model position + chain to m).
static func _rel(model: Node3D, m: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = m
	while n != null and n != model.get_parent():
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

## Places the same model at each [pos, yaw] in `spots`.
static func scatter(parent: Node3D, id: String, spots: Array, scale: float = 0.0,
		collide: bool = true) -> void:
	for s in spots:
		place(parent, id, s[0], float(s[1]) if s.size() > 1 else 0.0, scale, collide)

static func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		var path := DIR % id
		_scenes[id] = load(path) as PackedScene if ResourceLoader.exists(path) else null
		if _scenes[id] == null:
			push_warning("Props: missing model %s" % path)
	return _scenes[id]

## Merged mesh bounds of `n` and its children, in the space of `xf`.
static func bounds(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var found := false
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		found = true
	for c in n.get_children():
		var a := bounds(c, t)
		if a.size != Vector3.ZERO:
			out = a if not found else out.merge(a)
			found = true
	return out
