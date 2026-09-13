class_name CorpseMarker
extends Node3D
## What a dead guard leaves behind once the death animation finishes: a flat,
## dark marker on the floor that living guards can spot. Spotting is the
## quiet killer's tax — a body nobody sees costs nothing; a body a patrol
## walks past costs +15 alarm and an alerted guard.
##
## A marker is reported once, globally: the first guard to see it raises the
## alarm, every guard after that just sees a body.

var reported: bool = false

static func spawn(parent: Node, pos: Vector3) -> void:
	var m := CorpseMarker.new()
	m.position = Vector3(pos.x, pos.y + 0.06, pos.z)
	parent.add_child(m)
	m.add_to_group("corpses")

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.1, 0.12, 1.6)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.04, 0.04)
	mat.roughness = 0.9
	mi.material_override = mat
	add_child(mi)
