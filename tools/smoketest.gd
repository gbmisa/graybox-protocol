extends SceneTree
## Headless level and systems check.
##
##     godot --headless --path . --script res://tools/smoketest.gd
##
## Runs on the first frames rather than _initialize, because nodes added to the
## root before the tree starts never get _ready called.
##
## Every check here exists because the corresponding bug actually shipped once.

var _frame := 0
var _game: GrayboxGame
var _bad := 0

## label, position, headroom expectation
##   ""      must be standable (>= 1.75m)
##   "crawl" must be a crawl gap (~1.0m): fits 0.85m, excludes Chad at 1.45m
##   "any"   transitional space, height not asserted
const POINTS := [
	["spawn", Vector3(0, 0, 70), ""],
	["R culvert mouth", Vector3(-50, 0, 50), "crawl"],
	["R culvert inner", Vector3(-50, 0, 42), "crawl"],
	["R descent upper", Vector3(-50, -0.3, 39), "any"],
	["R descent foot", Vector3(-50, -3.7, 29), "any"],
	["R undercroft", Vector3(-50, -4, 24), ""],
	["R boiler room", Vector3(-45, -4, 2), ""],
	["R sump crawl", Vector3(-68, -4, -6), "crawl"],
	["R sump exit", Vector3(-74, -4, -6), "crawl"],
	["R stair foot", Vector3(-27, -4, -4), "any"],
	["R stair top", Vector3(-21, 6, -6), ""],
	["W courtyard", Vector3(0, 0, 25), ""],
	["W shaft ramp", Vector3(23, 1.0, 10.5), "any"],
	["W platform", Vector3(23, 2.0, 5), ""],
	["W ledge A", Vector3(13, 2.0, 5), ""],
	["W ledge B", Vector3(6, 3.6, 5), ""],
	["W ledge C", Vector3(-1, 5.2, 5), ""],
	["W mezz exit", Vector3(-6, 6, 6), ""],
	["C dock", Vector3(50, 0, 30), ""],
	["C breach inner", Vector3(26, 0, -8), ""],
	["C container 1", Vector3(23, 2.3, -2), ""],
	["C container 3", Vector3(12, 5.6, -2), ""],
	["C mezz exit", Vector3(12, 6, 1), ""],
	["freight floor", Vector3(14, 0, -20), ""],
	["mezz main", Vector3(-10, 6, -20), ""],
	["target spawn", Vector3(0, 12, -27.5), ""],
	["stair top W", Vector3(0, 12, -25), ""],
	["chute landing", Vector3(26, 0, -37), ""],
	["north exit", Vector3(0, 0, -42), ""],
	["roof stair mid", Vector3(-25, 16.4, -30), "any"],
	["roof stair top", Vector3(-25, 18.6, -26), ""],
	["helipad", Vector3(0, 18.6, -20), ""],
]

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.flow.start_mission()
		return false
	if _frame < 8:
		return false          # let the physics server register the new bodies
	if _frame == 8:
		var space := _game.get_world_3d().direct_space_state
		_check_points(space)
		_check_guard_vision()
		_check_crawl_gates_sealed(space)
		_check_freight_escape(space)
		_check_no_regen()
		_game.flow.show_select()
		return false          # let the UI lay out before measuring it
	if _frame < 12:
		return false
	if _frame == 12:
		_check_ui_fits()
		_game.flow.select_char("wizard")    # the longest briefing of the three
		return false
	if _frame < 16:
		return false
	_check_briefing_fits()
	print("\n%d problem(s)" % _bad)
	return true

## The briefing stacks description, route, controls, loadout cards and a
## deploy button. If it outgrows 720px the DEPLOY button goes off the bottom
## and the mission cannot be started at all.
func _check_briefing_fits() -> void:
	print("-- briefing screen fits the viewport --")
	var viewport_h := float(ProjectSettings.get_setting(
		"display/window/size/viewport_height"))
	var briefing := _game.screens._screens["briefing"] as ScreenBriefing
	if briefing.center.get_child_count() == 0:
		_fail("briefing screen built no content")
		return
	var h: float = (briefing.center.get_child(0) as Control).size.y
	if h > viewport_h:
		_fail("briefing is %.0fpx tall, viewport is %.0fpx — DEPLOY is off screen"
			% [h, viewport_h])
	else:
		print("  content %.0fpx tall, viewport %.0fpx" % [h, viewport_h])

# --------------------------------------------------------------- ui fit ---
## A Button sizes to its longest unbroken line of text, so a long description
## silently pushes the third operative's card off the side of the screen and
## you cannot pick them at all. Assert the row fits the viewport.
func _check_ui_fits() -> void:
	print("-- select screen fits the viewport --")
	var viewport_w := float(ProjectSettings.get_setting(
		"display/window/size/viewport_width"))
	var select := _game.screens._screens["select"] as ScreenSelect
	var row := select._cards
	if row.get_child_count() != CharData.ids().size():
		_fail("select screen shows %d cards, expected %d"
			% [row.get_child_count(), CharData.ids().size()])
	var w: float = row.size.x
	if w > viewport_w:
		_fail("operative row is %.0fpx wide, viewport is %.0fpx — %d card(s) off screen"
			% [w, viewport_w, ceili((w - viewport_w) / maxf(1.0, w / 3.0))])
	else:
		print("  %d cards, row %.0fpx wide, viewport %.0fpx"
			% [row.get_child_count(), w, viewport_w])

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

# ------------------------------------------------------- floor / headroom ---
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
		if want == "crawl" and (head < 0.9 or head > 1.35):
			note = " <-- crawl gap should be ~1.0m"
			_bad += 1
		elif want == "" and head < 1.75:
			note = " <-- cannot stand up here"
			_bad += 1
		print("  %-18s y=%7.2f head=%5.2f%s" % [label, floor_y, head, note])

# --------------------------------------------------------- guard vision ---
## Regression test for the bug where the LOS ray terminated inside the
## player's own capsule, so every sight check reported "blocked" and guards
## were blind for the entire life of the project.
func _check_guard_vision() -> void:
	print("-- guard vision --")
	var player := _game.player
	var guard := _game.guards[0] as Guard
	guard.global_position = player.global_position + Vector3(0, 0, 12)
	var to_p := player.global_position - guard.global_position
	guard.rotation.y = atan2(-to_p.x, -to_p.z)
	guard.detect = 0.0
	for i in range(10):
		guard.senses.tick(player, 0.1)
	if guard.detect <= 0.0:
		_fail("guard with clear line of sight did not detect the player")
	else:
		print("  clear LOS detects, meter=%.2f after 1s" % guard.detect)

# ---------------------------------------------------------- crawl gates ---
## A crawl gate enforced by collision is only as strong as the geometry around
## it. The storm drain shipped as a free-standing box with a 1.4m roof, which a
## 1.84m jump cleared — so the gate could simply be walked over.
func _check_crawl_gates_sealed(space: PhysicsDirectSpaceState3D) -> void:
	print("-- crawl gates sealed from above --")
	for probe in [["culvert", Vector3(-50, 0, 46)], ["descent", Vector3(-50, 0, 34)]]:
		var label: String = probe[0]
		var at: Vector3 = probe[1]
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(at.x, 8.0, at.z), Vector3(at.x, 0.2, at.z))
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			_fail("%s is open to the sky — you can drop in from above" % label)
			continue
		var top: float = (hit["position"] as Vector3).y
		if top < 1.9:
			_fail("%s has a standable roof at y=%.2f, within jump reach" % [label, top])
		else:
			print("  %-10s sealed, first surface overhead at y=%.2f" % [label, top])

# ------------------------------------------------------- freight escape ---
## The freight bay was sealed except a 2.3m mantle, so anyone who was not Chad
## and fell in was soft-locked with no way out and no way to die.
func _check_freight_escape(space: PhysicsDirectSpaceState3D) -> void:
	print("-- freight bay escape --")
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(11, 1.5, -19.5), Vector3(5, 1.5, -19.5))
	if space.intersect_ray(q).is_empty():
		print("  doorway to the ground floor is open")
	else:
		_fail("freight bay has no exit — anyone who cannot mantle 2.3m is trapped")

# ------------------------------------------------------------- no regen ---
func _check_no_regen() -> void:
	print("-- health does not regenerate --")
	var health := _game.player.health
	health.hp = 40.0
	for i in range(20):
		health.tick(0.5)
	if health.hp > 40.0:
		_fail("health regenerated to %.1f; it must be permanent for the run" % health.hp)
	else:
		print("  hp stayed at %.1f over 10s" % health.hp)

# ----------------------------------------------------------------- rays ---
func _floor_under(space: PhysicsDirectSpaceState3D, pos: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, 1.2, 0), pos + Vector3(0, -5.0, 0))
	var hit := space.intersect_ray(q)
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y

func _headroom(space: PhysicsDirectSpaceState3D, floor_pos: Vector3) -> float:
	var from := floor_pos + Vector3(0, 0.06, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 6.0, 0))
	var hit := space.intersect_ray(q)
	return 99.0 if hit.is_empty() else (hit["position"] as Vector3).y - floor_pos.y
