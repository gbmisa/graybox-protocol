class_name PlayerLook
extends Node
## Mouse aim and camera shake. Body yaw lives on the player, pitch on the
## camera, so movement direction always follows where you are facing.

const PITCH_LIMIT := 1.45
const SHAKE_DECAY := 1.8
const SHAKE_AMPLITUDE := 0.22

var player: Player
var shake: float = 0.0

var _sens: float = 0.0022

func setup(p_player: Player) -> void:
	player = p_player
	_sens = float(AbilityData.player()["mouse_sens"])

func handle_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var mm := event as InputEventMouseMotion
	player.rotate_y(-mm.relative.x * _sens)
	player.camera.rotate_x(-mm.relative.y * _sens)
	player.camera.rotation.x = clampf(
		player.camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)

func tick(delta: float) -> void:
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
