class_name GuardPostsCompound
extends RefCounted
## HOLLOWAY CAMPUS patrols (LEVEL-compound.md §5). Nine posts: seven lanes,
## two sentries. A lane covers its own axis and not much else, and every loop
## is walked 1.6m short (guards stop 0.8m before each waypoint) — the windows
## in the design doc are priced on that.
##
## Sentries carry a `facing` yaw, re-applied every time they return to their
## post (guard_brain). Yaw: 0 faces -z (north), PI faces +z (south), -PI/2
## faces +x (east), PI/2 faces -x (west).
##
## The count is a starting point, tuned by feel — there is no target number.

static func all() -> Array:
	return approach() + campus() + annex()

## The Scoring Annex district (r7): the checkpoint, Consent Way (road,
## booth, steps), inside (hall, 1F corridor, server room), the roof over the
## Way, the yards and the site. Alarm posts are deep inside (SecAlarm).
static func annex() -> Array:
	return [
		{"id": "N1", "waypoints": [Vector3(-7, 0, -45.2)], "facing": PI},          # checkpoint nest
		{"id": "N2", "waypoints": [Vector3(3, 0, -47), Vector3(3, 0, -60)]},       # Consent Way
		{"id": "N3", "waypoints": [Vector3(-9.5, 0, -61.5)], "facing": -PI / 2.0},  # booth
		{"id": "N4", "waypoints": [Vector3(4.5, 0, -73.5)], "facing": PI},         # front steps
		{"id": "N5", "waypoints": [Vector3(-14, 4, -78), Vector3(4, 4, -78)],
			"waits": [2.0, 2.0]},                                                  # 1F corridor
		{"id": "N6", "waypoints": [Vector3(0, 4, -88)], "facing": PI},             # server room
		{"id": "N7", "waypoints": [Vector3(0, 8, -78.5)], "facing": PI},           # roof
		{"id": "N8", "waypoints": [Vector3(30, 0, -56)], "facing": PI / 2.0},      # site, under S1
		{"id": "N9", "waypoints": [Vector3(-23, 0, -46), Vector3(-23, 0, -82)]},   # west yard
		{"id": "N10", "waypoints": [Vector3(-20, 0, -101), Vector3(14, 0, -101)]}, # back strip
		{"id": "N11", "waypoints": [Vector3(4, 0, -91.3), Vector3(15, 0, -91.3)]}, # hall
		{"id": "N12", "waypoints": [Vector3(28, 0, -89)], "facing": PI},           # tower foot
	]

## The approach (sec_app_*): sparse, each one a thing to get past rather than
## a wall — a yard patrol, a sentry staring down the subway, the road deck,
## the towpath hut, the allotments, the terrace fronts.
static func approach() -> Array:
	return [
		{"id": "A1", "waypoints": [Vector3(-24, 0, 156), Vector3(24, 0, 156)]},
		{"id": "A2", "waypoints": [Vector3(0, 0, 109.5)], "facing": PI},
		{"id": "A3", "waypoints": [Vector3(-36, 4, 125), Vector3(36, 4, 125)]},
		{"id": "A4", "waypoints": [Vector3(18, 0, 106)], "facing": PI / 2.0},
		{"id": "A5", "waypoints": [Vector3(-30, 0, 86), Vector3(30, 0, 86)]},
		{"id": "A6", "waypoints": [Vector3(-30, 0, 44), Vector3(30, 0, 44)]},   # clear of the overbridge stair
		{"id": "A7", "waypoints": [Vector3(-28, 0, 150), Vector3(-12, 0, 150)]},  # r8: the yard's second man
	]

static func campus() -> Array:
	return [
		{"id": "G1", "waypoints": [Vector3(-18, 0, -22), Vector3(18, 0, -22)]},   # north yard, LIT
		{"id": "G2", "waypoints": [Vector3(-16, 0, 12), Vector3(14, 0, 12)]},     # courtyard
		{"id": "G3", "waypoints": [Vector3(-25, 0, -16), Vector3(-25, 0, 14)]},   # west yard
		{"id": "G4", "waypoints": [Vector3(20, 0, -12), Vector3(20, 0, 4)]},      # gym floor
		{"id": "G5", "waypoints": [Vector3(13, 0, -19), Vector3(13, 0, 4)]},      # alley
		{"id": "G6", "waypoints": [Vector3(-18, 0, -12.5), Vector3(-2, 0, -12.5)]},  # N corridor
		{"id": "G7", "waypoints": [Vector3(0, 0, -6)], "facing": PI},             # lobby sentry
		{"id": "G8", "waypoints": [Vector3(-11, 4, -5), Vector3(-3.5, 4, -5)],
			"waits": [1.0, 3.0]},                                                 # 1F corridor
		{"id": "G10", "waypoints": [Vector3(-3.5, 10.4, -15.0)], "facing": PI},  # plant room top
		{"id": "G9", "waypoints": [Vector3(-11.5, 4, -11)], "facing": -PI / 2.0}, # hall doors
	]

## Called in on ALARM (MissionCompound.on_alarm). R1/R2 hold the north
## corridor's ends facing down it; R3 comes in from the smoking shelter and
## holds the west corridor's south half — the culvert and caretaker side.
static func reinforcements() -> Dictionary:
	return {
		"R1": {"id": "R1", "waypoints": [Vector3(-18, 0, -12.5)], "facing": -PI / 2.0},
		"R2": {"id": "R2", "waypoints": [Vector3(2, 0, -12.5)], "facing": PI / 2.0},
		"R3": {"id": "R3", "one_way": true, "facing": 0.0, "waypoints": [
			Vector3(-25, 0, 16), Vector3(-25, 0, -6), Vector3(-20.5, 0, -6),
			Vector3(-20.5, 0, -8.5)]},
		# r5: the alarm also fills the courtyard — one west of the portico, one
		# sweeping the rear lane behind the container stacks.
		"R4": {"id": "R4", "waypoints": [Vector3(-11, 0, 1.5)], "facing": PI},   # r7: off the portico line (clumped with posted guards)
		"R5": {"id": "R5", "waypoints": [Vector3(-10, 0, 18), Vector3(10, 0, 18)]},
	}
