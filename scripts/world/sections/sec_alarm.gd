class_name SecAlarm
extends RefCounted
## Alarm posts (the guards' way of raising the alarm) and sirens (what you
## then hear, from where they hang). Posts stand near each patrol so the
## nearest guard is never far from one, but never ON a lane: a post is a
## detour a guard takes, and the player's chance to shoot him on the way.
## Sirens are up high: the estate tower, the road deck, a terrace roof, the
## towpath hut, the campus roofs and the gatehouse.
##
## Rows: [position, yaw the panel faces (0 = south, PI = north, PI/2 = east,
## -PI/2 = west)].

const STATIONS := [
	# Approach.
	[Vector3(2, 0, 164), PI],          # estate yard, south of A1 (z 156)
	[Vector3(-6, 4, 121), 0.0],        # road deck, off A3's lane (z 125)
	[Vector3(22.4, 0, 108.8), PI],     # towpath hut, by A4
	[Vector3(-4, 0, 84), PI],          # allotments, off A5 (z 86)
	[Vector3(5, 0, 47.5), PI],         # terrace front, off A6 (z 44)
	# Campus.
	[Vector3(6, 0, -23.2), 0.0],       # north yard, by G1 (z -22)
	[Vector3(-4, 0, 22.6), PI],        # courtyard south wall, off G2 (z 12)
	[Vector3(-2.5, 0, -4.2), PI / 2.0],  # lobby, by G7
	[Vector3(-6, 4, -2.7), 0.0],       # 1F corridor, by G8
	[Vector3(26, 0, -9), -PI / 2.0],   # gym, off G4 (x 20)
	[Vector3(-26.4, 0, -1), PI / 2.0], # west yard, off G3 (x -25)
	[Vector3(15.4, 0, -6), -PI / 2.0], # alley, off G5 (x 13)
	# Scoring Annex.
	[Vector3(-11, 0, -46.5), PI],      # hall, by the south door
	[Vector3(-2, 4, -49.6), 0.0],      # 1F corridor
	[Vector3(19.6, 0, -54), -PI / 2.0], # dock, east wall
]

const SIRENS := [
	Vector3(-30, 28.2, 184), Vector3(30, 4.2, 136.2), Vector3(-8, 6.2, 57),
	Vector3(23, 2.9, 107), Vector3(-20, 8.5, -18), Vector3(8, 8.5, -3),
	Vector3(24, 6.7, 6), Vector3(-6, 4.1, -27), Vector3(-34, 4.1, -13),
	Vector3(-10, 8.6, -57),
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for s in STATIONS:
		AlarmStation.create(game, root, s[0], float(s[1]))
	for p in SIRENS:
		AlarmSiren.create(root, p)
