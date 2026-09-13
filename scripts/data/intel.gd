class_name IntelData
extends RefCounted
## Readable intel notes — the single source of truth for intel text.
## IntelPickup nodes reference an id; the reading panel shows title + body.
## Everything here is OPTIONAL: no objective ever requires an intel note.

static var _notes: Dictionary = {}

static func all() -> Dictionary:
	if _notes.is_empty():
		_notes = {
			"routine": {
				"title": "HARBORMASTER'S ROUTINE",
				"body": "He paces the customs office, day and night: east desk, west files, south windows. Never leaves the building. The guards change shifts; he does not.\n\n— R.",
			},
			"manifest12c": {
				"title": "MANIFEST 12-C",
				"body": "400 crates of \"olive oil\". Sure.\n\nSeized under customs hold 12-C. Awaiting auction that will never happen.\n\nOPTIONAL INTEL — flavor only, not an objective.",
			},
			"complaint": {
				"title": "DOCKWORKER'S COMPLAINT",
				"body": "To: Management\nRe: Crane 2\n\nIt has been broken since 2019. We have asked fourteen times. The pigeons have unionized. Yesterday a crate fell off the snapped cable and nobody even filed the form, because the form requires the crane to lift the crate, and the crane is broken.\n\nFix the crane.\n\n— D., Local 88",
			},
			"seized": {
				"title": "SEIZED GOODS LOG",
				"body": "Hold items, west warehouse:\n\n- 400 crates \"olive oil\" (see Manifest 12-C)\n- 12 pallets undeclared textiles\n- 1 forklift, slightly haunted\n- 3 tons of ball bearings, loose\n\nDo not stack the ball bearings above the olive oil.\n\nOPTIONAL INTEL — flavor only, not an objective.",
			},
		}
	return _notes

static func has(id: String) -> bool:
	return all().has(id)

static func title(id: String) -> String:
	return String(all().get(id, {}).get("title", id.to_upper()))

static func body(id: String) -> String:
	return String(all().get(id, {}).get("body", ""))
