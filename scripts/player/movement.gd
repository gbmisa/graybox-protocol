class_name PlayerMovement
extends Node
## Ground movement, gravity, jumping, and the crouch/crawl capsule.
##
## The capsule resize is load-bearing design, not polish. Crawl gaps in the
## level are 1.0m openings and each operative has a different crouched height
## (VerbData.crouch_height): the Regular and Wizard shrink to 0.85m and fit,
## Chad only reaches 1.45m and does not. No script checks who is allowed
## through a crawl gap — the collision shape decides.

const RESIZE_SPEED := 14.0
const STAND_CHECK_MARGIN := 0.05
const STEP_HEIGHT := 0.45
const STEP_REACH := 0.55

var player: Player
var crouching: bool = false
var is_sprinting: bool = false

var _stand_h: float = VerbData.STAND_H
var _crouch_h: float = 0.85
var _blocked_above: bool = false

func setup(p_player: Player) -> void:
	player = p_player
	_crouch_h = VerbData.crouch_height(player.char_id)

func tick(delta: float) -> void:
	# While the kit is driving velocity (the Wizard's dash) we only burn the
	# timer; the kit owns movement for those frames.
	if player.movement_suspend > 0.0:
		player.movement_suspend -= delta
		return
	_update_stance(delta)
	_apply_horizontal(delta)
	_apply_vertical(delta)
	_try_step_up()

# ------------------------------------------------------------- crouch ---
func _update_stance(delta: float) -> void:
	var want_crouch := Input.is_action_pressed("crouch")
	# Cannot stand up under a low ceiling — this is what keeps you from
	# clipping out of a crawl tunnel by releasing the key.
	_blocked_above = false
	if not want_crouch and crouching:
		_blocked_above = _ceiling_blocks_standing()
	crouching = want_crouch or _blocked_above
	var target_h := _crouch_h if crouching else _stand_h
	_resize_capsule(target_h, delta)
	_update_eye_height(target_h, delta)

func _resize_capsule(target_h: float, delta: float) -> void:
	var cap := player.collider.shape as CapsuleShape3D
	if cap == null:
		return
	var h := lerpf(cap.height, target_h, minf(1.0, RESIZE_SPEED * delta))
	if absf(h - target_h) < 0.01:
		h = target_h
	cap.height = h
	# Capsule origin sits at the player's feet, so the shape centre is h/2.
	player.collider.position.y = h * 0.5

func _update_eye_height(target_h: float, delta: float) -> void:
	var tuning := AbilityData.player()
	var eye: float = float(tuning["eye_stand"])
	if crouching:
		# Eye rides just under the crown of the capsule, so Chad's crouch
		# still reads as much taller than the Regular's.
		eye = maxf(0.45, target_h - 0.2)
	player.head.position.y = lerpf(
		player.head.position.y, eye, minf(1.0, RESIZE_SPEED * delta))

# ------------------------------------------------------------- step up ---
## CharacterBody3D will not climb even a small ledge on its own, so anything
## with a vertical face — a kerb, a 0.4m lip from a container onto a floor
## plate — has to be jumped. This lifts the body over low obstacles it is
## walking into. Staircases are ramps (see BuildUtils.stairs) and never rely
## on this; it exists for incidental geometry.
func _try_step_up() -> void:
	if not player.is_on_floor():
		return
	var horiz := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horiz.length() < 0.5:
		return
	var dir := horiz.normalized()
	var feet := player.global_position
	# Blocked low but clear at step height? Then it is a ledge, not a wall.
	if _probe(feet + Vector3(0, 0.1, 0), dir).is_empty():
		return
	if not _probe(feet + Vector3(0, STEP_HEIGHT + 0.1, 0), dir).is_empty():
		return
	var above := feet + dir * STEP_REACH + Vector3(0, STEP_HEIGHT + 0.25, 0)
	var top := _ray(above, above - Vector3(0, STEP_HEIGHT + 0.5, 0))
	if top.is_empty():
		return
	var lift: float = (top["position"] as Vector3).y - feet.y
	if lift <= 0.02 or lift > STEP_HEIGHT:
		return
	player.global_position.y += lift + 0.02

func _probe(from: Vector3, dir: Vector3) -> Dictionary:
	return _ray(from, from + dir * STEP_REACH)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(q)

func _ceiling_blocks_standing() -> bool:
	var from := player.global_position + Vector3(0, _crouch_h, 0)
	var to := player.global_position + Vector3(0, _stand_h + STAND_CHECK_MARGIN, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [player.get_rid()]
	return not player.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# --------------------------------------------------------- horizontal ---
func _apply_horizontal(delta: float) -> void:
	var f := Input.get_action_strength("move_forward") \
		- Input.get_action_strength("move_back")
	var s := Input.get_action_strength("move_right") \
		- Input.get_action_strength("move_left")
	is_sprinting = player.kit.allows_sprint() \
		and Input.is_action_pressed("sprint") and f > 0.1 and not crouching
	var speed := _current_speed()
	var yaw := player.rotation.y
	var dir := Vector3(
		-sin(yaw) * f + cos(yaw) * s,
		0.0,
		-cos(yaw) * f - sin(yaw) * s)
	if dir.length() > 1.0:
		dir = dir.normalized()
	var accel: float = float(player.char["accel"]) if player.is_on_floor() \
		else float(player.char["air_accel"])
	player.velocity.x = move_toward(
		player.velocity.x, dir.x * speed, accel * speed * delta)
	player.velocity.z = move_toward(
		player.velocity.z, dir.z * speed, accel * speed * delta)

func _current_speed() -> float:
	var speed := float(player.char["speed"]) * float(player.armor["speed_mul"])
	if is_sprinting:
		speed *= float(player.char["sprint_mul"])
	if crouching:
		speed *= float(AbilityData.player()["crouch_speed_mul"])
	return speed

# ----------------------------------------------------------- vertical ---
func _apply_vertical(delta: float) -> void:
	var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not player.is_on_floor():
		player.velocity.y -= grav * delta
	if Input.is_action_just_pressed("jump"):
		# A ledge in front always wins over a plain jump, so holding forward
		# into a wall and tapping jump climbs it instead of bouncing.
		if player.mantle.try_start():
			return
		if player.is_on_floor():
			player.velocity.y = float(player.char["jump_v"])
