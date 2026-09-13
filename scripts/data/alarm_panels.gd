class_name AlarmPanelData
extends RefCounted
## Data-driven alarm panel positions, per level. Panels are freestanding
## red pedestals with an "ALARM PANEL" label; the director spawns them from
## this table (see AlarmPanel.spawn_all), so moving one is a data edit, not
## a geometry edit.
##
## All positions were picked against the current gray-box geometry and must
## stay standable and reachable on foot:
##   L1  one per floor of the tower's vertical spine (lobby, mezzanine,
##       boardroom) — the runner never needs stairs it cannot climb.
##   L2  customs office front, pier dock office door, gatehouse — the three
##       named checkpoints of the district.

static func get_panels(level_id: int) -> Array:
	match int(level_id):
		2:
			return _port_vesper()
		_:
			return _meridian_capital()

## MERIDIAN CAPITAL. Ground floor inside the north emergency exit, the
## mezzanine convergence plate, and the west end of the boardroom floor —
## clear of the Chairman's patrol lane and the conference table.
static func _meridian_capital() -> Array:
	return [
		{"pos": Vector3(8, 0, -36), "name": "LOBBY"},
		{"pos": Vector3(-8, 6, -14), "name": "MEZZANINE"},
		{"pos": Vector3(-26, 12, -26), "name": "BOARDROOM"},
	]

## PORT VESPER. South of the customs office front door, outside the dock
## office's west door, and on open ground by the gatehouse desk.
static func _port_vesper() -> Array:
	return [
		{"pos": Vector3(-7.5, 0, -4.5), "name": "CUSTOMS OFFICE"},
		{"pos": Vector3(50, 0, -15), "name": "DOCK OFFICE"},
		{"pos": Vector3(8, 0, -52), "name": "GATEHOUSE"},
	]
