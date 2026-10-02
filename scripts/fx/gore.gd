class_name Gore
extends RefCounted
## Blood, the Cruelty Squad way: a hit throws chunks, a kill throws a lot and
## leaves a stain that stays. Pure decoration — nothing here is gameplay.

const BLOOD := Color(0.55, 0.02, 0.04)
const MAX_STAINS := 60
static var _stains: Array = []

## A burst of red chunks at `pos`, thrown away from `from_pos`.
static func burst(parent: Node3D, pos: Vector3, from_pos: Vector3, amount: int) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = (pos - from_pos).normalized() + Vector3(0, 0.4, 0)
	p.spread = 55.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 5.5
	p.gravity = Vector3(0, -14.0, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.albedo_color = BLOOD
	m.roughness = 1.0
	bm.material = m
	p.mesh = bm
	p.position = pos
	parent.add_child(p)
	p.get_tree().create_timer(1.6).timeout.connect(p.queue_free)

## A flat red stain on the floor under `pos`.
static func stain(parent: Node3D, pos: Vector3, size: float = 1.1) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.5, 0), pos - Vector3(0, 2.5, 0))
	q.collision_mask = VerbData.SHOT_MASK
	var hit := (parent as Node3D).get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var s := size * randf_range(0.8, 1.3)
	bm.size = Vector3(s, 0.015, s * randf_range(0.6, 1.0))
	var m := StandardMaterial3D.new()
	m.albedo_color = BLOOD.darkened(randf_range(0.0, 0.3))
	m.roughness = 0.3
	bm.material = m
	mi.mesh = bm
	mi.rotation.y = randf() * TAU
	mi.position = (hit["position"] as Vector3) + Vector3(0, 0.012, 0)
	parent.add_child(mi)
	_stains.append(mi)
	if _stains.size() > MAX_STAINS:
		var old = _stains.pop_front()
		if is_instance_valid(old):
			old.queue_free()
