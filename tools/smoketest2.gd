extends SceneTree
## Headless PORT VESPER check. Mirrors tools/smoketest.gd.
##     godot --headless --path . --script res://tools/smoketest2.gd
var _frame := 0
var _game: GrayboxGame
var _bad := 0

## label, position, headroom: "" = standable, "crawl" = exactly 1.0m,
## "any" = transitional (no height asserted).
const POINTS := [
	["spawn", Vector3(0, 0, -74), ""], ["culvert outer", Vector3(70, 0, -64), "crawl"],
	["culvert inner", Vector3(70, 0, -58), "crawl"], ["terminal mid", Vector3(-70, 0, -26), ""],
	["dash ramp base", Vector3(-58, 0, -26), "any"], ["dash P1", Vector3(-43, 4.2, -26), ""],
	["dash P2", Vector3(-28, 4.2, -26), ""], ["office roof", Vector3(0, 4.2, -24), ""],
	["skylight drop", Vector3(13, 0, -20), "any"], ["office interior", Vector3(8, 0, -22), ""],
	["breach outer", Vector3(-99, 0, -27), ""], ["breach inner", Vector3(-93, 0, -27), ""],
	["warehouse maze", Vector3(-80, 0, -27), ""], ["wh east door", Vector3(-64, 0, -27), ""],
	["storage compound", Vector3(-34, 0, 4), ""], ["dock office", Vector3(55, 0, -15), ""],
	["pier deck", Vector3(52.5, 0, 20), ""], ["boat", Vector3(52.5, 0, 42), ""],
	["van", Vector3(0, 0, -64), ""], ["outflow", Vector3(70, 0, -68), ""],
	["crane zone", Vector3(88, 0, 0), ""],
]
const ZONES := [
	["boat", Vector3(52.5, 0, 42), 4.0], ["van", Vector3(0, 0, -64), 4.0],
	["outflow", Vector3(70, 0, -68), 3.0],
]
const SPAWN := Vector3(0, 1.0, -74)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
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
		_check_pickups()
		_check_bolt_range()
	elif _frame >= 9 and _frame <= 11:
		var id: String = ["wizard", "chad", "regular"][_frame - 9]
		_game.selected_char = id
		_game.flow.start_mission()
		_check_kit(id)
		if _frame == 11:
			_game.flow.show_select()
	elif _frame == 15:
		_game.flow.select_char("wizard")
	elif _frame == 18:
		_check_ui_fits()
		print("\n%d problem(s)" % _bad)
		return true
	return false

func _check_kit(char_id: String) -> void:
	var p := _game.player
	if p.char_id != char_id:
		_fail("player char_id is %s, expected %s" % [p.char_id, char_id])
	if p.global_position.distance_to(Level2Builder.PLAYER_SPAWN) > 0.5:
		_fail("%s spawned at %s" % [char_id, p.global_position])
	else:
		print("-- kit: %s ok --" % char_id)

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
		if want == "crawl" and (head < 0.95 or head > 1.05):
			_fail("%s crawl is %.2fm, must be 1.0m" % [label, head])
		elif want == "" and head < 1.75:
			_fail("%s headroom %.2fm — cannot stand" % [label, head])
	print("  %d points floored" % POINTS.size())

func _check_zones() -> void:
	print("-- extraction zones --")
	var areas: Array = []
	_collect(_game.level_root, areas, "Area3D")
	for entry in ZONES:
		var ok := false
		for a in areas:
			var r := (((a as Area3D).get_child(0) as CollisionShape3D).shape as SphereShape3D).radius
			if (a as Area3D).global_position.distance_to(entry[1]) < 1.0 and absf(r - entry[2]) < 0.1:
				ok = true
		if not ok:
			_fail("extraction zone '%s' missing" % entry[0])
	print("  3 zones present")

## Generic subtree collector by class name.
func _collect(node: Node, out: Array, cls: String) -> void:
	for child in node.get_children():
		if child.get_class() == cls or (cls == "IntelPickup" and child is IntelPickup) \
				or (cls == "KeyItem" and child is KeyItem):
			out.append(child)
		_collect(child, out, cls)

func _check_target() -> void:
	print("-- the Harbormaster --")
	if _game.target == null:
		_fail("no target spawned")
	elif _game.target.patrol_points.size() != 3:
		_fail("target has %d patrol points, expected 3" % _game.target.patrol_points.size())
	else:
		print("  3 patrol points")

func _check_guard_count() -> void:
	if _game.guards.size() != 12:
		_fail("expected 12 guards, found %d" % _game.guards.size())
	else:
		print("-- guards --\n  12 guards posted")

func _check_culvert_sealed(space: PhysicsDirectSpaceState3D) -> void:
	print("-- culvert sealed --")
	for x in [68.4, 70.0, 71.6]:
		if _ray(space, Vector3(x, 8.0, -60), Vector3(x, 0.5, -60)).is_empty():
			_fail("open gap above/beside the culvert at x=%.1f" % x)
	print("  notch filled, lintel overhead")

## 9.0m gaps, unjumpable and dashable; corridor clear.
func _check_dash_line(space: PhysicsDirectSpaceState3D) -> void:
	print("-- dash line --")
	for g in [["gap 1", -39.9, -31.0], ["gap 2", -24.9, -16.0]]:
		var hit := _ray(space, Vector3(g[1], 3.6, -26), Vector3(g[1] + 16.0, 3.6, -26))
		var d: float = 999.0 if hit.is_empty() else (hit["position"] as Vector3).x - (g[1] as float)
		# From 0.1m past the platform edge, the next face is 8.9m on.
		if d < 8.5 or d > 9.5:
			_fail("%s is %.1fm, must be ~9.0m" % [g[0], d])
		else:
			print("  %s: %.1fm" % [g[0], d])
	if not _ray(space, Vector3(-44, 4.5, -26), Vector3(-14, 4.5, -26)).is_empty():
		_fail("dash corridor blocked above the platforms")
	else:
		print("  corridor clear")

## No guard post may see the spawn: every ray must hit cover or the post
## must be beyond guard vision (34m).
func _check_spawn_sightlines(space: PhysicsDirectSpaceState3D) -> void:
	print("-- spawn sightlines --")
	var n := 0
	for post in GuardPosts2.all():
		for wp in (post as Dictionary)["waypoints"]:
			n += 1
			var from: Vector3 = wp + Vector3(0, 1.6, 0)
			if _ray(space, from, SPAWN).is_empty() and from.distance_to(SPAWN) <= 34.0:
				_fail("guard at %s sees the spawn" % wp)
	print("  %d guard waypoints checked" % n)

## Every gated barrier must be continuous across its span — no walkaround.
func _check_gate_seals(space: PhysicsDirectSpaceState3D) -> void:
	print("-- gate seals --")
	for x in [42.0, 48.0, 52.0, 58.0, 63.0]:
		_must_hit(space, Vector3(x, 1.5, 0), Vector3(x, 1.5, 10), "pier fence")
	for z in [-5.0, 0.0, 6.0, 12.0, 18.0]:
		_must_hit(space, Vector3(-45, 1.5, z), Vector3(-35, 1.5, z), "storage fence")
	for z in [-27.0, -24.0, -21.0]:
		_must_hit(space, Vector3(10, 1.5, z), Vector3(20, 1.5, z), "office east wall")
	for z in [-30.0, -27.0, -24.0]:
		_must_hit(space, Vector3(-100, 1.5, z), Vector3(-92, 1.5, z), "warehouse west wall")
	print("  barrier spans continuous")

func _must_hit(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, label: String) -> void:
	if _ray(space, a, b).is_empty():
		_fail("walkaround gap in %s (%s -> %s)" % [label, a, b])

## 4 intel notes (valid ids) + 2 keys (valid ids).
func _check_pickups() -> void:
	print("-- intel and keys --")
	var intel: Array = []
	var keys: Array = []
	_collect(_game.level_root, intel, "IntelPickup")
	_collect(_game.level_root, keys, "KeyItem")
	if intel.size() != 4:
		_fail("expected 4 intel notes, found %d" % intel.size())
	for p in intel:
		if not IntelData.has((p as IntelPickup).intel_id):
			_fail("intel with bad id")
	if keys.size() != 2:
		_fail("expected 2 keys, found %d" % keys.size())
	for k in keys:
		if not KeyData.has((k as KeyItem).key_id):
			_fail("key with bad id")
	print("  %d intel, %d keys, ids valid" % [intel.size(), keys.size()])

## Charged bolt must die before guard vision does (34m).
func _check_bolt_range() -> void:
	var br := float(AbilityData.get_ability("bolt")["range"])
	var vr := float(GuardData.stats()["vision_range"])
	if br >= vr:
		_fail("bolt range %.0fm >= guard vision %.0fm" % [br, vr])
	else:
		print("-- charged bolt --\n  range %.0fm < vision %.0fm" % [br, vr])

## The briefing (with the new objective block) must fit 1280x720.
func _check_ui_fits() -> void:
	print("-- briefing fits --")
	var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var b := _game.screens._screens["briefing"] as ScreenBriefing
	var v := b.center.get_child(0)
	if not "PORT VESPER" in (v.get_child(0) as Label).text:
		_fail("briefing header wrong")
	var bh: float = (v as Control).size.y
	if bh > vh:
		_fail("briefing %.0fpx tall" % bh)
	else:
		print("  content %.0fpx tall" % bh)

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

func _ray(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b))

func _floor_under(space: PhysicsDirectSpaceState3D, pos: Vector3) -> float:
	var hit := _ray(space, pos + Vector3(0, 1.2, 0), pos + Vector3(0, -5.0, 0))
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
func _headroom(space: PhysicsDirectSpaceState3D, floor_pos: Vector3) -> float:
	var from := floor_pos + Vector3(0, 0.06, 0)
	var hit := _ray(space, from, from + Vector3(0, 6.0, 0))
	return 99.0 if hit.is_empty() else (hit["position"] as Vector3).y - floor_pos.y
