extends SceneTree
## Playtest round 9, one case per complaint, headless with the real player in
## HOLLOWAY ROAD:
##   grenades restock and come back to hand; the pump loads a shell at a time
##   and the trigger interrupts it; dead guards drop pistol rounds only; the
##   rifle's scope is a true 3x and hides the gun; a corpse heals 5; night
##   vision lifts the dark; the avenue car is gone; the hook yanks guards and
##   civilians, hauls you over a lip, and the edge of the world kills; a rifle
##   shot alerts guards well out of sight; an alerted guard who loses you goes
##   to where he last saw you, not to where you are now; caches sit on floor.
##
##     godot --headless --path . --script res://tools/smoketest_r9.gd

var _game: GrayboxGame
var _bad := 0
var _p: Player
var _w: PlayerWeapons

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _initialize() -> void:
	_game = GrayboxGame.new()
	root.add_child(_game)
	_run()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _run() -> void:
	await _frames(2)
	_game.selected_char = "regular"
	_game.selected_level = "compound"
	_game.flow.start_mission()
	await _frames(30)
	_p = _game.get_player()
	_p.health.hp = 1.0e6
	_w = _p.kit.get("weapons")
	_data_cases()
	await _grenade_case()
	await _shotgun_case()
	await _scope_case()
	await _nv_case()
	await _caches_case()
	await _yank_case()
	await _rifle_alert_case()
	await _last_seen_case()
	await _fall_case()
	print("%d problem(s)" % _bad)
	quit(1 if _bad > 0 else 0)

func _data_cases() -> void:
	_ok(WeaponData.DROP.keys() == ["pistol"], "a dead guard drops pistol rounds only (%s)" % [WeaponData.DROP])
	_ok(is_equal_approx(ToolEat.HEAL, 5.0), "a corpse heals 5 (%s)" % ToolEat.HEAL)
	var names := []
	for e in MissionCompoundData.EXTRACTIONS:
		names.append(String(e["name"]))
	_ok(not names.has("car"), "the avenue car exit is gone (%s)" % [names])
	_ok(MissionCompoundData.NO_GRAPPLE.is_empty(), "no surface refuses the hook")

func _grenade_case() -> void:
	_w.select("grenade")
	await _frames(30)
	var a: Dictionary = _w.ammo["grenade"]
	_w.set("_cd", 0.0)
	_w.call("_fire", _w.weapon())     # throw the starting one
	await _frames(2)
	_w.give("grenade", 5)
	_ok(int(a["mag"]) == 1 and int(a["reserve"]) == 4, "grenades: 0+5 picked up -> 1 in hand, 4 spare (%d/%d)" % [a["mag"], a["reserve"]])
	_w.select("grenade")
	await _frames(30)
	_w.set("_cd", 0.0)
	_w.call("_fire", _w.weapon())
	await _frames(2)
	_ok(int(a["mag"]) == 1 and int(a["reserve"]) == 3, "grenades: the next one is in hand at once (%d/%d)" % [a["mag"], a["reserve"]])

func _shotgun_case() -> void:
	_w.give("shotgun")
	_w.select("shotgun")
	await _frames(30)
	var a: Dictionary = _w.ammo["shotgun"]
	a["mag"] = 2
	a["reserve"] = 10
	_w.start_reload()
	var shell := float(_w.weapon()["shell_time"])
	await _frames(int(shell * 60.0) + 4)
	_ok(int(a["mag"]) == 3 and _w.reloading(), "pump: one shell per step, still loading (mag %d)" % a["mag"])
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	await _frames(2)
	_ok(not _w.reloading() and int(a["mag"]) == 2, "pump: the trigger stops the reload and fires (mag %d)" % a["mag"])
	_w.start_reload()
	await _frames(int(shell * 60.0 * 5.0) + 20)
	_ok(int(a["mag"]) == 6 and not _w.reloading(), "pump: loads on until full (mag %d)" % a["mag"])

func _scope_case() -> void:
	_w.give("rifle")
	_w.select("rifle")
	await _frames(30)
	Input.action_press("alt_attack")
	await _frames(30)
	var fov := Settings.fov()
	var mag := tan(deg_to_rad(fov) * 0.5) / tan(deg_to_rad(_p.camera.fov) * 0.5)
	_ok(absf(mag - 3.0) < 0.05, "rifle scope: %.2fx magnification" % mag)
	_ok(_p.viewmodel.scoped() and not _p.viewmodel.visible, "rifle scope: the gun drops out of view")
	_ok(HudScope.is_scoped(_game.hud), "rifle scope: the eyepiece is up")
	Input.action_release("alt_attack")
	await _frames(30)
	_ok(not _p.viewmodel.scoped() and _p.viewmodel.visible, "rifle scope: down again")

func _nv_case() -> void:
	var env: Environment = null
	for we in _game.level_root.find_children("*", "WorldEnvironment", true, false):
		env = (we as WorldEnvironment).environment
	var probes := get_nodes_in_group("pitch_probe")
	var off := env.ambient_light_energy
	Input.action_press("night_vision")
	await _frames(2)
	Input.action_release("night_vision")
	await _frames(30)
	var on := env.ambient_light_energy
	_ok(on > off * 3.0, "night vision: lifts the night's ambient (%.2f -> %.2f)" % [off, on])
	_ok(not probes.is_empty() and (probes[0] as ReflectionProbe).ambient_color_energy > 0.5,
		"night vision: PITCH rooms come up too (%d probes)" % probes.size())
	Input.action_press("night_vision")
	await _frames(2)
	Input.action_release("night_vision")
	await _frames(30)

func _caches_case() -> void:
	var space := _p.get_world_3d().direct_space_state
	for c in MissionCompoundData.CACHES:
		var at: Vector3 = c[1]
		var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0.5, 0), at - Vector3(0, 0.5, 0))
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		_ok(not hit.is_empty() and absf((hit["position"] as Vector3).y - at.y) < 0.15,
			"cache %s sits on a floor at %s" % [c[0], at])

## Hook a guard 12m off: he comes to you, reeling, and he's on to you.
func _yank_case() -> void:
	var spot := _clear_spot(12.0)
	_ok(spot != Vector3.INF, "a clear 12m line to test the yank on")
	if spot == Vector3.INF:
		return
	var g := _live_guard()
	g.global_position = spot + Vector3(0, 0, -12)
	g.waypoints = [g.global_position]
	g.brain.reset_route()
	_p.global_position = spot
	_p.velocity = Vector3.ZERO
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(deg_to_rad(-2), 0, 0)
	await _frames(3)
	var d0 := g.global_position.distance_to(_p.global_position)
	var gr: ToolGrapple = _p.kit.get("grapple")
	Input.action_press("grapple")
	await _frames(3)
	Input.action_release("grapple")
	await _frames(40)
	var d1 := g.global_position.distance_to(_p.global_position)
	_ok(d1 < d0 - 6.0 and not gr.hooked(), "grapple: yanks a guard to you (%.1fm -> %.1fm)" % [d0, d1])
	_ok(g.state == Guard.State.ALERT, "grapple: the yanked guard is on to you")
	var civ: Node3D = null
	for c in _game.civilians:
		if (c as Node3D) != null and bool((c as Node).get("alive")):
			civ = c as Node3D
			break
	if civ == null:
		_ok(false, "a civilian to yank")
		return
	g.global_position = Vector3(-60, 0, 0)   # out of the way
	civ.global_position = spot + Vector3(0, 0, -12)
	(civ as Node).process_mode = Node.PROCESS_MODE_DISABLED   # stand still for the shot
	_p.global_position = spot
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(deg_to_rad(-2), 0, 0)
	await _frames(3)
	(civ as Node).process_mode = Node.PROCESS_MODE_INHERIT
	var c0 := civ.global_position.distance_to(_p.global_position)
	Input.action_press("grapple")
	await _frames(3)
	Input.action_release("grapple")
	await _frames(30)
	var c1 := civ.global_position.distance_to(_p.global_position)
	_ok(c1 < c0 - 5.0, "grapple: yanks a civilian to you (%.1fm -> %.1fm)" % [c0, c1])

## A spot with nothing static in the 12m north of it at chest height.
func _clear_spot(d: float) -> Vector3:
	var space := _p.get_world_3d().direct_space_state
	for s in [Vector3(-30, 0.1, 42), Vector3(0, 0.1, 190), Vector3(-10, 4.1, 128), Vector3(0, 0.1, -50)]:
		var spot: Vector3 = s
		var q := PhysicsRayQueryParameters3D.create(spot + Vector3(0, 1.2, 0), spot + Vector3(0, 1.2, -d - 1.0))
		q.collision_mask = 1
		q.exclude = [_p.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit["collider"] is CharacterBody3D:
			return spot
	return Vector3.INF

## From the billboard scaffold (H10), with walls between: they still come.
func _rifle_alert_case() -> void:
	_reset_guards()
	_p.global_position = Vector3(12.6, 7.5, 31)
	await _frames(5)
	_w.select("rifle")
	await _frames(30)
	_w.ammo["rifle"]["mag"] = 5
	_w.set("_cd", 0.0)
	_w.call("_fire", _w.weapon())
	await _frames(2)
	var alerted := 0
	var unseen := 0
	for g in _game.guards:
		var gd := g as Guard
		if gd.alive and gd.state == Guard.State.ALERT:
			alerted += 1
			if not gd.brain.sees_player():
				unseen += 1
	_ok(alerted >= 6 and unseen >= 3, "rifle from the scaffold: %d guards alerted, %d of them out of sight" % [alerted, unseen])

## An alerted guard loses sight; you move on behind the wall. He goes to
## where he saw you — not after you through the wall.
func _last_seen_case() -> void:
	_reset_guards()
	var g := _live_guard()
	# Courtyard side of the compound's south wall; you are outside it.
	g.global_position = Vector3(-20, 0.1, 18)
	g.waypoints = [g.global_position]
	g.brain.reset_route()
	g.last_seen = Vector3(-20, 0.1, 12)
	g.detect = 1.0
	g.enter_alert()
	g.alarm_run = false
	_p.global_position = Vector3(-6, 0.1, 30)   # beyond the wall, out of sight
	_p.velocity = Vector3.ZERO
	await _frames(240)
	var to_seen := g.global_position.distance_to(g.last_seen)
	var to_you := g.global_position.distance_to(_p.global_position)
	_ok(not g.brain.sees_player() and to_seen < 3.0,
		"lost guard goes to last seen (%.1fm from it, %.1fm from you)" % [to_seen, to_you])

func _fall_case() -> void:
	var died := [false]
	_p.died.connect(func() -> void: died[0] = true)
	_p.health.hp = 100.0
	_p.global_position = Vector3(-60, -29.0, 184)   # past the tower's west edge, falling
	_p.velocity = Vector3(0, -20, 0)
	await _frames(20)
	_ok(died[0], "falling off the map kills (y %.1f)" % _p.global_position.y)

func _live_guard() -> Guard:
	for g in _game.guards:
		if (g as Guard).alive:
			return g as Guard
	return null

func _reset_guards() -> void:
	for g in _game.guards:
		var gd := g as Guard
		if gd.alive:
			gd.enter_patrol()
			gd.detect = 0.0
			gd.alarm_run = false
