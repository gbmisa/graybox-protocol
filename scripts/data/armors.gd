class_name ArmorData
extends RefCounted
## Pre-mission armor loadouts. Cruelty Squad rules: protection costs speed.
## Chosen on the briefing screen, never toggled mid-mission.

static var _armors: Dictionary = {}

static func all() -> Dictionary:
	if _armors.is_empty():
		_armors = {
			"none": {
				"id": "none",
				"name": "STREET CLOTHES",
				"desc": "No protection. Full speed, fragile.",
				"dmg_mul": 1.0,
				"speed_mul": 1.0,
			},
			"light": {
				"id": "light",
				"name": "LIGHT VEST",
				"desc": "35% less damage taken. 12% slower.",
				"dmg_mul": 0.65,
				"speed_mul": 0.88,
			},
			"heavy": {
				"id": "heavy",
				"name": "HEAVY PLATE",
				"desc": "65% less damage taken. 30% slower. Loud and clumsy.",
				"dmg_mul": 0.35,
				"speed_mul": 0.70,
			},
		}
	return _armors

static func get_armor(id: String) -> Dictionary:
	return all().get(id, all()["none"])

static func ids() -> Array:
	return ["none", "light", "heavy"]
