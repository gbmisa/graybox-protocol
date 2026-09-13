class_name LevelData
extends RefCounted
## Per-mission tuning: names, briefing copy, and the per-operative route text
## shown on the select cards. Level 1's route copy lives here (not in
## CharData) so every mission describes its own version of each way in.

static var _levels: Dictionary = {}

static func all() -> Dictionary:
	if _levels.is_empty():
		_levels = {
			1: {
				"id": 1,
				"name": "MERIDIAN CAPITAL",
				"desc": "A five-storey office tower downtown. One target, three extractions.",
				"infiltrate": "INFILTRATE MERIDIAN CAPITAL",
				"extractions": "EXTRACTIONS: helipad (roof) · van (street) · sump outflow (crawl only)",
				"routes": {
					"regular": "SERVICE ENTRANCE — storm drain, crawlspaces, locked doors. Tight corridors, nowhere to run.",
					"wizard": "THE VERTICAL — warded gates, open ground, a shaft you dash your way up. No cover, all tempo.",
					"chad": "THROUGH THE WALL — shutters, collapsed masonry, container stacks. Every gate you open wakes the building.",
				},
			},
			2: {
				"id": 2,
				"name": "PORT VESPER",
				"desc": "A waterfront customs impound dockyard at night. The Harbormaster walks his rounds — find him.",
				"infiltrate": "INFILTRATE PORT VESPER",
				"extractions": "EXTRACTIONS: boat (south pier) · van (north gate) · drainage outflow (crawl only)",
				"routes": {
					"regular": "DRAINAGE CULVERT — east crawl, container yard, locked doors. Quiet, slow, patient.",
					"wizard": "CONTAINER DASH LINE — north fence, 7m dash gaps over the yard, warded skylight. No cover, all tempo.",
					"chad": "IMPOUND BREACH — smash the west wall, through the warehouse, smash the office door. Every hit wakes the yard.",
				},
			},
		}
	return _levels

static func ids() -> Array:
	return [1, 2]

static func get_level(id: int) -> Dictionary:
	return all().get(id, all()[1])

static func get_name(id: int) -> String:
	return String(get_level(id)["name"])

static func get_route(level_id: int, char_id: String) -> String:
	var routes: Dictionary = get_level(level_id)["routes"]
	return String(routes.get(char_id, routes["regular"]))

static func get_infiltrate(id: int) -> String:
	return String(get_level(id)["infiltrate"])

static func get_extractions(id: int) -> String:
	return String(get_level(id)["extractions"])
