extends Node
const St2Util = preload("res://tools/st2_util.gd")
const St2Checks = preload("res://tools/st2_checks.gd")
## PORT VESPER smoketest driver: floor, zones, target, guards, spawn,
## culvert/vent, dash gap, gate seals, guard coverage, hiding spots,
## pickups, intel, UI fit.
var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _checks

const SPAWN := Vector3(60, 0, -72)

## label, position, headroom: "" = standable, "crawl" = exactly 1.0m,
## "any" = transitional (no height asserted).
const POINTS := [
	["spawn", Vector3(60, 0, -72), ""], ["gateway", Vector3(0, 0, -60), ""],
	["van", Vector3(6, 0, -64), ""], ["gatehouse", Vector3(11, 0, -53), ""],
	["fence door", Vector3(-60, 0, -58), ""], ["culvert outer", Vector3(70, 0, -64), "crawl"],
	["culvert inner", Vector3(70, 0, -58), "crawl"], ["outflow", Vector3(70, 0, -68), ""],
	["north road w", Vector3(-40, 0, -52), ""], ["north road e", Vector3(30, 0, -52), ""],
	["terminal w", Vector3(-80, 0, -20), ""], ["terminal mid", Vector3(-60, 0, 4), ""],
	["storage", Vector3(-40, 0, 6), ""], ["warehouse", Vector3(-80, 0, -48), ""],
	["vent outer", Vector3(-10, 0, -35), ""], ["vent mid", Vector3(-10, 0, -32), "crawl"],
	["vent inner", Vector3(-10, 0, -29.5), ""], ["office interior", Vector3(-6, 0, -16), ""],
	["safe room", Vector3(10, 0, -28), ""], ["skylight drop", Vector3(0, 0, -14), "any"],
	["office roof", Vector3(4, 4.2, -14), ""], ["ramp top", Vector3(-21, 4.2, -12), "any"],
	["dash platform", Vector3(-29.5, 5.1, -23), ""], ["west door out", Vector3(-24, 0, -14), ""],
	["east door out", Vector3(18, 0, -20), ""], ["front door out", Vector3(-4, 0, -4), ""],
	["dock office", Vector3(55, 0, -15), ""], ["pier deck", Vector3(52.5, 0, 20), ""],
	["boat", Vector3(52.5, 0, 42), ""], ["crane", Vector3(88, 0, 0), ""],
	["shore", Vector3(60, 0, 18), ""],
]
const ZONES := [
	["boat", Vector3(52.5, 0, 42), 4.0], ["van", Vector3(6, 0, -64), 4.0],
	["outflow", Vector3(70, 0, -68), 3.0],
]
## One waypoint list per approach band; every one needs 2+ guard cones
## and a hiding spot within 15m.
const APPROACHES := [
	["west", [Vector3(-70, 0, -14), Vector3(-50, 0, -14), Vector3(-30, 0, -14)]],
	["north", [Vector3(-20, 0, -52), Vector3(0, 0, -52), Vector3(20, 0, -52)]],
	["east", [Vector3(32, 0, -20), Vector3(44, 0, -21)]],
	["shore", [Vector3(40, 0, 18), Vector3(55, 0, 18)]],
	["roof", [Vector3(-29.5, 4.5, -23), Vector3(-20, 3.6, -12), Vector3(-14, 3.6, -12)]],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_checks = St2Checks.new(self)

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
		var space := _game.get_world_3d().direct_space_state
		_check_points(space)
		_check_zones()
		_check_target()
		_check_guard_count()
		_checks._check_culvert_sealed(space)
		_checks._check_vent(space)
		_checks._check_dash_gap(space)
		_checks._check_spawn_sightlines(space)
		_checks._check_gate_seals(space)
		_check_guard_coverage(space)
		_check_hiding_spots()
		_checks._check_pickups()
		_checks._check_bolt_range()
		_checks._check_intel_grounded(space)
	elif _frame >= 9 and _frame <= 11:
		var id: String = ["wizard", "chad", "regular"][_frame - 9]
		_game.selected_char = id
		_game.flow.start_mission()
		_check_kit(id)
		_check_spawn_yaw()
		if _frame == 11:
			_game.flow.show_select()
	elif _frame == 15:
		_game.flow.select_char("wizard")
	elif _frame == 18:
		_checks._check_ui_fits()
		_checks._check_intel_panel_fits()
		print("\n%d problem(s)" % _bad)
		get_tree().quit()

func _check_kit(char_id: String) -> void:
	var p := _game.player
	if p.char_id != char_id:
		_fail("player char_id is %s, expected %s" % [p.char_id, char_id])
	if p.global_position.distance_to(SPAWN) > 0.5:
		_fail("%s spawned at %s, expected %s" % [char_id, p.global_position, SPAWN])
	else:
		print("-- kit: %s ok --" % char_id)

func _check_points(space: PhysicsDirectSpaceState3D) -> void:
	print("-- floor and headroom --")
	for entry in POINTS:
		var label: String = entry[0]
		var pos: Vector3 = entry[1]
		var want: String = entry[2]
		var floor_y := St2Util.floor_under(space, pos)
		if floor_y < -900.0:
			_fail("%s has no floor at %s" % [label, pos])
			continue
		var head := St2Util.headroom(space, Vector3(pos.x, floor_y, pos.z))
		if want == "crawl" and (head < 0.95 or head > 1.05):
			_fail("%s crawl is %.2fm, must be 1.0m" % [label, head])
		elif want == "" and head < 1.75:
			_fail("%s headroom %.2fm — cannot stand" % [label, head])
	print("  %d points floored" % POINTS.size())

func _check_zones() -> void:
	print("-- extraction zones --")
	var areas: Array = []
	St2Util.collect(_game.level_root, areas, "Area3D")
	for entry in ZONES:
		var ok := false
		for a in areas:
			var r := (((a as Area3D).get_child(0) as CollisionShape3D).shape as SphereShape3D).radius
			if (a as Area3D).global_position.distance_to(entry[1]) < 1.0 and absf(r - entry[2]) < 0.1:
				ok = true
		if not ok:
			_fail("extraction zone '%s' missing" % entry[0])
	print("  3 zones present")

func _check_target() -> void:
	print("-- the Harbormaster --")
	if _game.target == null:
		_fail("no target spawned")
	elif _game.target.patrol_points.size() != 3:
		_fail("target has %d patrol points, expected 3" % _game.target.patrol_points.size())
	else:
		print("  3 patrol points")

func _check_guard_count() -> void:
	if _game.guards.size() != 23:
		_fail("expected 23 guards, found %d" % _game.guards.size())
	else:
		print("-- guards --\n  23 guards posted")

## The player must spawn facing the district (+z), not the fence.
func _check_spawn_yaw() -> void:
	var yaw := _game.player.rotation.y
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var dir: Vector3 = (Vector3(60, 0, -40) - _game.player.global_position).normalized()
	if fwd.dot(dir) < 0.9:
		_fail("%s spawn faces away (dot %.2f)" % [_game.selected_char, fwd.dot(dir)])
	else:
		print("-- yaw: %s faces the district --" % _game.selected_char)

func _check_guard_coverage(space: PhysicsDirectSpaceState3D) -> void:
	print("-- guard coverage --")
	var vr := float(GuardData.stats()["vision_range"])
	var exclude: Array[RID] = [_game.player.get_rid()]
	for g in _game.guards:
		exclude.append((g as Node3D).get_rid())
	var total := 0
	for a in APPROACHES:
		for wp in a[1]:
			total += 1
			var n := 0
			for post in GuardPosts2.all():
				var wps: Array = (post as Dictionary)["waypoints"]
				if _covers(space, wps[0], wps[1], wp, vr, exclude):
					n += 1
			if n < 2:
				_fail("%s approach at %s: %d cones, need 2" % [a[0], wp, n])
	print("  %d approach waypoints checked" % total)

func _covers(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3,
		wp: Vector3, vr: float, exclude: Array) -> bool:
	var target: Vector3 = wp + Vector3(0, 1.6, 0)
	for ep in [a, b]:
		var other: Vector3 = b if ep == a else a
		var eye: Vector3 = ep + Vector3(0, 1.6, 0)
		if eye.distance_to(target) > vr:
			continue
		var to := Vector2(wp.x - ep.x, wp.z - ep.z)
		var facing := Vector2(other.x - ep.x, other.z - ep.z)
		if to.length() < 1.5 or to.normalized().dot(facing.normalized()) > 0.45:
			var q := PhysicsRayQueryParameters3D.create(eye, target)
			q.exclude = exclude
			if space.intersect_ray(q).is_empty():
				return true
	return false

## A tagged hiding spot within 15m of every approach waypoint.
func _check_hiding_spots() -> void:
	print("-- hiding spots --")
	var spots: Array = []
	for n in _game.level_root.find_children("*", "", true, false):
		if n.is_in_group("hiding_spot"):
			spots.append(n)
	var total := 0
	for a in APPROACHES:
		for wp in a[1]:
			total += 1
			var w: Vector3 = wp
			var best := 999.0
			for s in spots:
				var p := (s as Node3D).global_position
				best = minf(best, Vector2(p.x - w.x, p.z - w.z).length())
			if best > 15.0:
				_fail("%s approach at %s: nearest cover %.1fm" % [a[0], w, best])
	print("  %d approach waypoints, %d spots tagged" % [total, spots.size()])

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)
