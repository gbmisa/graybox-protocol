class_name HudReticle
extends HudPanel
## Screen-centre feedback: the crosshair, the hitmarker that confirms damage,
## and the red vignette that fires when the player is hit.

const HITMARKER_FADE := 0.2
const VIGNETTE_FADE := 2.5
const VIGNETTE_PEAK := 0.45

var _crosshair: ColorRect
var _hitmarker: Label
var _vignette: ColorRect

var _hit_alpha: float = 0.0
var _vignette_alpha: float = 0.0

func build(root: Control) -> void:
	# Vignette goes in first so it draws behind the crosshair.
	_vignette = ColorRect.new()
	_vignette.color = Color(0.8, 0.0, 0.0, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	ignore(_vignette)
	root.add_child(_vignette)
	_crosshair = ColorRect.new()
	_crosshair.color = Color.WHITE
	_crosshair.custom_minimum_size = Vector2(6, 6)
	_crosshair.size = Vector2(6, 6)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-3, -3)
	ignore(_crosshair)
	root.add_child(_crosshair)
	_hitmarker = make_label("✕", 36, RED, HORIZONTAL_ALIGNMENT_CENTER)
	_hitmarker.set_anchors_preset(Control.PRESET_CENTER)
	_hitmarker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hitmarker.position = Vector2(0, -18)
	_hitmarker.modulate.a = 0.0
	root.add_child(_hitmarker)

func tick(delta: float) -> void:
	if _hit_alpha > 0.0:
		_hit_alpha = maxf(0.0, _hit_alpha - delta / HITMARKER_FADE)
		_hitmarker.modulate.a = _hit_alpha
	if _vignette_alpha > 0.0:
		_vignette_alpha = maxf(0.0, _vignette_alpha - VIGNETTE_FADE * delta)
		_vignette.color.a = _vignette_alpha

func show_hitmarker() -> void:
	_hit_alpha = 1.0
	_hitmarker.modulate.a = 1.0

func flash_damage() -> void:
	_vignette_alpha = VIGNETTE_PEAK
