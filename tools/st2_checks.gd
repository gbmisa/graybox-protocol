extends RefCounted
const St2Util = preload("res://tools/st2_util.gd")
## PORT VESPER smoketest: pickup/intel/UI checks.
var _d: Node

func _init(d: Node) -> void:
	_d = d

func _check_pickups() -> void:
	print("-- intel and keys --")
	var intel: Array = []
	var keys: Array = []
	St2Util.collect(_d._game.level_root, intel, "IntelPickup")
	St2Util.collect(_d._game.level_root, keys, "KeyItem")
	if intel.size() != 6:
		_d._fail("expected 6 intel notes, found %d" % intel.size())
	for p in intel:
		if not IntelData.has((p as IntelPickup).intel_id):
			_d._fail("intel with bad id")
	if keys.size() != 3:
		_d._fail("expected 3 keys, found %d" % keys.size())
	for k in keys:
		if not KeyData.has((k as KeyItem).key_id):
			_d._fail("key with bad id")
	print("  %d intel, %d keys, ids valid" % [intel.size(), keys.size()])

## Every intel note must sit on a physical surface: a ray down from its
## base must hit solid ground within 0.5m.
func _check_intel_grounded(space: PhysicsDirectSpaceState3D) -> void:
	print("-- intel grounded --")
	var intel: Array = []
	St2Util.collect(_d._game.level_root, intel, "IntelPickup")
	for p in intel:
		var pos := (p as Node3D).global_position
		# The visible datapad sits at local y≈0.03; the surface must be
		# within 0.5m below it, or the prop floats.
		var prop := pos + Vector3(0, 0.03, 0)
		var hit := St2Util.ray(space, prop + Vector3(0, 0.05, 0), prop - Vector3(0, 0.5, 0))
		if hit.is_empty():
			_d._fail("intel %s floats at %s" % [(p as IntelPickup).intel_id, pos])
	print("  %d notes grounded" % intel.size())

## Every intel reading panel must fit inside the 1280x720 viewport.
func _check_intel_panel_fits() -> void:
	print("-- intel panels fit --")
	var vw := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	for id in IntelData.all().keys():
		_d._game.hud.show_intel(id)
		var rect: Rect2 = (_d._game.hud.intel as HudIntel)._panel.get_rect()
		if rect.position.x < 0 or rect.position.y < 0 \
				or rect.end.x > vw or rect.end.y > vh:
			_d._fail("intel panel %s overflows: %s" % [id, rect])
		_d._game.hud.intel.hide_panel()
	print("  4 panels inside %dx%d" % [vw, vh])
func _check_bolt_range() -> void:
	var br := float(AbilityData.get_ability("bolt")["range"])
	var vr := float(GuardData.stats()["vision_range"])
	if br >= vr:
		_d._fail("bolt range %.0fm >= guard vision %.0fm" % [br, vr])
	else:
		print("-- charged bolt --\n  range %.0fm < vision %.0fm" % [br, vr])

func _check_culvert_sealed(space: PhysicsDirectSpaceState3D) -> void:
	print("-- culvert sealed --")
	for x in [68.4, 70.0, 71.6]:
		if St2Util.ray(space, Vector3(x, 8.0, -60), Vector3(x, 0.5, -60)).is_empty():
			_d._fail("open gap above/beside the culvert at x=%.1f" % x)
	print("  notch filled, lintel overhead")

## The office vent: exactly 1.0m inside, capped by the header above.
func _check_vent(space: PhysicsDirectSpaceState3D) -> void:
	print("-- vent --")
	var head := St2Util.headroom(space, Vector3(-10, 0, -32))
	if head < 0.95 or head > 1.05:
		_d._fail("vent crawl is %.2fm, must be 1.0m" % head)
	else:
		print("  vent is 1.0m")
	if St2Util.ray(space, Vector3(-10, 2.0, -28), Vector3(-10, 2.0, -36)).is_empty():
		_d._fail("open gap above the vent at x=-10")
	else:
		print("  header caps the vent")

## 6.7m gap, unjumpable (jump ~4.74m) and dashable (dash 9.1m). The roof
## is a huge landing — no precision braking. Corridor clear above.
func _check_dash_gap(space: PhysicsDirectSpaceState3D) -> void:
	print("-- dash gap --")
	# Platform P1 east edge (x=-27, top 4.5) to roof west edge (x=-20):
	# the horizontal corridor must be empty, and the drop is landable.
	var gap_ray := St2Util.ray(space, Vector3(-26.9, 4.5, -23), Vector3(-20, 4.5, -23))
	if not gap_ray.is_empty():
		_d._fail("dash gap blocked at %s" % gap_ray["position"])
	else:
		print("  gap: 7.0m, corridor clear")
	var plat := St2Util.ray(space, Vector3(-29.5, 6.0, -23), Vector3(-29.5, 3.0, -23))
	var roof := St2Util.ray(space, Vector3(-15, 6.0, -23), Vector3(-15, 2.0, -23))
	var ph: float = 0.0 if plat.is_empty() else (plat["position"] as Vector3).y
	var rh: float = 0.0 if roof.is_empty() else (roof["position"] as Vector3).y
	if ph < 4.4 or ph > 4.6:
		_d._fail("platform top at %.1fm, expected 4.5" % ph)
	if rh < 3.5 or rh > 3.7:
		_d._fail("roof top at %.1fm, expected 3.6" % rh)
	if ph - rh < 0.5 or ph - rh > 1.5:
		_d._fail("drop %.1fm, must be 0.9m" % (ph - rh))

## The single spawn must be 25m+ from every guard post, with no clear
## 34m sightline to it.
func _check_spawn_sightlines(space: PhysicsDirectSpaceState3D) -> void:
	print("-- spawn sightlines --")
	var n := 0
	var s := Vector3(60, 1.0, -72)
	for post in GuardPosts2.all():
		for wp in (post as Dictionary)["waypoints"]:
			n += 1
			var from: Vector3 = wp + Vector3(0, 1.6, 0)
			var d: float = from.distance_to(s)
			if d < 25.0:
				_d._fail("guard at %s only %.1fm from spawn" % [wp, d])
			elif d <= 34.0 and St2Util.ray(space, from, s).is_empty():
				_d._fail("guard at %s sees the spawn" % wp)
	print("  %d guard waypoints checked" % n)

## Every gated barrier must be continuous across its span — no walkaround.
func _check_gate_seals(space: PhysicsDirectSpaceState3D) -> void:
	print("-- gate seals --")
	# Office south wall (z=-8): solid except the front door x[-5,-3].
	for x in [-14.0, -4.0, 2.0, 10.0]:
		_must_hit(space, Vector3(x, 1.5, -4), Vector3(x, 1.5, -12), "office south wall")
	# Office north wall (z=-32): solid except the crawl vent (checked above).
	for x in [-16.0, -10.0, 0.0, 8.0]:
		_must_hit(space, Vector3(x, 1.5, -28), Vector3(x, 1.5, -36), "office north wall")
	# Office west wall (x=-20): solid except the west door z[-15,-13].
	for z in [-26.0, -14.0, -10.0]:
		_must_hit(space, Vector3(-24, 1.5, z), Vector3(-16, 1.5, z), "office west wall")
	# Office east wall (x=14): solid except the service door z[-21,-19].
	for z in [-28.0, -20.0, -12.0]:
		_must_hit(space, Vector3(10, 1.5, z), Vector3(18, 1.5, z), "office east wall")
	# Pier fence x[28,72] at z=5 + side fences into the water at z[5,25].
	for x in [30.0, 40.0, 52.0, 62.0, 70.0]:
		_must_hit(space, Vector3(x, 1.5, 0), Vector3(x, 1.5, 10), "pier fence")
	for z in [8.0, 15.0, 22.0]:
		_must_hit(space, Vector3(22, 1.5, z), Vector3(34, 1.5, z), "pier side west")
		_must_hit(space, Vector3(66, 1.5, z), Vector3(78, 1.5, z), "pier side east")
	# Storage building: solid south/east/west walls, north wall split by
	# the single 3m door at x[-41.5,-38.5], z=-6.
	for x in [-44.0, -42.0, -38.0, -36.0]:
		_must_hit(space, Vector3(x, 1.5, 12), Vector3(x, 1.5, 24), "storage south wall")
		_must_hit(space, Vector3(x, 1.5, 0), Vector3(x, 1.5, -12), "storage north wall")
	_must_hit(space, Vector3(-52, 1.5, 6), Vector3(-40, 1.5, 6), "storage west wall")
	_must_hit(space, Vector3(-40, 1.5, 6), Vector3(-28, 1.5, 6), "storage east wall")
	# North fence: continuous except the open gateway x[-3,3], the fence
	# door x[-61,-59] (closed, three verbs) and the culvert notch x[68,72].
	for x in [-80.0, -40.0, -20.0, 10.0, 50.0]:
		_must_hit(space, Vector3(x, 1.5, -56), Vector3(x, 1.5, -64), "north fence")
	_must_hit(space, Vector3(-60, 1.5, -56), Vector3(-60, 1.5, -64), "fence door")
	if not St2Util.ray(space, Vector3(0, 1.5, -56), Vector3(0, 1.5, -64)).is_empty():
		_d._fail("vehicle gateway blocked — it must stay open")
	else:
		print("  gateway open")
	print("  barrier spans continuous")

func _must_hit(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, label: String) -> void:
	if St2Util.ray(space, a, b).is_empty():
		_d._fail("walkaround gap in %s (%s -> %s)" % [label, a, b])

## The briefing (with the new objective block) must fit 1280x720.
func _check_ui_fits() -> void:
	print("-- briefing fits --")
	var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var b := _d._game.screens._screens["briefing"] as ScreenBriefing
	var v := b.center.get_child(0)
	if not "PORT VESPER" in (v.get_child(0) as Label).text:
		_d._fail("briefing header wrong")
	var bh: float = (v as Control).size.y
	if bh > vh:
		_d._fail("briefing %.0fpx tall" % bh)
	else:
		print("  content %.0fpx tall" % bh)

