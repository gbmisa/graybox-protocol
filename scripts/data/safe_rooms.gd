class_name SafeRoomData
extends RefCounted
## Per-level lockdown data: where the target relocates when the alarm maxes
## out, where the two bodyguards post, and the four map-edge posts the
## reinforcements arrive from.
##
## All positions are authored against the current gray-box geometry and must
## stay standable. Phase 2 may rebuild the safe rooms physically (walls, a
## single door); the relocation logic only needs the positions below.
##
## get_safe_room(level_id) -> {
##   "target_name": String,   # already capitalised for HUD sentences
##   "pos": Vector3,          # where the target relocates
##   "bodyguard_posts": Array,# 2 waypoint pairs patrolling the safe room
##   "reinforce_posts": Array,# 4 waypoint pairs at map-edge arrival points
## }

static func get_safe_room(level_id: int) -> Dictionary:
	match int(level_id):
		2:
			return _port_vesper()
	return _meridian_capital()

## PORT VESPER. The safe room is the north-east corner of the customs office
## interior (x [-16,16], z [-30,-14]) — inside the building, clear of the
## Harbormaster's three patrol stations. Bodyguards pace a tight box around
## it. Reinforcements arrive at verified-standable map-edge points (all four
## are floor/headroom-checked in smoketest2).
static func _port_vesper() -> Dictionary:
	return {
		"target_name": "Harbormaster",
		"pos": Vector3(10, 0, -28),
		"bodyguard_posts": [
			[Vector3(8, 0, -28), Vector3(12, 0, -27)],
			[Vector3(12, 0, -28.5), Vector3(8, 0, -27.5)],
		],
		"reinforce_posts": [
			[Vector3(-4, 0, -64), Vector3(4, 0, -64)],      # north gate road
			[Vector3(-74, 0, -26), Vector3(-66, 0, -26)],   # terminal west
			[Vector3(84, 0, 0), Vector3(92, 0, 0)],         # crane yard
			[Vector3(48.5, 0, 20), Vector3(56.5, 0, 20)],   # pier deck
		],
	}

## MERIDIAN CAPITAL. The safe room is the east end of the boardroom floor
## (y = 12), clear of the target's patrol lane and the conference table.
## Reinforcements arrive at verified-standable street-level points (all four
## are floor/headroom-checked in smoketest).
static func _meridian_capital() -> Dictionary:
	return {
		"target_name": "Chairman",
		"pos": Vector3(24, 12, -27),
		"bodyguard_posts": [
			[Vector3(22, 12, -27), Vector3(26, 12, -26.5)],
			[Vector3(26, 12, -27.5), Vector3(22, 12, -26.5)],
		],
		"reinforce_posts": [
			[Vector3(-4, 0, 70), Vector3(4, 0, 70)],       # south street
			[Vector3(-4, 0, -42), Vector3(4, 0, -42)],     # north exit
			[Vector3(46, 0, 30), Vector3(54, 0, 30)],       # dock approach
			[Vector3(10, 0, -20), Vector3(18, 0, -20)],     # freight floor
		],
	}
