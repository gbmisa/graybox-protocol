class_name HudSubtitle
extends HudPanel
## The campus tannoy, as a subtitle: low on the screen, tagged with who is
## speaking, typed out as it's "said", chime first. The PA used to share the
## gold centre-message style with objectives and read as game instructions
## nobody had explained — this makes it plainly the building talking.

const TYPE_RATE := 38.0     # characters per second
const HOLD := 3.5           # seconds the full line stays up

var _box: PanelContainer
var _speaker: Label
var _line: Label
var _full: String = ""
var _shown: float = 0.0
var _hold: float = 0.0

func build(root: Control) -> void:
	_box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.05, 0.78)
	sb.border_color = Color(1.0, 0.72, 0.25, 0.9)
	sb.border_width_left = 3
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	_box.add_theme_stylebox_override("panel", sb)
	_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.position.y = -150
	ignore(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	ignore(v)
	_box.add_child(v)
	_speaker = make_label("", 12, Color(1.0, 0.72, 0.25))
	v.add_child(_speaker)
	_line = make_label("", 19, Color(0.95, 0.95, 0.92))
	v.add_child(_line)
	_box.visible = false
	root.add_child(_box)

## `speaker` names the source ("PUBLIC ADDRESS — HOLLOWAY CAMPUS").
func say(speaker: String, text: String) -> void:
	_speaker.text = "◢ " + speaker
	_full = text
	_shown = 0.0
	_hold = HOLD
	_line.text = ""
	_box.visible = true
	AudioSynth.play(hud, "pa_chime", -8.0)

func tick(delta: float) -> void:
	if not _box.visible:
		return
	if _shown < float(_full.length()):
		_shown += TYPE_RATE * delta
		_line.text = _full.substr(0, int(_shown))
		return
	_hold -= delta
	if _hold <= 0.0:
		_box.visible = false

func on_player_changed() -> void:
	_box.visible = false
