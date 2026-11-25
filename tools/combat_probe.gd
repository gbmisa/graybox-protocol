extends SceneTree
## How dangerous are guards? Gregory (r8): "they're just running towards the
## nearest alarm and not fighting back. I haven't taken damage from guards in
## multiple runs." Puts the player (standing still, unkillable) in plain view
## of guards at a few spots, alerts every guard within RADIUS, and over
## FIGHT_TIME reports damage the player took, shots fired and landed, and how
## long each guard spent running for an alarm instead of fighting.
##
##     godot --headless --path . --script res://tools/combat_probe.gd
##
## Exits 1 if any spot with fighters near deals less than MIN_DPS. The single
## alarm runner doesn't count: running away is his job.

const RADIUS := 30.0
const FIGHT_TIME := 10.0
const MIN_DPS := 6.0
## r8 combat review: a crouched player was immune (guards aimed at 1.2m).
## `-- --crouch` holds crouch for the whole probe.
var SPOTS := [
	Vector3(-6, 0.1, 18),     # courtyard
	Vector3(0, 0.1, -55),     # annex: Consent Way
	Vector3(-6, 0.1, 160),    # approach: estate yard
]

var _frame := 0
var _game: GrayboxGame
var _spot := 0
var _t := 0.0
var _hp0 := 0.0
var _run := {}
var _bad := 0
var _total_dmg := 0.0

func _initialize() -> void:
	_game = GrayboxGame.new()
	root.add_child(_game)

func _physics_process(delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
	if _frame < 30:
		return false
	var p := _game.get_player()
	if OS.get_cmdline_user_args().has("--crouch"):
		Input.action_press("crouch")
	if _frame == 30:
		_begin(p)
		return false
	_t += delta
	for g in _game.guards:
		var gd := g as Guard
		if gd.alive and gd.alarm_run:
			_run[gd] = float(_run.get(gd, 0.0)) + delta
	if _t < FIGHT_TIME:
		return false
	_report(p)
	_spot += 1
	if _spot >= SPOTS.size():
		print("TOTAL damage %.0f   %d problem(s)" % [_total_dmg, _bad])
		quit(1 if _bad > 0 else 0)
		return true
	_game.flow.start_mission()
	_frame = 20
	return false

func _begin(p: Player) -> void:
	var at: Vector3 = SPOTS[_spot]
	p.global_position = at
	p.health.hp = 1.0e9
	_hp0 = p.health.hp
	_t = 0.0
	_run = {}
	for g in _game.guards:
		var gd := g as Guard
		gd.combat.shots = 0
		gd.combat.hits = 0
		if gd.alive and gd.global_position.distance_to(at) < RADIUS:
			gd.last_seen = at
			gd.enter_alert()

func _report(p: Player) -> void:
	var dmg := _hp0 - p.health.hp
	_total_dmg += dmg
	var shots := 0
	var hits := 0
	var near := 0
	var running := 0.0
	for g in _game.guards:
		var gd := g as Guard
		# The one alarm runner is the stealth window, not a fighter.
		if gd.global_position.distance_to(SPOTS[_spot]) < RADIUS and not gd.alarm_run:
			near += 1
			if OS.get_cmdline_user_args().has("--verbose"):
				print("    %s %.1fm state=%d run=%s shots=%d sees=%s" % [gd.post_id, gd.global_position.distance_to(p.global_position),
					gd.state, gd.alarm_run, gd.combat.shots, gd.brain.call("_sees", p)])
		shots += gd.combat.shots
		hits += gd.combat.hits
		running += float(_run.get(gd, 0.0))
	var dps := dmg / FIGHT_TIME
	var ok := near == 0 or dps >= MIN_DPS
	if not ok:
		_bad += 1
	print("%s spot %s: %d fighters near, %d shots, %d hits, %.0f dmg (%.1f/s), %.1f guard-s running for alarms" % [
		"ok  " if ok else "FAIL", SPOTS[_spot], near, shots, hits, dmg, dps, running])
