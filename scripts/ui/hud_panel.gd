class_name HudPanel
extends Node
## Base for the HUD's panels. Each panel builds its own controls into the
## shared root and ticks itself; none of them know about the others.
##
## Every control goes through `ignore()` — the HUD sits over a captured-mouse
## first-person view and must never eat input.

const GOLD := Color(1.0, 0.84, 0.37)
const RED := Color(1.0, 0.25, 0.25)
const DIM := Color(0.62, 0.64, 0.68)

var hud: HUD
static var _font: Font

func setup(p_hud: HUD, root: Control) -> void:
	hud = p_hud
	build(root)

## Subclasses create their controls here.
func build(_root: Control) -> void:
	pass

func tick(_delta: float) -> void:
	pass

## Called whenever the mission spawns a new player.
func on_player_changed() -> void:
	pass

func ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func make_label(text: String, size: int, color: Color = Color.WHITE,
		align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	# r8: the HUD wears the menu's display face, with a hard shadow so it
	# reads over neon and night alike.
	# Small text stays in the plain default face: the display face's K/Q/R
	# misread below ~22px (review: "V HICK", "D GRAPPLE").
	if size >= 22:
		if _font == null:
			_font = load(UiTheme.FONT_BODY) as Font
		l.add_theme_font_override("font", _font)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return ignore(l) as Label

func make_bar(width: float, height: float, fill: Color = Color(1.0, 0.22, 0.12)) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, height)
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.03, 0.05, 0.85)
	bg.border_color = Color(0, 0, 0, 0.9)
	bg.set_border_width_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return ignore(b) as ProgressBar

func player() -> Player:
	return hud.player
