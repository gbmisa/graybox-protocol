class_name PlayerMovement
extends Node
## Ground movement, gravity, jumping, and the crouch/crawl/squeeze capsule.
##
## The capsule resize is load-bearing design, not polish. Crawl gaps in the
## level are 1.0m openings and each operative has a different crouched height
## (VerbData.crouch_height): the Regular and Wizard shrink to 0.85m and fit,
## Chad only reaches 1.45m and does not. The Wizard alone has a third stance,
## the squeeze (0.5m tall, 0.25 radius, held key), which fits 0.6m gaps and
## costs mana while held. No script checks who is allowed through a gap —
## the collision shape decides.

const RESIZE_SPEED := 14.0
const STAND_CHECK_MARGIN := 0.05
## The world's 9.8 is for physics props; a body that floats that long feels
## like the moon. Jump speeds in characters.gd are tuned against this.
const PLAYER_GRAVITY := 24.0
const FALL_MUL := 1.35
const STEP_HEIGHT := 0.45
const STEP_REACH := 0.55
const MAX_AIR_SPEED := 16.0

enum Stance { STAND, CROUCH, SQUEEZE }

var player: Player
var crouching: bool = false      # true while crouched OR squeezed
var squeezing: bool = false
var is_sprinting: bool = false
var on_ladder: bool = false
## Set by a kick launch or the grappling hook: in the air, input only steers
## and never brakes the body, until it lands.
var keep_momentum: bool = false
## Seconds a launch survives touching the floor (a kick off the ground starts
## on it, and would be braked to nothing the very next frame).
var momentum_lock: float = 0.0
## Height of the floor at the last frame the body stood on one. The mantle
## measures rise from here so a jump adds nothing to its reach (D14).
var last_floor_y: float = INF

var _stance: int = Stance.STAND
var _stand_h: float = VerbData.STAND_H
var _crouch_h: float = 0.85
var _squeeze_h: float = 0.0
var _squeeze_r: float = VerbData.BODY_RADIUS

func setup(p_player: Player) -> void:
	player = p_player
	_crouch_h = VerbData.crouch_height(player.char_id)
	_squeeze_h = VerbData.squeeze_height(player.char_id)
	_squeeze_r = VerbData.squeeze_radius(player.char_id)

func tick(delta: float) -> void:
	if player.is_on_floor():
		last_floor_y = player.global_position.y
	# While the kit is driving velocity (the Wizard's dash) we only burn the
	# timer; the kit owns movement for those frames.
	if player.movement_suspend > 0.0:
		player.movement_suspend -= delta
		return
	_update_stance(delta)
	_apply_horizontal(delta)
	if not _climb(delta):
		_apply_vertical(delta)
	_try_step_up()

# ------------------------------------------------------------- stance ---
func _update_stance(delta: float) -> void:
	var want := Stance.STAND
	if _squeeze_h > 0.0 and Input.is_action_pressed("squeeze") and player.mana > 0.0:
		want = Stance.SQUEEZE
	elif Input.is_action_pressed("crouch"):
		want = Stance.CROUCH
	# Cannot grow under a low ceiling — this is what keeps you from clipping
	# out of a crawl or squeeze by letting go of the key (or of the mana).
	while want < _stance and _ceiling_blocks(_height_for(want)):
		want += 1
	_stance = want
	squeezing = _stance == Stance.SQUEEZE
	crouching = _stance != Stance.STAND
	if squeezing:
		var rate := float(AbilityData.player()["squeeze_mana_per_s"])
		player.mana = maxf(0.0, player.mana - rate * delta)
	var target_h := _height_for(_stance)
	var target_r := _squeeze_r if squeezing else VerbData.BODY_RADIUS
	_resize_capsule(target_h, target_r, delta)
	_update_eye_height(target_h, delta)

func _height_for(stance: int) -> float:
	match stance:
		Stance.SQUEEZE: return _squeeze_h
		Stance.CROUCH: return _crouch_h
		_: return _stand_h

## Writes radius and height in the order Godot's clamp (radius <= height / 2)
## allows: radius first when shrinking, height first when growing.
func _resize_capsule(target_h: float, target_r: float, delta: float) -> void:
	var cap := player.collider.shape as CapsuleShape3D
	if cap == null:
		return
	var h := lerpf(cap.height, target_h, minf(1.0, RESIZE_SPEED * delta))
	if absf(h - target_h) < 0.01:
		h = target_h
	if target_r < cap.radius:
		cap.radius = target_r
		cap.height = h
	else:
		cap.height = h
		cap.radius = minf(target_r, h * 0.5)
	# Capsule origin sits at the player's feet, so the shape centre is h/2.
	player.collider.position.y = h * 0.5

func _update_eye_height(target_h: float, delta: float) -> void:
	var tuning := AbilityData.player()
	var eye: float = float(tuning["eye_stand"])
	if squeezing:
		eye = maxf(0.3, target_h - 0.15)
	elif crouching:
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
	q.collision_mask = VerbData.BODY_MASK
	return player.get_world_3d().direct_space_state.intersect_ray(q)

## Is there anything between the current crown and a crown `h` tall?
func _ceiling_blocks(h: float) -> bool:
	var cap := player.collider.shape as CapsuleShape3D
	var from := player.global_position + Vector3(0, cap.height - 0.02, 0)
	var to := player.global_position + Vector3(0, h + STAND_CHECK_MARGIN, 0)
	return not _ray(from, to).is_empty()

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
	momentum_lock = maxf(0.0, momentum_lock - delta)
	if player.is_on_floor() and momentum_lock <= 0.0:
		keep_momentum = false
	elif keep_momentum:
		player.velocity.x += dir.x * speed * 1.2 * delta
		player.velocity.z += dir.z * speed * 1.2 * delta
		# Steering can turn a launch but never feed it (combat review).
		var flat := Vector2(player.velocity.x, player.velocity.z)
		if flat.length() > MAX_AIR_SPEED:
			flat = flat.normalized() * MAX_AIR_SPEED
			player.velocity.x = flat.x
			player.velocity.z = flat.y
		return
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
	if squeezing:
		speed *= float(AbilityData.player()["squeeze_speed_mul"])
	elif crouching:
		speed *= float(AbilityData.player()["crouch_speed_mul"])
	return speed

# ------------------------------------------------------------- ladder ---
## On a Ladder zone: forward climbs, back descends, jump kicks off. Returns
## false off a ladder so the normal gravity/jump runs.
func _climb(_delta: float) -> bool:
	on_ladder = Ladder.at(player.global_position)
	if not on_ladder:
		return false
	var f := Input.get_action_strength("move_forward") \
		- Input.get_action_strength("move_back")
	if Input.is_action_just_pressed("jump"):
		var yaw := player.rotation.y
		player.velocity = Vector3(sin(yaw), 0, cos(yaw)) * 3.0 + Vector3(0, 4.0, 0)
		on_ladder = false
		return true
	player.velocity.y = f * Ladder.CLIMB_SPEED
	if player.is_on_floor() and f < 0.0:
		player.velocity.y = 0.0
	return true

# ----------------------------------------------------------- vertical ---
func _apply_vertical(delta: float) -> void:
	var grav := PLAYER_GRAVITY
	if not player.is_on_floor():
		# Heavier on the way down so a jump (or a walk off a crate) has weight
		# instead of hanging in the air.
		if player.velocity.y < 0.0:
			grav *= FALL_MUL
		player.velocity.y -= grav * delta
	if Input.is_action_just_pressed("jump"):
		# A ledge in front always wins over a plain jump, so holding forward
		# into a wall and tapping jump climbs it instead of bouncing.
		if player.mantle.try_start():
			return
		if player.is_on_floor():
			player.velocity.y = float(player.char["jump_v"])
