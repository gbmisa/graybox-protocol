class_name Explosion
extends RefCounted
## A blast at a point: damage falling off to nothing at `radius`, only to what
## the blast can reach (a wall in between shields you), knockback, gibs on
## overkill, a fireball, a light, smoke, a crater stain, shake and noise. It
## hurts the player too — stand back from your own grenade.

static func blast(game: GrayboxGame, pos: Vector3, w: Dictionary) -> void:
	var radius := float(w["radius"])
	var dmg := float(w["damage"])
	var space := game.level_root.get_world_3d().direct_space_state
	var bodies: Array = []
	for g in game.guards.duplicate():
		bodies.append(g)
	for c in game.civilians.duplicate():
		bodies.append(c)
	if game.target != null:
		bodies.append(game.target)
	for b in bodies:
		var n := b as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var at := n.global_position + Vector3(0, 1.0, 0)
		var d := at.distance_to(pos)
		if d > radius or not _reaches(space, pos, at, n):
			continue
		var hit := dmg * (1.0 - d / radius)
		var was_alive: bool = n.get("alive")
		if was_alive:
			n.call("take_damage", hit, pos)
			if n.has_method("apply_knockback"):
				n.call("apply_knockback", (at - pos).normalized() * float(w["knockback"]) * (1.0 - d / radius) + Vector3(0, 2.0, 0))
		if hit >= float(w["gib"]) or not was_alive:
			if not bool(n.get("alive")):
				Gore.gib(n, pos)
	var p := game.get_player()
	if p != null and p.alive:
		var pd := (p.global_position + Vector3(0, 1.0, 0)).distance_to(pos)
		if pd < radius and _reaches(space, pos, p.global_position + Vector3(0, 1.0, 0), p):
			p.take_damage(dmg * 0.6 * (1.0 - pd / radius))
			p.velocity += ((p.global_position - pos).normalized() + Vector3(0, 0.6, 0)) * 9.0 * (1.0 - pd / radius)
		p.add_shake(clampf(1.6 - pd / 20.0, 0.1, 1.2))
	game.emit_noise(pos, float(w["noise"]))
	game.panic_civilians(pos, 40.0)
	SoundAt.play(game, pos, "explosion", 4.0, randf_range(0.9, 1.05), 140.0)
	_fx(game.level_root, pos, radius)
	Gore.stain(game.level_root, pos, 2.0)

static func _reaches(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, n: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 0.2, 0), to)
	q.collision_mask = 1
	if n is CollisionObject3D:
		q.exclude = [(n as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(q)
	return hit.is_empty() or hit.get("collider") == n

static func _fx(root: Node3D, pos: Vector3, radius: float) -> void:
	var fire := CPUParticles3D.new()
	fire.one_shot = true
	fire.emitting = true
	fire.amount = 40
	fire.lifetime = 0.6
	fire.explosiveness = 1.0
	fire.direction = Vector3.UP
	fire.spread = 180.0
	fire.initial_velocity_min = 4.0
	fire.initial_velocity_max = radius * 1.6
	fire.gravity = Vector3(0, 2.0, 0)
	fire.scale_amount_min = 1.0
	fire.scale_amount_max = 3.0
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.12)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.5, 0.1)
	m.emission_energy_multiplier = 4.0
	sm.material = m
	fire.mesh = sm
	fire.color_ramp = _ramp(Color(1.0, 0.95, 0.6), Color(0.25, 0.08, 0.02, 0.0))
	fire.position = pos
	root.add_child(fire)
	var smoke := fire.duplicate() as CPUParticles3D
	smoke.amount = 24
	smoke.lifetime = 2.6
	smoke.initial_velocity_max = 3.0
	smoke.gravity = Vector3(0, 1.2, 0)
	var sm2 := sm.duplicate() as SphereMesh
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color(0.12, 0.11, 0.12, 0.8)
	m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.vertex_color_use_as_albedo = true
	sm2.material = m2
	smoke.mesh = sm2
	smoke.color_ramp = _ramp(Color(0.3, 0.3, 0.3, 0.9), Color(0.1, 0.1, 0.1, 0.0))
	smoke.emitting = true
	root.add_child(smoke)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 12.0
	light.omni_range = radius * 3.0
	light.position = pos + Vector3(0, 0.5, 0)
	root.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.5)
	tw.tween_callback(light.queue_free)
	root.get_tree().create_timer(3.5).timeout.connect(fire.queue_free)
	root.get_tree().create_timer(3.5).timeout.connect(smoke.queue_free)

static func _ramp(a: Color, b: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	return g
