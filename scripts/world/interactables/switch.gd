class_name Switch
extends Interactable
## A lever, isolator or release anyone can throw — no verb, no noise. Fires a
## callback once: the mast isolator, the gate lever, the panic-room release.

const USE := {"use": {"time": 0.4, "noise": 0.0, "mana": 0.0}}

var _on_use: Callable

static func create(game: GrayboxGame, parent: Node3D, display: String,
		pos: Vector3, size: Vector3, on_use: Callable) -> Switch:
	var s := Switch.new()
	s.position = pos
	parent.add_child(s)
	s._on_use = on_use
	s.setup(game, display, USE.duplicate(true), size, Color(0.62, 0.52, 0.16))
	return s

func method_for(_char_id: String) -> Dictionary:
	var m: Dictionary = USE["use"].duplicate()
	m["verb"] = "use"
	return m

## Stays where it is and goes green; the effect is the callback's.
func _animate_open() -> void:
	(_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.2, 0.7, 0.3)
	if _on_use.is_valid():
		_on_use.call()
