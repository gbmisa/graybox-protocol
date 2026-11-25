class_name SecAlarm
extends RefCounted
## Alarm posts (the guards' way of raising the alarm) and sirens (what you
## then hear, from where they hang).
##
## r7: "make it so there's an opportunity to kill guards without them being
## right next to an alarm". A post is now a RUN: tucked away from the patrol
## lanes, so an alerted guard has 12m+ of navmesh to cover (3s+ at his run
## speed, not shooting) — usually 20-50m. Exceptions on purpose: G5 (alley)
## and G7 (lobby sentry) are ~12-14m from the kitchen post. r8 added posts for
## the road deck and the annex roof.
## Measure with `tools/alarm_reach.gd`; `_compound_systems` enforces it.
## Sirens are up high: the estate tower, the road deck, a terrace roof, the
## towpath hut, the campus roofs and the gatehouse.
##
## Rows: [position, yaw the panel faces (0 = south, PI = north, PI/2 = east,
## -PI/2 = west)].

const STATIONS := [
	# Approach.
	[Vector3(10, 0, 182), PI],         # spawn street
	[Vector3(-30, 0, 106), 0.0],       # towpath, west end
	[Vector3(-26, 0, 65), 0.0],        # terrace back yards
	# Campus.
	[Vector3(24, 0, 20), -PI / 2.0],   # refuse yard
	[Vector3(6, 0, -17), 0.0],         # kitchen
	[Vector3(8, 4, -14), 0.0],         # 1F east landing
	# Scoring Annex district: deep inside, nothing on Consent Way.
	[Vector3(-16.5, 0, -94.6), 0.0],   # hall, NW corner
	[Vector3(-16.5, 4, -94.6), 0.0],   # 1F west office, NW corner
	[Vector3(-32.5, 0, -103), -PI / 2.0], # back strip, far west
	# r8 level review: guards with no post in reach carried no stakes. The
	# road deck's far corner (a run off A3's lane) and the annex roof.
	[Vector3(43, 4, 137), PI],         # road deck, far NE corner
	[Vector3(-14, 8, -92), 0.0],       # annex roof, by the hatch
	[Vector3(31, 0, -43), PI],         # foot of the site stair (N8's run)
	[Vector3(-36, 0, 145), 0.0],       # estate substation wall (A7's run)
]

const SIRENS := [
	Vector3(-30, 28.2, 184), Vector3(30, 4.2, 136.2), Vector3(-8, 6.2, 57),
	Vector3(23, 2.9, 107), Vector3(-20, 8.5, -18), Vector3(8, 8.5, -3),
	Vector3(24, 6.7, 6), Vector3(-6, 4.1, -27), Vector3(-34, 4.1, -13),
	Vector3(-12, 8.6, -95), Vector3(12, 8.6, -95), Vector3(33.5, 6.3, -76),
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for s in STATIONS:
		AlarmStation.create(game, root, s[0], float(s[1]))
	for p in SIRENS:
		AlarmSiren.create(root, p)
