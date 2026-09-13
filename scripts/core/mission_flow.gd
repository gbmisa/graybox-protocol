class_name MissionFlow
extends Node
## Screen state machine: title -> select -> briefing -> playing -> pause / end.
##
## Owns which screen is up and the mouse-capture and pause side effects of each
## transition. Spawning and teardown live on GrayboxGame; this only says when.

enum State { TITLE, SELECT, BRIEFING, PLAYING, PAUSED, WIN, LOSE }

var game: GrayboxGame
var state: int = State.TITLE

func setup(p_game: GrayboxGame) -> void:
	game = p_game

func is_playing() -> bool:
	return state == State.PLAYING

func handle_pause(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if state == State.PLAYING:
		pause()
	elif state == State.PAUSED:
		resume()

# ------------------------------------------------------------ pre-mission ---
func show_title() -> void:
	game.clear_mission()
	_transition(State.TITLE, false)
	game.screens.show_title()

func show_select() -> void:
	game.clear_mission()
	_transition(State.SELECT, false)
	game.screens.show_select()

func select_char(id: String) -> void:
	game.selected_char = id
	game.screens.click()
	_transition(State.BRIEFING, false)
	game.screens.show_briefing()

func set_armor(id: String) -> void:
	game.selected_armor = id
	game.screens.click()
	game.screens.show_briefing()

func deploy() -> void:
	game.screens.click()
	start_mission()

# --------------------------------------------------------------- in-play ---
func start_mission() -> void:
	get_tree().paused = false
	game.spawn_mission()
	game.screens.hide_all()
	_transition(State.PLAYING, true)

func pause() -> void:
	_transition(State.PAUSED, false)
	get_tree().paused = true
	game.screens.show_pause()

func resume() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	_transition(State.PLAYING, true)
	game.screens.hide_all()

func restart_mission() -> void:
	start_mission()

func quit_to_select() -> void:
	get_tree().paused = false
	show_select()

# ------------------------------------------------------------------- end ---
func win(stats: Dictionary) -> void:
	_transition(State.WIN, false)
	AudioSynth.play(game, "win")
	game.screens.show_win(stats)

func lose() -> void:
	_transition(State.LOSE, false)
	AudioSynth.play(game, "lose")
	await get_tree().create_timer(1.2).timeout
	game.screens.show_lose()

func _transition(next: int, capture_mouse: bool) -> void:
	state = next
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture_mouse \
		else Input.MOUSE_MODE_VISIBLE
