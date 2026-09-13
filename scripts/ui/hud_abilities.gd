class_name HudAbilities
extends HudPanel
## Bottom-right ability list.
##
## The text comes from the kit's own `hud_lines()`, already formatted with live
## cooldowns, so this panel never branches on which character is loaded and
## adding an operative needs no HUD change at all.

var _box: VBoxContainer
var _labels: Array[Label] = []

func build(root: Control) -> void:
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 4)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_box.position = Vector2(-280, -110)
	ignore(_box)
	root.add_child(_box)

func on_player_changed() -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()
	var p := player()
	if p == null:
		return
	for line in p.kit.hud_lines():
		var l := make_label(String(line), 16, Color.WHITE,
			HORIZONTAL_ALIGNMENT_RIGHT)
		_box.add_child(l)
		_labels.append(l)

func tick(_delta: float) -> void:
	if not hud.is_live():
		return
	var lines: Array = player().kit.hud_lines()
	# Rebuild only if the kit changed shape; otherwise just refresh the text.
	if lines.size() != _labels.size():
		on_player_changed()
		return
	for i in range(lines.size()):
		_labels[i].text = String(lines[i])
