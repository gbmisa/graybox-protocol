extends SceneTree
## A measured plan of HOLLOWAY ROAD for review (r8's level-design judge),
## from physics, not pixels: every 0.5m, is there a wall at body height on
## the ground floor, and how high is the topmost walkable surface (the high
## routes)? Writes screenshots/plan.txt (one row per z, from north) for
## tools/gen/draw_plan.py, which draws it with the room tags.
##
##     godot --headless --path . --script res://tools/map_plan.gd && python3 tools/gen/draw_plan.py

const X0 := -46.0
const X1 := 46.0
const Z0 := -110.0
const Z1 := 198.0
const STEP := 0.5

var _frame := 0
var _level: Node3D

func _initialize() -> void:
	_level = Node3D.new()
	root.add_child(_level)
	for sec in LevelCompound.sections().values():
		sec.build(_level, null)

func _physics_process(_d: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var space := _level.get_world_3d().direct_space_state
	var pq := PhysicsPointQueryParameters3D.new()
	pq.collision_mask = 1
	var f := FileAccess.open("res://screenshots/plan.txt", FileAccess.WRITE)
	f.store_line("%f %f %f %f %f" % [X0, X1, Z0, Z1, STEP])
	var z := Z0
	while z < Z1:
		var row := PackedStringArray()
		var x := X0
		while x < X1:
			# Ground: floor under (x, 1.0, z) and whether 1.0m above it is solid.
			var down := PhysicsRayQueryParameters3D.create(Vector3(x, 1.0, z), Vector3(x, -6.0, z))
			down.collision_mask = 1
			var g := space.intersect_ray(down)
			var gy: float = (g["position"] as Vector3).y if not g.is_empty() else -99.0
			pq.position = Vector3(x, (gy if gy > -50 else 0.0) + 1.0, z)
			var wall := not space.intersect_point(pq, 1).is_empty()
			# Top: highest surface under the sky.
			var top_ray := PhysicsRayQueryParameters3D.create(Vector3(x, 40.0, z), Vector3(x, -6.0, z))
			top_ray.collision_mask = 1
			var t := space.intersect_ray(top_ray)
			var ty: float = (t["position"] as Vector3).y if not t.is_empty() else -99.0
			row.append("%s,%.1f,%.1f" % ["W" if wall else ("." if gy > -50 else "_"), gy, ty])
			x += STEP
		f.store_line(" ".join(row))
		z += STEP
	f.close()
	var rf := FileAccess.open("res://screenshots/plan_rooms.txt", FileAccess.WRITE)
	for r in SecRoomNames.ROOMS:
		var p: Vector3 = r[2]
		rf.store_line("%s|%s|%f|%f|%f" % [r[0], r[1], p.x, p.y, p.z])
	rf.close()
	print("plan written")
	quit()
	return true
