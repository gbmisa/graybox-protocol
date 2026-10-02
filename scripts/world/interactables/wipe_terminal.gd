class_name WipeTerminal
extends Interactable
## A console that does one thing once, slowly and audibly: the Scoring Annex's
## server (the secondary objective). Hold interact for USE.time; it makes
## noise, so the server room hears you. Calls `on_done` and stays done.

const USE := {"use": {"time": 3.0, "noise": 14.0, "mana": 0.0}}

var _on_done: Callable

static func create(p_game: GrayboxGame, parent: Node3D, display: String, pos: Vector3,
		size: Vector3, on_done: Callable) -> WipeTerminal:
	var w := WipeTerminal.new()
	w.position = pos
	parent.add_child(w)
	w._on_done = on_done
	w.setup(p_game, display, USE.duplicate(true), size, Color(0.15, 0.9, 0.5))
	return w

func method_for(_char_id: String) -> Dictionary:
	var m: Dictionary = USE["use"].duplicate()
	m["verb"] = "use"
	return m

func prompt_for(_player: Player) -> Dictionary:
	if is_open:
		return {}
	return {"text": "HOLD  %s" % display_name, "usable": true,
		"time": float(USE["use"]["time"]), "verb": "use"}

## Stays put; the panel goes dead red. The effect is the callback's.
func _animate_open() -> void:
	(_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.5, 0.05, 0.05)
	if _on_done.is_valid():
		_on_done.call()
