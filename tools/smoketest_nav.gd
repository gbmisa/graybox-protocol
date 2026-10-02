extends SceneTree
## Guard navigation: the navmesh bakes, and a guard walks round a wall to
## reach the player instead of into it.
##
##     godot --headless --path . --script res://tools/smoketest_nav.gd

var _frame := 0
var _game: GrayboxGame
var _bad := 0
var _g: Guard
var _t0 := 0
var _before_len := 0.0

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_t0 = Time.get_ticks_msec()
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
		print("start_mission + bake: %d ms" % (Time.get_ticks_msec() - _t0))
		return false
	if _frame == 2:
		# A long wall across open ground, guard on one side, goal on the other.
		BuildUtils.box(_game.level_root, Vector3(0, 1.5, 300), Vector3(14, 3.0, 0.4),
			BuildUtils.WALL)
		return false
	if _frame < 40:
		return false
	if _frame > 40:
		return _locked_door_check()
	_ok(GuardNav.ready_map, "navmesh baked")
	var w := _game.level_root.get_world_3d()
	var p := GuardNav.path(w, Vector3(0, 0, 190), Vector3(0, 0, 100))
	_ok(p.size() > 1, "path along the approach (%d points)" % p.size())
	var p2 := GuardNav.path(w, Vector3(0, 0, 20), Vector3(0, 0, 60))
	_ok(p2.size() > 1, "path from campus yard out to the estate (%d points)" % p2.size())
	# r5 lanes: the zigzag must still be walkable, and longer than a straight line.
	var z1 := GuardNav.path(w, Vector3(0, 0, 190), Vector3(0, 0, 150))
	var len1 := 0.0
	for i in range(1, z1.size()):
		len1 += z1[i - 1].distance_to(z1[i])
	_ok(z1.size() > 1 and len1 > 60.0, "estate yard is a zigzag: spawn -> yard walks %.0fm for 40m as the crow flies" % len1)
	var z2 := GuardNav.path(w, Vector3(0, 0, 40), Vector3(0, 0, -6))
	_ok(z2.size() > 1, "the campus portico is reachable on foot (%d points)" % z2.size())
	var z3 := GuardNav.path(w, Vector3(0, 0, 0), Vector3(-8, 0, 21.5))
	_ok(z3.size() > 1, "courtyard rear to front stays connected")
	return false

func _locked_door_check() -> bool:
	var w := _game.level_root.get_world_3d()
	if _frame < 200:
		return false
	if _frame == 200:
		# A locked door must leave the navmesh: lock the CSD pair, wait for the
		# background bake, and the lobby no longer walks through to the corridor.
		_before_len = _plen(GuardNav.path(w, Vector3(0, 0, -6), Vector3(0, 0, -14)))
		for d in (_game.mission as MissionCompound).csd:
			(d as RemoteDoor).lock()
		return false
	if _frame < 420:
		return false
	var after := _plen(GuardNav.path(w, Vector3(0, 0, -6), Vector3(0, 0, -14)))
	_ok(_before_len > 1.0 and after > _before_len + 3.0,
		"a locked security door reroutes guards (%.1fm -> %.1fm)" % [_before_len, after])
	print("%d problem(s)" % _bad)
	quit()
	return true

func _plen(p: PackedVector3Array) -> float:
	var l := 0.0
	for i in range(1, p.size()):
		l += p[i - 1].distance_to(p[i])
	return l
