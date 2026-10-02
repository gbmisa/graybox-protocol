class_name ScreenOptions
extends ScreenBase
## OPTIONS, reachable from the main menu and the pause menu; BACK returns
## to whichever opened it. Every control writes straight through Settings,
## which saves and applies at once — there is no "apply" button to forget.

## [key, label, min, max, step, format] for sliders.
const SLIDERS := [
	["master_volume", "MASTER VOLUME", 0.0, 1.0, 0.05, "%d%%"],
	["sensitivity", "MOUSE SENSITIVITY", 0.25, 3.0, 0.05, "%.2fx"],
	["fov", "FIELD OF VIEW", 60.0, 110.0, 1.0, "%d°"],
]
## [key, label] for toggles.
const TOGGLES := [
	["invert_y", "INVERT MOUSE Y"],
	["head_bob", "WEAPON BOB"],
	["trip_fx", "TRIP FILTER"],
	["fullscreen", "FULLSCREEN"],
	["vsync", "VSYNC"],
	["room_tags", "ROOM ID TAGS (PLAYTEST — NEXT MISSION)"],
]

var from: String = "title"

func backdrop_color() -> Color:
	return Color(0.02, 0.025, 0.04, 0.86)

func refresh() -> void:
	clear(center)
	var v := column(10)
	center.add_child(v)
	v.add_child(title("OPTIONS", 44))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for s in SLIDERS:
		_slider(grid, s)
	for t in TOGGLES:
		_toggle(grid, String(t[0]), String(t[1]))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	v.add_child(gap)
	v.add_child(button("BACK", func() -> void:
		AudioSynth.play(screens, "back", -6.0)
		if from == "pause":
			screens.show_pause()
		else:
			screens.show_title()
	))

func _slider(grid: GridContainer, s: Array) -> void:
	var key := String(s[0])
	var name_l := text(String(s[1]), 18)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	grid.add_child(name_l)
	var sl := HSlider.new()
	sl.min_value = float(s[2])
	sl.max_value = float(s[3])
	sl.step = float(s[4])
	sl.value = float(Settings.get_value(key))
	sl.custom_minimum_size = Vector2(300, 24)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(sl)
	var val := text("", 18, UiTheme.AMBER)
	val.custom_minimum_size = Vector2(80, 0)
	grid.add_child(val)
	var show := func(x: float) -> void:
		val.text = String(s[5]) % (x * 100.0 if key == "master_volume" else x)
	show.call(sl.value)
	sl.value_changed.connect(func(x: float) -> void:
		show.call(x)
		Settings.set_value(key, x)
		_live(key, x)
	)
	sl.drag_ended.connect(func(_changed: bool) -> void:
		AudioSynth.play(screens, "click", -10.0)
	)

func _toggle(grid: GridContainer, key: String, label: String) -> void:
	var name_l := text(label, 18)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	grid.add_child(name_l)
	var cb := CheckButton.new()
	cb.button_pressed = bool(Settings.get_value(key))
	cb.toggled.connect(func(on: bool) -> void:
		AudioSynth.play(screens, "click", -8.0)
		Settings.set_value(key, on)
	)
	_hover_sound(cb)
	grid.add_child(cb)
	grid.add_child(Control.new())

## Options that touch a live mission take effect without a restart.
func _live(key: String, x: float) -> void:
	var p := game().player if game() != null else null
	if p == null:
		return
	if key == "fov":
		p.camera.fov = x
