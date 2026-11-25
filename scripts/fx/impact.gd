class_name Impact
extends RefCounted
## Where a bullet lands: a spark puff, a bullet hole decal that stays a while
## (a ring buffer), and a ricochet tick. Bodies get blood from their own
## take_hit, so this only marks the world.

const MAX_HOLES := 80
static var _holes: Array = []

static func at(game: GrayboxGame, hit: Dictionary, from: Vector3) -> void:
	var col := hit.get("collider") as Node
	var pos: Vector3 = hit["position"]
	var n: Vector3 = hit.get("normal", Vector3.UP)
	if col != null and (col.is_in_group("guards") or col.is_in_group("civilians")
			or col.is_in_group("target")):
		return
	var root := game.level_root
	if root == null:
		return
	_sparks(root, pos, n)
	if n.length() > 0.5:
		_hole(root, pos, n)
	if randf() < 0.35:
		SoundAt.play(game, pos, "ricochet", -10.0, randf_range(0.9, 1.2), 30.0)

static func _sparks(root: Node3D, pos: Vector3, n: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = n
	p.spread = 40.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -12, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.025, 0.025, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.8, 0.4)
	bm.material = m
	p.mesh = bm
	p.position = pos + n * 0.03
	root.add_child(p)
	p.get_tree().create_timer(0.8).timeout.connect(p.queue_free)

static func _hole(root: Node3D, pos: Vector3, n: Vector3) -> void:
	var d := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	d.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.03)
	m.roughness = 1.0
	d.material_override = m
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(d)
	d.global_position = pos + n * 0.006
	var up := Vector3.UP if absf(n.y) < 0.95 else Vector3.FORWARD
	d.global_basis = Basis.looking_at(-n, up)
	_holes.append(d)
	while _holes.size() > MAX_HOLES:
		var old: Variant = _holes.pop_front()
		if is_instance_valid(old):
			(old as Node).queue_free()
