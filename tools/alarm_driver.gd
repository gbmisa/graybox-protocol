extends Node
## Runner-model consequence driver: at alarm 100 the nearest ALERT guard runs
## for the nearest panel; only a panel activation trips lockdown. (a) 100
## assigns a runner; (b) arrival -> lockdown; (c) killing the runner ->
## no lockdown; (d) 100 with nobody alert -> standoff; (e) decay +
## permanence; plus shout spread (25m, no chains).

const SAFE_POS := Vector3(10, 0, -28)
const VICTIM_SPOT := Vector3(-70, 0, 10)

var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _baseline := 0

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
		1: _boot()
		8: _stage1()
		48: _stage2()
		80: _stage3()
		200: _stage4()
		500: _stage5()
		560: _stage6()
		740: _finish()

func _ok(cond: bool, m: String) -> void:
	print(("  " if cond else "  FAIL  ") + m)
	if not cond:
		_bad += 1

# ------------------------------------------------------------------ util ---
func _living() -> Array:
	return _game.guards.filter(func(g: Guard) -> bool: return g.alive)

func _patrol() -> Array:
	return _living().filter(func(g: Guard) -> bool:
		return g.state == Guard.State.PATROL)

func _reset_meter() -> void:
	var d := _game.director
	d.alarm = 0.0
	d._quiet = 0.0
	if d.runner != null:
		d.runner.clear_run()
		d.runner = null

func _send_runner(near: Vector3) -> Guard:
	var r := _patrol()[0] as Guard
	r.global_position = near
	_game.director.alarm = 90.0
	r.enter_alert(false)  # +10 -> 100, no callout of its own
	return r

# ---------------------------------------------------------------- stages ---
func _boot() -> void:
	_game = GrayboxGame.new(); get_tree().root.add_child(_game)
	_game.selected_level = 2
	_game.flow.start_mission()
	_baseline = _game.guards.size()
	_check_panels_spawned(); _check_data()

func _stage1() -> void:
	_check_loud_kill(); _check_corpse(); _check_spread(); _reset_meter()
	_check_runner_assigned()       # (a)

func _stage2() -> void:
	_assert_lockdown(_baseline - 1 + 6)  # (b)
	_game.flow.restart_mission(); _check_runner_killed()  # (c)

func _stage3() -> void:
	_game.flow.restart_mission(); _check_standoff_setup()  # (d)
	_game.director._quiet = 999.0

func _stage4() -> void:
	_check_standoff_holds(); _game.director.alarm = 50.0
	_game.director._quiet = 999.0

func _stage5() -> void:
	_check_decay()                 # (e)
	_send_runner(Vector3(8, 0, -50))

func _stage6() -> void:
	_assert_lockdown(_baseline + 6)
	_game.director.alarm = 2.0; _game.director._quiet = 999.0

func _finish() -> void:
	_check_permanent(); _check_briefing_line()  # (e)
	print("\n%d problem(s)" % _bad)
	get_tree().quit(1 if _bad > 0 else 0)

# ---------------------------------------------------------------- checks ---
func _check_panels_spawned() -> void:
	print("-- alarm panels spawn per level --")
	_ok(_game.panels.size() == 3, "3 panels placed on PORT VESPER")
	for p in _game.panels:
		_ok(not (p as AlarmPanel).activated and not (p as AlarmPanel).revealed,
			"panel starts dormant")

func _check_data() -> void:
	print("-- safe room + panel data --")
	var l2 := SafeRoomData.get_safe_room(2)
	var l1 := SafeRoomData.get_safe_room(1)
	_ok((l2["pos"] as Vector3).distance_to(SAFE_POS) < 0.01
		and String(l2["target_name"]) == "Harbormaster", "L2 safe room")
	_ok(absf((l1["pos"] as Vector3).y - 12.0) < 0.01
		and String(l1["target_name"]) == "Chairman", "L1 safe room")
	_ok(AlarmPanelData.get_panels(1).size() == 3, "3 L1 panels in data")
	for lvl in [l1, l2]:
		_ok((lvl["bodyguard_posts"] as Array).size() == 2
			and (lvl["reinforce_posts"] as Array).size() == 4,
			"2 bodyguard + 4 reinforcement posts")

func _check_loud_kill() -> void:
	print("-- loud kill raises the alarm --")
	_ok(_game.director.alarm == 0.0, "alarm starts at 0")
	var victim := _living()[0] as Guard; victim.global_position = VICTIM_SPOT
	victim.take_damage(999.0, Vector3.ZERO, 45.0)
	_ok(absf(_game.director.alarm - 10.0) < 0.01, "+10 alarm on loud kill")

func _check_corpse() -> void:
	print("-- corpse sighting -> ALERT + alarm bump --")
	var before: float = _game.director.alarm
	var s := _living()[1] as Guard
	s.global_position = VICTIM_SPOT + Vector3(0, 0, 5); s.rotation.y = 0.0
	s.state = Guard.State.PATROL; s.detect = 0.0
	for i in range(30):
		s.senses.tick(_game.player, 0.1)
	_ok(s.state == Guard.State.ALERT, "guard facing a corpse goes ALERT")
	_ok(_game.director.alarm - before >= 24.9, "alarm bump >= 25 (body+alert)")

func _check_spread() -> void:
	print("-- shout spread: 25m, no chain reactions --")
	var p := _patrol()
	var a: Guard = p[0]; var b: Guard = p[1]
	var c: Guard = p[2]; var d: Guard = p[3]
	a.global_position = Vector3(80, 0, 20)
	b.global_position = Vector3(95, 0, 20)    # 15m: called out
	c.global_position = Vector3(-100, 0, -60); d.global_position = Vector3(110, 0, 10)
	a.enter_alert()  # propagate=true: the callout every real sighting makes
	_ok(b.state == Guard.State.ALERT, "15m guard joins the ALERT")
	_ok(c.state != Guard.State.ALERT, "far guard stays calm (no telepathy)")
	_ok(d.state != Guard.State.ALERT, "no chain from the called-out guard")

func _check_runner_assigned() -> void:
	print("-- (a) meter 100 assigns a runner --")
	var dr := _game.director
	var r := _send_runner(Vector3(-7.5, 0, -2.5))
	_ok(dr.panels_revealed, "panels revealed on the way to 100")
	_ok(dr.runner == r and r.is_runner and r.runner_panel != null
		and r.runner_panel.panel_name == "CUSTOMS OFFICE",
		"runner assigned -> CUSTOMS OFFICE panel")
	var n := 0
	for pl in _game.panels:
		n += 1 if (pl as AlarmPanel).revealed else 0
	_ok(n == 3, "all 3 panels revealed")
	_ok(String(_game.hud.feed._message.text).contains("RUNNER"), "HUD warns")

func _assert_lockdown(expect_guards: int) -> void:
	print("-- runner reaching a panel trips lockdown --")
	var dr := _game.director
	_ok(dr.lockdown, "lockdown tripped")
	_ok(absf(dr.heat() - 1.0) < 0.01, "heat is 1")
	var t := _game.target  # relocated target paces a 2m beat around the room
	_ok(t != null and t.global_position.distance_to(SAFE_POS) < 3.0
		and t.relocated, "target relocated to the safe room")
	_ok(_game.guards.size() == expect_guards, "%d guards" % expect_guards)
	var near := 0
	for g in _game.guards:
		near += 1 if (g as Guard).global_position.distance_to(SAFE_POS) <= 6.0 else 0
	_ok(near == 2, "2 bodyguards + 4 reinforcements")
	_ok(dr.runner == null, "runner cleared")
	_ok(_game.is_klaxon_playing(), "klaxon playing (single instance)")
	var msg: Label = _game.hud.feed._message
	_ok(msg.visible and String(msg.text).contains("relocated under guard"),
		"HUD lockdown notice")

func _check_runner_killed() -> void:
	print("-- (c) killing the runner prevents lockdown --")
	var dr := _game.director
	var r := _send_runner(Vector3(0, 0, 20))
	_ok(dr.runner == r, "setup: runner was assigned")
	if dr.runner != r:
		return
	r.take_damage(999.0, Vector3.ZERO, 0.0)
	_ok(not dr.lockdown, "no lockdown after the runner died")
	_ok(dr.runner == null, "dead runner unassigned")
	_ok(absf(dr.alarm - 100.0) < 0.01, "meter sits at 100")
	var tripped := false
	for pl in _game.panels:
		tripped = tripped or (pl as AlarmPanel).activated
	_ok(not tripped, "no panel activated")

func _check_standoff_setup() -> void:
	print("-- (d) full meter, zero alert guards --")
	var dr := _game.director
	dr.raise_alarm(100.0)
	_ok(dr.runner == null, "no runner assigned")
	_ok(not dr.lockdown, "no lockdown tripped")
	_ok(absf(dr.alarm - 100.0) < 0.01, "meter at 100")

func _check_standoff_holds() -> void:
	print("-- (d) the standoff holds: no decay, no lockdown --")
	var dr := _game.director
	_ok(absf(dr.alarm - 100.0) < 0.01, "meter did not decay")
	_ok(not dr.lockdown and dr.runner == null, "state unchanged")

func _check_decay() -> void:
	print("-- (e) alarm decays after quiet --")
	_ok(absf(_game.director.alarm - 40.0) < 2.0, "50 -> ~40 over 5s")

func _check_permanent() -> void:
	print("-- (e) lockdown is permanent --")
	var dr := _game.director
	_ok(dr.alarm == 0.0, "alarm fully decayed")
	_ok(dr.lockdown, "lockdown flag held")
	_ok(_game.target != null
		and _game.target.global_position.distance_to(SAFE_POS) < 3.0,
		"target still at the safe room")

func _check_briefing_line() -> void:
	print("-- briefing teaches the consequence --")
	_game.flow.show_select()
	_game.flow.select_char("regular")
	var texts: Array[String] = []
	_collect_labels(_game.screens._screens["briefing"].center, texts)
	var found := false
	for t in texts:
		found = found or t.contains("relocates under guard")
	_ok(found, "briefing line present")

func _collect_labels(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_collect_labels(c, out)
