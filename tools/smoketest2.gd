extends SceneTree
## Headless PORT VESPER check. Mirrors tools/smoketest.gd.
##     godot --headless --path . --script res://tools/smoketest2.gd
var _frame := 0
var _game: GrayboxGame
var _bad := 0

## label, position, headroom: "" = standable, "crawl" = exactly 1.0m,
## "any" = transitional (no height asserted).
const POINTS := [
	["spawn", Vector3(0, 0, -62), ""],
	["culvert outer", Vector3(63, 0, 20), "crawl"],
	["culvert inner", Vector3(61, 0, 20), "crawl"],
	["yard mid", Vector3(40, 0, 20), ""],
	["locker A", Vector3(40, 0, 5), ""],
	["office east appr", Vector3(24, 0, -24), ""],
	["office interior", Vector3(8, 0, -22), ""],
	["dash ramp base", Vector3(38, 2.0, -42), "any"],
	["dash ramp top", Vector3(32, 5.0, -42), "any"],
	["dash P1", Vector3(28, 3.6, -42), ""],
	["dash P2", Vector3(28, 3.6, -24), ""],
	["office roof", Vector3(11, 3.6, -24), ""],
	["skylight drop", Vector3(13, 0, -20), "any"],
	["breach outer", Vector3(-63, 0, -3), ""],
	["breach inner", Vector3(-56, 0, -3), ""],
	["warehouse", Vector3(-42, 0, -3), ""],
	["wh east door", Vector3(-25, 0, -5.5), ""],
	["yard gap", Vector3(-17, 0, -15), ""],
	["office west appr", Vector3(-18, 0, -24), ""],
	["pier deck", Vector3(30, 0, 50), ""],
	["boat", Vector3(30, 0, 58), ""],
	["van", Vector3(0, 0, -57), ""],
	["outflow", Vector3(67, 0, 20), ""],
]
const ZONES := [
	["boat", Vector3(30, 0, 58), 4.0],
	["van", Vector3(0, 0, -57), 4.0],
	["outflow", Vector3(67, 0, 20), 3.0],
]

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_level = 2
		_game.selected_char = "regular"
		_game.flow.start_mission()
		return false
	if _frame < 8:
		return false
	if _frame == 8:
		var space := _game.get_world_3d().direct_space_state
		_check_points(space)
		_check_zones()
		_check_target(space)
		_check_guard_count()
		_check_culvert_sealed(space)
		_check_dash_line(space)
		return false
	if _frame >= 9 and _frame <= 11:
		var id: String = ["wizard", "chad", "regular"][_frame - 9]
		_game.selected_char = id
		_game.flow.start_mission()
		_check_kit(id)
		if _frame == 11:
			_game.flow.show_select()
		return false
	if _frame < 15:
		return false
	if _frame == 15:
		_check_ui_fits(false)
		_game.flow.select_char("wizard")
		return false
	if _frame < 19:
		return false
	_check_ui_fits(true)
	print("\n%d problem(s)" % _bad)
	return true

func _check_kit(char_id: String) -> void:
	print("-- kit: %s --" % char_id)
	var p := _game.player
	if p.char_id != char_id:
		_fail("player char_id is %s, expected %s" % [p.char_id, char_id])
		return
	var want_hp := float(CharData.get_char(char_id)["hp"])
	if absf(p.health.hp - want_hp) > 0.01:
		_fail("%s has %.0f HP, expected %.0f" % [char_id, p.health.hp, want_hp])
	var verbs: Dictionary = p.verbs
	var want := {"lockpick": char_id == "regular",
		"arcane": char_id == "wizard", "smash": char_id == "chad"}
	for verb in want:
		if bool(verbs.get(verb, false)) != bool(want[verb]):
			_fail("%s: %s=%s, expected %s" % [char_id, verb, verbs.get(verb), want[verb]])
	var crawls := char_id != "chad"
	var crouch_h := float(verbs.get("crouch_h", 0.85))
	if crawls and crouch_h > 1.0:
		_fail("%s crouches %.2fm — cannot fit the 1.0m culvert" % [char_id, crouch_h])
	if not crawls and crouch_h <= 1.0:
		_fail("%s crouches %.2fm — the culvert would not stop them" % [char_id, crouch_h])
	if p.global_position.distance_to(Level2Builder.PLAYER_SPAWN) > 0.5:
		_fail("%s spawned at %s" % [char_id, p.global_position])
	else:
		print("  %s ok: %.0f HP, crouch %.2fm" % [char_id, want_hp, crouch_h])

func _check_points(space: PhysicsDirectSpaceState3D) -> void:
	print("-- floor and headroom --")
	for entry in POINTS:
		var label: String = entry[0]
		var pos: Vector3 = entry[1]
		var want: String = entry[2]
		var floor_y := _floor_under(space, pos)
		if floor_y < -900.0:
			_fail("%s has no floor at %s" % [label, pos])
			continue
		var head := _headroom(space, Vector3(pos.x, floor_y, pos.z))
		var note := ""
		if want == "crawl" and (head < 0.95 or head > 1.05):
			note = " <-- crawl must be 1.0m, measured %.2f" % head
			_bad += 1
		elif want == "" and head < 1.75:
			note = " <-- cannot stand up here"
			_bad += 1
		print("  %-16s y=%7.2f head=%5.2f%s" % [label, floor_y, head, note])

func _check_zones() -> void:
	print("-- extraction zones --")
	var areas: Array = []
	_collect_areas(_game.level_root, areas)
	for entry in ZONES:
		var ok := false
		for a in areas:
			var area := a as Area3D
			var r := ((area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius
			if area.global_position.distance_to(entry[1]) < 1.0 and absf(r - entry[2]) < 0.1:
				ok = true
		if not ok:
			_fail("extraction zone '%s' missing" % entry[0])
		else:
			print("  '%s' r=%.1f" % [entry[0], entry[2]])

func _collect_areas(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Area3D:
			out.append(child)
		_collect_areas(child, out)

func _check_target(space: PhysicsDirectSpaceState3D) -> void:
	print("-- the Harbormaster --")
	var t := _game.target
	if t == null:
		_fail("no target spawned")
		return
	if t.patrol_points.size() != 3:
		_fail("target has %d patrol points, expected 3" % t.patrol_points.size())
	for i in range(t.patrol_points.size()):
		var wp: Vector3 = t.patrol_points[i]
		var floor_y := _floor_under(space, wp)
		if floor_y < -900.0:
			_fail("target waypoint %d has no floor" % i)
		elif _headroom(space, Vector3(wp.x, floor_y, wp.z)) < 1.75:
			_fail("target waypoint %d is under a low ceiling" % i)
		else:
			print("  waypoint %d ok" % i)

func _check_guard_count() -> void:
	print("-- guards --")
	if _game.guards.size() != 11:
		_fail("expected 11 guards, found %d" % _game.guards.size())
	else:
		print("  11 guards posted")

## The 1.0m crawl is only a gate if the fence above the pipe is solid.
func _check_culvert_sealed(space: PhysicsDirectSpaceState3D) -> void:
	print("-- culvert sealed from above --")
	var q := PhysicsRayQueryParameters3D.create(Vector3(60, 8.0, 20), Vector3(60, 1.6, 20))
	if space.intersect_ray(q).is_empty():
		_fail("open sky above the culvert at the fence line — jump over it")
	else:
		print("  fence lintel overhead")

## The dash is horizontal: tops at 3.6m, corridor clear, east wall below.
func _check_dash_line(space: PhysicsDirectSpaceState3D) -> void:
	print("-- dash line --")
	var q := PhysicsRayQueryParameters3D.create(Vector3(28, 3.0, -36.9), Vector3(28, 3.0, -20))
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		_fail("gap 1: no far platform — the dash line is broken")
	else:
		var d: float = (hit["position"] as Vector3).z - -36.9
		if d < 6.5 or d > 7.5:
			_fail("gap 1 is %.1fm, must be ~7m" % d)
		else:
			print("  gap 1 clear, %.1fm of air" % d)
	q = PhysicsRayQueryParameters3D.create(Vector3(28, 4.5, -36.9), Vector3(28, 4.5, -18.1))
	if not space.intersect_ray(q).is_empty():
		_fail("dash corridor blocked")
	else:
		print("  dash corridor clear between P1 and P2")
	q = PhysicsRayQueryParameters3D.create(Vector3(24.9, 3.7, -24), Vector3(10, 3.7, -24))
	if not space.intersect_ray(q).is_empty():
		_fail("final dash clips the office east wall")
	else:
		print("  final dash clears the east wall, lands on the roof")

## Select's second card row and the per-level briefing must fit 1280x720.
func _check_ui_fits(briefing: bool) -> void:
	var vw := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	if not briefing:
		print("-- select screen fits the viewport --")
		var select := _game.screens._screens["select"] as ScreenSelect
		if select._cards.get_child_count() != CharData.ids().size():
			_fail("wrong operative card count")
		if select._levels.get_child_count() != LevelData.ids().size():
			_fail("wrong level card count")
		var h: float = (select.center.get_child(0) as Control).size.y
		if select._cards.size.x > vw or select._levels.size.x > vw:
			_fail("a card row is wider than the 1280px viewport")
		elif h > vh:
			_fail("select screen is %.0fpx tall" % h)
		else:
			print("  rows fit 1280px, content %.0fpx tall" % h)
		return
	print("-- briefing screen fits the viewport --")
	var b := _game.screens._screens["briefing"] as ScreenBriefing
	var v := b.center.get_child(0)
	var title := (v.get_child(0) as Label).text
	if not "PORT VESPER" in title:
		_fail("briefing header is '%s'" % title)
	var bh: float = (v as Control).size.y
	if bh > vh:
		_fail("briefing is %.0fpx tall — DEPLOY is off screen" % bh)
	else:
		print("  '%s', content %.0fpx tall" % [title, bh])

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

func _floor_under(space: PhysicsDirectSpaceState3D, pos: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 1.2, 0), pos + Vector3(0, -5.0, 0))
	var hit := space.intersect_ray(q)
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
func _headroom(space: PhysicsDirectSpaceState3D, floor_pos: Vector3) -> float:
	var from := floor_pos + Vector3(0, 0.06, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 6.0, 0))
	var hit := space.intersect_ray(q)
	return 99.0 if hit.is_empty() else (hit["position"] as Vector3).y - floor_pos.y
