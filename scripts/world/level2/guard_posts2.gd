class_name GuardPosts2
extends RefCounted
## Patrol routes for PORT VESPER, grouped by district.
##
## 15 guards. The warehouse pair is authored for Chad's consequence: his
## breach lands at (-96, 0, -27) with 60 noise, both guards investigate the
## breach, and their patrol routes run through the east-personnel-door
## corridor — so his way out of the warehouse is hotter than his way in.
## No new systems; the consequence is spatial. The corridor/lane guards give
## the Wizard's dash line its timing beat and the Regular's east approach
## its final decision.

static func all() -> Array:
	var posts: Array = []
	posts.append_array(_terminal())
	posts.append_array(_warehouse())
	posts.append_array(_office())
	posts.append_array(_gate())
	posts.append_array(_pier())
	posts.append_array(_crane())
	posts.append_array(_dash_threat())
	return posts

## Container terminal (west), y = 0. Three patrols working the container
## lanes; the third covers the south lanes near the storage compound.
static func _terminal() -> Array:
	return [
		{"waypoints": [Vector3(-80, 0, -30), Vector3(-60, 0, -30)]},
		{"waypoints": [Vector3(-70, 0, 0), Vector3(-50, 0, 10)]},
		{"waypoints": [Vector3(-90, 0, 10), Vector3(-70, 0, 20)]},
	]

## Warehouse interior, y = 0. Both routes pass the east personnel door
## (-64, 0, -27) — the corridor Chad must leave through. Both are inside
## the 60m breach noise radius.
static func _warehouse() -> Array:
	return [
		{"waypoints": [Vector3(-88, 0, -32), Vector3(-70, 0, -20)]},
		{"waypoints": [Vector3(-80, 0, -16), Vector3(-68, 0, -24)]},
	]

## Customs office interior, y = 0. Close protection around the target's
## three patrol stations.
static func _office() -> Array:
	return [
		{"waypoints": [Vector3(-8, 0, -21), Vector3(8, 0, -21)]},
		{"waypoints": [Vector3(2, 0, -26), Vector3(2, 0, -17)]},
	]

## North gate checkpoint, y = 0. Posted on the van extraction approach.
## Their sightlines to the spawn pad (0,0,-74) are blocked by the blast wall.
static func _gate() -> Array:
	return [
		{"waypoints": [Vector3(-4, 0, -63), Vector3(4, 0, -63)]},
		{"waypoints": [Vector3(5, 0, -57), Vector3(-5, 0, -57)]},
	]

## Pier district, y = 0. One works the dock office, one the pier root
## (north of the pier gate).
static func _pier() -> Array:
	return [
		{"waypoints": [Vector3(50, 0, -10), Vector3(60, 0, -5)]},
		{"waypoints": [Vector3(48, 0, -2), Vector3(56, 0, -2)]},
	]

## Far-east crane zone, y = 0. One guard on the storage key.
static func _crane() -> Array:
	return [
		{"waypoints": [Vector3(84, 0, 4), Vector3(92, 0, -4)]},
	]

## The Wizard's timing beat, y = 0. One patrols the clear corridor UNDER the
## dash line (the ramp climb and any fall happen in its sightline); two work
## the lanes flanking the office, so the roof crossing has to be timed
## between passes. The east one doubles as the Regular's final decision
## before the east service door.
static func _dash_threat() -> Array:
	return [
		{"waypoints": [Vector3(-54, 0, -22), Vector3(-30, 0, -22)]},
		{"waypoints": [Vector3(-20, 0, -32), Vector3(-20, 0, -12)]},
		{"waypoints": [Vector3(20, 0, -32), Vector3(20, 0, -12)]},
	]
