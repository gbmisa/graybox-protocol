class_name PlayerLook
extends Node
## Mouse aim and camera shake. Body yaw lives on the player, pitch on the
## camera, so movement direction always follows where you are facing.

const PITCH_LIMIT := 1.45
const SHAKE_DECAY := 1.8
const SHAKE_AMPLITUDE := 0.22

var player: Player
var shake: float = 0.0
## Camera punch from firing, in radians of pitch; springs back to zero. It
## rides on the head node so it never fights the mouse's pitch.
var recoil: float = 0.0

var _sens: float = 0.0022
## FOV multiplier, set by the viewmodel while aiming down sights.
var zoom: float = 1.0

func setup(p_player: Player) -> void:
	player = p_player
	_sens = float(AbilityData.player()["mouse_sens"])
	player.camera.fov = Settings.fov()

func handle_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var mm := event as InputEventMouseMotion
	# Read live, so OPTIONS from the pause menu applies on resume.
	var sens := _sens * Settings.sensitivity() * zoom
	var dy := -mm.relative.y if Settings.invert_y() else mm.relative.y
	player.rotate_y(-mm.relative.x * sens)
	player.camera.rotate_x(-dy * sens)
	if player.viewmodel != null:
		player.viewmodel.add_look(mm.relative)
	player.camera.rotation.x = clampf(
		player.camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)

func tick(delta: float) -> void:
	player.camera.fov = Settings.fov() * zoom
	recoil = move_toward(recoil, 0.0, (absf(recoil) * 9.0 + 0.02) * delta)
	player.head.rotation.x = recoil
	if shake <= 0.0:
		player.camera.position = Vector3.ZERO
		return
	player.camera.position = Vector3(
		randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) \
		* SHAKE_AMPLITUDE * shake
	shake = maxf(0.0, shake - delta * SHAKE_DECAY)

## Additive so overlapping hits stack rather than resetting each other.
func add_shake(amount: float) -> void:
	shake = minf(1.0, shake + amount)

func add_recoil(amount: float) -> void:
	recoil = clampf(recoil + amount, -0.12, 0.12)
