class_name CivilianPostsCompound
extends RefCounted
## HOLLOWAY CAMPUS bystanders: residents on the approach, staff and guests on
## the campus, the audit's audience in the hall. A single waypoint is someone
## standing about; two or more is someone pacing between them. No script counts
## them — they are there to scream, run, and get in the way when it goes loud.
##
## Rows are plain waypoint lists; `tools/smoketest_civilians.gd` checks that
## every spot is floor with room to stand.

static func all() -> Array:
	var out: Array = []
	var n := 0
	for row in ROWS:
		n += 1
		out.append({"waypoints": row, "seed": 1000 + n * 37})
	return out

const ROWS := [
	# Scoring Annex: clerks counting.
	[Vector3(-7, 0, -50.5), Vector3(-1, 0, -50.5)],
	[Vector3(-9, 4, -55)],
	# Spawn street.
	[Vector3(-6.5, 0, 190.5)],
	[Vector3(-4, 0, 182), Vector3(5, 0, 182)],
	# Estate yard (the zigzag corridor).
	[Vector3(-18, 0, 153)],
	[Vector3(-12, 0, 159), Vector3(2, 0, 159)],
	[Vector3(30, 0, 156)],
	# Ring road deck.
	[Vector3(14, 4, 128)],
	[Vector3(-30, 4, 122), Vector3(-14, 4, 122)],
	# Towpath.
	[Vector3(-12, 0, 102.5)],
	[Vector3(-20, 0, 106), Vector3(2, 0, 106)],
	# Allotments and terraces.
	[Vector3(-8, 0, 78)],
	[Vector3(20, 0, 72), Vector3(20, 0, 82)],
	[Vector3(0, 0, 50.5), Vector3(14, 0, 50.5)],
	# Campus: courtyard, smoking shelter, forecourt, gym.
	[Vector3(-14, 0, 15.5), Vector3(8, 0, 15.5)],
	[Vector3(-8, 0, 21.5)],
	[Vector3(-25.8, 0, 17.8)],
	[Vector3(26.5, 0, 10)],
	[Vector3(20, 0, -4)],
	# The audit's audience, in the hall.
	[Vector3(-8, 4, -18)],
	[Vector3(-3, 4, -18.5)],
	[Vector3(2.5, 4, -18)],
]
