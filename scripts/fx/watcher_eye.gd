class_name WatcherEye
extends Node3D
## Something that turns to look at you: the giant eye on the courtyard mast,
## the CCTV cameras on the walls. Pure dressing — guards do their own seeing —
## but it is how the place feels watched. Turns smoothly, within `arc` of
## its rest yaw, and only while the player is within `reach`.

var reach := 45.0
var arc := PI * 0.75
var turn := 1.6            # radians per second
var _rest := Basis.IDENTITY
var _player: Node3D
var _glows: Array[StandardMaterial3D] = []
var powered := true

## A big eyeball: white, an emissive iris, a pupil. Faces -z at rest.
static func eyeball(parent: Node3D, pos: Vector3, radius: float, iris: Color) -> WatcherEye:
	var e := WatcherEye.new()
	e.position = pos
	parent.add_child(e)
	e._sphere(Vector3.ZERO, radius, Color(0.92, 0.9, 0.84), 0.0)
	e._sphere(Vector3(0, 0, -radius * 0.82), radius * 0.48, iris, 2.5, Vector3(1, 1, 0.35))
	e._sphere(Vector3(0, 0, -radius * 0.95), radius * 0.22, Color(0.02, 0.02, 0.03), 0.0,
		Vector3(1, 1, 0.3))
	e.add_to_group("watcher_eye")
	return e

## A wall camera: housing, lens, a red tally light. Faces -z at rest.
static func camera(parent: Node3D, pos: Vector3, yaw: float) -> WatcherEye:
	var e := WatcherEye.new()
	e.position = pos
	e.rotation.y = yaw
	parent.add_child(e)
	BuildUtils.box(e, Vector3(0, 0, -0.1), Vector3(0.22, 0.2, 0.45), Color(0.82, 0.82, 0.78), false)
	BuildUtils.box(e, Vector3(0, 0, -0.34), Vector3(0.14, 0.14, 0.05), Color(0.05, 0.05, 0.06), false)
	e._sphere(Vector3(0.07, 0.08, -0.3), 0.025, Color(1.0, 0.1, 0.1), 4.0)
	e.add_to_group("cctv")
	e.reach = 20.0
	e.arc = PI * 0.4
	return e

func _ready() -> void:
	_rest = transform.basis

func _sphere(at: Vector3, r: float, color: Color, glow: float, squash := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.35
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
		_glows.append(m)
	mi.material_override = m
	mi.position = at
	mi.scale = squash
	add_child(mi)

## The Score is wiped (Surveillance.blackout) or its isolator thrown: the
## light goes out, it sags on its mount and stops following anyone. An
## eyeball's white goes grey too, so it reads as dead, not asleep.
func power_off() -> void:
	if not powered:
		return
	powered = false
	for m in _glows:
		m.emission_enabled = false
		m.albedo_color = m.albedo_color.darkened(0.7)
	for c in get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.material_override is StandardMaterial3D and mi.mesh is SphereMesh:
			var m := mi.material_override as StandardMaterial3D
			if not m.emission_enabled and m.albedo_color.v > 0.5:
				m.albedo_color = Color(0.35, 0.33, 0.30)
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", rotation.x - 0.7, 1.2) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not powered:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var target := _rest
	var to := _player.global_position + Vector3(0, 1.5, 0) - global_position
	if to.length() < reach and to.length() > 0.5:
		var want := Basis.looking_at(to.normalized(), Vector3.UP)
		# Stay within `arc` of where it was mounted looking.
		var rest_fwd := -(get_parent_node_3d().global_basis * _rest).z if get_parent_node_3d() else -_rest.z
		if rest_fwd.angle_to(to.normalized()) < arc:
			target = (get_parent_node_3d().global_basis.inverse() * want) if get_parent_node_3d() else want
	var q := transform.basis.get_rotation_quaternion().slerp(
		target.get_rotation_quaternion(), minf(1.0, turn * delta))
	transform.basis = Basis(q)
