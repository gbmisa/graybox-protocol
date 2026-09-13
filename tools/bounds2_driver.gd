extends Node
## P0 verification: the PORT VESPER playable rectangle x[-111,111],
## z[-81,96] is fully enclosed and falling is impossible.
##   1. Raycast audit: the four outer walls exist where expected.
##   2. Walk probes: bodies driven outward cannot leave the rect
##      (incl. a replay of the reported bug: immediate left/east from spawn).
##   3. Drop probes: ground exists all along the inside edge (no holes).
##   4. killZ: a player dropped into the void snaps back to safe ground.
var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _walkers: Array = []  # [CharacterBody3D, dir]
var _drops: Array = []
var _saved_pos := Vector3.ZERO

const XMIN := -111.0
const XMAX := 111.0
const ZMIN := -81.0
const ZMAX := 96.0

# [start, outward dir]
const WALKERS := [
	[Vector3(60, 0.5, -70), Vector3(0, 0, -1)],   # north wall
	[Vector3(60, 0.5, 80), Vector3(0, 0, 1)],    # south wall (wading)
	[Vector3(-95, 0.5, -70), Vector3(-1, 0, 0)], # west wall
	[Vector3(95, 0.5, -70), Vector3(1, 0, 0)],   # east wall
	[Vector3(62, 0.5, -72), Vector3(1, 0, 0)],   # designer replay: east from spawn
]
const DROPS := [
	Vector3(-100, 2, -79), Vector3(-50, 2, -79), Vector3(0, 2, -79),
	Vector3(50, 2, -79), Vector3(100, 2, -79), Vector3(-100, 2, 94),
	Vector3(0, 2, 94), Vector3(100, 2, 94), Vector3(-109, 2, -40),
	Vector3(-109, 2, 40), Vector3(109, 2, -40), Vector3(109, 2, 40),
]
# [ray from, ray to, expected hit distance]
const RAYS := [
	[Vector3(60, 1.5, -70), Vector3(60, 1.5, -95), 10.7],
	[Vector3(60, 1.5, 80), Vector3(60, 1.5, 105), 15.7],
	[Vector3(-95, 1.5, -70), Vector3(-120, 1.5, -70), 15.7],
	[Vector3(95, 1.5, -70), Vector3(120, 1.5, -70), 15.7],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
		_audit_rays()
		_spawn_probes()
	elif _frame > 8 and _frame <= 308:
		for w in _walkers:
			var b := w[0] as CharacterBody3D
			b.velocity = Vector3(w[1].x * 6.0, 0, w[1].z * 6.0)
			b.move_and_slide()
	elif _frame == 309:
		_check_walkers()
		_check_drops()
		_saved_pos = _game.player.global_position
		_game.player.global_position = Vector3(0, -50, 0)  # into the void
	elif _frame == 320:
		_check_killz()
		print("\n%d problem(s)" % _bad)
		get_tree().quit()

func _excludes() -> Array[RID]:
	var e: Array[RID] = [_game.player.get_rid()]
	for g in _game.guards:
		e.append((g as CollisionObject3D).get_rid())
	if _game.target != null:
		e.append(_game.target.get_rid())
	return e

func _audit_rays() -> void:
	print("-- outer wall raycast audit --")
	var space := _game.get_world_3d().direct_space_state
	var excl := _excludes()
	for r in RAYS:
		var q := PhysicsRayQueryParameters3D.create(r[0], r[1], 1, excl)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			_fail("no wall hit on ray %s -> %s" % [r[0], r[1]])
			continue
		var d: float = (r[0] as Vector3).distance_to(hit["position"])
		if absf(d - float(r[2])) > 3.0:
			_fail("wall at %.1fm, expected ~%.1fm (%s -> %s)" % [d, float(r[2]), r[0], r[1]])

func _spawn_probes() -> void:
	var excl := _excludes()
	for w in WALKERS:
		var b := CharacterBody3D.new()
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.0
		cs.shape = cap
		b.add_child(cs)
		b.collision_layer = 4
		b.collision_mask = 1
		b.position = w[0]
		get_tree().root.add_child(b)
		b.add_collision_exception_with(_game.player)
		for g in _game.guards:
			b.add_collision_exception_with(g)
		if _game.target != null:
			b.add_collision_exception_with(_game.target)
		_walkers.append([b, w[1]])
	for p in DROPS:
		var rb := RigidBody3D.new()
		var cs2 := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 0.4
		cs2.shape = sp
		rb.add_child(cs2)
		rb.position = p
		get_tree().root.add_child(rb)
		_drops.append(rb)

func _check_walkers() -> void:
	print("-- walk probes (300 physics frames outward) --")
	for w in _walkers:
		var b := w[0] as CharacterBody3D
		var p := b.global_position
		if p.x < XMIN - 0.5 or p.x > XMAX + 0.5 or p.z < ZMIN - 0.5 or p.z > ZMAX + 0.5:
			_fail("walker escaped rect at %s" % p)
		elif p.y < -2.0:
			_fail("walker fell through at %s" % p)

func _check_drops() -> void:
	print("-- drop probes (ground along the inside edge) --")
	for rb in _drops:
		var p := (rb as RigidBody3D).global_position
		if p.y < -2.0:
			_fail("hole in ground near %s (probe at y=%.1f)" % [p, p.y])

func _check_killz() -> void:
	print("-- killZ fallback --")
	var p := _game.player.global_position
	if p.y < -2.0:
		_fail("player still in void at %s" % p)
	elif p.distance_to(_saved_pos) > 5.0:
		_fail("player recovered to %s, expected near %s" % [p, _saved_pos])
	else:
		print("  killZ recovered player to %s" % p)

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)
