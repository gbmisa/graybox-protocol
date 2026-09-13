class_name ScreenBase
extends Node
## Base for a single menu screen. Each subclass builds its own content into a
## full-rect root that the Screens router shows one at a time.
##
## Screens that depend on live state (the armor highlight, the win stats)
## rebuild in `refresh()` rather than caching widgets.

const BG := Color(0.04, 0.05, 0.08, 0.92)
const GOLD := Color(1.0, 0.84, 0.37)
const INFO := Color(0.5, 0.83, 1.0)
const SELECTED := Color(0.6, 1.0, 0.6)

var screens: Screens
var root: Control
var center: CenterContainer

func setup(p_screens: Screens) -> void:
	screens = p_screens
	root = Control.new()
	root.name = get_script().resource_path.get_file().get_basename()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	screens.add_child(root)
	root.visible = false
	build()

## Build static content once. Screens with live content leave this empty and
## do their work in refresh().
func build() -> void:
	pass

## Called every time the screen is shown.
func refresh() -> void:
	pass

func game() -> GrayboxGame:
	return screens.game

# --------------------------------------------------------------- widgets ---
func column(separation: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", separation)
	return v

func row(separation: int = 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", separation)
	return h

func text(content: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = content
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func wrapped(content: String, size: int, width: float,
		color: Color = Color.WHITE) -> Label:
	var l := text(content, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l

func button(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(240, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(callback)
	return b

func card(label: String, size: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = size
	b.pressed.connect(callback)
	return b

func clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
