class_name GuardPosts2
extends RefCounted
## Patrol routes for PORT VESPER — one dense district, no authored lanes.
##
## 23 guards. Cones overlap on every approach: the west lane, the north
## road, the east lane, the shore/pier, and the office roof. Nothing is a
## free corridor, but every approach has tagged cover inside 15m, so a
## ghost run stays possible (Phase 3 bots will prove it).

static func all() -> Array:
	var posts: Array = []
	posts.append_array(_terminal())
	posts.append_array(_warehouse())
	posts.append_array(_office())
	posts.append_array(_road())
	posts.append_array(_gate())
	posts.append_array(_pier())
	posts.append_array(_crane())
	posts.append_array(_yard())
	return posts

## Container terminal (west), y = 0. Three patrols working the container
## lanes above, through and below the west approach lane (z=-14).
static func _terminal() -> Array:
	return [
		{"waypoints": [Vector3(-80, 0, -20), Vector3(-60, 0, -20)]},
		{"waypoints": [Vector3(-70, 0, 2), Vector3(-50, 0, 8)]},
		{"waypoints": [Vector3(-90, 0, 12), Vector3(-70, 0, 16)]},
	]

## Warehouse interior, y = 0. Both routes cross the crate maze; the open
## east personnel gap is the quiet way through.
static func _warehouse() -> Array:
	return [
		{"waypoints": [Vector3(-88, 0, -44), Vector3(-72, 0, -44)]},
		{"waypoints": [Vector3(-80, 0, -52), Vector3(-68, 0, -46)]},
	]

## Customs office: two inside (y = 0) on close protection around the
## Harbormaster's stations, one on the roof (y = 3.6) watching the
## skylight approach and the ramp top.
static func _office() -> Array:
	return [
		{"waypoints": [Vector3(-12, 0, -12), Vector3(-4, 0, -12)]},
		{"waypoints": [Vector3(-16, 0, -24), Vector3(-16, 0, -14)]},
		{"waypoints": [Vector3(-14, 3.6, -12), Vector3(6, 3.6, -12)]},
	]

## North road, y = 0. Two long lanes covering the road approaches; their
## cones overlap the gate pair on the gateway.
static func _road() -> Array:
	return [
		{"waypoints": [Vector3(-35, 0, -52), Vector3(5, 0, -52)]},
		{"waypoints": [Vector3(15, 0, -52), Vector3(45, 0, -52)]},
	]

## North gate checkpoint, y = 0. Posted on the van extraction approach.
## Their sightlines to the spawn pad (60,0,-72) are blocked by the fence.
static func _gate() -> Array:
	return [
		{"waypoints": [Vector3(-4, 0, -63), Vector3(4, 0, -63)]},
		{"waypoints": [Vector3(5, 0, -56), Vector3(-5, 0, -56)]},
	]

## Pier district, y = 0. One works the dock office, one the pier root
## (north of the pier gate).
static func _pier() -> Array:
	return [
		{"waypoints": [Vector3(50, 0, -10), Vector3(60, 0, -6)]},
		{"waypoints": [Vector3(48, 0, -2), Vector3(56, 0, -2)]},
	]

## Far-east crane zone, y = 0. One guard on the storage key.
static func _crane() -> Array:
	return [
		{"waypoints": [Vector3(84, 0, 4), Vector3(92, 0, -4)]},
	]

## Open yard, y = 0. The shore guard covers the water-edge approach and
## the boat extraction; the office-south guard covers the front door;
## the west-yard guard covers the roof ramps and the dash platform.
## The west-lane, east-lane and shore-west patrols fill the approach
## coverage so every approach waypoint sits in 2+ cones.
static func _yard() -> Array:
	return [
		{"waypoints": [Vector3(30, 0, 18), Vector3(70, 0, 18)]},
		{"waypoints": [Vector3(-10, 0, -2), Vector3(8, 0, -2)]},
		{"waypoints": [Vector3(-44, 0, -18), Vector3(-28, 0, -18)]},
		{"waypoints": [Vector3(-72, 0, -14), Vector3(-28, 0, -14)]},
		{"waypoints": [Vector3(20, 0, -24), Vector3(44, 0, -24)]},
		{"waypoints": [Vector3(30, 0, 14), Vector3(44, 0, 14)]},
		{"waypoints": [Vector3(10, 0, -46), Vector3(30, 0, -46)]},
		{"waypoints": [Vector3(-12, 3.6, -22), Vector3(-2, 3.6, -22)]},
	]
