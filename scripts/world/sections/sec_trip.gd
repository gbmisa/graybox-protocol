class_name SecTrip
extends RefCounted
## Where the trip gets into the walls (TripZone): the dark places you have to
## go through or choose to, each a box. Eyes in their walls follow you; faces
## wait at the edge of your vision. None of it is on the Score's grid.

## [box, eyes (clusters), faces]
const ZONES := [
	[AABB(Vector3(-1.5, 0, 112), Vector3(3, 3, 26)), 40, 3],        # A09 subway
	[AABB(Vector3(-10, -2.5, 92), Vector3(20, 2.5, 8)), 30, 3],     # A15 canal bed, under the bridge
	[AABB(Vector3(-22, -3, -20), Vector3(9, 2.2, 12)), 40, 3],      # U03/U04 west run and spur
	[AABB(Vector3(-34, -3, -18), Vector3(5.2, 3, 10)), 25, 2],      # U01 boiler basement
	[AABB(Vector3(22, -3, -72), Vector3(12, 3, 10)), 35, 3],        # S04 the excavation
	[AABB(Vector3(-6, 4, -96), Vector3(12, 4, 12)), 45, 2],         # N16 server room
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	var i := 0
	for z in ZONES:
		i += 1
		TripZone.create(root, z[0], int(z[1]), int(z[2]), 4120 + i * 31)
