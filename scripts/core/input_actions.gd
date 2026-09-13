class_name InputActions
extends RefCounted
## Registers the game's input actions at runtime rather than in project
## settings, so the bindings live next to the code that reads them.
##
## Note that "sprint" is bound to Shift for everyone, but the Wizard's kit
## returns false from allows_sprint() and consumes the same key as his dash.

const KEYS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_C, KEY_CTRL],
	"ability": [KEY_E, KEY_Q],
	"interact": [KEY_F],
	"pause": [KEY_ESCAPE],
}

const MOUSE := {
	"attack": MOUSE_BUTTON_LEFT,
	"alt_attack": MOUSE_BUTTON_RIGHT,
}

static func register() -> void:
	for action in KEYS.keys():
		for key in KEYS[action]:
			_add_key(String(action), key)
	for action in MOUSE.keys():
		_add_mouse(String(action), MOUSE[action])

static func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	# Guard against duplicates when the game reloads in the editor.
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)

static func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
