class_name AlarmDirector
extends Node
## The consequence spine's runtime: one global alarm meter (0-100) per
## mission, the lockdown it triggers at full, and the slow decay when the
## player goes quiet.
##
## Lockdown is a one-way door. When the meter hits 100: the klaxon sounds,
## the target abandons patrol for the level's safe room, two bodyguards post
## there and four reinforcements arrive at map-edge posts. The meter then
## keeps decaying, but the target never walks back — going loud is permanent
## for the rest of the mission.
##
## Decay ticks in _physics_process so headless tests can count physics frames
## deterministically (idle frames run unthrottled headless).

var game: GrayboxGame = null
var alarm: float = 0.0
var lockdown: bool = false
var _quiet: float = 0.0

func setup(p_game: GrayboxGame) -> void:
	game = p_game

## Raise the meter. Resets the decay clock; trips lockdown at the top.
func raise_alarm(amount: float) -> void:
	if amount <= 0.0:
		return
	if game != null and not game.is_playing():
		return
	var cd := ConsequenceData.alarm()
	alarm = minf(float(cd["max"]), alarm + amount)
	_quiet = 0.0
	if alarm >= float(cd["max"]) and not lockdown:
		_trigger_lockdown()

## Lockdown heat for the HUD and any heat-scaled behaviour: 1 at the klaxon,
## bleeding off with the meter. Zero before lockdown ever trips.
func heat() -> float:
	if not lockdown:
		return 0.0
	return alarm / float(ConsequenceData.alarm()["max"])

func _physics_process(delta: float) -> void:
	if game == null or not game.is_playing():
		return
	var cd := ConsequenceData.alarm()
	_quiet += delta
	if _quiet >= float(cd["decay_delay"]) and alarm > 0.0:
		alarm = maxf(0.0, alarm - float(cd["decay_per_sec"]) * delta)

# -------------------------------------------------------------- lockdown ---
func _trigger_lockdown() -> void:
	lockdown = true
	var room := SafeRoomData.get_safe_room(game.selected_level)
	AudioSynth.play(game, "klaxon")
	var line := "The %s has relocated under guard." \
		% String(room["target_name"])
	game.hud.show_message("LOCKDOWN — " + line, 6.0)
	game.hud.add_killfeed("LOCKDOWN — reinforcements inbound")
	if is_instance_valid(game.target) and game.target.alive:
		game.target.relocate_to(room["pos"] as Vector3)
	_spawn_forces(room)

func _spawn_forces(room: Dictionary) -> void:
	var n := 0
	for post in room["bodyguard_posts"] as Array:
		_spawn_guard(post as Array)
		n += 1
	for post in room["reinforce_posts"] as Array:
		_spawn_guard(post as Array)
		n += 1
	print("LOCKDOWN: %d extra guards posted" % n)

func _spawn_guard(post: Array) -> void:
	var g := Guard.new()
	game.level_root.add_child(g)
	g.setup(post, game)
	game.guards.append(g)
