class_name KeyData
extends RefCounted
## Physical keys — the single source of truth for key ids and display names.
## Doors list "key:<id>" alongside verbs in their open_methods; a key in the
## player's inventory opens the door as an alternate gate (no mana, no noise).

static var _keys: Dictionary = {}

static func all() -> Dictionary:
	if _keys.is_empty():
		_keys = {
			"pier_key": {
				"name": "PIER KEY",
				"desc": "Opens the pier gate — an alternative to picking its lock.",
			},
			"storage_key": {
				"name": "STORAGE KEY",
				"desc": "Opens the storage compound gate in the container terminal.",
			},
			"roof_key": {
				"name": "ROOF KEY",
				"desc": "Opens the office skylight hatch — a shortcut from the roof.",
			},
		}
	return _keys

static func has(id: String) -> bool:
	return all().has(id)

static func key_name(id: String) -> String:
	return String(all().get(id, {}).get("name", id.to_upper()))
