class_name GuardBrain
extends Node
## The patrol -> suspicious -> alert state machine and the movement each state
## drives. State itself lives on the Guard root; this decides what to do in it.

const ARRIVE_DIST := 0.8
const PATROL_WAIT := 1.0
const SCAN_TIME := 3.0
const CHASE_DIST := 14.0
const GIVE_UP_DIST := 45.0
const GIVE_UP_TIME := 6.0
const STRAFE_SWAP := 1.4
const STRAFE_SPEED := 3.5

var guard: Guard

var _wp_index: int = 0
var _wait: float = 0.0
var _look: float = 0.0
var _lose: float = 0.0
var _strafe_dir: float = 1.0
var _strafe_t: float = 0.0

func setup(p_guard: Guard) -> void:
	guard = p_guard

func tick(player: Player, delta: float) -> void:
	match guard.state:
		Guard.State.PATROL:
			_patrol(delta)
		Guard.State.SUSPICIOUS:
			_suspicious(delta)
		Guard.State.ALERT:
			_alert(player, delta)

func on_enter_alert() -> void:
	_lose = 0.0
	_strafe_t = 0.0
	guard.combat.reset_cooldown(0.5)

func on_enter_suspicious() -> void:
	_look = 0.0

# ---------------------------------------------------------------- patrol ---
func _patrol(delta: float) -> void:
	if guard.waypoints.is_empty():
		guard.stop()
		return
	var wp: Vector3 = guard.waypoints[_wp_index]
	var to := wp - guard.global_position
	to.y = 0.0
	if to.length() >= ARRIVE_DIST:
		_wait = 0.0
		guard.move_to(wp, float(GuardData.stats()["patrol_speed"]), delta)
		return
	# Pause at each end of the route before turning around.
	guard.stop()
	_wait += delta
	if _wait >= PATROL_WAIT:
		_wait = 0.0
		_wp_index = (_wp_index + 1) % guard.waypoints.size()

# ------------------------------------------------------------ suspicious ---
func _suspicious(delta: float) -> void:
	var to := guard.investigate_pos - guard.global_position
	to.y = 0.0
	if to.length() > 1.0:
		guard.move_to(guard.investigate_pos,
			float(GuardData.stats()["investigate_speed"]), delta)
		return
	# Arrived at the disturbance: sweep the area, then give up.
	guard.stop()
	_look += delta
	guard.rotate_y(1.2 * delta)
	if _look >= SCAN_TIME and guard.detect < 0.15:
		_look = 0.0
		guard.enter_patrol()

# ----------------------------------------------------------------- alert ---
func _alert(player: Player, delta: float) -> void:
	if player == null or not player.alive:
		_losing(delta)
		return
	var to_p: Vector3 = player.global_position - guard.global_position
	to_p.y = 0.0
	var dist := to_p.length()
	if dist > GIVE_UP_DIST:
		_losing(delta)
		return
	_lose = 0.0
	if dist > CHASE_DIST:
		guard.move_to(player.global_position,
			float(GuardData.stats()["chase_speed"]), delta)
	else:
		_strafe(to_p, delta)
	if dist > 0.01:
		guard.face(atan2(-to_p.x, -to_p.z), delta)
	guard.combat.tick(player, delta, dist)

## Circles the player at close range instead of walking straight in, so a
## cornered guard is still a moving target.
func _strafe(to_p: Vector3, delta: float) -> void:
	_strafe_t += delta
	if _strafe_t >= STRAFE_SWAP:
		_strafe_t = 0.0
		_strafe_dir = -_strafe_dir
	var dir := to_p.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x) * _strafe_dir
	guard.velocity.x = perp.x * STRAFE_SPEED
	guard.velocity.z = perp.z * STRAFE_SPEED

func _losing(delta: float) -> void:
	_lose += delta
	guard.stop()
	if _lose >= GIVE_UP_TIME:
		_lose = 0.0
		guard.enter_suspicious(guard.last_seen, 0.5)
