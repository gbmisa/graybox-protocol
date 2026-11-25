class_name GuardRunner
extends RefCounted
## The alerted guard's alarm run (split out of GuardBrain in r8).

var brain: GuardBrain
var run_t: float = 0.0
var gave_up: bool = false
var fight_t: float = 0.0
const HAND_OFF := 3.0

## Is anyone running for an alarm right now?
static func anyone(game: GrayboxGame) -> bool:
	for o in game.guards:
		var g := o as Guard
		if g.alive and g.alarm_run:
			return true
	return false

## The slot is free and this alerted guard has a post in reach: he takes it.
## (The first man alerted may have none — G10 — or die on the way; the job
## passes on instead of dying with him.)
func maybe_take() -> void:
	var guard := brain.guard
	if guard.alarm_run or gave_up or guard.game.alert.is_alarm() \
			or guard.game.get_tree().get_nodes_in_group("alarm_station").is_empty():
		return
	if guard.game.nearest_station(guard.global_position) == null or anyone(guard.game):
		return
	guard.alarm_run = true
	run_t = 0.0

## An alerted guard's first job is the alarm: run to the nearest station on
## his floor and press it. Only one guard runs at a time (game.guard_alerted);
## he shoots only if you are within RUNNER_FIGHT_DIST — the window to drop him. Gives up after RUN_TIME (blocked, or too far) and fights.
const RUN_TIME := 15.0
const RUNNER_FIGHT_DIST := 10.0
const PRESS_DIST := 1.3

func run(delta: float) -> bool:
	var guard := brain.guard
	if guard.game.alert.is_alarm():
		guard.alarm_run = false
		return false
	run_t += delta
	var st := guard.game.nearest_station(guard.global_position)
	if st == null or run_t > RUN_TIME or not _claim(st):
		guard.alarm_run = false
		gave_up = true
		return false
	var to := st.global_position - guard.global_position
	to.y = 0.0
	if to.length() > PRESS_DIST:
		# Crowd him (in sight, within RUNNER_FIGHT_DIST) and he turns and
		# fights (r8); otherwise he runs. Facing you, so the tell is honest.
		var p := guard.game.get_player()
		if p != null and p.alive:
			var tp := p.global_position - guard.global_position
			tp.y = 0.0
			if tp.length() < RUNNER_FIGHT_DIST and brain.call("_sees", p):
				guard.stop()
				guard.face(atan2(-tp.x, -tp.z), delta)
				guard.combat.tick(p, delta, tp.length())
				run_t -= delta   # fighting isn't running out of time...
				fight_t += delta
				if fight_t > HAND_OFF:   # ...but past HAND_OFF he's a fighter now,
					guard.alarm_run = false   # and the run passes to someone else
					gave_up = true
				return true
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
	var guard := brain.guard
	var r: Variant = st.get_meta("runner") if st.has_meta("runner") else null
	if r != null and r != guard and is_instance_valid(r) and (r as Guard).alive \
			and (r as Guard).alarm_run:
		return false
	st.set_meta("runner", guard)
	return true
