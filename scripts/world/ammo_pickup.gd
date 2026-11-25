class_name AmmoPickup
extends Area3D
## The ammo box a dead guard drops: spins, glows, and walking over it tops up
## the guns it has rounds for (WeaponData.DROP: since r9, his pistol only).

var amounts: Dictionary = {}
var _mesh: MeshInstance3D
var _t: float = 0.0

## `root`: where to put it (a cache placed while the level builds, at exactly
## `pos`); otherwise it lands on the floor under `pos` in the live level.
static func drop(game: GrayboxGame, pos: Vector3, p_amounts: Dictionary,
		root: Node3D = null) -> AmmoPickup:
	if game == null or (game.level_root == null and root == null):
		return null
	var a := AmmoPickup.new()
	a.add_to_group("ammo_pickup")
	a.amounts = p_amounts.duplicate()
	a.collision_layer = 0
	a.collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.9
	cs.shape = sh
	cs.position = Vector3(0, 0.5, 0)
	a.add_child(cs)
	a._mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.2, 0.22)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.32, 0.36, 0.16)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.15)
	m.emission_energy_multiplier = 0.6
	bm.material = m
	a._mesh.mesh = bm
	a._mesh.position = Vector3(0, 0.35, 0)
	a.add_child(a._mesh)
	var stripe := Label3D.new()
	stripe.text = _label(p_amounts)
	stripe.font_size = 28
	stripe.pixel_size = 0.004
	stripe.modulate = Color(1.0, 0.85, 0.2)
	stripe.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stripe.position = Vector3(0, 0.65, 0)
	a.add_child(stripe)
	if root != null:
		root.add_child(a)
		a.position = pos
		a.body_entered.connect(a._on_body)
		return a
	game.level_root.add_child(a)
	# On the floor under the body, a little to the side so it isn't hidden.
	var from := pos + Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5))
	var q := PhysicsRayQueryParameters3D.create(from, from - Vector3(0, 4, 0))
	q.collision_mask = 1
	var hit := game.level_root.get_world_3d().direct_space_state.intersect_ray(q)
	a.global_position = (hit["position"] as Vector3) if not hit.is_empty() else pos
	a.body_entered.connect(a._on_body)
	return a

func _process(delta: float) -> void:
	_t += delta
	_mesh.rotation.y = _t * 2.0
	_mesh.position.y = 0.35 + sin(_t * 3.0) * 0.05

func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var p := body as Player
	var w: PlayerWeapons = p.kit.get("weapons")
	if w == null:
		return
	if not w.add_ammo(amounts):
		p.game.hud.show_message("NO GUN FOR THESE", 1.2)
		return
	AudioSynth.play(p.game, "pickup", -4.0)
	p.game.hud.show_message("+ %s" % _describe(), 1.2)
	queue_free()

static func _label(am: Dictionary) -> String:
	if am.size() != 1:
		return "AMMO"
	return String(WeaponData.get_weapon(String(am.keys()[0])).get("ammo", "AMMO"))

func _describe() -> String:
	var parts: Array = []
	for id in amounts:
		parts.append("%d %s" % [int(amounts[id]), String(WeaponData.get_weapon(id)["name"])])
	return ", ".join(parts)
