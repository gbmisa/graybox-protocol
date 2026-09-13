class_name Sec2Cover
extends RefCounted
## Deliberate hiding spots for PORT VESPER: crates, barriers and roof clutter
## tagged into the "hiding_spot" group. District sections tag their own
## crates via Sec2Cover.crate so the mazes double as cover; build() places
## the approach-line cover. The smoketest requires a tagged spot within 15m
## of every approach waypoint — no free corridors, but ghosting stays
## possible.

static func crate(parent: Node3D, pos: Vector3, size: Vector3,
		color: Color) -> MeshInstance3D:
	var mi := BuildUtils.box(parent, pos, size, color)
	mi.add_to_group("hiding_spot")
	return mi

static func build(_game: GrayboxGame, root: Node3D) -> void:
	var c := Color(0.44, 0.32, 0.20)
	var c2 := Color(0.36, 0.28, 0.18)
	# West lane (z=-14) to the office west door — cover set back from the
	# lane so patrol sightlines stay open.
	for i in range(4):
		var x := -70.0 + 14.0 * i
		crate(root, Vector3(x, 1.0, -9), Vector3(2, 2, 2),
			c if i % 2 == 0 else c2)
	# North road (z=-52) and the gateway approach.
	# North road cover — set back from the road and the patrol lanes.
	for xp in [-45.0, 30.0]:
		crate(root, Vector3(xp, 1.0, -46), Vector3(2, 2, 2), c)
	for xp in [-8.0, 8.0]:
		crate(root, Vector3(xp, 0.75, -55), Vector3(1.5, 1.5, 1.5), c2)
	# East lane (z=-20) to the office east door — set back from the lane.
	for xp in [25.0, 38.0]:
		crate(root, Vector3(xp, 1.0, -15), Vector3(2, 2, 2),
			c if xp < 30.0 else c2)
	# South shore (z=18) toward the pier — set back from the patrol lanes.
	for i in range(3):
		crate(root, Vector3(35.0 + 20.0 * i, 1.0, 10), Vector3(2, 2, 2),
			c2 if i % 2 == 0 else c)
	# Pier deck clutter.
	crate(root, Vector3(48, 0.5, 15), Vector3(2, 1, 2), c)
	crate(root, Vector3(57, 0.5, 30), Vector3(2, 1, 2), c2)
	# Vent approach cover (north of the office).
	crate(root, Vector3(-14, 1.0, -36), Vector3(2, 2, 2), c)
	crate(root, Vector3(-6, 1.0, -36), Vector3(2, 2, 2), c2)
	# Culvert approach (outside the fence).
	crate(root, Vector3(64, 1.0, -64), Vector3(2, 2, 2), c)
	crate(root, Vector3(76, 1.0, -64), Vector3(2, 2, 2), c2)
	# Office roof clutter: vent housing + AC unit.
	crate(root, Vector3(-10, 4.0, -20), Vector3(1.5, 0.8, 1.5),
		BuildUtils.METAL)
	crate(root, Vector3(5, 4.1, -10), Vector3(2, 1.0, 1.2),
		BuildUtils.CONCRETE)
