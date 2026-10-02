class_name UiTheme
extends RefCounted
## The menus' look, built once in code: Kenney Future (CC0) for headings and
## buttons, the engine's own face for anything you read as a paragraph (the
## squared display face is unreadable at length), flat council-navy panels,
## amber for the thing under your cursor. Every menu screen's root carries
## this theme, so a Button needs no styling of its own.

const AMBER := Color(1.0, 0.72, 0.25)
const INK := Color(0.92, 0.93, 0.95)
const DIM := Color(0.55, 0.58, 0.64)
const NAVY := Color(0.04, 0.05, 0.09, 0.92)
const RED := Color(0.95, 0.22, 0.18)

const FONT_HEAD := "res://assets/fonts/Kenney Future.ttf"
const FONT_BODY := "res://assets/fonts/Kenney Future Narrow.ttf"

static var _theme: Theme = null

static func head_font() -> Font:
	return load(FONT_HEAD) as Font

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	var narrow := load(FONT_BODY) as Font
	if narrow != null:
		t.set_font("font", "Button", narrow)
		t.set_font("font", "CheckButton", narrow)
	_buttons(t)
	_sliders(t)
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _flat(NAVY, Color(1, 1, 1, 0.08), 1))
	_theme = t
	return t

static func _buttons(t: Theme) -> void:
	var clear := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	clear.content_margin_left = 14
	clear.content_margin_right = 14
	var hover := _flat(Color(1.0, 0.72, 0.25, 0.10), AMBER, 0)
	hover.border_width_left = 4
	hover.content_margin_left = 18
	hover.content_margin_right = 14
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(1.0, 0.72, 0.25, 0.22)
	for type in ["Button", "CheckButton"]:
		t.set_stylebox("normal", type, clear)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("focus", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("disabled", type, clear)
		t.set_color("font_color", type, INK)
		t.set_color("font_hover_color", type, AMBER)
		t.set_color("font_focus_color", type, AMBER)
		t.set_color("font_pressed_color", type, AMBER)
		t.set_color("font_hover_pressed_color", type, AMBER)
		t.set_color("font_disabled_color", type, DIM)
	# A switch that is on is not a switch being hovered.
	t.set_stylebox("pressed", "CheckButton", clear)
	t.set_stylebox("hover_pressed", "CheckButton", hover)

static func _sliders(t: Theme) -> void:
	var track := _flat(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := _flat(AMBER, Color(0, 0, 0, 0), 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)

static func _flat(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s
