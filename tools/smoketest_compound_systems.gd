extends SceneTree
## Headless HOLLOWAY CAMPUS systems check — the mechanics the level leans on,
## as the Regular plays it:
##
##     godot --headless --path . --script res://tools/smoketest_compound_systems.gd
##
## Geometry (floor, headroom, openings) is tools/smoketest_compound.gd's job.
## Every case here is a bug that either shipped once or is load-bearing for
## the level's routes: D14 mantle reach, fence vaults, headshots, sentry
## facing (H4), collision layers (H3), crawl gates, the alarm, the puddle,
## unlabelled extractions, and the briefing fitting its screen.

var _frame := 0
var _game: GrayboxGame
var _bad := 0
var _dummy: Guard

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
		return false
	if _frame == 2:
		# A 1.0m fence on the road for the vault case, added early so the
		# physics space has it by the time the checks run.
		BuildUtils.box(_game.level_root, Vector3(0, 0.5, 30), Vector3(6, 1.0, 0.2),
			BuildUtils.WALL)
		_dummy = _game.spawn_guard({"waypoints": [Vector3(0, 0, 36)]})
	if _frame < 8:
		return false
	if _frame == 8:
		_check_alarm()      # first: shooting the dummy guard raises one too
		_check_mantle()
		_check_vault()
		_check_crawl_gates()
		_check_layers()
		_check_headshots()
		_check_sentry_facing()
		_check_puddle()
		_check_labels()
		_check_loadout()
		_game.flow.select_char("regular")
		return false
	if _frame < 12:
		return false
	_check_briefing_fits()
	print("\n%d problem(s)" % _bad)
	return true

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok    %s" % what)
	else:
		_bad += 1
		print("  FAIL  %s" % what)

func _space() -> PhysicsDirectSpaceState3D:
	return _game.get_world_3d().direct_space_state

## Places the player (on no floor in particular) facing `yaw`, pretending his
## last floor was at `floor_y`, and asks the mantle what it would do.
func _ledge_from(pos: Vector3, yaw: float, floor_y: float) -> Vector3:
	var p := _game.player
	p.global_position = pos
	p.rotation.y = yaw
	p.movement.last_floor_y = floor_y
	return p.mantle._find_ledge()

# ----------------------------------------------------------------- cases ---
## D14: the crate stair's first stack (1.15) climbs from the alley floor; the
## second (2.30) does not, from the floor or from the top of a jump.
func _check_mantle() -> void:
	print("-- mantle (D14) --")
	var west := PI / 2.0
	_ok(_ledge_from(Vector3(12.6, 0, -19.6), west, 0.0) != Vector3.INF,
		"stack 1 (1.15) climbs from the alley floor")
	_ok(_ledge_from(Vector3(12.6, 0, -18.2), west, 0.0) == Vector3.INF,
		"stack 2 (2.30) does not climb from the floor")
	_ok(_ledge_from(Vector3(12.6, 1.84, -18.2), west, 0.0) == Vector3.INF,
		"stack 2 does not climb from the top of a jump either")
	_ok(_ledge_from(Vector3(11.0, 6.9, -14.25), west, 6.9) == Vector3.INF,
		"roof from stack 6 (1.5) is a jump, not a mantle")

## A 1.0m fence has no top to stand on: the climb vaults it.
func _check_vault() -> void:
	print("-- fence vault --")
	var dest := _ledge_from(Vector3(0, 0, 30.9), 0.0, 0.0)
	_ok(dest != Vector3.INF and dest.z < 29.8 and dest.y < 0.3,
		"a 1.0m fence vaults to the far side (landed at %s)" % dest)

## Crawl gates are collision: 0.85 fits the shutter, 1.45 does not.
func _check_crawl_gates() -> void:
	print("-- crawl gates --")
	for c in [["shutter", Vector3(28.4, 0, -17)], ["culvert", Vector3(-27.4, 0, 6)],
			["roof duct", Vector3(4.5, 8.4, -12)], ["hatch duct", Vector3(-16, 4, -16.4)],
			["approach culvert", Vector3(-30, 0, 125)]]:
		_ok(_capsule_fits(c[1], 0.85), "0.85 crouch fits the %s" % c[0])
		_ok(not _capsule_fits(c[1], 1.45), "1.45 crouch does not fit the %s" % c[0])

func _capsule_fits(at: Vector3, h: float) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = h
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), at + Vector3(0, h * 0.5 + 0.03, 0))
	q.collision_mask = VerbData.BODY_MASK
	q.exclude = [_game.player.get_rid()]
	return _space().intersect_shape(q, 1).is_empty()

## H3: bodies mask 3; the barred window blocks bodies but not bullets.
func _check_layers() -> void:
	print("-- collision layers (H3) --")
	_ok(_game.player.collision_mask == VerbData.BODY_MASK, "player masks layers 1+2")
	_ok(_game.target.collision_mask == VerbData.BODY_MASK, "target masks layers 1+2")
	var q := PhysicsRayQueryParameters3D.create(Vector3(-16, 1.5, -22), Vector3(-16, 1.5, -17))
	q.collision_mask = VerbData.SHOT_MASK
	_ok(_space().intersect_ray(q).is_empty(), "a shot passes the barred window")
	_ok(not _capsule_fits(Vector3(-16, 0.75, -20), 0.85), "a body does not")

## D12: the head is its own shape, and two suppressed headshots kill a guard.
func _check_headshots() -> void:
	print("-- headshots (D12) --")
	var g := _dummy
	var head := _shot(Vector3(0, 1.95, 33), Vector3(0, 1.95, 38), g)
	var body := _shot(Vector3(0, 1.2, 33), Vector3(0, 1.2, 38), g)
	_ok(not head.is_empty() and g.is_head_shape(int(head["shape"])), "a ray at 1.95 hits the head")
	_ok(not body.is_empty() and not g.is_head_shape(int(body["shape"])), "a ray at 1.2 hits the body")
	var dmg := float(AbilityData.get_ability("pistol")["damage"]) \
		* float(LoadoutData.get_mod("suppressed")["damage_mul"])
	g.take_hit(dmg, Vector3.ZERO, head)
	_ok(g.alive, "one suppressed headshot leaves a guard standing")
	g.take_hit(dmg, Vector3.ZERO, head)
	_ok(not g.alive, "two suppressed headshots kill him")

func _shot(a: Vector3, b: Vector3, g: Guard) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.collision_mask = VerbData.SHOT_MASK
	var hit := _space().intersect_ray(q)
	return hit if not hit.is_empty() and hit["collider"] == g else {}

## H4: a sentry spun by an investigation turns back to his post's facing.
func _check_sentry_facing() -> void:
	print("-- sentry facing (H4) --")
	var g := _game.spawn_guard({"waypoints": [Vector3(0, 0, 42)], "facing": PI})
	g.rotation.y = 0.3
	g.enter_patrol()
	for i in 90:
		g.brain._patrol(1.0 / 60.0)
	_ok(absf(angle_difference(g.rotation.y, PI)) < 0.05,
		"sentry faces his post again (yaw %.2f)" % g.rotation.y)

## §2.6: the puddle kills a walking Wizard, and a sprinting Regular's round
## trip to look at the squeeze is survivable in street clothes.
func _check_puddle() -> void:
	print("-- puddle --")
	var len := MissionCompoundData.HAZARD_BOX.size.z
	var dps := MissionCompoundData.HAZARD_DPS
	_ok(dps * len / 6.6 >= 60.0, "walking it kills a 60 HP Wizard (%.0f)" % (dps * len / 6.6))
	var trip := 2.0 * dps * len / 10.5
	_ok(trip < 100.0, "a sprinting Regular's round trip is %.0f of 100" % trip)

## §9: extractions are unlabelled.
func _check_labels() -> void:
	print("-- unlabelled extractions --")
	var bad := []
	for l in _game.level_root.find_children("*", "Label3D", true, false):
		var t := (l as Label3D).text.to_upper()
		for word in ["EXTRACT", "VAN", "HELI", "CAR", "EXIT"]:
			var re := RegEx.create_from_string("\\b%s\\b" % word)
			if re.search(t) != null:
				bad.append(t)
	_ok(bad.is_empty(), "no sign names a way out %s" % str(bad))

func _check_loadout() -> void:
	print("-- loadout --")
	_ok(float(LoadoutData.get_mod(LoadoutData.DEFAULT)["noise"]) == 0.0,
		"the default sidearm is silent")

## F2: ALARM locks the CSD pair, sends the target running, calls R1 + R2.
func _check_alarm() -> void:
	print("-- alarm (F2) --")
	var before := _game.guards.size()
	_game.alert.raise("TEST")
	var m := _game.mission as MissionCompound
	_ok(_game.alert.is_alarm(), "alarm raised")
	_ok(m.csd.all(func(d) -> bool: return not (d as RemoteDoor).is_open), "CSD pair locked")
	_ok(_game.target.fleeing, "target is running for G.04")
	_ok(_game.guards.size() == before + 2,
		"two reinforcements called in (%d -> %d)" % [before, _game.guards.size()])
	_game.alert.raise("AGAIN")
	_ok(_game.guards.size() == before + 2, "a raise during ALARM adds nobody")

func _check_briefing_fits() -> void:
	print("-- briefing fits --")
	var screen: ScreenBase = _game.screens._screens["briefing"]
	var content := screen.center.get_child(0) as Control
	var h := content.get_combined_minimum_size().y
	_ok(h <= 720.0, "compound briefing is %dpx tall in a 720px viewport" % int(h))
