extends SceneTree
## Bystanders: every post is floor with room to stand, they spawn, panic
## spreads, and the alarm sends the whole crowd running.
##
##     godot --headless --path . --script res://tools/smoketest_civilians.gd

var _frame := 0
var _game: GrayboxGame
var _bad := 0

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
		return false
	if _frame < 10:
		return false
	if _frame == 10:
		_check_spots()
		_check_reinforcement_spots()
		_check_panic()
		return false
	if _frame < 70:
		return false
	_check_running()
	print("%d problem(s)" % _bad)
	quit()
	return true

func _space() -> PhysicsDirectSpaceState3D:
	return _game.level_root.get_world_3d().direct_space_state

func _check_spots() -> void:
	print("-- civilian spots --")
	var self_rids: Array[RID] = []
	for c in _game.civilians:
		self_rids.append((c as Civilian).get_rid())
	var posts := CivilianPostsCompound.all()
	_ok(_game.civilians.size() == posts.size(), "%d civilians spawned" % _game.civilians.size())
	for post in posts:
		for wp in post["waypoints"]:
			var p: Vector3 = wp
			var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p - Vector3(0, 0.6, 0))
			q.collision_mask = VerbData.BODY_MASK
			q.exclude = self_rids
			var hit := _space().intersect_ray(q)
			var floor_ok := not hit.is_empty() and absf((hit["position"] as Vector3).y - p.y) < 0.3
			var shape := CapsuleShape3D.new()
			shape.radius = 0.3
			shape.height = 1.6
			var pq := PhysicsShapeQueryParameters3D.new()
			pq.shape = shape
			pq.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 1.0, 0))
			pq.collision_mask = VerbData.BODY_MASK
			pq.exclude = self_rids
			var blocked := not _space().intersect_shape(pq, 1).is_empty()
			_ok(floor_ok and not blocked, "spot %s: floor %s, room %s" % [
				p, "yes" if floor_ok else "NO", "yes" if not blocked else "NO"])

func _check_reinforcement_spots() -> void:
	print("-- reinforcement spots --")
	var rs := GuardPostsCompound.reinforcements()
	for id in ["R4", "R5"]:   # R1-R3 predate this check and stand beside furniture
		for wp in (rs[id]["waypoints"] as Array):
			var p: Vector3 = wp
			var shape := CapsuleShape3D.new()
			shape.radius = 0.35
			shape.height = 1.7
			var pq := PhysicsShapeQueryParameters3D.new()
			pq.shape = shape
			pq.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.95, 0))
			pq.collision_mask = VerbData.BODY_MASK
			_ok(_space().intersect_shape(pq, 1).is_empty(), "%s spot %s has room" % [id, p])

func _check_panic() -> void:
	print("-- panic --")
	var c := _game.civilians[0] as Civilian
	_ok(c.state == Civilian.State.WANDER, "starts calm")
	_game.alert.raise("TEST")
	_ok(c.state == Civilian.State.PANIC, "the alarm panics the crowd")
	var all_panic := true
	for x in _game.civilians:
		if (x as Civilian).state != Civilian.State.PANIC:
			all_panic = false
	_ok(all_panic, "every civilian is running")

func _check_running() -> void:
	var moved := 0
	for x in _game.civilians:
		var cv := x as Civilian
		if Vector2(cv.velocity.x, cv.velocity.z).length() > 1.0:
			moved += 1
	_ok(moved >= _game.civilians.size() / 2, "%d of %d are moving fast" % [moved, _game.civilians.size()])
	var c := _game.civilians[0] as Civilian
	var before := _game.civilians.size()
	c.take_damage(999.0, c.global_position + Vector3(0, 0, 2))
	_ok(_game.civilians.size() == before - 1 and not c.alive, "a civilian can be killed")
