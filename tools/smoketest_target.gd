extends SceneTree
## r8: Vandermeer's routine. With guards off, he leaves his lane within the
## first trip time, reaches the 1F south window (navmesh), stands there, and
## comes back to the lane.
##
##     godot --headless --path . --script res://tools/smoketest_target.gd

var _game: GrayboxGame
var _bad := 0

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _initialize() -> void:
	_game = GrayboxGame.new()
	root.add_child(_game)
	_run()

func _run() -> void:
	for i in 2:
		await physics_frame
	_game.selected_char = "regular"
	_game.selected_level = "compound"
	_game.flow.start_mission()
	for i in 30:
		await physics_frame
	for g in _game.guards:
		(g as Node).process_mode = Node.PROCESS_MODE_DISABLED
	_game.get_player().health.hp = 1.0e6
	var t := _game.target
	var spot: Vector3 = MissionCompoundData.TARGET_VISIT
	var best := 999.0
	var reached_at := -1.0
	var back := false
	var frames := int((40.0 + 60.0 + Target.VISIT_STAY + 60.0) * 60.0)
	for i in frames:
		await physics_frame
		var d := Vector2(t.global_position.x - spot.x, t.global_position.z - spot.z).length()
		best = minf(best, d)
		if d < 1.0 and reached_at < 0.0:
			reached_at = i / 60.0
		if reached_at > 0.0 and t.global_position.distance_to(MissionCompoundData.TARGET_LANE[0]) < 1.2:
			back = true
			break
	_ok(reached_at > 0.0, "he reaches the window (closest %.1fm, at %.0fs)" % [best, reached_at])
	_ok(back, "and walks back to his lane")
	_ok(absf(t.global_position.y - 4.0) < 0.5, "never leaves the 1F (y %.1f)" % t.global_position.y)
	print("%d problem(s)" % _bad)
	quit(1 if _bad > 0 else 0)
