class_name HudScope
extends HudPanel
## r9 (Gregory: "add a three times zoom through the scope for the rifle"):
## aimed with a weapon that has a `scope` (WeaponData), the gun drops out of
## view (PlayerViewmodel.scoped) and you look through this: a black mask with
## a round eyepiece, posts and a fine cross, at the scope's magnification
## (WeaponData.zoom_for). The crosshair dot hides meanwhile (HudReticle).

var _draw_node: Control

func build(root: Control) -> void:
	_draw_node = ignore(Control.new())
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.draw.connect(_draw_scope)
	_draw_node.visible = false
	root.add_child(_draw_node)

func tick(_delta: float) -> void:
	var on := is_scoped(hud)
	if on != _draw_node.visible:
		_draw_node.visible = on
	if on:
		_draw_node.queue_redraw()

static func is_scoped(h: HUD) -> bool:
	return h.is_live() and h.player.viewmodel != null and h.player.viewmodel.scoped()

func _draw_scope() -> void:
	var size := _draw_node.size
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.46
	var ink := Color(0.0, 0.0, 0.0, 1.0)
	# The mask: everything outside the eyepiece, as four bands and a thick ring.
	_draw_node.draw_rect(Rect2(0, 0, c.x - r, size.y), ink)
	_draw_node.draw_rect(Rect2(c.x + r, 0, size.x - c.x - r, size.y), ink)
	_draw_node.draw_rect(Rect2(c.x - r, 0, r * 2.0, c.y - r), ink)
	_draw_node.draw_rect(Rect2(c.x - r, c.y + r, r * 2.0, size.y - c.y - r), ink)
	_draw_node.draw_arc(c, r * 1.2, 0.0, TAU, 96, ink, r * 0.42, true)
	# Posts from three sides up to the fine cross, and the cross itself.
	var gap := r * 0.18
	var post := maxf(4.0, r * 0.025)
	_draw_node.draw_line(Vector2(c.x - r, c.y), Vector2(c.x - gap, c.y), ink, post)
	_draw_node.draw_line(Vector2(c.x + gap, c.y), Vector2(c.x + r, c.y), ink, post)
	_draw_node.draw_line(Vector2(c.x, c.y + gap), Vector2(c.x, c.y + r), ink, post)
	_draw_node.draw_line(Vector2(c.x - gap, c.y), Vector2(c.x + gap, c.y), ink, 1.5)
	_draw_node.draw_line(Vector2(c.x, c.y - r), Vector2(c.x, c.y + gap), ink, 1.5)
	# Drop marks under the centre, in the reticle's red.
	for i in range(1, 4):
		_draw_node.draw_circle(Vector2(c.x, c.y + gap * 0.25 * i), 2.0, Color(0.9, 0.1, 0.1))
	_draw_node.draw_circle(c, 1.6, Color(0.9, 0.1, 0.1))
