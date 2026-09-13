class_name IntelPickup
extends StaticBody3D
## A readable intel note: a small datapad the player aims at and reads with
## the interact key. Opens the HUD reading panel; never required, always
## tagged OPTIONAL INTEL in-world so it can't read as an objective.

var game: GrayboxGame
var intel_id: String = ""

static func create(p_game: GrayboxGame, parent: Node3D, id: String,
		pos: Vector3) -> IntelPickup:
	var p := IntelPickup.new()
	p.game = p_game
	p.intel_id = id
	p.position = pos
	parent.add_child(p)
	p.add_to_group("intel_pickup")
	# Datapad prop: dark slab with a lit screen.
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.05, 0.26)
	slab.mesh = bm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.10, 0.11, 0.14)
	smat.roughness = 0.6
	slab.material_override = smat
	slab.position = Vector3(0, 0.85, 0)
	p.add_child(slab)
	var screen := MeshInstance3D.new()
	var scm := BoxMesh.new()
	scm.size = Vector3(0.28, 0.012, 0.20)
	screen.mesh = scm
	var scmat := StandardMaterial3D.new()
	scmat.albedo_color = Color(0.55, 0.85, 1.0)
	scmat.emission_enabled = true
	scmat.emission = Color(0.45, 0.75, 1.0)
	scmat.emission_energy_multiplier = 1.6
	screen.material_override = scmat
	screen.position = Vector3(0, 0.882, 0)
	p.add_child(screen)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 1.2, 0.6)
	col.shape = shape
	col.position = Vector3(0, 0.85, 0)
	p.add_child(col)
	BuildUtils.label(parent, "OPTIONAL INTEL", pos + Vector3(0, 1.55, 0), Color(0.55, 0.85, 1.0), 28)
	return p

func prompt_text() -> String:
	return "READ — %s" % IntelData.title(intel_id)

func activate(player: Player) -> void:
	player.game.hud.show_intel(intel_id)
