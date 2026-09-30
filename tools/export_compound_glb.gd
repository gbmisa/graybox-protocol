extends SceneTree
## Writes HOLLOWAY CAMPUS's visible geometry to blender/holloway_campus.glb:
##
##     godot --headless --path . --script res://tools/export_compound_glb.gd
##
## One parent empty per section, so each `sec_cmp_*.gd` becomes its own
## hierarchy in Blender. Lamps, route points and declared doors from
## tools/smoketest_compound.gd come along as named empties, so the file shows
## where things are meant to connect, not just what exists. Collision is not
## exported — glTF round-trips drop it.

const OUT := "res://blender/holloway_campus.glb"

var sections := LevelCompound.sections()

func _initialize() -> void:
	var out := Node3D.new()
	out.name = "HollowayCampus"
	for sec_name in sections:
		var src := Node3D.new()
		root.add_child(src)
		sections[sec_name].build(src, null)
		var dst := _empty(out, sec_name, Vector3.ZERO)
		var lamps := _empty(dst, sec_name + "_lamps", Vector3.ZERO)
		var n := 0
		for node in src.find_children("*", "", true, false):
			if node is MeshInstance3D:
				n += 1
				_copy_mesh(dst, node as MeshInstance3D, _world(node, src), "%s_%03d" % [sec_name, n])
			elif node is OmniLight3D:
				_empty(lamps, "lamp", _world(node, src).origin)
		print("  %-12s %d meshes" % [sec_name, n])
	_markers(out)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(out, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(OUT))
	print("wrote %s (%s)" % [ProjectSettings.globalize_path(OUT), error_string(err)])
	quit(0 if err == OK else 1)

## Copies with the global transform baked in, and moves the colour onto the
## mesh itself: the builder sets material_override, which glTF may not carry.
func _copy_mesh(parent: Node3D, src: MeshInstance3D, xform: Transform3D, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh: Mesh = src.mesh.duplicate()
	if mesh is PrimitiveMesh and src.material_override != null:
		(mesh as PrimitiveMesh).material = src.material_override
	mi.mesh = mesh
	mi.transform = xform
	parent.add_child(mi)

## Nodes built in _initialize are not inside the tree yet, so global_transform
## reads as identity; compose the local transforms up to the section root.
func _world(node: Node3D, section_root: Node3D) -> Transform3D:
	var t := node.transform
	var p := node.get_parent()
	while p != section_root:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t

func _markers(out: Node3D) -> void:
	var consts: Dictionary = load("res://tools/smoketest_compound.gd").get_script_constant_map()
	var route := _empty(out, "route_points", Vector3.ZERO)
	for p in consts["POINTS"]:
		_empty(route, "pt " + String(p[0]), p[1])
	var doors := _empty(out, "declared_doors", Vector3.ZERO)
	for d in consts["DOORS"]:
		_empty(doors, "door " + String(d[0]).replace("<->", "-"), d[1] + Vector3(0, 0.9, 0))

func _empty(parent: Node3D, node_name: String, pos: Vector3) -> Node3D:
	var e := Node3D.new()
	e.name = node_name
	e.position = pos
	parent.add_child(e)
	return e
