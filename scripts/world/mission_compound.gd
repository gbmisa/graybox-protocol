class_name MissionCompound
extends Node
## HOLLOWAY ROAD's moving parts, placed after the geometry: the doors and
## switches, the extractions, the puddle, the light tiers, the target, the
## PA announcements on the approach — and what the level does when the
## building wakes up (GrayboxGame calls on_alarm through AlertState).
##
## ALARM here means: the CSD pair locks for good, the target runs for the
## panic room with G9 behind him, and reinforcements come in (R1 + R2 on the
## first, R3 after). The hall is empty by the time a loud operative gets
## there, and the panic room is a harder, different problem, not a restart.
##
## Numbers live in MissionCompoundData; this file only wires them up.

const D := preload("res://scripts/data/mission_compound_data.gd")

var game: GrayboxGame
var panic_door: RemoteDoor
var boiler_door: RemoteDoor
var gate: RemoteDoor
var csd: Array = []
var hazard: Hazard
var located: bool = false

var _spawned: Array = []
var _poll: float = 0.0
var _pa_done: Array = []

static func create(p_game: GrayboxGame, root: Node3D) -> MissionCompound:
	var m := MissionCompound.new()
	m.name = "Mission"
	m.game = p_game
	root.add_child(m)
	m._build(root)
	return m

func _build(root: Node3D) -> void:
	for t in D.TIERS:
		game.tiers.add(t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7])
	_entries(root)
	_inner_doors(root)
	_switches(root)
	SecondaryScore.create(game, root)
	for e in D.EXTRACTIONS:
		BuildUtils.zone(root, game, String(e["name"]), e["pos"], float(e["radius"]))
	hazard = Hazard.create(game, root, D.HAZARD_BOX, D.HAZARD_DPS)
	var t := Target.new()
	root.add_child(t)
	t.setup(game, D.TARGET_LANE[0], D.TARGET_LANE.duplicate())
	game.target = t

# ------------------------------------------------------------------ gates ---
## The gate out to the car. Level one is the Regular with his base kit: no
## picks, no wards, no breaching — every door he meets is open, shut from the
## far side, or worked by a switch somewhere else.
func _entries(root: Node3D) -> void:
	gate = RemoteDoor.create(game, root, "GATE", Vector3(0, 2.0, -24.4),
		Vector3(6.0, 4.0, 0.8), false)

func _inner_doors(root: Node3D) -> void:
	panic_door = RemoteDoor.create(game, root, "CONTINUITY SUITE G.04",
		Vector3(-16, 1.2, -14), Vector3(1.6, 2.4, 0.2), false)
	boiler_door = RemoteDoor.create(game, root, "BOILER HOUSE DOOR",
		Vector3(-34, 1.2, -13), Vector3(0.2, 2.4, 1.4), false)
	_barred_window(root)
	csd = [
		RemoteDoor.create(game, root, "SECURITY DOOR", Vector3(0, 1.2, -11),
			Vector3(1.6, 2.4, 0.2), true),
		RemoteDoor.create(game, root, "SECURITY DOOR", Vector3(3, 1.2, -9.5),
			Vector3(0.2, 2.4, 1.4), true),
	]

## Bars on the bodies-only layer: bullets and sight pass them — you can
## shoot into G.04 from the north yard, and whoever is inside can shoot back
## — but nobody climbs through.
func _barred_window(root: Node3D) -> void:
	for i in 4:
		var rod := StaticBody3D.new()
		rod.collision_layer = VerbData.LAYER_BODY_ONLY
		rod.position = Vector3(-16.6 + i * 0.4, 1.5, -20)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.1, 1.6, 0.1)
		cs.shape = shape
		rod.add_child(cs)
		root.add_child(rod)
		BuildUtils.box(rod, Vector3.ZERO, shape.size, BuildUtils.METAL, false)

## The energised water's isolator, on the run's west wall straight ahead as you
## come in from the spur — before the puddle, not past it.
func _switches(root: Node3D) -> void:
	Switch.create(game, root, "WATER ISOLATOR", D.ISOLATOR_POS,
		Vector3(0.2, 0.6, 0.5), _puddle_off)
	Switch.create(game, root, "MAST ISOLATOR", Vector3(-16.5, 1.4, -10.75),
		Vector3(0.7, 0.7, 0.2), _mast_off)
	Switch.create(game, root, "DOOR RELEASE", Vector3(-14.8, 1.3, -14.25),
		Vector3(0.5, 0.5, 0.2), func() -> void: panic_door.release())
	Switch.create(game, root, "DOOR RELEASE", Vector3(-33.7, 1.3, -11.8),
		Vector3(0.2, 0.5, 0.4), func() -> void: boiler_door.release())
	Switch.create(game, root, "GATE LEVER", Vector3(-8.7, 1.2, -27.5),
		Vector3(0.2, 0.6, 0.4), func() -> void: gate.release())

func _puddle_off() -> void:
	hazard.set_enabled(false)
	game.hud.add_killfeed("Water isolated — the undercroft is safe to wade")

## Courtyard disc goes DARK — tier swapped, not deleted — and the mast dies.
func _mast_off() -> void:
	for l in get_tree().get_nodes_in_group("mast_lamp"):
		(l as Light3D).visible = false
	game.tiers.set_tier("mast_disc", "DARK")
	game.hud.add_killfeed("Mast isolated — courtyard dark")

# ------------------------------------------------------------------ alarm ---
func on_alarm(count: int, _reason: String) -> void:
	for d in csd:
		(d as RemoteDoor).lock()
	if count == 1:
		game.hud.add_killfeed("LOCKDOWN — security doors sealed")
	var t := game.target
	if t != null and is_instance_valid(t) and t.alive:
		t.flee(D.FLEE_PATH.duplicate())
	var g9 := _guard("G9")
	if g9 != null and g9.state != Guard.State.ALERT:
		g9.set_route(D.ESCORT_PATH.duplicate(), true, PI)
	if g9 != null:
		# His post is the panic-room door; he fights from there, not after you.
		g9.hold_pos = D.ESCORT_PATH[D.ESCORT_PATH.size() - 1]
		g9.hold_yaw = PI
	_reinforce(D.FIRST_WAVE if count == 1 else D.LATER_WAVE)
	var n := DefencePlan.man(game, D.POSTS, ["G9"])
	if n > 0:
		game.hud.add_killfeed("Guards taking defensive positions")

## A guard alerted while the alarm is already up takes a post too.
func post_guard(g: Guard) -> void:
	DefencePlan.post_one(game, D.POSTS, g)

func on_calm() -> void:
	pass

func _reinforce(ids: Array) -> void:
	if game.no_guards:
		return
	var posts := GuardPostsCompound.reinforcements()
	var p := game.get_player()
	for id in ids:
		if _spawned.size() >= D.CAP:
			return
		var pick := String(id)
		var at: Vector3 = (posts[pick]["waypoints"] as Array)[0]
		if p != null and pick != "R3" and p.global_position.distance_to(at) < D.MIN_DIST:
			pick = "R3"
		if pick in _spawned:
			continue
		_spawned.append(pick)
		game.spawn_guard((posts[pick] as Dictionary).duplicate(true))

func _guard(id: String) -> Guard:
	for g in game.guards:
		if (g as Guard).post_id == id and (g as Guard).alive:
			return g as Guard
	return null

func _bark_nearest(pos: Vector3, kind: String) -> void:
	var best: Guard = null
	for g in game.guards:
		var gd := g as Guard
		if gd.alive and (best == null or gd.global_position.distance_to(pos)
				< best.global_position.distance_to(pos)):
			best = gd
	if best != null:
		best.bark(kind)

# ------------------------------------------------------------------- tick ---
func _physics_process(delta: float) -> void:
	if game == null or not game.is_playing():
		return
	_poll += delta
	if _poll < 0.2:
		return
	_poll = 0.0
	_panic_passage()
	_check_pa()
	if not located and game.objective_stage == 1:
		_check_locate()

## One PA line per stretch of the approach, the first time you enter it.
func _check_pa() -> void:
	var p := game.get_player()
	if p == null or game.alert.is_alarm():
		return
	for i in D.PA.size():
		if i in _pa_done:
			continue
		if (D.PA[i][0] as AABB).has_point(p.global_position + Vector3(0, 1, 0)):
			_pa_done.append(i)
			game.hud.say(D.PA_SPEAKER, String(D.PA[i][1]))
			return

## The target and his escort walk through G.04's door without opening it.
func _panic_passage() -> void:
	if panic_door == null or panic_door.is_open:
		return
	for n in [game.target, _guard("G9")]:
		if n == null or not is_instance_valid(n):
			continue
		if (n as Node3D).global_position.distance_to(D.PANIC_DOOR_POS) < 1.8:
			panic_door.let_through(1.2)
			return

func _check_locate() -> void:
	var p := game.get_player()
	var t := game.target
	if p == null or t == null or not is_instance_valid(t) or not t.alive:
		return
	for box in D.INTEL_BOXES:
		if (box as AABB).has_point(p.global_position + Vector3(0, 1, 0)):
			_locate("INTEL: assembly hall 1F, 21:00 — panic room G.04, north corridor")
			return
	var from := p.camera.global_position
	var to := t.global_position + Vector3(0, 1.9, 0)
	if from.distance_to(to) > D.LOCATE_RANGE or p.aim_dir().dot((to - from).normalized()) < 0.55:
		return
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [p.get_rid(), t.get_rid()]
	q.collision_mask = VerbData.SHOT_MASK
	if p.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		_locate("Vandermeer sighted")

func _locate(msg: String) -> void:
	located = true
	game.hud.set_objective(String(game.level_data.get("located_objective", "KILL THE TARGET")))
	game.hud.add_killfeed(msg)
