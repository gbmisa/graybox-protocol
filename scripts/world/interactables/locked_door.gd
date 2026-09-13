class_name LockedDoor
extends Interactable
## A security door. Which verbs open it is per-instance, so the same class
## builds a three-way soft gate or a single-verb hard gate.
##
##     LockedDoor.create(game, root, "MAINTENANCE DOOR", pos, size,
##         ["lockpick", "arcane", "smash"])
##
## Costs come from `standard_methods` so every door in the level stays
## consistent and the whole game retunes from one place.

const COSTS := {
	"lockpick": {"time": 3.0, "noise": 0.0, "mana": 0.0},
	"arcane": {"time": 0.6, "noise": 12.0, "mana": 30.0},
	"smash": {"time": 0.4, "noise": 45.0, "mana": 0.0},
}

## Build a cost table from a list of verbs, e.g. ["lockpick", "smash"].
static func standard_methods(verbs: Array) -> Dictionary:
	var out: Dictionary = {}
	for v in verbs:
		if COSTS.has(v):
			out[v] = COSTS[v].duplicate()
	return out

static func create(game: GrayboxGame, parent: Node3D, display: String,
		pos: Vector3, size: Vector3, verbs: Array,
		overrides: Dictionary = {}) -> LockedDoor:
	var d := LockedDoor.new()
	d.position = pos
	parent.add_child(d)
	var methods := standard_methods(verbs)
	# Per-door tuning, e.g. {"lockpick": {"time": 2.5}} for a faster lock.
	for verb in overrides.keys():
		if methods.has(verb):
			for k in (overrides[verb] as Dictionary).keys():
				methods[verb][k] = overrides[verb][k]
	d.setup(game, display, methods, size, Color(0.30, 0.32, 0.38))
	return d

## Doors sink into the floor rather than swinging, which never clips the
## player standing in the doorway waiting for it.
func _animate_open() -> void:
	_col.set_deferred("disabled", true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_mesh, "position",
		_mesh.position + Vector3(0, -_size.y - 0.15, 0), 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var accent := _mesh.get_meta("accent", null) as Node3D
	if accent != null:
		tw.tween_property(accent, "position",
			accent.position + Vector3(0, -_size.y - 0.15, 0), 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
