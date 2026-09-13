class_name Tracer
extends Node3D
## A brief bright line from muzzle to impact point.
##
## Guard fire is instant hitscan, so without a tracer there is nothing on
## screen to tell you a shot was taken, who took it, or where from. Combined
## with the aim telegraph in guard_combat.gd this is what makes incoming fire
## readable — and therefore dodgeable.

const LIFETIME := 0.09
const THICKNESS := 0.045

static func fire(parent: Node, from: Vector3, to: Vector3,
		color: Color = Color(1.0, 0.85, 0.45)) -> void:
	var length := from.distance_to(to)
	if length < 0.2:
		return
	var t := Tracer.new()
	parent.add_child(t)
	t.global_position = (from + to) * 0.5
	# look_at needs an up vector that is not parallel to the shot direction.
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	t.look_at(to, up)
	t._build(length, color)

func _build(length: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	# Node3D faces -Z, so the beam runs along local Z.
	bm.size = Vector3(THICKNESS, THICKNESS, length)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, LIFETIME)
	tw.tween_property(mi, "scale", Vector3(0.3, 0.3, 1.0), LIFETIME)
	tw.chain().tween_callback(queue_free)
