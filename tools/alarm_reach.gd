extends SceneTree
## How far each guard has to RUN to raise the alarm (r7: "make it so there's
## an opportunity to kill guards without them being right next to an alarm").
## For every guard post, samples its lane every 2m and reports the shortest
## navmesh walk from any point on it to the station that guard would pick
## (GrayboxGame.nearest_station), plus whether each station stands on floor.
##
##     godot --headless --path . --script res://tools/alarm_reach.gd

var _frame := 0
var _game: GrayboxGame

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.no_guards = true
		_game.flow.start_mission()
		return false
	if _frame < 40:
		return false
	var w := _game.level_root.get_world_3d()
	var space := w.direct_space_state
	print("-- stations --")
	for st in _game.get_tree().get_nodes_in_group("alarm_station"):
		var p: Vector3 = (st as Node3D).global_position
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p + Vector3(0, -1.0, 0))
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		var fy: float = (hit["position"] as Vector3).y if not hit.is_empty() else -99.0
		print("  %s  floor %s" % [p, "ok" if absf(fy - p.y) < 0.35 else "MISSING (%.2f)" % fy])
	print("-- shortest run per guard (m) --")
	for post in GuardPostsCompound.all():
		var wps: Array = post["waypoints"]
		var pts: Array = []
		for i in wps.size():
			var a: Vector3 = wps[i]
			var b: Vector3 = wps[(i + 1) % wps.size()]
			var n := maxi(1, int(a.distance_to(b) / 2.0))
			for k in n + 1:
				pts.append(a.lerp(b, float(k) / n))
		var best := INF
		var best_st := Vector3.INF
		var total := 0.0
		var counted := 0
		for p in pts:
			var st := _game.nearest_station(p)
			if st == null:
				continue
			var path := GuardNav.path(w, p, st.global_position)
			var l := 0.0
			for i in range(1, path.size()):
				l += path[i - 1].distance_to(path[i])
			# A partial path (the lane point is on an island, e.g. inside a shed
			# the guard walks round) is no reading at all.
			if path.size() < 2 or path[path.size() - 1].distance_to(st.global_position) > 1.5:
				l = INF
			else:
				total += l
				counted += 1
			if l < best:
				best = l
				best_st = st.global_position
		print("  %-4s %s  mean %s  %s" % [post["id"], "none in reach" if best == INF else "%5.1f" % best,
			"-" if counted == 0 else "%5.1f (%d/%d pts in reach)" % [total / counted, counted, pts.size()],
			"" if best == INF else str(best_st)])
	return true
