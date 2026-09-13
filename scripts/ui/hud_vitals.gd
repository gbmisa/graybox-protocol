class_name HudVitals
extends HudPanel
## Bottom-left: health, the character's resource line, and the mana bar.
## The mana bar only exists for operatives that have mana, so the panel does
## not need to know which character is loaded beyond that one check.

var _hp_bar: ProgressBar
var _hp_label: Label
var _resource_label: Label
var _mana_bar: ProgressBar

func build(root: Control) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.position = Vector2(12, -78)
	ignore(box)
	_hp_label = make_label("HP", 14)
	box.add_child(_hp_label)
	_hp_bar = make_bar(200, 14)
	box.add_child(_hp_bar)
	_resource_label = make_label("", 12, DIM)
	box.add_child(_resource_label)
	_mana_bar = make_bar(200, 10)
	box.add_child(_mana_bar)
	root.add_child(box)

func on_player_changed() -> void:
	var p := player()
	if p == null:
		return
	var has_mana := p.max_mana > 0.0
	_mana_bar.visible = has_mana
	_resource_label.text = "MANA" if has_mana \
		else "ARMOR: %s" % String(p.armor.get("name", ""))

func tick(_delta: float) -> void:
	if not hud.is_live():
		return
	var p := player()
	_hp_bar.value = p.health.fraction() * 100.0
	_hp_label.text = "HP  %d / %d" % [int(p.hp()), int(p.max_hp())]
	# Flash the label while i-frames are up, so the dodge reads as having
	# actually done something.
	_hp_label.add_theme_color_override("font_color",
		Color(0.4, 0.9, 1.0) if p.health.is_invulnerable() else Color.WHITE)
	if p.max_mana > 0.0:
		_mana_bar.value = clampf(p.mana / p.max_mana * 100.0, 0.0, 100.0)
