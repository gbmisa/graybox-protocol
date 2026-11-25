extends SceneTree
## r8's weapons and tools, played headless with the real player in HOLLOWAY
## ROAD: every gun kills a guard stood in front of it, reload refills the
## mag from reserve, switching swaps the model, a grenade kills, the kick
## shoves a guard and launches you off a wall, the grappling hook bites and
## pulls you toward the anchor, night vision toggles, eating a corpse heals,
## and a dead guard's ammo box tops you up.
##
##     godot --headless --path . --script res://tools/smoketest_arsenal.gd

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

func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
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
	_ok(_w != null, "the Regular carries PlayerWeapons")
	_ok(_w.owned.keys().size() == 2 and _w.owned.has("pistol") and _w.owned.has("grenade"),
		"starts with the pistol and a grenade only (%s)" % [_w.owned.keys()])
	await _pickup_case()
	for id in ["shotgun", "rifle"]:
		_w.give(id)
	# A clear spot on the verge, facing north at a guard placed 6m away.
	var spot := Vector3(-30, 0.1, 42)   # south road, open both ways
	for id in ["pistol", "smg", "shotgun", "rifle"]:
		await _kill_with(id, spot)
	await _reload_case()
	await _grenade_case(spot)
	await _kick_case(spot)
	await _grapple_case()
	await _nv_case()
	await _eat_case()
	print("%d problem(s)" % _bad)
	quit(1 if _bad > 0 else 0)

## A guard (any live one, moved) 6m in front of the player, unaware.
func _victim(spot: Vector3) -> Guard:
	for g in _game.guards:
		var gd := g as Guard
		if gd.alive:
			gd.global_position = spot + Vector3(0, 0, -6)
			gd.waypoints = [gd.global_position]
			gd.brain.reset_route()
			gd.velocity = Vector3.ZERO
			return gd
	return null

func _face(spot: Vector3) -> void:
	_p.global_position = spot
	_p.velocity = Vector3.ZERO
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(deg_to_rad(-6), 0, 0)   # chest height at 6m

func _kill_with(id: String, spot: Vector3) -> void:
	var g := _victim(spot)
	_face(spot)
	_w.select(id)
	await _frames(30)
	_ok(_w.current == id, "%s: switched to it" % id)
	await _frames(2)
	var shots := 0
	while g.alive and shots < 12:
		_w.set("_cd", 0.0)
		_w.call("_fire", _w.weapon())
		shots += 1
		await _frames(3)
		_face(spot)
	_ok(not g.alive, "%s: kills a guard at 6m in %d shot(s)" % [id, shots])

## Walk onto the placed SMG: you own it, with a full mag, and it comes up.
func _pickup_case() -> void:
	var smg: WeaponPickup = null
	for n in get_nodes_in_group("weapon_pickup"):
		if (n as WeaponPickup).weapon_id == "smg":
			smg = n
	_ok(smg != null, "an SMG lies somewhere in the level")
	if smg == null:
		return
	_p.global_position = smg.global_position + Vector3(0, 0.1, 0)
	await _frames(40)
	_ok(_w.owned.has("smg") and int(_w.ammo["smg"]["mag"]) == 32 and _w.current == "smg",
		"picking it up: owned, full mag, in hand (%s)" % _w.current)

func _reload_case() -> void:
	_w.select("smg")
	await _frames(30)
	var a: Dictionary = _w.ammo["smg"]
	a["mag"] = 3
	a["reserve"] = 40
	var reserve := int(a["reserve"])
	_w.start_reload()
	await _frames(int(float(WeaponData.get_weapon("smg")["reload"]) * 60.0) + 10)
	_ok(int(a["mag"]) == 32 and int(a["reserve"]) == reserve - 29,
		"reload: mag 3 -> %d, reserve %d -> %d" % [int(a["mag"]), reserve, int(a["reserve"])])

func _grenade_case(spot: Vector3) -> void:
	var g := _victim(spot)
	_face(spot)
	g.process_mode = Node.PROCESS_MODE_DISABLED   # alerted guards walk off; hold him
	Grenade.throw(_game, g.global_position + Vector3(0.6, 0.5, 0.6), Vector3.ZERO, WeaponData.get_weapon("grenade"))
	await _frames(int(2.2 * 60) + 20)
	g.process_mode = Node.PROCESS_MODE_INHERIT
	_ok(not g.alive, "grenade: kills a guard it lands beside")

func _kick_case(spot: Vector3) -> void:
	var g := _victim(spot)
	g.global_position = spot + Vector3(0, 0, -1.3)
	_face(spot)
	var before := g.global_position
	await _tap("kick")
	await _frames(10)
	_ok(g.global_position.distance_to(before) > 0.5 or not g.alive,
		"kick: shoves a guard (moved %.2fm)" % g.global_position.distance_to(before))
	# Kick the floor under you (look down): it throws you up.
	_p.global_position = Vector3(-30, 0.1, 44)
	_p.camera.rotation = Vector3(deg_to_rad(-85), 0, 0)
	_p.velocity = Vector3.ZERO
	await _frames(30)
	var kicker: ToolKick = _p.kit.get("kick")
	kicker.set("_cd", 0.0)
	var y0 := _p.global_position.y
	var top := y0
	Input.action_press("kick")
	for i in 30:
		await physics_frame
		top = maxf(top, _p.global_position.y)
	Input.action_release("kick")
	_ok(top - y0 > 1.0, "kick: the floor throws you up (%.2fm)" % (top - y0))

func _grapple_case() -> void:
	_p.global_position = Vector3(0, 0.1, 40)
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(0.0, 0, 0)
	_p.velocity = Vector3.ZERO
	await _frames(20)
	var gr: ToolGrapple = _p.kit.get("grapple")
	Input.action_press("grapple")
	await _frames(3)
	_ok(gr.hooked(), "grapple: bites on the campus wall ahead")
	var anchor := gr.anchor
	var d0 := _p.global_position.distance_to(anchor) if gr.hooked() else 0.0
	var d1 := d0
	for k in 60:
		await physics_frame
		d1 = minf(d1, _p.global_position.distance_to(anchor))
	_ok(d1 < d0 - 2.0, "grapple: reels you in (%.1fm -> %.1fm)" % [d0, d1])
	Input.action_release("grapple")
	await _frames(2)
	_ok(not gr.hooked(), "grapple: lets go with Q")
	# r9: a route tool — the compound wall's top takes the hook, and the lip
	# hauls you up onto it (it used to slide off: NO_GRAPPLE).
	_p.global_position = Vector3(0, 0.1, 34)
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(deg_to_rad(12), 0, 0)   # the face, just under the top
	_p.velocity = Vector3.ZERO
	await _frames(20)
	Input.action_press("grapple")
	await _frames(3)
	_ok(gr.hooked() and gr.ledge, "grapple: bites the compound wall's lip (hooked %s ledge %s at %s, from %s)" % [gr.hooked(), gr.ledge, gr.anchor, _p.global_position])
	var top_y := 0.0
	for k in 120:
		await physics_frame
		top_y = maxf(top_y, _p.global_position.y)
	Input.action_release("grapple")
	await _frames(2)
	_ok(top_y > 4.0, "grapple: hauls you over the lip onto the wall top (peak %.2f)" % top_y)

func _nv_case() -> void:
	var nv: ToolNightVision = _p.kit.get("night_vision")
	await _tap("night_vision")
	await _frames(20)
	_ok(nv.on and ToolNightVision.current > 0.9, "night vision: on (level %.2f)" % ToolNightVision.current)
	await _tap("night_vision")
	await _frames(20)
	_ok(not nv.on and ToolNightVision.current < 0.1, "night vision: off")

func _eat_case() -> void:
	var boxes := get_nodes_in_group("ammo_pickup").size()
	_ok(boxes > 0, "dead guards dropped ammo boxes (%d)" % boxes)
	if boxes > 0:
		var w: PlayerWeapons = _p.kit.get("weapons")
		var before := int(w.ammo["pistol"]["reserve"])
		var box: Node3D = null
		for b in get_nodes_in_group("ammo_pickup"):
			if (b as AmmoPickup).amounts.has("pistol"):
				box = b as Node3D
		_p.global_position = box.global_position + Vector3(0, 0.1, 0)
		await _frames(10)
		_ok(int(w.ammo["pistol"]["reserve"]) > before, "an ammo box tops up the reserve")
	for g in _game.guards:   # nobody shoots the diner
		(g as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var c: Node3D = null
	for n in get_nodes_in_group("corpses"):
		if not (n as Node3D).has_meta("gibbed"):
			c = n as Node3D
			break
	_ok(c != null, "a corpse that isn't gibbed exists")
	if c == null:
		return
	_p.health.hp = 40.0
	_p.global_position = c.global_position + Vector3(0, 0.1, 1.2)
	_p.rotation = Vector3.ZERO
	_p.camera.rotation = Vector3(deg_to_rad(-55), 0, 0)
	await _frames(5)
	Input.action_press("interact")
	await _frames(int(ToolEat.EAT_TIME * 60) + 10)
	Input.action_release("interact")
	_ok(_p.health.hp > 40.0, "eat: a corpse heals (40 -> %.0f)" % _p.health.hp)
