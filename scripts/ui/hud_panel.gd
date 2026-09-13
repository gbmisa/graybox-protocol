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
	return ignore(l) as Label

func make_bar(width: float, height: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, height)
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	return ignore(b) as ProgressBar

func player() -> Player:
	return hud.player
