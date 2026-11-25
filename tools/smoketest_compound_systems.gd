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
var _runner: Guard
var _veh: Array = []
var _wiped_at := 0

const VEHICLES := ["car/delivery", "car/taxi", "car/truck", "car/suv", "car/garbage-truck",
	"car/van", "car/police", "car/sedan"]

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
		# Vehicles on empty ground, for the hitbox check.
		for i in VEHICLES.size():
			_veh.append(Props.vehicle(_game.level_root, VEHICLES[i], Vector3(100 + i * 8, 0, 300), 0.0))
	if _frame == 3:
		_check_stations()   # before anything raises the alarm
	if _frame < 8:
		return false
	if _frame == 8:
		_check_alarm()      # first: shooting the dummy guard raises one too
		_check_station_press()
		_check_alarm_runs()
		_check_vehicles()
		_check_mantle()
		_check_vertical()
		_check_site_route()
		_check_lanes()
		_check_vault()
		_check_wall_not_vaulted()
		_check_crawl_gates()
		_check_layers()
		_check_headshots()
		_check_sentry_facing()
		_check_puddle()
		_check_labels()
		_check_loadout()
		_check_secondary()   # last: it switches the level's surveillance off
		_wiped_at = Time.get_ticks_msec()
		return false
	if Time.get_ticks_msec() - _wiped_at < 3000:
		return false
	if _wiped_at > 0:
		_check_blackout_settled()
		_wiped_at = 0
		_game.flow.select_char("regular")
		_frame = 100
		return false
	if _frame < 104:
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

## r6 high levels (SecCmpVertical): each tops out one mantle under the wall
## top or the next perch, and the podium is not a climb from the courtyard.
func _check_vertical() -> void:
	print("-- high levels (r6) --")
	var d := _ledge_from(Vector3(10, 3.0, -25.4), PI, 3.0)
	_ok(d != Vector3.INF and d.y > 3.9, "car-park deck -> compound wall top (%s)" % d)
	d = _ledge_from(Vector3(-27.6, 3.0, 2.0), PI / 2.0, 3.0)
	_ok(d != Vector3.INF and d.y > 3.9, "west gantry -> compound wall top (%s)" % d)
	d = _ledge_from(Vector3(-17.7, 2.85, 23.2), PI, 2.85)
	_ok(d != Vector3.INF and d.y > 3.9, "podium -> south wall top (%s)" % d)
	d = _ledge_from(Vector3(-4.2, 10.4, -16.0), PI / 2.0, 10.4)
	_ok(d != Vector3.INF and d.y > 11.4, "plant room top -> water tank platform (%s)" % d)
	_ok(_ledge_from(Vector3(-17.7, 0, 18.6), PI, 0.0) == Vector3.INF,
		"podium is not a climb from the courtyard floor")

## r6 secondary, r7 blackout: the server in the annex wipes the score, and
## with it every camera, eye, score screen, lock and alarm post in the level.
func _check_secondary() -> void:
	print("-- secondary + blackout (r7) --")
	var term: WipeTerminal = null
	for n in _game.get_tree().get_nodes_in_group("interactable"):
		if n is WipeTerminal:
			term = n
	_ok(term != null, "the annex has a score server terminal")
	if term == null:
		return
	_ok(not _game.stats.has("secondary"), "the score starts intact")
	var tree := _game.get_tree()
	_ok(tree.get_nodes_in_group("score_display").size() >= 8, "score screens around the level")
	term.open(_game.player)
	_ok(String(_game.stats.get("secondary", "")) != "", "wiping it is recorded for the end screen")
	_ok(term.prompt_for(_game.player).is_empty(), "the terminal is done after one wipe")
	_ok(tree.get_nodes_in_group("alarm_station").is_empty(), "every alarm post is dead")
	_game.alert.raise("TEST")
	_ok(not _game.alert.is_alarm(), "nothing can raise the alarm after the wipe")
	var live := 0
	for e in tree.get_nodes_in_group("cctv") + tree.get_nodes_in_group("watcher_eye"):
		if (e as WatcherEye).powered:
			live += 1
	_ok(live == 0, "cameras and eyes are off (%d still on)" % live)
	var m := _game.mission as MissionCompound
	var shut := 0
	for d in m.csd + [m.panic_door, m.boiler_door, m.gate]:
		if not (d as RemoteDoor).is_open:
			shut += 1
	_ok(shut == 0, "every automatic lock released (%d still shut)" % shut)

## After the flicker: the billboard and every score screen are dark.
func _check_blackout_settled() -> void:
	var tree := _game.get_tree()
	var lit := 0
	for b in tree.get_nodes_in_group("score_board_face"):
		if ((b as MeshInstance3D).material_override as StandardMaterial3D).emission_enabled:
			lit += 1
	for l in tree.get_nodes_in_group("score_board"):
		if (l as Label3D).visible:
			lit += 1
	for s in tree.get_nodes_in_group("score_display"):
		if (s.get_meta("face") as StandardMaterial3D).emission_enabled:
			lit += 1
	_ok(lit == 0, "billboard and score screens dark after the wipe (%d lit)" % lit)
	for lt in tree.get_nodes_in_group("score_board_light"):
		_ok(not (lt as Light3D).visible, "the billboard's floodlight is off")

## r7 site route (SecAnnexSite): the mantles on it, and the ladders.
## Yaw: 0 north (-z), PI south, PI/2 west, -PI/2 east.
func _check_site_route() -> void:
	print("-- site route (r7) --")
	var steps := [
		["C2 -> tower floor 2", Vector3(21.9, 7.0, -93.2), -PI / 2.0, 7.0, 7.95],
	]
	for st in steps:
		var d := _ledge_from(st[1], float(st[2]), float(st[3]))
		_ok(d != Vector3.INF and d.y > float(st[4]), "%s (%s)" % [st[0], d])
	for spot in [Vector3(27.59, 0.5, -50.0), Vector3(32.0, 3.5, -73.59),
			Vector3(30.0, 0.5, -78.41), Vector3(27.41, 4.5, -95.0), Vector3(29.0, 8.5, -99.09),
			Vector3(15.0, 4.5, -95.11)]:
		_ok(Ladder.at(spot), "a ladder at %s" % spot)
	# Every plank has floor along its whole length (a plank is 0.4 wide).
	for pl in [[Vector3(32.8, 3.0, -62.5), Vector3(32.8, 3.0, -69.5)],
			[Vector3(27.5, 6.0, -76.0), Vector3(22.3, 6.0, -76.0)],
			[Vector3(22.0, 8.0, -95.0), Vector3(18.6, 8.0, -95.0)]]:
		var gaps := 0
		for i in 8:
			var at: Vector3 = (pl[0] as Vector3).lerp(pl[1], i / 7.0)
			var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 1, 0), at - Vector3(0, 0.5, 0))
			if _space().intersect_ray(q).is_empty():
				gaps += 1
		_ok(gaps == 0, "plank %s -> %s is continuous" % [pl[0], pl[1]])

## r5 lanes: the container stacks and the estate-yard zigzag walls climb in
## 1.15 rises and not before.
func _check_lanes() -> void:
	print("-- lanes (r5) --")
	var east := -PI / 2.0
	_ok(_ledge_from(Vector3(-16.6, 1.15, 5.6), east, 1.15) != Vector3.INF,
		"west stack: crate -> lower roof")
	_ok(_ledge_from(Vector3(-16.7, 0, 5.6), east, 0.0) == Vector3.INF,
		"west stack: the lower roof (2.3) is not a climb from the floor")
	_ok(_ledge_from(Vector3(-12.8, 2.3, 5.6), east, 2.3) != Vector3.INF,
		"west stack: lower roof -> roof crate")
	_ok(_ledge_from(Vector3(-11.6, 3.45, 5.6), east, 3.45) != Vector3.INF,
		"west stack: roof crate -> upper roof")
	_ok(_ledge_from(Vector3(13.4, 1.15, 5.6), PI / 2.0, 1.15) != Vector3.INF,
		"east stack: crate -> lower roof")
	_ok(_ledge_from(Vector3(10.6, 2.3, 5.6), PI / 2.0, 2.3) != Vector3.INF,
		"east stack: lower roof -> roof crate")
	_ok(_ledge_from(Vector3(8.6, 3.45, 5.6), PI / 2.0, 3.45) != Vector3.INF,
		"east stack: roof crate -> upper roof")
	_ok(_ledge_from(Vector3(-8, 1.15, 167.6), 0.0, 1.15) != Vector3.INF,
		"yard wall 1: crate stair -> wall top")
	_ok(_ledge_from(Vector3(-3, 0, 168.4), 0.0, 0.0) == Vector3.INF,
		"yard wall 1: not climbable from the floor")
	_ok(_ledge_from(Vector3(16, 1.15, 146.9), PI, 1.15) != Vector3.INF,
		"yard wall 2: crate stair -> wall top")

## A 1.0m fence has no top to stand on: the climb vaults it.
func _check_vault() -> void:
	print("-- fence vault --")
	var dest := _ledge_from(Vector3(0, 0, 30.9), 0.0, 0.0)
	_ok(dest != Vector3.INF and dest.z < 29.8 and dest.y < 0.3,
		"a 1.0m fence vaults to the far side (landed at %s)" % dest)

## A building wall is not a fence. Jumping at the main block's east wall from
## any crate (or the bridge roof) must never carry you through it.
func _check_wall_not_vaulted() -> void:
	print("-- walls are not vaulted --")
	var west := PI / 2.0
	var bad := 0
	for c in [[1.15, -19.0], [2.30, -18.0], [3.45, -17.0], [4.60, -16.0],
			[5.75, -15.0], [6.90, -14.25]]:
		for x in [10.5, 10.9]:
			for jump in [0.0, 1.0]:
				var d := _ledge_from(Vector3(x, float(c[0]) + jump, float(c[1])), west, float(c[0]))
				if d != Vector3.INF and d.x < 10.1 and d.y < 8.2:
					bad += 1
	_ok(bad == 0, "no crate position vaults through the east wall (%d did)" % bad)
	_ok(_ledge_from(Vector3(12.5, 0, -17), west, 0.0) == Vector3.INF
		or _ledge_from(Vector3(12.5, 0, -17), west, 0.0).x > 10.1,
		"the ground-floor alley does not vault into the building either")

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
	var m := _game.mission as MissionCompound
	m.hazard.set_enabled(false)
	_ok(not m.hazard.enabled, "the water isolator switches the energised zone off")
	m.hazard.set_enabled(true)
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
	_ok(_game.atmosphere._alarm, "siren and red pulse started")
	_ok(m.csd.all(func(d) -> bool: return not (d as RemoteDoor).is_open), "CSD pair locked")
	_ok(_game.target.fleeing, "target is running for G.04")
	_ok(_game.guards.size() == before + 3,
		"three reinforcements called in (%d -> %d)" % [before, _game.guards.size()])
	_game.alert.raise("AGAIN")
	_ok(_game.guards.size() == before + 3, "a raise during ALARM adds nobody")

## The alarm is a guard's walk to a station, not a reflex. Shooting a guard
## alerts him and sends him running; it does not raise the alarm. Pressing the
## station does.
func _check_stations() -> void:
	print("-- alarm stations --")
	var stations := get_nodes_in_group_safe("alarm_station")
	_ok(stations.size() >= 8, "%d alarm stations in the level" % stations.size())
	_ok(get_nodes_in_group_safe("siren").size() >= 6, "sirens are mounted in the level")
	var st := stations[0] as AlarmStation
	_runner = _game.spawn_guard({"waypoints": [st.global_position + Vector3(0, 0, -8)]})
	_runner.take_damage(10.0, _runner.global_position + Vector3(0, 0, -5))
	_ok(not _game.alert.is_alarm(), "a guard being hit does not raise the alarm")
	_ok(_runner.alarm_run, "he is sent running for a station")

## r7: no guard patrols next to an alarm post. From anywhere on his lane, an
## alerted guard walks 12m+ of navmesh to the post he'd pick — except G5 and
## G7, the agreed exceptions (SecAlarm), who still get 9m. Tools/alarm_reach.gd
## prints the full table.
func _check_alarm_runs() -> void:
	print("-- alarm runs (r7) --")
	var w := _game.level_root.get_world_3d()
	var short: Array = []
	for post in GuardPostsCompound.all():
		var wps: Array = post["waypoints"]
		var best := INF
		for i in wps.size():
			var a: Vector3 = wps[i]
			var b: Vector3 = wps[(i + 1) % wps.size()]
			var n := maxi(1, int(a.distance_to(b) / 2.0))
			for k in n + 1:
				var p := a.lerp(b, float(k) / n)
				var st := _game.nearest_station(p)
				if st == null:
					continue
				var path := GuardNav.path(w, p, st.global_position)
				if path.size() < 2 or path[path.size() - 1].distance_to(st.global_position) > 1.5:
					continue
				var l := 0.0
				for j in range(1, path.size()):
					l += path[j - 1].distance_to(path[j])
				best = minf(best, l)
		var need := 9.0 if post["id"] in ["G5", "G7"] else 12.0
		if best < need:
			short.append("%s %.1fm" % [post["id"], best])
	_ok(short.is_empty(), "every guard has a run to his alarm post %s" % str(short))

## Second half, after the alarm test (pressing spawns reinforcements, which
## would skew its count): the guard arrives and presses.
func _check_station_press() -> void:
	var st := _game.nearest_station(_runner.global_position)
	_ok(st != null, "a station is in reach of the guard")
	_game.alert.reset()
	_runner.alarm_run = true
	_runner.global_position = st.global_position + Vector3(0, 0, -1.0)
	_runner.brain._run_to_station(0.1)
	_ok(_game.alert.is_alarm(), "a guard reaching the station raises the alarm")
	_runner.alive = false

func get_nodes_in_group_safe(group: String) -> Array:
	return root.get_tree().get_nodes_in_group(group)

## Parked vehicles are uncapped (a van is as tall as it looks) and their
## collision is the bodywork's own mesh: a ray down through the middle of the
## roof must land on the visual roof, and a ray in from the side must stop at
## the visual flank — not at a box round the model.
func _check_vehicles() -> void:
	print("-- vehicles --")
	for i in VEHICLES.size():
		var holder := _veh[i] as Node3D
		var box := Props.bounds(holder, (holder.get_parent() as Node3D).global_transform)
		# Highest collision surface over a grid of the footprint vs the visual roof.
		var top := -1.0
		for fx: float in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
			for fz: float in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
				var px := box.position.x + box.size.x * fx
				var pz := box.position.z + box.size.z * fz
				var hit := _space().intersect_ray(PhysicsRayQueryParameters3D.create(
					Vector3(px, box.end.y + 2.0, pz), Vector3(px, -1, pz)))
				if not hit.is_empty():
					top = maxf(top, (hit["position"] as Vector3).y)
		_ok(absf(top - box.end.y) < 0.15 and box.size.y > 1.0,
			"%s: hitbox roof %.2fm vs model roof %.2fm" % [VEHICLES[i], top, box.end.y])
		# Flank: a shot in from the west stops at the bodywork, not a box round it.
		var cz := box.position.z + box.size.z * 0.5
		var side := _space().intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(box.position.x - 3.0, 0.9, cz), Vector3(box.end.x, 0.9, cz)))
		var gap: float = (side["position"] as Vector3).x - box.position.x if not side.is_empty() else 99.0
		_ok(gap > -0.05 and gap < 0.7, "%s: flank hit %.2fm inside the model's edge" % [VEHICLES[i], gap])

func _check_briefing_fits() -> void:
	print("-- briefing fits --")
	var screen: ScreenBase = _game.screens._screens["briefing"]
	var content := screen.center.get_child(0) as Control
	var h := content.get_combined_minimum_size().y
	_ok(h <= 720.0, "compound briefing is %dpx tall in a 720px viewport" % int(h))
