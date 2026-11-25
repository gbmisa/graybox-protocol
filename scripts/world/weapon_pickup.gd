class_name WeaponPickup
extends Area3D
## A gun lying where exploring pays (r8: level review "put the loadout in the
## world"; combat review "ammo and health are never scarce"). You start with
## the pistol and one grenade; everything else is found. Walk over it: you own
## the weapon (with a full mag and its starting reserve), or, if you already
## do, you take its rounds. Spins and glows; the label names the gun only.
##
## The places are MissionCompoundData.WEAPONS, each at the end of a detour.

var weapon_id: String = ""
var count: int = 1
var _mesh: Node3D
var _t: float = 0.0

static func place(game: GrayboxGame, root: Node3D, id: String, at: Vector3, p_count: int = 1) -> WeaponPickup:
	var w := WeaponPickup.new()
	w.weapon_id = id
	w.count = p_count
	w.add_to_group("weapon_pickup")
	w.collision_layer = 0
	w.collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.0
	cs.shape = sh
	cs.position = Vector3(0, 0.6, 0)
	w.add_child(cs)
	w._mesh = Node3D.new()
	w.add_child(w._mesh)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.16, 0.18) if id != "grenade" else Vector3(0.18, 0.18, 0.18)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.12, 0.14)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.25, 0.75)
	m.emission_energy_multiplier = 1.2
	bm.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	w._mesh.add_child(mi)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.3, 0.8)
	glow.light_energy = 1.5
	glow.omni_range = 3.0
	glow.position = Vector3(0, 0.6, 0)
	w.add_child(glow)
	var l := Label3D.new()
	l.text = String(WeaponData.get_weapon(id)["name"]) + ("" if p_count <= 1 else " x%d" % p_count)
	l.font_size = 32
	l.pixel_size = 0.005
	l.outline_size = 8
	l.modulate = Color(1.0, 0.5, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 1.1, 0)
	w.add_child(l)
	root.add_child(w)
	var q := PhysicsRayQueryParameters3D.create(at, at - Vector3(0, 6, 0))
	q.collision_mask = 1
	var hit := root.get_world_3d().direct_space_state.intersect_ray(q)
	w.global_position = (hit["position"] as Vector3) if not hit.is_empty() else at
	w.body_entered.connect(w._on_body)
	return w

func _process(delta: float) -> void:
	_t += delta
	_mesh.rotation.y = _t * 1.6
	_mesh.position.y = 0.55 + sin(_t * 2.5) * 0.08

func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var p := body as Player
	var w: PlayerWeapons = p.kit.get("weapons")
	if w == null:
		return
	var fresh := w.give(weapon_id, count)
	AudioSynth.play(p.game, "pickup", 0.0)
	p.game.hud.show_message(("NEW: %s  [%d]" if fresh else "+ %s  [%d]") % [
		String(WeaponData.get_weapon(weapon_id)["name"]), int(WeaponData.get_weapon(weapon_id)["slot"])], 2.0)
	queue_free()
