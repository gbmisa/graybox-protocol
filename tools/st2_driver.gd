extends Node
const St2Util = preload("res://tools/st2_util.gd")
const St2Checks = preload("res://tools/st2_checks.gd")
## PORT VESPER smoketest driver: floor, zones, target, guards, seals,
## spawns, dash line, gates, pickups, intel, UI fit.
var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _checks

## label, position, headroom: "" = standable, "crawl" = exactly 1.0m,
## "any" = transitional (no height asserted).
const POINTS := [
	["culvert outer", Vector3(70, 0, -64), "crawl"],
	["culvert inner", Vector3(70, 0, -58), "crawl"], ["terminal mid", Vector3(-70, 0, -26), ""],
	["dash ramp base", Vector3(-58, 0, -26), "any"], ["dash P1", Vector3(-43, 4.2, -26), ""],
	["dash P2", Vector3(-28, 4.2, -26), ""], ["office roof", Vector3(0, 4.2, -24), ""],
	["skylight drop", Vector3(13, 0, -20), "any"], ["office interior", Vector3(8, 0, -22), ""],
	["breach outer", Vector3(-99, 0, -27), ""], ["breach inner", Vector3(-93, 0, -27), ""],
	["warehouse maze", Vector3(-80, 0, -27), ""], ["wh east door", Vector3(-64, 0, -27), ""],
	["storage interior", Vector3(-43, 0, 6), ""], ["dock office", Vector3(55, 0, -15), ""],
	["pier deck", Vector3(52.5, 0, 20), ""], ["boat", Vector3(52.5, 0, 42), ""],
	["van", Vector3(0, 0, -64), ""], ["outflow", Vector3(70, 0, -68), ""],
	["crane zone", Vector3(88, 0, 0), ""],
]
const ZONES := [
	["boat", Vector3(52.5, 0, 42), 4.0], ["van", Vector3(0, 0, -64), 4.0],
	["outflow", Vector3(70, 0, -68), 3.0],
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
		_check_culvert_sealed(space)
		_check_dash_line(space)
		_check_spawn_sightlines(space)
		_check_gate_seals(space)
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
	var want: Vector3 = (Level2Builder.player_spawns()[char_id] as Dictionary)["pos"]
	if p.global_position.distance_to(want) > 0.5:
		_fail("%s spawned at %s, expected %s" % [char_id, p.global_position, want])
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
	if _game.guards.size() != 15:
		_fail("expected 15 guards, found %d" % _game.guards.size())
	else:
		print("-- guards --\n  15 guards posted")

## The player must spawn facing the level, not a wall: yaw 0 faces -z, so
## every level-2 spawn yaw must point the camera at its vector (dot > 0.9).
func _check_spawn_yaw() -> void:
	var yaw := _game.player.rotation.y
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var want: Vector3 = {
		"regular": Vector3(70, 0, -60), "wizard": Vector3(-58, 0, -40),
		"chad": Vector3(-96, 0, -40)}[_game.selected_char]
	var dir: Vector3 = (want - _game.player.global_position).normalized()
	if fwd.dot(dir) < 0.9:
		_fail("%s spawn faces away (dot %.2f)" % [_game.selected_char, fwd.dot(dir)])
	else:
		print("-- yaw: %s faces the level --" % _game.selected_char)

func _check_culvert_sealed(space: PhysicsDirectSpaceState3D) -> void:
	print("-- culvert sealed --")
	for x in [68.4, 70.0, 71.6]:
		if St2Util.ray(space, Vector3(x, 8.0, -60), Vector3(x, 0.5, -60)).is_empty():
			_fail("open gap above/beside the culvert at x=%.1f" % x)
	print("  notch filled, lintel overhead")

## 5.5m gaps, unjumpable (jump ~4.74m) and dashable (dash 9.1m); the 13m P2
## and the 32m office roof are generous landings — no precision braking.
## Corridor clear above the platforms.
func _check_dash_line(space: PhysicsDirectSpaceState3D) -> void:
	print("-- dash line --")
	for g in [["gap 1", -39.9, -34.5], ["gap 2", -21.4, -16.0]]:
		var hit := St2Util.ray(space, Vector3(g[1], 3.6, -26), Vector3(g[1] + 16.0, 3.6, -26))
		var d: float = 999.0 if hit.is_empty() else (hit["position"] as Vector3).x - (g[1] as float)
		# From 0.1m past the platform edge, the next face is 5.5m on.
		if d < 5.0 or d > 6.0:
			_fail("%s is %.1fm, must be ~5.5m" % [g[0], d])
		else:
			print("  %s: %.1fm" % [g[0], d])
	if not St2Util.ray(space, Vector3(-44, 4.5, -26), Vector3(-14, 4.5, -26)).is_empty():
		_fail("dash corridor blocked above the platforms")
	else:
		print("  corridor clear")

## Every guard post must be 25m+ from every spawn pad, and no post may
## have a clear 34m sightline to any spawn.
func _check_spawn_sightlines(space: PhysicsDirectSpaceState3D) -> void:
	print("-- spawn sightlines --")
	var n := 0
	var spawns := Level2Builder.player_spawns()
	for post in GuardPosts2.all():
		for wp in (post as Dictionary)["waypoints"]:
			n += 1
			var from: Vector3 = wp + Vector3(0, 1.6, 0)
			for cid in spawns.keys():
				var s: Vector3 = (spawns[cid] as Dictionary)["pos"] + Vector3(0, 1.0, 0)
				var d: float = from.distance_to(s)
				if d < 25.0:
					_fail("guard at %s only %.1fm from %s spawn" % [wp, d, cid])
				elif d <= 34.0 and St2Util.ray(space, from, s).is_empty():
					_fail("guard at %s sees the %s spawn" % [wp, cid])
	print("  %d guard waypoints checked x3 spawns" % n)

## Every gated barrier must be continuous across its span — no walkaround.
func _check_gate_seals(space: PhysicsDirectSpaceState3D) -> void:
	print("-- gate seals --")
	# Pier fence x[28,72] at z=5 + side fences into the water at z[5,25].
	for x in [30.0, 40.0, 52.0, 62.0, 70.0]:
		_must_hit(space, Vector3(x, 1.5, 0), Vector3(x, 1.5, 10), "pier fence")
	for z in [8.0, 15.0, 22.0]:
		_must_hit(space, Vector3(22, 1.5, z), Vector3(34, 1.5, z), "pier side west")
		_must_hit(space, Vector3(66, 1.5, z), Vector3(78, 1.5, z), "pier side east")
	# Storage building: solid south/east/west walls, north wall split by
	# the single 3m key door at x[-41.5,-38.5], z=-6.
	for x in [-44.0, -42.0, -38.0, -36.0]:
		_must_hit(space, Vector3(x, 1.5, 12), Vector3(x, 1.5, 24), "storage south wall")
		_must_hit(space, Vector3(x, 1.5, 0), Vector3(x, 1.5, -12), "storage north wall")
	_must_hit(space, Vector3(-52, 1.5, 6), Vector3(-40, 1.5, 6), "storage west wall")
	_must_hit(space, Vector3(-40, 1.5, 6), Vector3(-28, 1.5, 6), "storage east wall")
	for z in [-27.0, -24.0, -21.0]:
		_must_hit(space, Vector3(10, 1.5, z), Vector3(20, 1.5, z), "office east wall")
	for z in [-30.0, -27.0, -24.0]:
		_must_hit(space, Vector3(-100, 1.5, z), Vector3(-92, 1.5, z), "warehouse west wall")
	print("  barrier spans continuous")

func _must_hit(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, label: String) -> void:
	if St2Util.ray(space, a, b).is_empty():
		_fail("walkaround gap in %s (%s -> %s)" % [label, a, b])

## 4 intel notes (valid ids) + 2 keys (valid ids).
func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

