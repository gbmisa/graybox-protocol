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
	if intel.size() != 4:
		_d._fail("expected 4 intel notes, found %d" % intel.size())
	for p in intel:
		if not IntelData.has((p as IntelPickup).intel_id):
			_d._fail("intel with bad id")
	if keys.size() != 2:
		_d._fail("expected 2 keys, found %d" % keys.size())
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

