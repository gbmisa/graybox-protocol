class_name CharData
extends RefCounted
## Per-character movement and survivability stats, plus the kit script that
## supplies that character's moveset. Adding an operative means adding an entry
## here and a kit script — no gameplay code changes.

static var _chars: Dictionary = {}

static func all() -> Dictionary:
	if _chars.is_empty():
		_chars = {
			"regular": {
				"id": "regular",
				"name": "THE REGULAR",
				"role": "STEALTH / GUNS",
				"desc": "A relatable guy with a pistol and a set of picks. Fragile on his own — take armor, but every plate costs you speed.",
				"style": "stealth / precision",
				"route": "SERVICE ENTRANCE — storm drain, crawlspaces, locked doors. Tight corridors, nowhere to run.",
				"kit": "res://scripts/player/kits/kit_regular.gd",
				"hp": 100.0,
				"speed": 7.0,
				"sprint_mul": 1.5,
				"jump_v": 6.0,
				"accel": 40.0,
				"air_accel": 14.0,
			},
			"wizard": {
				"id": "wizard",
				"name": "THE WIZARD",
				"role": "GLASS CANNON / ARCANE",
				"desc": "Squishy scholar of the arcane. Fireballs, a charged bolt, a meteor for the crowd, and a dash that phases you out of harm.",
				"style": "burst / mobility",
				"route": "THE VERTICAL — warded gates, open ground, a shaft you dash your way up. No cover, all tempo.",
				"kit": "res://scripts/player/kits/kit_wizard.gd",
				"hp": 60.0,
				"speed": 6.6,
				"sprint_mul": 1.0,          # no sprint — the dash is the mobility tool
				"jump_v": 6.0,
				"accel": 35.0,
				"air_accel": 8.0,
			},
			"chad": {
				"id": "chad",
				"name": "GIGA CHAD",
				"role": "MELEE TANK / DEMOLITION",
				"desc": "An unstoppable beat-em-up machine. Punch through guards, shrug off bullets, slam the earth, put a door through a wall.",
				"style": "brute force / parkour",
				"route": "THROUGH THE WALL — shutters, collapsed masonry, container stacks. Every gate you open wakes the building.",
				"kit": "res://scripts/player/kits/kit_chad.gd",
				"hp": 250.0,
				"speed": 7.6,
				"sprint_mul": 1.6,
				"jump_v": 7.5,
				"accel": 50.0,
				"air_accel": 20.0,
			},
		}
	return _chars

static func get_char(id: String) -> Dictionary:
	return all().get(id, all()["regular"])

static func ids() -> Array:
	return ["regular", "wizard", "chad"]
