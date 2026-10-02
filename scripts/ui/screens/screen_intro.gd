class_name ScreenIntro
extends ScreenBase
## THE OPENING — a visual-novel cold open, drawn in 2D from shapes (first
## pass; Gregory iterates on it). The Regular on his couch in a VR helmet,
## the ads that finally break him, the street outside. Click / Space / Enter
## advances, ESC skips back to the menu.
##
## Each scene is a builder that draws into `_stage` and returns its lines;
## `_cam` slowly pans and pushes in on every scene so nothing sits still.

const W := 1280.0
const H := 720.0

var _stage: Control
var _cam: Control
var _box: Label
var _who: Label
var _scene := 0
var _lines: Array = []
var _line := 0
var _tw: Tween

func backdrop_color() -> Color:
	return Color.BLACK

func build() -> void:
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.clip_contents = true
	root.add_child(_stage)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.78)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -150
	root.add_child(panel)
	_who = text("", 18, UiTheme.AMBER)
	_who.position = Vector2(60, 14)
	panel.add_child(_who)
	_box = text("", 22, Color(0.92, 0.92, 0.9))
	_box.position = Vector2(60, 42)
	_box.size = Vector2(1100, 90)
	_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_box)
	var hint := text("CLICK / SPACE — NEXT     ESC — SKIP", 12, UiTheme.DIM)
	hint.position = Vector2(W - 330, 124)
	panel.add_child(hint)

func refresh() -> void:
	_scene = 0
	_play_scene()

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
		_advance()

func _advance() -> void:
	if _box.visible_ratio < 1.0:
		_box.visible_ratio = 1.0
		return
	_line += 1
	if _line < _lines.size():
		_say()
		return
	_scene += 1
	if _scene >= SCENES.size():
		screens.show_title()
		return
	_play_scene()

const SCENES := ["_apartment", "_ad_hotdog", "_ad_lips", "_street", "_title"]

func _play_scene() -> void:
	for c in _stage.get_children():
		c.queue_free()
	_cam = Control.new()
	_cam.size = Vector2(W, H)
	_cam.pivot_offset = Vector2(W, H) * 0.5
	_stage.add_child(_cam)
	_lines = call(SCENES[_scene])
	_line = 0
	if _tw != null:
		_tw.kill()
	_tw = _cam.create_tween()
	_tw.tween_property(_cam, "scale", Vector2.ONE * 1.08, 14.0).from(Vector2.ONE)
	_tw.parallel().tween_property(_cam, "position", Vector2(-30, -12), 14.0).from(Vector2.ZERO)
	_say()

func _say() -> void:
	var l: Array = _lines[_line]
	_who.text = String(l[0])
	_box.text = String(l[1])
	_box.visible_ratio = 0.0
	var tw := _box.create_tween()
	tw.tween_property(_box, "visible_ratio", 1.0, 0.025 * String(l[1]).length())

# ----------------------------------------------------------------- scenes ---
func _apartment() -> Array:
	_rect(Vector2.ZERO, Vector2(W, H), Color(0.08, 0.05, 0.13))
	_rect(Vector2(760, 90), Vector2(380, 260), Color(0.04, 0.03, 0.1))       # window
	for i in 9:
		_rect(Vector2(780 + i * 40, 350 - (i * 37 % 150) - 60), Vector2(28, 200), Color(0.15, 0.18, 0.4))
	var glow := _rect(Vector2(120, 260), Vector2(300, 190), Color(0.3, 0.9, 1.0, 0.25))  # TV wash
	_pulse(glow, 0.12, 0.35, 0.4)
	_rect(Vector2(380, 470), Vector2(520, 120), Color(0.35, 0.12, 0.2))       # couch
	_rect(Vector2(560, 330), Vector2(120, 170), Color(0.25, 0.25, 0.3))        # body
	_circle(Vector2(620, 300), 46, Color(0.75, 0.6, 0.5))                      # head
	var helmet := _rect(Vector2(570, 270), Vector2(100, 50), Color(0.1, 1.0, 0.9))
	_pulse(helmet, 0.6, 1.0, 0.7)
	_rect(Vector2(470, 560), Vector2(70, 26), Color(0.9, 0.85, 0.2))           # takeaway box
	return [["", "HOLLOWAY ROAD. 23:40."],
		["YOU", "Same flat. Same couch. Same helmet. The world outside gets worse every week and I pay a subscription to watch it happen."],
		["YOU", "Fine. One episode. Then sleep."]]

func _ad_hotdog() -> Array:
	_rect(Vector2.ZERO, Vector2(W, H), Color(1.0, 0.82, 0.1))
	_label("AD BREAK — VERIFY YOUR APPETITE", Vector2(0, 60), 40, Color(0.8, 0.1, 0.1))
	_label("PLACE THE FRANK IN YOUR MOUTH TO CONTINUE WATCHING", Vector2(0, 120), 22, Color(0.3, 0.05, 0.05))
	var dog := Control.new()
	dog.position = Vector2(470, 260)
	_cam.add_child(dog)
	_rect(Vector2(0, 30), Vector2(340, 70), Color(0.85, 0.55, 0.25), dog)     # bun
	_rect(Vector2(-20, 20), Vector2(380, 40), Color(0.75, 0.2, 0.15), dog)    # sausage
	_rect(Vector2(20, 26), Vector2(300, 8), Color(0.95, 0.85, 0.1), dog)      # mustard
	var tw := dog.create_tween().set_loops()
	tw.tween_property(dog, "position:y", 230.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(dog, "position:y", 270.0, 0.4).set_trans(Tween.TRANS_SINE)
	_rect(Vector2(340, 440), Vector2(600, 30), Color(0.3, 0.05, 0.05))
	var bar := _rect(Vector2(344, 444), Vector2(10, 22), Color(0.1, 0.8, 0.2))
	bar.create_tween().tween_property(bar, "size:x", 380.0, 6.0)
	_label("CHEWING DETECTED", Vector2(0, 480), 18, Color(0.3, 0.05, 0.05))
	return [["ADVERT", "Hungry for content? Prove it! Our Partner Frank™ unlocks your show the moment your lips close."],
		["YOU", "They want me to put a hot dog in my mouth. On camera. To unlock the rest of a cooking show. About hot dogs."],
		["YOU", "...I did it. I'm not proud. The helmet said I chewed with \"low enthusiasm.\" Minus two."]]

func _ad_lips() -> Array:
	_rect(Vector2.ZERO, Vector2(W, H), Color(0.55, 0.05, 0.35))
	var lips := Control.new()
	lips.position = Vector2(640, 330)
	lips.pivot_offset = Vector2.ZERO
	_cam.add_child(lips)
	_ellipse(Vector2(0, -24), Vector2(170, 50), Color(0.95, 0.1, 0.3), lips)
	_ellipse(Vector2(0, 30), Vector2(150, 55), Color(0.85, 0.05, 0.25), lips)
	_ellipse(Vector2(0, 2), Vector2(130, 8), Color(0.25, 0.0, 0.1), lips)
	var tw := lips.create_tween().set_loops()
	tw.tween_property(lips, "scale", Vector2(1.08, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lips, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	_label("HOT SINGLES IN YOUR CONSENT BRACKET", Vector2(0, 70), 38, Color(1.0, 0.85, 0.95))
	_label("they've seen your score. they're into it. ♥ 412", Vector2(0, 500), 22, Color(1.0, 0.7, 0.85))
	return [["ADVERT", "Hey you. Yeah, you on the couch. Your bank wants to get to know you better. Much better."],
		["YOU", "Every ad's a come-on now. The bank. The council. The bins. Even the bins are flirting with me."],
		["YOU", "No. No more. I'm taking it off."]]

func _street() -> Array:
	_rect(Vector2.ZERO, Vector2(W, H), Color(0.05, 0.03, 0.1))
	_rect(Vector2(0, 520), Vector2(W, 200), Color(0.12, 0.12, 0.15))          # road
	var ads := [["McGRATITUDE", "I'M SCORING IT"], ["THE McCONSENT", "NOW WITH 40% MORE TERMS"],
		["McGRATITUDE", "YOU'RE WELCOME. SAY THANK YOU."]]
	for i in ads.size():
		var x := 60 + i * 410
		var b := _rect(Vector2(x, 80 + (i % 2) * 40), Vector2(360, 200), Color(0.85, 0.1, 0.1))
		_circle(Vector2(x + 60, 180 + (i % 2) * 40), 40, Color(1.0, 0.8, 0.1))   # the smiling bun
		_label(String(ads[i][0]), Vector2(x + 210 - W * 0.5, 130 + (i % 2) * 40), 24, Color(1.0, 0.85, 0.1))
		_label(String(ads[i][1]), Vector2(x + 210 - W * 0.5, 175 + (i % 2) * 40), 14, Color(1, 1, 1))
		_pulse(b, 0.8, 1.0, 0.3 + i * 0.13)
		_rect(Vector2(x + 170, 280 + (i % 2) * 40), Vector2(16, 240), Color(0.2, 0.2, 0.25))
	# The courier: moped, delivery box, headset, three phones.
	var moped := Control.new()
	moped.position = Vector2(-300, 440)
	_cam.add_child(moped)
	_circle(Vector2(20, 90), 26, Color(0.1, 0.1, 0.1), moped)
	_circle(Vector2(170, 90), 26, Color(0.1, 0.1, 0.1), moped)
	_rect(Vector2(10, 50), Vector2(180, 30), Color(0.2, 0.7, 0.9), moped)
	_rect(Vector2(-10, -10), Vector2(70, 60), Color(0.95, 0.5, 0.1), moped)  # delivery box
	_rect(Vector2(80, -30), Vector2(60, 80), Color(0.3, 0.3, 0.6), moped)    # rider
	_circle(Vector2(110, -50), 26, Color(0.6, 0.45, 0.35), moped)
	_rect(Vector2(88, -58), Vector2(46, 6), Color(0.1, 0.1, 0.1), moped)     # headset band
	moped.create_tween().tween_property(moped, "position:x", 1500.0, 9.0)
	return [["YOU", "Outside. Three burger boards on one block, all of them grinning at me."],
		["COURIER", "— have you tried turning your score off and on again? Mm-hm. Hold please, I have a burrito for flat nine. — Sir? Still there?"],
		["YOU", "He's doing tech support for three apps at thirty miles an hour. Nobody pays him for any of it. Nobody pays anybody."],
		["YOU", "Somebody has to unplug the thing that's doing this. The Score lives on Holloway Road."]]

func _title() -> Array:
	_rect(Vector2.ZERO, Vector2(W, H), Color.BLACK)
	var t := _label("HOLLOWAY ROAD", Vector2(0, 280), 84, UiTheme.AMBER)
	t.modulate.a = 0.0
	t.create_tween().tween_property(t, "modulate:a", 1.0, 2.0)
	_label("THE SCORE IS WATCHING", Vector2(0, 390), 22, Color(0.7, 1.0, 0.3))
	return [["", "Level one. Get there however you get there."]]

# ---------------------------------------------------------------- drawing ---
func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node = null) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else _cam).add_child(r)
	return r

func _ellipse(c: Vector2, radii: Vector2, color: Color, parent: Node = null) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	p.polygon = pts
	p.color = color
	(parent if parent != null else _cam).add_child(p)
	return p

func _circle(c: Vector2, r: float, color: Color, parent: Node = null) -> Polygon2D:
	return _ellipse(c, Vector2(r, r), color, parent)

func _label(s: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := text(s, size, color)
	l.size = Vector2(W, size * 1.4)
	l.position = pos
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cam.add_child(l)
	return l

## Alpha breathing between `lo` and `hi`, `period` seconds a half-cycle.
func _pulse(c: CanvasItem, lo: float, hi: float, period: float) -> void:
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "modulate:a", lo, period)
	tw.tween_property(c, "modulate:a", hi, period)
