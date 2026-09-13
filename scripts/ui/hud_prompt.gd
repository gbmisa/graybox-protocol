class_name HudPrompt
extends HudPanel
## The interaction prompt, just under the crosshair.
##
## Shows in white with a fill bar while the operative can open what they are
## looking at, and greyed out when they cannot — a hard gate is supposed to
## explain itself ("REQUIRES BRUTE FORCE") rather than read as scenery that
## happens not to respond.

const USABLE := Color(1.0, 1.0, 1.0)
const BLOCKED := Color(0.72, 0.44, 0.44)

var _box: VBoxContainer
var _label: Label
var _bar: ProgressBar

func build(root: Control) -> void:
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 6)
	_box.set_anchors_preset(Control.PRESET_CENTER)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.position = Vector2(-140, 44)
	_box.custom_minimum_size = Vector2(280, 0)
	_box.visible = false
	ignore(_box)
	_label = make_label("", 18, USABLE, HORIZONTAL_ALIGNMENT_CENTER)
	_label.custom_minimum_size = Vector2(280, 0)
	_box.add_child(_label)
	_bar = make_bar(200, 6)
	_bar.value = 0
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_bar)
	root.add_child(_box)

func show_prompt(text: String, usable: bool, progress: float) -> void:
	_box.visible = true
	_label.text = ("[F]  " + text) if usable else text
	_label.add_theme_color_override("font_color", USABLE if usable else BLOCKED)
	_bar.visible = usable and progress > 0.0
	_bar.value = progress * 100.0

func hide_prompt() -> void:
	_box.visible = false
	_bar.value = 0
