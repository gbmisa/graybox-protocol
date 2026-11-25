class_name HudAmmo
extends HudPanel
## Bottom-right corner (r8): the weapon in hand and its rounds, big — MAG over
## a small /RESERVE — like every shooter. Hidden for kits with no arsenal.
## Goes red when the mag is empty, reads RELOADING while it refills.

var _box: VBoxContainer
var _name: Label
var _mag: Label
var _state: Label

func build(root: Control) -> void:
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.position = Vector2(-18, -18)
	_box.add_theme_constant_override("separation", 0)
	ignore(_box)
	_state = make_label("", 14, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_name = make_label("", 15, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_RIGHT)
	_mag = make_label("", 40, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	for l in [_state, _name, _mag]:
		_box.add_child(l)
	root.add_child(_box)

func tick(_delta: float) -> void:
	var p := player()
	var w: PlayerWeapons = p.kit.get("weapons") if p != null and hud.is_live() else null
	_box.visible = w != null
	if w == null:
		return
	var a: Dictionary = w.ammo[w.current]
	var wd := w.weapon()
	_name.text = String(wd["name"])
	_mag.text = "%d / %d" % [int(a["mag"]), int(a["reserve"])]
	_mag.add_theme_color_override("font_color",
		Color(1.0, 0.25, 0.2) if int(a["mag"]) == 0 else Color.WHITE)
	_state.text = "RELOADING" if w.reloading() else ""
