class_name GuardPosts2
extends RefCounted
## Patrol routes for PORT VESPER, grouped by sector.
##
## The yard is stacked because the Wizard crosses it at container height with
## 60 HP and the grouped patrols are meteor bait. The warehouse pair is
## authored for Chad's consequence: his breach lands at (-60, 0, -3) with 60
## noise, both guards investigate the breach, and their patrol routes run
## through the east-personnel-door corridor — so his way out of the warehouse
## is hotter than his way in. No new systems; the consequence is spatial.

static func all() -> Array:
	var posts: Array = []
	posts.append_array(_yard())
	posts.append_array(_warehouse())
	posts.append_array(_office())
	posts.append_array(_gate())
	posts.append_array(_pier())
	return posts

## Container yard, y = 0. Grouped under the Wizard's dash line — except the
## second patrol, which works the west containers near the warehouse exit.
## That puts it inside the 60m smash radius, so Chad's breach pulls it onto
## his way out.
static func _yard() -> Array:
	return [
		{"waypoints": [Vector3(10, 0, -10), Vector3(26, 0, -10)]},
		{"waypoints": [Vector3(-2, 0, -8), Vector3(-14, 0, -2)]},
		{"waypoints": [Vector3(8, 0, 8), Vector3(24, 0, 14)]},
		{"waypoints": [Vector3(34, 0, 4), Vector3(34, 0, 20)]},
	]

## Warehouse interior, y = 0. Both routes pass the east personnel door
## (-24, 0, -5.5) — the corridor Chad must leave through.
static func _warehouse() -> Array:
	return [
		{"waypoints": [Vector3(-48, 0, -12), Vector3(-28, 0, -6)]},
		{"waypoints": [Vector3(-36, 0, 8), Vector3(-28, 0, -2)]},
	]

## Customs office interior, y = 0. Close protection around the target's
## three patrol stations.
static func _office() -> Array:
	return [
		{"waypoints": [Vector3(-8, 0, -21), Vector3(8, 0, -21)]},
		{"waypoints": [Vector3(2, 0, -26), Vector3(2, 0, -17)]},
	]

## North gate checkpoint, y = 0. Posted on the van extraction approach.
static func _gate() -> Array:
	return [
		{"waypoints": [Vector3(-4, 0, -53), Vector3(4, 0, -53)]},
		{"waypoints": [Vector3(5, 0, -48), Vector3(-5, 0, -48)]},
	]

## South pier, y = 0. One guard walks the boat extraction.
static func _pier() -> Array:
	return [
		{"waypoints": [Vector3(30, 0, 48), Vector3(30, 0, 58)]},
	]
