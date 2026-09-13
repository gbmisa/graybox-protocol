extends Node
## Reset-determinism driver: records a PORT VESPER baseline, trips lockdown
## through a panel, restarts mid-lockdown, then asserts the mission comes
## back clean: alarm 0, no lockdown, no runner, target back at its post,
## guard count restored, old nodes freed, klaxon stopped, panels fresh.

const TARGET_POST := Vector3(-12, 0, -12)

var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _baseline_guards := 0
var _restarted_at := -1
var _lockdown_seen := false
var _old_level: Node
var _old_director: AlarmDirector
var _old_target: Target

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _pf:
		return
	_pf = pf
	_frame += 1
	if _frame > 3000:
		print("\n1 problem(s)")
		get_tree().quit(1)
		return
	match _frame:
		1:
			_boot()
		8:
			_trigger_lockdown()
		740:
			_fail("lockdown never tripped")
			_finish()
	if _restarted_at < 0 and _game != null and _game.director.lockdown:
		_check_lockdown_state()
		_old_level = _game.level_root
		_old_director = _game.director
		_old_target = _game.target
		_game.flow.restart_mission()
		_restarted_at = _frame
	elif _restarted_at >= 0 and _frame >= _restarted_at + 15:
		_check_reset_state()
		_finish()

func _ok(cond: bool, m: String) -> void:
	print(("  " if cond else "  FAIL  ") + m)
	if not cond:
		_bad += 1

func _fail(m: String) -> void:
	_bad += 1
	print("  FAIL  " + m)

func _finish() -> void:
	print("\n%d problem(s)" % _bad)
	get_tree().quit(1 if _bad > 0 else 0)

# ---------------------------------------------------------------- stages ---
func _boot() -> void:
	_game = GrayboxGame.new()
	get_tree().root.add_child(_game)
	_game.selected_level = 2
	_game.flow.start_mission()
	print("-- baseline --")
	_baseline_guards = _game.guards.size()
	_ok(_game.director.alarm == 0.0, "alarm starts at 0")
	_ok(not _game.director.lockdown, "no lockdown at boot")
	_ok(_game.director.runner == null, "no runner at boot")
	var t := _game.target
	_ok(t != null and not t.relocated
		and t.global_position.distance_to(TARGET_POST) < 0.5,
		"target at its original post")
	_ok(_game.guards.size() == _baseline_guards, "%d guards" % _baseline_guards)
	_ok(_game.panels.size() == 3, "3 panels placed")
	_ok(not _game.is_klaxon_playing(), "klaxon silent at boot")

func _trigger_lockdown() -> void:
	var r: Guard = null
	for g in _game.guards:
		if (g as Guard).alive and (g as Guard).state == Guard.State.PATROL:
			r = g
			break
	r.global_position = Vector3(-7.5, 0, -2.5)  # beside customs panel
	_game.director.alarm = 90.0
	r.enter_alert(false)  # +10 -> 100 -> runner assigned
	print("-- lockdown tripped via panel --")

func _check_lockdown_state() -> void:
	_lockdown_seen = true
	var dr := _game.director
	_ok(dr.lockdown, "lockdown active before restart")
	_ok(dr.runner == null, "runner cleared on arrival")
	_ok(_game.target.relocated, "target relocated")
	_ok(_game.guards.size() == _baseline_guards + 6, "6 extra guards posted")
	_ok(_game.is_klaxon_playing(), "klaxon playing before restart")
	var tripped := false
	for pl in _game.panels:
		tripped = tripped or (pl as AlarmPanel).activated
	_ok(tripped, "a panel was activated")

func _check_reset_state() -> void:
	print("-- after restart --")
	var dr := _game.director
	_ok(absf(dr.alarm) < 0.01, "alarm back to 0")
	_ok(absf(dr.heat()) < 0.01, "heat back to 0")
	_ok(not dr.lockdown, "lockdown flag cleared")
	_ok(dr.runner == null, "no runner carried over")
	var t := _game.target
	_ok(t != null and not t.relocated
		and t.global_position.distance_to(TARGET_POST) < 2.0,
		"target back at its original post")
	_ok(_game.guards.size() == _baseline_guards, "guard count restored")
	var in_group := 0
	for n in get_tree().get_nodes_in_group("guards"):
		if (n as Guard).alive:
			in_group += 1
	_ok(in_group == _baseline_guards, "guard group matches fresh spawn")
	_ok(not is_instance_valid(_old_level), "old level freed")
	_ok(not is_instance_valid(_old_director), "old director freed")
	_ok(not is_instance_valid(_old_target), "old target freed")
	_ok(not _game.is_klaxon_playing(), "klaxon stopped")
	_ok(_game.panels.size() == 3, "panels respawned")
	var fresh := true
	for pl in _game.panels:
		var p := pl as AlarmPanel
		fresh = fresh and not p.activated and not p.revealed
	_ok(fresh, "panels dormant and unrevealed")
