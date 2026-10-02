extends SceneTree
## Guards under fire keep moving. Gregory (2026-10-01): "the guards just grouped
## up and didn't move when I shot at them". Puts the player in a spot, wings
## every guard within RADIUS, runs the fight for a while with the player
## unkillable, and reports any guard that stands still for STILL_TIME while
## he is alerted or investigating. Shooting them all also brings the alarm,
## so each spot is a test of the defence plan too: no clump of CLUMP guards
## within CLUMP_R of each other at the end, and every post is reachable.
##
##     godot --headless --path . --script res://tools/smoketest_guard_stuck.gd [-- x y z]

const RADIUS := 40.0
const RUN_TIME := 30.0
const STILL_TIME := 6.0
const STILL_DIST := 0.6
const CLUMP := 3
const CLUMP_R := 2.5
var SPOTS := [
	Vector3(-6, 0.1, 18),     # courtyard, south of the mast
	Vector3(0, 0.1, 28),      # verge, outside the south wall
	Vector3(13, 0.1, -8),     # the alley
	Vector3(0, 0.1, -43),     # annex checkpoint
]

var _frame := 0
var _game: GrayboxGame
var _bad := 0
var _spot := 0
var _t := 0.0
var _hist := {}     # guard -> Array of [time, pos]
var _flagged := {}

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

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
	p.health.hp = 1.0e9
	if _frame == 30:
		if _spot == 0:
			_check_posts()
		_begin()
		return false
	_t += delta
	for g in _game.guards:
		var gd := g as Guard
		if not gd.alive:
			continue
		var h: Array = _hist.get(gd, [])
		h.append([_t, gd.global_position])
		_hist[gd] = h
		if gd.state == Guard.State.PATROL or _flagged.has(gd):
			continue
		var moved := 0.0
		for e in h:
			if _t - float(e[0]) <= STILL_TIME:
				moved = maxf(moved, (e[1] as Vector3).distance_to(gd.global_position))
		# Holding still while shooting at him is fighting, not frozen.
		var engaged: bool = gd.state == Guard.State.ALERT and gd.brain.call("_sees", p) \
			and gd.global_position.distance_to(p.global_position) < GuardBrain.CHASE_DIST
		# On (or fighting within leash of) his post is holding it, not frozen.
		var holding := gd.hold_pos != Vector3.INF \
			and Vector2(gd.hold_pos.x - gd.global_position.x,
				gd.hold_pos.z - gd.global_position.z).length() < GuardBrain.LEASH + 0.5
		if _t > STILL_TIME + 1.0 and moved < STILL_DIST and not engaged and not holding:
			_flagged[gd] = true
			print("    stuck: %s state=%s alarm_run=%s at %s, player %.1fm, goal %s" % [
				gd.post_id, ["PATROL", "SUSPICIOUS", "ALERT"][gd.state], gd.alarm_run,
				_v(gd.global_position), gd.global_position.distance_to(p.global_position),
				_v(gd.investigate_pos if gd.state == Guard.State.SUSPICIOUS else p.global_position)])
	if _t < RUN_TIME:
		return false
	_ok(_flagged.is_empty(), "spot %s: no guard stands still for %.0fs while alerted (%d stuck)" % [
		_v(SPOTS[_spot]), STILL_TIME, _flagged.size()])
	var worst := _worst_clump()
	_ok(worst.size() < CLUMP, "spot %s: no %d guards within %.1fm of each other %s" % [
		_v(SPOTS[_spot]), CLUMP, CLUMP_R, worst])
	var held := 0
	for g in _game.guards:
		if (g as Guard).alive and (g as Guard).hold_pos != Vector3.INF:
			held += 1
	print("    alarm=%s, %d guards on posts" % [_game.alert.is_alarm(), held])
	_spot += 1
	if _spot >= SPOTS.size() or OS.get_cmdline_user_args().size() >= 3:
		print("%d problem(s)" % _bad)
		quit()
		return true
	_frame = 1
	return false

func _begin() -> void:
	var p := _game.get_player()
	var at: Vector3 = SPOTS[_spot]
	var args := OS.get_cmdline_user_args()
	if args.size() >= 3:
		at = Vector3(float(args[0]), float(args[1]), float(args[2]))
		SPOTS[_spot] = at
	p.global_position = at
	_t = 0.0
	_hist.clear()
	_flagged.clear()
	var n := 0
	for g in _game.guards:
		var gd := g as Guard
		if gd.alive and gd.global_position.distance_to(at) < RADIUS:
			gd.take_damage(1.0, at + Vector3(0, 1.4, 0))
			n += 1
	print("spot %s: shot %d guards" % [_v(at), n])

## The biggest group of live guards all within CLUMP_R of one of them.
func _worst_clump() -> Array:
	var worst: Array = []
	for a in _game.guards:
		var ga := a as Guard
		if not ga.alive:
			continue
		var near: Array = [ga.post_id]
		for b in _game.guards:
			var gb := b as Guard
			if gb != ga and gb.alive and gb.global_position.distance_to(ga.global_position) < CLUMP_R:
				near.append(gb.post_id)
		if near.size() > worst.size():
			worst = near
	return worst

## Every defensive post has floor under it and a walk to it from the courtyard.
func _check_posts() -> void:
	var w := _game.level_root.get_world_3d()
	for post in MissionCompoundData.POSTS:
		var at: Vector3 = post[0]
		# From the courtyard, or for the annex's posts from the annex yard.
		var end := Vector3.INF
		var path := PackedVector3Array()
		for from in [Vector3(0, 0, 14), Vector3(0, 0, -43)]:
			path = GuardNav.path(w, from, at)
			end = path[path.size() - 1] if path.size() > 0 else Vector3.INF
			if end.distance_to(at) < 1.0:
				break
		_ok(path.size() > 1 and end.distance_to(at) < 1.0,
			"post %s reachable on foot (path ends %s)" % [_v(at), _v(end)])

func _v(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]
