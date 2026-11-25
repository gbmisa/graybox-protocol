class_name ScreenIntro
extends ScreenBase
## THE OPENING — comic pages in the manner of Postal 4's intro (r7): slanted
## panels with thick ink borders on a cream page, sliding in one after
## another, each slowly pushing in on its art, with a narration box and the
## odd sound word. The words and pictures are IntroScript's; this only plays
## them. Click / Space / Enter: next page (or finish the current one). ESC
## skips to the menu.

const W := 1280.0
const H := 720.0
const PAPER := Color(0.93, 0.89, 0.79)
const INK := Color(0.06, 0.05, 0.06)
const MARGIN := 26.0
const GUTTER := 20.0
const SLANT := 70.0
const STAGGER := 0.7

var _page_root: Control
var _page := 0
var _live: Array = []         # [polygon, bbox, tex size, focus, push, t0]
var _t := 0.0
var _done_at := 0.0
var _paper_tex: ImageTexture

func backdrop_color() -> Color:
	return PAPER

func build() -> void:
	_paper_tex = _paper_noise()
	var grain := TextureRect.new()
	grain.texture = _paper_tex
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grain)
	_page_root = Control.new()
	_page_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_page_root)
	var hint := text("CLICK — NEXT     ESC — SKIP", 11, Color(0.3, 0.27, 0.22))
	hint.position = Vector2(W - 230, H - 20)
	root.add_child(hint)

func refresh() -> void:
	_page = 0
	_show_page()

func _input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		screens.show_title()
		return
	var next: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if next:
		get_viewport().set_input_as_handled()
		_next()

func _next() -> void:
	_page += 1
	if _page >= IntroScript.PAGES.size():
		screens.show_title()
		return
	_show_page()

func _process(delta: float) -> void:
	if not root.visible:
		return
	_t += delta
	for p in _live:
		_frame_art(p)
	if _done_at > 0.0 and _t > _done_at:
		_done_at = 0.0
		_next()

# ------------------------------------------------------------------ pages ---
func _show_page() -> void:
	for c in _page_root.get_children():
		c.queue_free()
	_live.clear()
	_t = 0.0
	var page: Dictionary = IntroScript.PAGES[_page]
	var panels: Array = page["panels"]
	var shapes := _layout(String(page["layout"]), panels.size())
	for i in panels.size():
		_panel(panels[i], shapes[i], i * STAGGER)
	_done_at = panels.size() * STAGGER + 2.5 + float(page.get("hold", 3.0))

## Panel outlines for a layout, in page pixels: Postal's leaning dividers.
func _layout(kind: String, n: int) -> Array:
	var out: Array = []
	var top := MARGIN
	var bot := H - MARGIN - 18.0
	match kind:
		"splash":
			out.append(PackedVector2Array([Vector2(MARGIN, top), Vector2(W - MARGIN, top),
				Vector2(W - MARGIN, bot), Vector2(MARGIN, bot)]))
		"stack":
			var mid := (top + bot) * 0.5
			out.append(PackedVector2Array([Vector2(MARGIN, top), Vector2(W - MARGIN, top),
				Vector2(W - MARGIN, mid - GUTTER * 0.5 - 20), Vector2(MARGIN, mid - GUTTER * 0.5 + 20)]))
			out.append(PackedVector2Array([Vector2(MARGIN, mid + GUTTER * 0.5 + 20),
				Vector2(W - MARGIN, mid + GUTTER * 0.5 - 20), Vector2(W - MARGIN, bot), Vector2(MARGIN, bot)]))
		_:
			var w := (W - MARGIN * 2.0 - GUTTER * (n - 1)) / n
			for i in n:
				var x0 := MARGIN + i * (w + GUTTER)
				var x1 := x0 + w
				# Interior edges lean; the page's outer edges stay square.
				var l_top := x0 + (SLANT * 0.5 if i > 0 else 0.0)
				var l_bot := x0 - (SLANT * 0.5 if i > 0 else 0.0)
				var r_top := x1 + (SLANT * 0.5 if i < n - 1 else 0.0)
				var r_bot := x1 - (SLANT * 0.5 if i < n - 1 else 0.0)
				out.append(PackedVector2Array([Vector2(l_top, top), Vector2(r_top, top),
					Vector2(r_bot, bot), Vector2(l_bot, bot)]))
	return out

func _panel(spec: Dictionary, shape: PackedVector2Array, delay: float) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.modulate.a = 0.0
	_page_root.add_child(holder)
	var bbox := Rect2(shape[0], Vector2.ZERO)
	for v in shape:
		bbox = bbox.expand(v)
	var poly := Polygon2D.new()
	poly.polygon = shape
	var tex := load(IntroScript.ART % String(spec["art"])) as Texture2D
	if tex == null:
		poly.color = Color(0.2, 0.2, 0.25)
	else:
		poly.texture = tex
	holder.add_child(poly)
	var border := Line2D.new()
	border.points = shape
	border.closed = true
	border.width = 7.0
	border.default_color = INK
	border.joint_mode = Line2D.LINE_JOINT_SHARP
	holder.add_child(border)
	if tex != null:
		_live.append([poly, bbox, tex.get_size(), spec.get("focus", Vector2(0.5, 0.5)),
			float(spec.get("push", 0.12)), delay])
		_frame_art(_live[-1])
	var cap := String(spec.get("caption", ""))
	if cap != "":
		_caption(holder, cap, bbox, shape)
	var sfx := String(spec.get("sfx", ""))
	if sfx != "":
		_sfx(holder, sfx, bbox, delay)
	# In: slide along the lean from below, ink first.
	holder.position = Vector2(-SLANT * 0.3, 60)
	var tw := holder.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(holder, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(holder, "position", Vector2.ZERO, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioSynth.play(game(), "click", -14.0)

## The art's window onto its image: the largest crop of the panel's shape
## around `focus`, creeping in by `push` over ~10s.
func _frame_art(p: Array) -> void:
	var poly: Polygon2D = p[0]
	var bbox: Rect2 = p[1]
	var ts: Vector2 = p[2]
	var focus: Vector2 = p[3]
	var k := clampf((_t - float(p[5])) / 10.0, 0.0, 1.0)
	var aspect := bbox.size.x / bbox.size.y
	var cw := minf(ts.x, ts.y * aspect)
	var crop := Vector2(cw, cw / aspect) * (1.0 - float(p[4]) * k)
	var c := Vector2(clampf(focus.x * ts.x, crop.x * 0.5, ts.x - crop.x * 0.5),
		clampf(focus.y * ts.y, crop.y * 0.5, ts.y - crop.y * 0.5))
	var uv := PackedVector2Array()
	for v in poly.polygon:
		var f := (v - bbox.position) / bbox.size
		uv.append(c - crop * 0.5 + f * crop)
	poly.uv = uv

func _caption(holder: Control, text_s: String, bbox: Rect2, shape: PackedVector2Array) -> void:
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.93, 0.62)
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.set_content_margin_all(8)
	box.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text_s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", INK)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_font_override("font", load("res://assets/fonts/Kenney Future Narrow.ttf") as Font)
	box.add_child(l)
	# Fits inside the panel's top edge (the lean eats into the bottom).
	var w := minf(shape[1].x - shape[0].x - 32.0, 420.0)
	box.custom_minimum_size = Vector2(w, 0)
	l.custom_minimum_size = Vector2(w - 16, 0)
	# Top-left corner of the panel, inside its lean.
	box.position = Vector2(shape[0].x + 14.0, bbox.position.y + 14.0)
	holder.add_child(box)

func _sfx(holder: Control, word: String, bbox: Rect2, delay: float) -> void:
	var l := Label.new()
	l.text = word
	l.add_theme_font_override("font", load("res://assets/fonts/Kenney Future.ttf") as Font)
	l.add_theme_font_size_override("font_size", clampi(int(bbox.size.x / (word.length() * 0.9)), 40, 74))
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 16)
	l.position = bbox.position + bbox.size * Vector2(0.12, 0.66)
	l.rotation = -0.2
	l.pivot_offset = Vector2(80, 40)
	l.scale = Vector2.ZERO
	holder.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(delay + 0.9)
	tw.tween_property(l, "scale", Vector2.ONE * 1.15, 0.12)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1)

## Faint paper grain, tiled over the page.
func _paper_noise() -> ImageTexture:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for y in 256:
		for x in 256:
			var v := rng.randf()
			img.set_pixel(x, y, Color(0.35, 0.28, 0.18, v * 0.07))
	return ImageTexture.create_from_image(img)
