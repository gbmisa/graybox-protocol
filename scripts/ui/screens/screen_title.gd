class_name ScreenTitle
extends ScreenBase
## Main menu. Sits over the live MenuBackdrop: a dark wash down the left for
## the menu column, the logo, the entries, and the estate's consent score
## crawling along the bottom like a news ticker.

const TICKER := "HOLLOWAY ROAD COLLECTIVE CONSENT SCORE  412 ▼ 3   ·   BIN COLLECTION SUSPENDED: EAST OF THE RING ROAD   ·   Q3 GRATITUDE AUDIT TONIGHT 21:00 — ATTENDANCE IS ITS OWN REWARD   ·   NON-CONSENTING INDIVIDUALS: REPORT, DO NOT ENGAGE (ENGAGEMENT IS SCORED)   ·   YOUR LIGHT IS PROVIDED BY A PARTNERSHIP   ·   "
const TICKER_SPEED := 60.0
const VERSION := "PROTOTYPE · BUILD 0.4 · HOLLOWAY ROAD"

var _ticker: Label
var _ticker_x: float = 0.0

func backdrop_color() -> Color:
	return Color(0, 0, 0, 0)

func build() -> void:
	center.visible = false
	_wash()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = 84
	col.offset_top = 120
	col.offset_right = 600
	root.add_child(col)
	col.add_child(title("GRAYBOX", 76, UiTheme.INK))
	col.add_child(title("PROTOCOL", 76, UiTheme.AMBER))
	var tag := text("one operative. every way in. one target.", 18, UiTheme.DIM)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	col.add_child(menu_entry("NEW GAME", _new_game))
	col.add_child(menu_entry("OPENING", func() -> void:
		screens.click()
		screens.show_intro()
	))
	col.add_child(menu_entry("MISSIONS", func() -> void:
		screens.click()
		screens.show_missions()
	))
	col.add_child(menu_entry("OPTIONS", func() -> void:
		screens.click()
		screens.show_options("title")
	))
	col.add_child(menu_entry("CREDITS", func() -> void:
		screens.click()
		screens.show_credits()
	))
	col.add_child(menu_entry("QUIT", func() -> void:
		screens.click()
		get_tree().quit()
	))
	_footer()

## Straight into level one: the mission the build is about.
func _new_game() -> void:
	screens.click()
	game().selected_level = "compound"
	game().show_select()

## Dark down the left, clear on the right where the backdrop shows.
func _wash() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.025, 0.04, 0.94))
	g.set_color(1, Color(0.02, 0.025, 0.04, 0.0))
	g.add_point(0.45, Color(0.02, 0.025, 0.04, 0.78))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var wash := TextureRect.new()
	wash.texture = tex
	wash.stretch_mode = TextureRect.STRETCH_SCALE
	wash.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	wash.offset_right = 900
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)

func _footer() -> void:
	var band := ColorRect.new()
	band.color = Color(0.0, 0.0, 0.0, 0.7)
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -34
	band.clip_contents = true
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	_ticker = text(TICKER + TICKER, 15, UiTheme.AMBER)
	_ticker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ticker.position = Vector2(0, 7)
	band.add_child(_ticker)
	var ver := text(VERSION, 12, UiTheme.DIM)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.position = Vector2(-20, -62)
	root.add_child(ver)

func _process(delta: float) -> void:
	if _ticker == null or not root.visible:
		return
	_ticker_x -= TICKER_SPEED * delta
	var half := _ticker.size.x * 0.5
	if half > 0.0 and -_ticker_x >= half:
		_ticker_x += half
	_ticker.position.x = _ticker_x
