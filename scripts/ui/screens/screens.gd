class_name Screens
extends CanvasLayer
## Menu router. Owns one ScreenBase per screen and shows exactly one at a time.
##
## Runs with PROCESS_MODE_ALWAYS so the pause menu still works while the game
## tree is paused.

var game: GrayboxGame = null

var _screens: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register("title", ScreenTitle.new())
	_register("select", ScreenSelect.new())
	_register("briefing", ScreenBriefing.new())
	_register("pause", ScreenPause.new())
	var win := ScreenEnd.new()
	win.is_win = true
	_register("win", win)
	_register("lose", ScreenEnd.new())
	hide_all()

func setup(p_game: GrayboxGame) -> void:
	game = p_game

func _register(key: String, screen: ScreenBase) -> void:
	add_child(screen)
	screen.setup(self)
	_screens[key] = screen

func click() -> void:
	AudioSynth.play(self, "click")

# ------------------------------------------------------------ public API ---
func show_title() -> void:
	_show("title")

func show_select() -> void:
	_show("select")

func show_briefing() -> void:
	_show("briefing")

func show_pause() -> void:
	_show("pause")

func show_win(stats: Dictionary) -> void:
	(_screens["win"] as ScreenEnd).stats = stats
	_show("win")

func show_lose() -> void:
	_show("lose")

func hide_all() -> void:
	for key in _screens:
		(_screens[key] as ScreenBase).root.visible = false

func _show(key: String) -> void:
	var screen := _screens[key] as ScreenBase
	screen.refresh()
	hide_all()
	screen.root.visible = true
