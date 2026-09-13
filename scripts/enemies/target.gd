class_name Target
extends CharacterBody3D

# The assassination VIP. Unarmed: slow-patrols between points, never retaliates.
# Marked with a red "TARGET" label and a slowly rotating red marker above the head.

var alive: bool = true
var hp: float = 100.0
var game: GrayboxGame = null

var patrol_points: Array = []
var wp_index: int = 0

var _marker: MeshInstance3D = null


# ---------------------------------------------------------------- setup/visuals

func setup(p_game: GrayboxGame, pos: Vector3, p_patrol_points: Array) -> void:
	game = p_game
	patrol_points = p_patrol_points
	add_to_group("target")
	position = pos


func _ready() -> void:
	# Suit: dark-gray box centered at y ~0.95
	var suit := _make_box(Vector3(0.7, 1.7, 0.4), Color(0.15, 0.15, 0.15), 0.95)
	add_child(suit)
	# Head (tan/light skin)
	var head := _make_box(Vector3(0.4, 0.35, 0.35), Color(0.85, 0.7, 0.6), 1.95)
	add_child(head)
	# Arms (dark suit sleeves)
	add_child(_make_box(Vector3(0.25, 0.6, 0.25), Color(0.10, 0.10, 0.10), 1.3))
	add_child(_make_box(Vector3(0.25, 0.6, 0.25), Color(0.10, 0.10, 0.10), 1.3))
	# Red "TARGET" label above the head
	var label := Label3D.new()
	label.text = "TARGET"
	label.position = Vector3(0, 2.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	label.font_size = 64
	label.modulate = Color.RED
	add_child(label)
	# Slowly rotating red marker (diamond-ish box) above the label
	_marker = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.4, 0.4, 0.4)
	_marker.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.1, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.1, 0.1)
	_marker.material_override = m
	_marker.position = Vector3(0, 2.8, 0)
	_marker.rotation.z = PI / 4.0  # diamond tilt
	add_child(_marker)
	# Capsule collision
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)


func _make_box(size: Vector3, color: Color, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = Vector3(0, y, 0)
	return mi


# ---------------------------------------------------------------- main loop

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if alive and patrol_points.size() > 1 and game != null and game.is_playing():
		_update_patrol(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _process(delta: float) -> void:
	# Spin the floating marker (survives even when not playing)
	if _marker != null and alive:
		_marker.rotate_y(1.5 * delta)


func _update_patrol(delta: float) -> void:
	var wp: Vector3 = patrol_points[wp_index]
	var to := wp - global_position
	to.y = 0.0
	if to.length() < 0.6:
		wp_index = (wp_index + 1) % patrol_points.size()
		return
	var dir := to.normalized()
	velocity.x = dir.x * 1.2
	velocity.z = dir.z * 1.2
	var yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 6.0 * delta)


# ---------------------------------------------------------------- damage

func take_damage(dmg: float, from_pos: Vector3) -> void:
	if not alive:
		return
	hp -= dmg
	if hp <= 0.0:
		alive = false
		if _marker != null:
			_marker.queue_free()
		# Tip over, notify the game, keep the body briefly, then remove.
		collision_layer = 0
		collision_mask = 0
		var tween := create_tween()
		tween.tween_property(self, "rotation:x", -PI / 2.0, 0.4)
		game.on_target_killed()
		await tween.finished
		await get_tree().create_timer(2.0).timeout
		queue_free()
	else:
		# VIP is unarmed: no retaliation, just a hurt sound.
		AudioSynth.play(self, "hurt")
