class_name Grenade
extends RigidBody3D
## A thrown frag: bounces off the level with a clack, beeps faster as the fuse
## runs down, then Explosion.blast. Bodies don't stop it (layer 1 only).

var game: GrayboxGame
var cfg: Dictionary
var _t: float = 0.0
var _beep: float = 0.0

static func throw(p_game: GrayboxGame, from: Vector3, vel: Vector3, p_cfg: Dictionary) -> Grenade:
	var g := Grenade.new()
	g.game = p_game
	g.cfg = p_cfg
	g.collision_layer = 0
	g.collision_mask = 1
	g.continuous_cd = true
	g.contact_monitor = true
	g.max_contacts_reported = 2
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.8
	g.physics_material_override = pm
	g.mass = 0.4
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.07
	cs.shape = sh
	g.add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.15
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.3, 0.15)
	sm.material = m
	mi.mesh = sm
	g.add_child(mi)
	var led := OmniLight3D.new()
	led.light_color = Color(1, 0.1, 0.05)
	led.light_energy = 0.8
	led.omni_range = 1.5
	led.name = "Led"
	g.add_child(led)
	p_game.level_root.add_child(g)
	g.global_position = from
	g.linear_velocity = vel
	g.angular_velocity = Vector3(randf(), randf(), randf()) * 8.0
	g.body_entered.connect(g._on_bump)
	return g

func _physics_process(delta: float) -> void:
	_t += delta
	var fuse := float(cfg["fuse"])
	_beep -= delta
	if _beep <= 0.0:
		_beep = lerpf(0.5, 0.08, _t / fuse)
		AudioSynth.play_at(self, "beep", -12.0, 1.0, 25.0)
		var led := get_node("Led") as OmniLight3D
		led.light_energy = 2.5
		create_tween().tween_property(led, "light_energy", 0.3, 0.06)
	if _t >= fuse:
		Explosion.blast(game, global_position, cfg)
		queue_free()

func _on_bump(_body: Node) -> void:
	if linear_velocity.length() > 2.0:
		AudioSynth.play_at(self, "clack", -6.0, randf_range(0.9, 1.15), 30.0)
