class_name GuardBrain
extends Node
## The patrol -> suspicious -> alert state machine and the movement each state
## drives. State itself lives on the Guard root; this decides what to do in it.

const ARRIVE_DIST := 0.8
const SCAN_TIME := 3.0
const CHASE_DIST := 14.0
const GIVE_UP_DIST := 45.0
const GIVE_UP_TIME := 6.0
const STRAFE_SWAP := 1.4
const STRAFE_SPEED := 3.5
const LEASH := 5.0           # a guard on a post fights within this of it
const HOLD_LOOK := 2.5       # seconds he watches where he lost you before falling back
const HOLD_CALM := 20.0      # unseen this long, he stands down at his post

var guard: Guard

var _wp_index: int = 0
var _wait: float = 0.0
var _look: float = 0.0
var _lose: float = 0.0
var _strafe_dir: float = 1.0
var _strafe_t: float = 0.0
var _run_t: float = 0.0
var _unseen: float = 0.0
var _chatter_t: float = randf_range(8.0, 25.0)

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
	_run_t = 0.0
	_lose = 0.0
	_strafe_t = 0.0
	guard.combat.reset_cooldown(0.5)

func on_enter_suspicious() -> void:
	_look = 0.0

func reset_route() -> void:
	_wp_index = 0
	_wait = 0.0

# ---------------------------------------------------------------- patrol ---
## A sentry (one waypoint) or the end of a one-way route holds its post and
## turns back to its facing every frame — re-applied here, on the way back to
## PATROL, because an investigation spins the guard and would otherwise leave
## him facing wherever the scan stopped (H4).
func _patrol(delta: float) -> void:
	_chatter(delta)
	if guard.waypoints.is_empty():
		guard.stop()
		return
	var wp: Vector3 = guard.waypoints[_wp_index]
	var to := wp - guard.global_position
	to.y = 0.0
	if to.length() >= ARRIVE_DIST:
		_wait = 0.0
		# Called to a post: he hurries.
		var key := "investigate_speed" if guard.hold_pos != Vector3.INF else "patrol_speed"
		guard.move_to(wp, float(GuardData.stats()[key]), delta)
		return
	guard.stop()
	var at_end := _wp_index == guard.waypoints.size() - 1
	if guard.waypoints.size() == 1 or (guard.one_way and at_end):
		if guard.has_facing:
			guard.face(guard.facing, delta)
		return
	if guard.one_way:
		_wp_index += 1
		return
	# Pause at each end of the route before turning around.
	_wait += delta
	if _wait >= guard.wait_at(_wp_index):
		_wait = 0.0
		_wp_index = (_wp_index + 1) % guard.waypoints.size()

## Idle talk, only when the player is close enough to overhear it.
func _chatter(delta: float) -> void:
	_chatter_t -= delta
	if _chatter_t > 0.0:
		return
	_chatter_t = randf_range(18.0, 35.0)
	var p := guard.game.get_player()
	if p != null and p.global_position.distance_to(guard.global_position) < 16.0:
		guard.bark("patrol")

# ------------------------------------------------------------ suspicious ---
func _suspicious(delta: float) -> void:
	var to := guard.investigate_pos - guard.global_position
	to.y = 0.0
	if to.length() > 1.0 and not (to.length() < 3.5 and _spot_taken()):
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

## Someone else is already standing on the spot: close enough, look around
## from here rather than queueing to stand where he stands.
func _spot_taken() -> bool:
	for g in guard.game.guards:
		var o := g as Guard
		if o != guard and o.alive and o.global_position.distance_to(guard.investigate_pos) < 1.5:
			return true
	return false

# ----------------------------------------------------------------- alert ---
func _alert(player: Player, delta: float) -> void:
	if guard.alarm_run and _run_to_station(delta):
		return
	if guard.hold_pos != Vector3.INF:
		_hold(player, delta)
		return
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
	# Close but with a wall between: strafing would circle on the spot.
	if dist > CHASE_DIST or not _sees(player):
		guard.move_to(player.global_position,
			float(GuardData.stats()["chase_speed"]), delta)
	else:
		_strafe(to_p, delta)
	if dist > 0.01:
		guard.face(atan2(-to_p.x, -to_p.z), delta)
	guard.combat.tick(player, delta, dist)

func _sees(player: Player) -> bool:
	var from := guard.global_position + Vector3(0, 1.4, 0)
	return guard.ray(from, player.global_position + Vector3(0, 1.0, 0),
		[player.get_rid()]).is_empty()

## An alerted guard's first job is the alarm: run to the nearest station on
## his floor and press it. He does not shoot while he runs — which is the
## window to drop him. Gives up after RUN_TIME (blocked, or too far) and fights.
const RUN_TIME := 15.0
const PRESS_DIST := 1.3

func _run_to_station(delta: float) -> bool:
	if guard.game.alert.is_alarm():
		guard.alarm_run = false
		return false
	_run_t += delta
	var st := guard.game.nearest_station(guard.global_position)
	if st == null or _run_t > RUN_TIME or not _claim(st):
		guard.alarm_run = false
		return false
	var to := st.global_position - guard.global_position
	to.y = 0.0
	if to.length() > PRESS_DIST:
		guard.move_to(st.global_position,
			float(GuardData.stats()["chase_speed"]) * 1.1, delta)
		return true
	guard.stop()
	guard.alarm_run = false
	st.press()
	guard.game.alert.raise("ALARM STATION")
	return true

## One runner per station — a second would only queue at it. He fights instead.
func _claim(st: AlarmStation) -> bool:
	var r: Variant = st.get_meta("runner", null)
	if r != null and r != guard and is_instance_valid(r) and (r as Guard).alive \
			and (r as Guard).alarm_run:
		return false
	st.set_meta("runner", guard)
	return true

## Alerted on a post: shoot from it, never chase out. Lose sight and he watches
## a moment, falls back to the post facing the way in, then stands down there.
func _hold(player: Player, delta: float) -> void:
	var alive := player != null and player.alive
	var to_p := Vector3(player.global_position - guard.global_position) * Vector3(1, 0, 1) if alive else Vector3.ZERO
	var sees := alive and to_p.length() < GIVE_UP_DIST and _sees(player)
	_unseen = 0.0 if sees else _unseen + delta
	var off := guard.hold_pos - guard.global_position
	off.y = 0.0
	if sees:
		if off.length() > LEASH:
			guard.move_to(guard.hold_pos, float(GuardData.stats()["chase_speed"]), delta)
		elif to_p.length() < CHASE_DIST:
			_strafe(to_p, delta)
		else:
			guard.stop()
		guard.face(atan2(-to_p.x, -to_p.z), delta)
		guard.combat.tick(player, delta, to_p.length())
		return
	if _unseen < HOLD_LOOK:
		guard.stop()
		return
	if off.length() > ARRIVE_DIST:
		guard.move_to(guard.hold_pos, float(GuardData.stats()["chase_speed"]), delta)
	else:
		guard.stop()
		guard.face(guard.hold_yaw, delta)
	if _unseen > HOLD_CALM:
		_unseen = 0.0
		guard.enter_patrol()

## Circles the player at close range instead of walking straight in, so a
## cornered guard is still a moving target.
func _strafe(to_p: Vector3, delta: float) -> void:
	_strafe_t += delta
	if _strafe_t >= STRAFE_SWAP:
		_strafe_t = 0.0
		_strafe_dir = -_strafe_dir
	var dir := to_p.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x) * _strafe_dir
	# No room to the side (a doorway, a corridor): try the other side, and
	# with neither free, push through toward him instead of grinding a jamb.
	# Probe from 10cm up: at floor level the seam between two slabs reads as a
	# wall, and the guard flipped direction every frame on the spot.
	var probe := guard.global_transform.translated(Vector3.UP * 0.1)
	if guard.test_move(probe, perp * 0.4):
		_strafe_dir = -_strafe_dir
		perp = -perp
		if guard.test_move(probe, perp * 0.4):
			guard.move_to(guard.global_position + to_p, STRAFE_SPEED, delta)
			return
	guard.velocity.x = perp.x * STRAFE_SPEED
	guard.velocity.z = perp.z * STRAFE_SPEED

func _losing(delta: float) -> void:
	_lose += delta
	guard.stop()
	if _lose >= GIVE_UP_TIME:
		_lose = 0.0
		guard.enter_suspicious(guard.last_seen, 0.5)
