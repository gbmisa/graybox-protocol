class_name HudFeed
extends HudPanel
## The top-of-screen cluster: current objective, the killfeed, and transient
## centre messages.
##
## There is deliberately no detection meter. Whether you are being seen is
## read off the guards ("?" / "!", barks, the orange aim tell) and the world
## (light tiers you can see), never off a HUD gauge (D11).

const KILLFEED_LIFETIME := 4.0

var _objective: Label
var _killfeed: VBoxContainer
var _message: Label
var _message_timer: float = 0.0

func build(root: Control) -> void:
	_objective = make_label("ASSASSINATE THE TARGET", 20, GOLD,
		HORIZONTAL_ALIGNMENT_CENTER)
	_objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_objective.position.y = 18
	root.add_child(_objective)
	_killfeed = VBoxContainer.new()
	_killfeed.add_theme_constant_override("separation", 4)
	_killfeed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_killfeed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_killfeed.position = Vector2(-340, 18)
	ignore(_killfeed)
	root.add_child(_killfeed)
	_message = make_label("", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.position.y = 160
	_message.visible = false
	root.add_child(_message)

func tick(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_message.visible = false

# ------------------------------------------------------------ public API ---
func set_objective(text: String) -> void:
	_objective.text = text

func show_message(text: String, dur: float) -> void:
	_message.text = text
	_message.visible = true
	_message_timer = dur

## Entries expire on their own timer. Safe while paused because the HUD runs
## with PROCESS_MODE_ALWAYS.
func add_killfeed(text: String) -> void:
	var l := make_label(text, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_killfeed.add_child(l)
	var tw := create_tween()
	tw.tween_interval(KILLFEED_LIFETIME)
	tw.tween_callback(l.queue_free)
