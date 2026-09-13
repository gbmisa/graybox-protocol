class_name GuardBody
extends Node
## Guard visuals: the low-poly box figure, its collision capsule, the state
## indicator above its head, hit flash and the death animation.

const BASE_COLOR := Color(0.55, 0.12, 0.12)
const LIMB_COLOR := Color(0.45, 0.10, 0.10)
const AIM_COLOR := Color(1.00, 0.52, 0.18)

var guard: Guard
var _indicator: Label3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D

func setup(p_guard: Guard) -> void:
	guard = p_guard
	_build_meshes()
	_build_collision()
	_build_indicator()

func _build_meshes() -> void:
	_body_mesh = _box(Vector3(0.7, 1.7, 0.4), BASE_COLOR, 0.95)
	guard.add_child(_body_mesh)
	_head_mesh = _box(Vector3(0.4, 0.35, 0.35), BASE_COLOR, 1.95)
	guard.add_child(_head_mesh)
	for x in [-0.45, 0.45]:
		var arm := _box(Vector3(0.25, 0.6, 0.25), LIMB_COLOR, 1.3)
		arm.position.x = x
		guard.add_child(arm)

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	guard.add_child(col)

func _build_indicator() -> void:
	_indicator = Label3D.new()
	_indicator.position = Vector3(0, 2.4, 0)
	_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicator.no_depth_test = true
	_indicator.pixel_size = 0.01
	_indicator.font_size = 96
	_indicator.modulate = Color.YELLOW
	_indicator.visible = false
	guard.add_child(_indicator)

func _box(size: Vector3, color: Color, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = Vector3(0, y, 0)
	return mi

## "?" while investigating, "!" once alerted, blank on patrol.
func set_indicator(text: String, color: Color) -> void:
	if _indicator == null:
		return
	_indicator.visible = not text.is_empty()
	_indicator.text = text
	_indicator.modulate = color

## The wind-up tell. The guard goes orange and the indicator switches to a
## reticle for the duration of the aim, which is the only cue the player gets
## that a shot is coming — and the thing the Wizard's dash is timed against.
func set_aiming(on: bool) -> void:
	if on:
		set_indicator("◎", AIM_COLOR)
		_tint(AIM_COLOR)
	else:
		set_indicator("!", Color.RED)
		_tint(BASE_COLOR)

func _tint(color: Color) -> void:
	for m in [_body_mesh, _head_mesh]:
		if m != null:
			(m.material_override as StandardMaterial3D).albedo_color = color

func flash_hit() -> void:
	if _body_mesh == null or _head_mesh == null:
		return
	var tw := guard.create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body_mesh, "material_override:albedo_color", Color.WHITE, 0.05)
	tw.tween_property(_head_mesh, "material_override:albedo_color", Color.WHITE, 0.05)
	tw.chain().tween_property(
		_body_mesh, "material_override:albedo_color", BASE_COLOR, 0.15)
	tw.parallel().tween_property(
		_head_mesh, "material_override:albedo_color", BASE_COLOR, 0.15)

func play_death() -> void:
	set_indicator("", Color.YELLOW)
	var tw := guard.create_tween()
	tw.tween_property(guard, "rotation:x", -PI / 2.0, 0.4)
	tw.tween_interval(1.5)
	tw.tween_callback(guard.queue_free)
