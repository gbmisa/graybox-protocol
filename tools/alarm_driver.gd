extends Node
## Consequence-spine driver: alarm, lockdown, decay, loud kills, corpses.
## Keyed on physics frames (idle frames run unthrottled headless).

const SAFE_POS := Vector3(10, 0, -28)   # L2 safe room, mirrors SafeRoomData
const VICTIM_SPOT := Vector3(-70, 0, 10) # open terminal ground

var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _pf:
		return
	_pf = pf
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		get_tree().root.add_child(_game)
		_game.selected_level = 2
		_game.selected_char = "regular"
		_game.flow.start_mission()
	elif _frame == 8:
		_check_data()
		_check_loud_kill()
		_check_corpse_sighting()
		_check_lockdown()
		# (b) decay: 50 alarm, clock long past the delay, 5s of frames.
		_game.director.alarm = 50.0
		_game.director._quiet = 999.0
	elif _frame == 308:
		_check_decay()
		# (e) full drain, then permanence.
		_game.director.alarm = 2.0
		_game.director._quiet = 999.0
	elif _frame == 488:
		_check_permanent()
		_check_briefing_line()
		print("\n%d problem(s)" % _bad)
		get_tree().quit(1 if _bad > 0 else 0)

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

# ------------------------------------------------------------- data ---
func _check_data() -> void:
	print("-- safe room data --")
	var l2 := SafeRoomData.get_safe_room(2)
	if (l2["pos"] as Vector3).distance_to(SAFE_POS) > 0.01:
		_fail("L2 safe room moved: %s" % l2["pos"])
	if String(l2["target_name"]) != "Harbormaster":
		_fail("L2 target name is '%s'" % l2["target_name"])
	var l1 := SafeRoomData.get_safe_room(1)
	if absf((l1["pos"] as Vector3).y - 12.0) > 0.01:
		_fail("L1 safe room not on the boardroom floor")
	if String(l1["target_name"]) != "Chairman":
		_fail("L1 target name is '%s'" % l1["target_name"])
	for lvl in [l1, l2]:
		if (lvl["bodyguard_posts"] as Array).size() != 2:
			_fail("expected 2 bodyguard posts")
		if (lvl["reinforce_posts"] as Array).size() != 4:
			_fail("expected 4 reinforcement posts")
	print("  L1 + L2 rooms: 2 bodyguards, 4 reinforcements each")

# -------------------------------------------------------- (c) loud kill ---
func _check_loud_kill() -> void:
	print("-- loud kill raises the alarm --")
	if _game.director.alarm != 0.0:
		_fail("alarm starts at %.1f, expected 0" % _game.director.alarm)
	var victim := _living_guard(0)
	victim.global_position = VICTIM_SPOT
	victim.take_damage(999.0, Vector3.ZERO, 45.0)  # meteor-loud killing blow
	if absf(_game.director.alarm - 10.0) > 0.01:
		_fail("loud kill moved alarm to %.1f, expected 10" % _game.director.alarm)
	else:
		print("  +10 alarm on loud kill")

# -------------------------------------------------- (d) corpse sighting ---
func _check_corpse_sighting() -> void:
	print("-- corpse sighting -> ALERT + alarm bump --")
	var before: float = _game.director.alarm
	var spotter := _living_guard(1)
	spotter.global_position = VICTIM_SPOT + Vector3(0, 0, 5)
	spotter.rotation.y = 0.0  # faces -z, straight at the body
	spotter.state = Guard.State.PATROL
	spotter.detect = 0.0
	for i in range(30):
		spotter.senses.tick(_game.player, 0.1)
	if spotter.state != Guard.State.ALERT:
		_fail("guard facing a corpse did not go ALERT")
	var bump: float = _game.director.alarm - before
	if bump < 24.9:  # corpse bump 15 + alert bump 10
		_fail("corpse sighting bumped alarm by %.1f, expected >= 25" % bump)
	else:
		print("  ALERT, alarm +%.0f (body 15 + alert 10)" % bump)

# -------------------------------------------------------- (a) lockdown ---
func _check_lockdown() -> void:
	print("-- full alarm -> lockdown --")
	_game.director.raise_alarm(100.0)
	var d := _game.director
	if not d.lockdown:
		_fail("alarm hit 100 without lockdown")
	if absf(d.heat() - 1.0) > 0.01:
		_fail("lockdown heat is %.2f, expected 1" % d.heat())
	var t := _game.target
	if t == null or t.global_position.distance_to(SAFE_POS) > 1.0:
		_fail("target not relocated to the safe room")
	elif not t.relocated:
		_fail("target.relocated flag not set")
	else:
		print("  target relocated to %s" % SAFE_POS)
	# 23 posted, 1 killed above, 6 spawned: 2 bodyguards + 4 reinforcements.
	if _game.guards.size() != 28:
		_fail("expected 28 guards after lockdown, found %d" % _game.guards.size())
	var near := 0
	for g in _game.guards:
		if (g as Guard).global_position.distance_to(SAFE_POS) <= 6.0:
			near += 1
	if near != 2:
		_fail("expected 2 bodyguards at the safe room, found %d" % near)
	else:
		print("  2 bodyguards + 4 reinforcements posted")
	var msg: Label = _game.hud.feed._message
	if not msg.visible or not String(msg.text).contains("relocated under guard"):
		_fail("HUD lockdown notice missing")
	else:
		print("  HUD notice: \"%s\"" % msg.text)

# ------------------------------------------------------------ (b) decay ---
func _check_decay() -> void:
	print("-- alarm decays after quiet --")
	var a: float = _game.director.alarm  # 50 - 2*5 = 40
	if absf(a - 40.0) > 2.0:
		_fail("after 5s quiet the alarm is %.1f, expected ~40" % a)
	else:
		print("  50 -> %.1f over 5s" % a)

# ------------------------------------------------------- (e) permanence ---
func _check_permanent() -> void:
	print("-- lockdown is permanent --")
	var d := _game.director
	if d.alarm != 0.0:
		_fail("alarm did not fully decay (%.1f)" % d.alarm)
	if not d.lockdown:
		_fail("lockdown flag cleared on decay")
	if _game.target == null \
			or _game.target.global_position.distance_to(SAFE_POS) > 3.0:
		_fail("target left the safe room after decay")
	else:
		print("  alarm 0, target still at the safe room")

# ------------------------------------------------------------- briefing ---
func _check_briefing_line() -> void:
	print("-- briefing teaches the consequence --")
	_game.flow.show_select()
	_game.flow.select_char("regular")
	var texts: Array[String] = []
	_collect_labels(_game.screens._screens["briefing"].center, texts)
	var found := false
	for t in texts:
		if t.contains("relocates under guard"):
			found = true
	if not found:
		_fail("briefing line about lockdown missing")
	else:
		print("  briefing line present")

func _collect_labels(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_collect_labels(c, out)

# ------------------------------------------------------------------ util ---
func _living_guard(idx: int) -> Guard:
	var n := 0
	for g in _game.guards:
		var gd := g as Guard
		if gd != null and gd.alive:
			if n == idx:
				return gd
			n += 1
	return null
