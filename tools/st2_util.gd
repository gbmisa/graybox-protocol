## Shared physics/probe helpers for the PORT VESPER smoketest.
static func collect(node: Node, out: Array, cls: String) -> void:
	for child in node.get_children():
		if child.get_class() == cls or (cls == "IntelPickup" and child is IntelPickup) \
				or (cls == "KeyItem" and child is KeyItem):
			out.append(child)
		collect(child, out, cls)

static func ray(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b))

static func floor_under(space: PhysicsDirectSpaceState3D, pos: Vector3) -> float:
	var hit := ray(space, pos + Vector3(0, 1.2, 0), pos + Vector3(0, -5.0, 0))
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
static func headroom(space: PhysicsDirectSpaceState3D, floor_pos: Vector3) -> float:
	var from := floor_pos + Vector3(0, 0.06, 0)
	var hit := ray(space, from, from + Vector3(0, 6.0, 0))
	return 99.0 if hit.is_empty() else (hit["position"] as Vector3).y - floor_pos.y
