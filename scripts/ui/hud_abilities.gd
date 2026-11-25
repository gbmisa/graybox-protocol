class_name HudAbilities
extends HudPanel
## Ability list, bottom-left above the vitals — bottom-right is where the
## viewmodel's hand and pistol are.
##
## The text comes from the kit's own `hud_lines()`, already formatted with live
## cooldowns, so this panel never branches on which character is loaded and
## adding an operative needs no HUD change at all.

var _box: VBoxContainer
var _labels: Array[Label] = []
## r8: the controls are a crib sheet for the first HELP_TIME seconds of a
## mission, then only while F1 is toggled on. A kit whose first line is its
## weapon (the Regular) has that line drawn big by HudAmmo instead.
const HELP_TIME := 20.0
var _t: float = 0.0
var _help: bool = false

func build(root: Control) -> void:
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 4)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.position = Vector2(18, -112)
	ignore(_box)
	root.add_child(_box)

func _lines() -> Array:
	var lines: Array = player().kit.hud_lines()
	if player().kit.get("weapons") != null and not lines.is_empty():
		lines = lines.slice(1)
	return lines

func on_player_changed() -> void:
	_t = 0.0
	for l in _labels:
		l.queue_free()
	_labels.clear()
	var p := player()
	if p == null:
		return
	for line in _lines():
		var l := make_label(String(line), 14, Color(1, 1, 1, 0.75),
			HORIZONTAL_ALIGNMENT_LEFT)
		_box.add_child(l)
		_labels.append(l)

func tick(delta: float) -> void:
	if not hud.is_live():
		return
	_t += delta
	if Input.is_action_just_pressed("hud_help"):
		_help = not _help
	_box.visible = _help or _t < HELP_TIME
	var lines: Array = _lines()
	# Rebuild only if the kit changed shape; otherwise just refresh the text.
	if lines.size() != _labels.size():
		on_player_changed()
		return
	for i in range(lines.size()):
		_labels[i].text = String(lines[i])
