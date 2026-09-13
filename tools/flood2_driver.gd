class_name Flood2Driver
extends Node
## PORT VESPER enclosure proof: 1m-grid BFS on the ground plane.
## With every LockedDoor closed, the office interior, storage interior, and
## pier deck must be unreachable from their exteriors. Then each designated
## gate's collision is disabled (simulating the open door) and the interior
## must become reachable — proving the gate is the ONLY way in.
## Water counts as non-standable: the 2.2m water-to-deck rise exceeds the
## 1.2m mantle limit, so wading around a barrier is not a walkaround.
var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _space: PhysicsDirectSpaceState3D
var _bad := 0
var _stand := {}

const REGIONS := {
	"office": {"x0": -25.0, "x1": 25.0, "z0": -35.0, "z1": -5.0,
		"seed": Vector3(0, 0, -10), "target": Vector3(8, 0, -22),
		"gates": [Vector3(16, 1.5, -24)]},
	"storage": {"x0": -55.0, "x1": -25.0, "z0": -15.0, "z1": 25.0,
		"seed": Vector3(-40, 0, -12), "target": Vector3(-43, 0, 6),
		"gates": [Vector3(-40, 1.5, -6)]},
	"pier": {"x0": 20.0, "x1": 80.0, "z0": -10.0, "z1": 50.0,
		"seed": Vector3(52, 0, 0), "target": Vector3(52.5, 0, 20),
		"gates": [Vector3(52, 1.5, 5)]},
}

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
		_space = _game.get_world_3d().direct_space_state
		print("-- closed-door floods --")
		for name in REGIONS.keys():
			var r: Dictionary = REGIONS[name]
			var reached := _flood(name, r, false)
			var t := _cell(r["target"])
			if t in reached:
				_fail("%s interior reachable with doors closed" % name)
			else:
				print("  %s sealed (%d cells)" % [name, reached.size()])
	elif _frame == 10:
		for name in REGIONS.keys():
			for gp in (REGIONS[name] as Dictionary)["gates"]:
				_open_door_near(gp)
	elif _frame == 14:
		print("-- gate-open floods --")
		for name in REGIONS.keys():
			var r: Dictionary = REGIONS[name]
			var reached := _flood(name, r, true)
			var t := _cell(r["target"])
			if not (t in reached):
				_fail("%s interior unreachable even with gate open" % name)
			else:
				print("  %s reachable through its gate" % name)
		print("\n%d problem(s)" % _bad)
		get_tree().quit()

## BFS over 1m cells; with gates_open the (already disabled) door cells
## are walkable. Returns the set of reached cell keys.
func _flood(name: String, r: Dictionary, gates_open: bool) -> Dictionary:
	var key := "%s_%s" % [name, gates_open]
	if _stand.has(key):
		return _stand[key]
	var reached := {}
	var queue: Array = [_cell(r["seed"])]
	reached[_cell(r["seed"])] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			var wx: float = r["x0"] + n.x
			var wz: float = r["z0"] + n.y
			if wx < r["x0"] or wx > r["x1"] or wz < r["z0"] or wz > r["z1"]:
				continue
			if n in reached or not _standable(wx, wz):
				continue
			reached[n] = true
			queue.append(n)
	_stand[key] = reached
	return reached

func _cell(p: Vector3) -> Vector2i:
	for name in REGIONS.keys():
		var r: Dictionary = REGIONS[name]
		if p.x >= r["x0"] and p.x <= r["x1"] and p.z >= r["z0"] and p.z <= r["z1"]:
			return Vector2i(int(round(p.x - r["x0"])), int(round(p.z - r["z0"])))
	return Vector2i(-1, -1)

## Standable: floor within [-0.6, 1.2] of y=0 and 1.75m of headroom.
## The downward ray starts at y=3.5 (above 3m walls/doors) so a probe
## inside a wall's footprint reads the wall top, not the ground.
func _standable(x: float, z: float) -> bool:
	var down := _space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(x, 3.5, z), Vector3(x, -2.5, z)))
	if down.is_empty():
		return false
	var fy: float = (down["position"] as Vector3).y
	if fy < -0.6 or fy > 1.2:
		return false
	var up := _space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(x, fy + 0.06, z), Vector3(x, fy + 6.0, z)))
	var head: float = 99.0 if up.is_empty() else (up["position"] as Vector3).y - fy
	return head >= 1.75

func _open_door_near(p: Vector3) -> void:
	for d in _doors():
		if (d as Node3D).global_position.distance_to(p) < 2.0:
			(d as LockedDoor)._col.set_deferred("disabled", true)

func _doors() -> Array:
	var out: Array = []
	_collect(_game.level_root, out)
	return out

func _collect(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is LockedDoor:
			out.append(child)
		_collect(child, out)

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)
