class_name KeyItem
extends StaticBody3D
## A physical key pickup. Taking it adds the key to the player's inventory;
## doors listing "key:<id>" then open for that player as an alternate gate.

var game: GrayboxGame
var key_id: String = ""

static func create(p_game: GrayboxGame, parent: Node3D, id: String,
		pos: Vector3) -> KeyItem:
	var k := KeyItem.new()
	k.game = p_game
	k.key_id = id
	k.position = pos
	parent.add_child(k)
	k.add_to_group("key_item")
	# Key prop: small brass bow + shaft, floating over a crate-height plinth.
	var bow := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.11
	bow.mesh = torus
	var shaft := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.05, 0.22, 0.05)
	shaft.mesh = sbm
	shaft.position = Vector3(0, -0.16, 0)
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(0.85, 0.65, 0.25)
	kmat.metallic = 0.8
	kmat.roughness = 0.35
	kmat.emission_enabled = true
	kmat.emission = Color(0.85, 0.65, 0.25)
	kmat.emission_energy_multiplier = 0.7
	bow.material_override = kmat
	shaft.material_override = kmat
	var spin := Node3D.new()
	spin.position = Vector3(0, 1.0, 0)
	spin.add_child(bow)
	spin.add_child(shaft)
	spin.rotation_degrees.x = 90.0
	k.add_child(spin)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 1.4, 0.7)
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	k.add_child(col)
	BuildUtils.label(parent, KeyData.key_name(id), pos + Vector3(0, 1.65, 0), Color(0.85, 0.65, 0.25), 28)
	return k

func prompt_text() -> String:
	return "TAKE — %s" % KeyData.key_name(key_id)

func activate(player: Player) -> void:
	player.add_key(key_id)
	player.game.hud.add_killfeed("PICKED UP %s" % KeyData.key_name(key_id))
	AudioSynth.play(game, "unlock")
	queue_free()
