class_name GuardPosts
extends RefCounted
## Patrol routes, grouped by the sector each guard belongs to.
##
## Counts are weighted by how each route plays rather than spread evenly. The
## courtyard is stacked because the Wizard fights in the open with 60 HP and
## needs targets worth spending a Meteor on; the undercroft is nearly empty
## because two guards in a corridor with no retreat is already the encounter.

static func all() -> Array:
	var posts: Array = []
	posts.append_array(_undercroft())
	posts.append_array(_courtyard())
	posts.append_array(_dock())
	posts.append_array(_mezzanine())
	posts.append_array(_boardroom())
	return posts

## REGULAR's route, y = -4. Sparse and claustrophobic.
static func _undercroft() -> Array:
	# Guard 1 paces east of the descent ramp / maintenance door so a ghost
	# can pick the door while the guard moves at 90 degrees to them (P7).
	return [
		{"waypoints": [Vector3(-44, -4, 30), Vector3(-44, -4, 24)]},
		{"waypoints": [Vector3(-52, -4, 4), Vector3(-30, -4, 10)]},
	]

## WIZARD's route, y = 0. The densest sector in the level, and grouped so a
## single well-placed Meteor is worth the 45 mana.
static func _courtyard() -> Array:
	return [
		{"waypoints": [Vector3(-20, 0, 36), Vector3(-20, 0, 16)]},
		{"waypoints": [Vector3(-6, 0, 34), Vector3(14, 0, 34)]},
		{"waypoints": [Vector3(20, 0, 30), Vector3(20, 0, 14)]},
		{"waypoints": [Vector3(4, 0, 16), Vector3(-14, 0, 22)]},
		{"waypoints": [Vector3(0, 0, 26), Vector3(10, 0, 20)]},
	]

## CHAD's route, y = 0. Positioned to converge on the shutter, because
## breaching it is the loudest event in the game.
static func _dock() -> Array:
	return [
		{"waypoints": [Vector3(44, 0, 34), Vector3(64, 0, 34)]},
		{"waypoints": [Vector3(60, 0, 10), Vector3(38, 0, 16)]},
		{"waypoints": [Vector3(52, 0, 24), Vector3(52, 0, 6)]},
		{"waypoints": [Vector3(24, 0, -18), Vector3(14, 0, -6)]},
	]

## Convergence floor, y = 6. Everyone meets these. Routes are kept on the
## unbroken z [-34, -8] band so no guard patrols into a shaft opening.
static func _mezzanine() -> Array:
	# Guard 1 moved west off the entry stair (was x=-22, the stair's own
	# footprint) so climbing the stair no longer means walking into him (P7).
	# Guard 3 keeps off z -12: the boardroom stair's new side walls (P7) stand
	# on that line, so the patrol runs 2m south of the stair entries — still
	# watching them, but no longer walking through masonry.
	return [
		{"waypoints": [Vector3(-28.8, 6, -12), Vector3(-28.8, 6, -26)]},
		{"waypoints": [Vector3(-8, 6, -20), Vector3(12, 6, -20)]},
		{"waypoints": [Vector3(22, 6, -10), Vector3(8, 6, -10)]},
		{"waypoints": [Vector3(-14, 6, -32), Vector3(8, 6, -32)]},
	]

## Target's floor, y = 12. Close protection.
static func _boardroom() -> Array:
	return [
		{"waypoints": [Vector3(-12, 12, -28), Vector3(-12, 12, -36)]},
		{"waypoints": [Vector3(12, 12, -30), Vector3(12, 12, -37)]},
	]
