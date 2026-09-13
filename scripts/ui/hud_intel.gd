class_name HudIntel
extends HudPanel
## The reading panel for IntelPickup notes: a centered card with the note's
## title and body. The game keeps running underneath; F closes the panel.
## The interactor hides its prompt and demands a fresh press while open.

var _panel: PanelContainer
var _title: Label
var _body: Label
var _open: bool = false

func build(root: Control) -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.10, 0.96)
	style.border_color = Color(0.55, 0.85, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)
	_title = make_label("TITLE", 20, Color(0.55, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(_title)
	var tag := make_label("OPTIONAL INTEL — NEVER AN OBJECTIVE", 11, DIM,
		HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(tag)
	_body = make_label("", 15)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(480, 0)
	vbox.add_child(_body)
	var hint := make_label("CLOSE [F]", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(hint)
	_panel.visible = false
	ignore(_panel)
	root.add_child(_panel)

func show_intel(id: String) -> void:
	_title.text = IntelData.title(id)
	_body.text = IntelData.body(id)
	_panel.visible = true
	_open = true
	AudioSynth.play(hud, "click")

func is_open() -> bool:
	return _open

func hide_panel() -> void:
	_panel.visible = false
	_open = false

func _input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("interact") and not event.is_echo():
		hide_panel()
		get_viewport().set_input_as_handled()
