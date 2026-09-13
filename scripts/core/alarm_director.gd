class_name AlarmDirector
extends Node
## The consequence spine's runtime: one global alarm meter (0-100) per
## mission, the runner it sends for the alarm panels at full, and the slow
## decay when the player goes quiet.
##
## Lockdown is NOT instant anymore. When the meter hits 100, the nearest
## ALERT guard is assigned as the RUNNER: it breaks off and moves for the
## nearest alarm panel, and only a panel activation trips LOCKDOWN (klaxon,
## the target relocates to the safe room, two bodyguards post there, four
## reinforcements arrive at map-edge posts). Kill or stop the runner first
## and the meter just sits at 100 — no lockdown, no relocation, no extra
## guards. Going loud stays costly; it is telegraphed now (shout radius,
## marked panels, an interceptable runner) instead of a surprise.
##
## Decay ticks in _physics_process so headless tests can count physics frames
## deterministically (idle frames run unthrottled headless).

var game: GrayboxGame = null
var alarm: float = 0.0
var lockdown: bool = false
## The guard currently running for an alarm panel, if any.
var runner: Guard = null
## Latched once the meter first passes the reveal threshold: the panel
## beacons light up and the HUD marks them.
var panels_revealed: bool = false
var _quiet: float = 0.0

func setup(p_game: GrayboxGame) -> void:
	game = p_game

## Raise the meter. Resets the decay clock; at the reveal threshold the
## panels are marked; at the top a runner is assigned — never instant
## lockdown.
func raise_alarm(amount: float) -> void:
	if amount <= 0.0:
		return
	if game != null and not game.is_playing():
		return
	var cd := ConsequenceData.alarm()
	alarm = minf(float(cd["max"]), alarm + amount)
	_quiet = 0.0
	if not panels_revealed and alarm >= float(cd["panel_reveal_alarm"]):
		_reveal_panels()
	if alarm >= float(cd["max"]) and not lockdown:
		_assign_runner()

## Lockdown heat for the HUD and any heat-scaled behaviour: 1 at the klaxon,
## bleeding off with the meter. Zero before lockdown ever trips.
func heat() -> float:
	if not lockdown:
		return 0.0
	return alarm / float(ConsequenceData.alarm()["max"])

func _physics_process(delta: float) -> void:
	if game == null or not game.is_playing():
		return
	# A maxed meter with no lockdown is a standoff, not a decay: it sits at
	# 100 until a runner trips a panel (or the mission resets).
	if alarm >= float(ConsequenceData.alarm()["max"]) and not lockdown:
		return
	var cd := ConsequenceData.alarm()
	_quiet += delta
	if _quiet >= float(cd["decay_delay"]) and alarm > 0.0:
		alarm = maxf(0.0, alarm - float(cd["decay_per_sec"]) * delta)

# -------------------------------------------------------------- panels ---
func _reveal_panels() -> void:
	panels_revealed = true
	if game == null:
		return
	for p in game.panels:
		(p as AlarmPanel).set_revealed()
	game.hud.show_message("ALARM PANELS MARKED — STOP THE RUNNER!", 5.0)
	game.hud.add_killfeed("Alarm panels marked — intercept the runner")

# -------------------------------------------------------------- runner ---
## The living ALERT guard nearest to its nearest panel becomes the runner.
## Nobody alert means nobody runs: the meter sits at 100, no lockdown.
func _assign_runner() -> void:
	if runner != null and is_instance_valid(runner) and runner.alive:
		return
	runner = null
	var best: Guard = null
	var best_panel: AlarmPanel = null
	var best_d := INF
	for g in game.guards:
		var gd := g as Guard
		if gd == null or not gd.alive or gd.state != Guard.State.ALERT:
			continue
		var panel := _nearest_panel(gd.global_position)
		if panel == null:
			continue
		var d := gd.global_position.distance_to(panel.global_position)
		if d < best_d:
			best_d = d
			best = gd
			best_panel = panel
	if best == null or best_panel == null:
		return
	runner = best
	best.start_run(best_panel)
	game.hud.show_message("RUNNER — a guard is going for an alarm panel!", 5.0)
	game.hud.add_killfeed("Runner! Stop them before they reach a panel")

func _nearest_panel(pos: Vector3) -> AlarmPanel:
	var best: AlarmPanel = null
	var best_d := INF
	for p in game.panels:
		var panel := p as AlarmPanel
		if panel == null or panel.activated:
			continue
		var d := pos.distance_to(panel.global_position)
		if d < best_d:
			best_d = d
			best = panel
	return best

## The runner went down. Promote the next alert guard while the meter is
## still maxed; otherwise the standoff holds at 100 with no lockdown.
func on_runner_down(g: Guard) -> void:
	if runner != g:
		return
	runner = null
	if not lockdown and alarm >= float(ConsequenceData.alarm()["max"]):
		_assign_runner()

# ------------------------------------------------------------ lockdown ---
## Called by AlarmPanel.activate(). One-way: the klaxon sounds, the target
## abandons patrol for the level's safe room, two bodyguards post there and
## four reinforcements arrive at map-edge posts. The meter keeps decaying,
## but the target never walks back — going loud is permanent for the rest
## of the mission.
func trigger_lockdown() -> void:
	if lockdown:
		return
	lockdown = true
	if runner != null and is_instance_valid(runner):
		runner.clear_run()
	runner = null
	var room := SafeRoomData.get_safe_room(game.selected_level)
	game.start_klaxon()
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
