class_name GrayboxGame
extends Node3D
## Mission orchestrator. Spawns the level, player and guards, routes world
## events between them, and tracks the run's stats.
##
## A level's builder returns its data dict; optional keys let a level add
## behaviour without this file naming it: "mission" (a node with on_alarm /
## on_calm hooks), "barks", "objective", "extract_objective", "radio".
##
## Screen state lives in MissionFlow; the show_*/resume/restart methods here
## are thin forwards so the UI has one object to talk to.

var flow: MissionFlow
var hud: HUD
var screens: Screens

var selected_char: String = "regular"
var selected_armor: String = "none"
var selected_mod: String = LoadoutData.DEFAULT
var selected_level: String = Levels.DEFAULT_ID

var player: Player = null
var guards: Array = []
var civilians: Array = []
var target: Target = null
var level_root: Node3D = null
var level_data: Dictionary = {}
var mission: Node = null
var alert: AlertState
var tiers: LightTiers = LightTiers.new()

var objective_stage: int = 1      # 1 = assassinate, 2 = extract
var stats: Dictionary = {"kills": 0, "alarms": 0, "detected": 0}
var mission_start_msec: int = 0
var no_guards: bool = false
const STATION_REACH := 50.0
var backdrop: MenuBackdrop = null
var atmosphere: Atmosphere

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	no_guards = "--no-guards" in OS.get_cmdline_args()
	Settings.apply()
	InputActions.register()
	screens = Screens.new()
	add_child(screens)
	screens.setup(self)
	hud = HUD.new()
	add_child(hud)
	hud.visible = false
	alert = AlertState.new()
	add_child(alert)
	alert.setup(self)
	atmosphere = Atmosphere.new()
	add_child(atmosphere)
	flow = MissionFlow.new()
	add_child(flow)
	flow.setup(self)
	flow.show_title()

func _unhandled_input(event: InputEvent) -> void:
	flow.handle_pause(event)

# ---------------------------------------------------------------- mission ---
func clear_mission() -> void:
	atmosphere.clear()
	if level_root != null and is_instance_valid(level_root):
		level_root.queue_free()
	level_root = null
	level_data = {}
	mission = null
	player = null
	guards = []
	civilians = []
	target = null
	hud.visible = false

func spawn_mission() -> void:
	clear_mission()
	tiers = LightTiers.new()
	alert.reset()
	stats = {"kills": 0, "alarms": 0, "detected": 0}
	var data: Dictionary = Levels.builder_for(selected_level).build(self)
	level_data = data
	level_root = data["level_root"] as Node3D
	mission = data.get("mission", null) as Node
	GuardNav.bake(level_root)
	_spawn_player(data["player_spawn"] as Vector3)
	if not no_guards:
		_spawn_guards(data["guard_posts"] as Array)
	for post in data.get("civilians", []) as Array:
		spawn_civilian(post)
	mission_start_msec = Time.get_ticks_msec()
	objective_stage = 1
	atmosphere.setup(self)
	hud.setup(self, player)
	hud.visible = true
	hud.set_objective(String(data.get("objective", "ASSASSINATE THE TARGET")))
	hud.show_message("INFILTRATE %s" % Levels.NAMES[selected_level], 3.0)

func _spawn_player(spawn: Vector3) -> void:
	player = Player.new()
	level_root.add_child(player)
	player.setup(selected_char, ArmorData.get_armor(selected_armor), self)
	player.position = spawn
	player.died.connect(_on_player_died)

func _spawn_guards(posts: Array) -> void:
	for post in posts:
		spawn_guard(post)

## One guard from a post dict: waypoints, plus optional facing / waits /
## one_way (see Guard.setup). Public so a mission can call in reinforcements.
func spawn_guard(post: Dictionary) -> Guard:
	var g := Guard.new()
	level_root.add_child(g)
	g.setup(post["waypoints"] as Array, self, post)
	guards.append(g)
	return g

## One bystander from a post dict: {"waypoints": [...], "seed": int}.
func spawn_civilian(post: Dictionary) -> Civilian:
	var c := Civilian.new()
	level_root.add_child(c)
	c.setup(post["waypoints"] as Array, self, int(post.get("seed", 0)))
	civilians.append(c)
	return c

## Everyone within `radius` of `pos` who is not already running starts.
func panic_civilians(pos: Vector3, radius: float) -> void:
	for c in civilians:
		var cv := c as Civilian
		if cv != null and cv.alive and cv.global_position.distance_to(pos) <= radius:
			cv.panic(pos)

func on_civilian_killed(c: Civilian) -> void:
	civilians.erase(c)
	stats["civilians"] = int(stats.get("civilians", 0)) + 1
	hud.add_killfeed("Bystander down")

func is_playing() -> bool:
	return flow.is_playing()

func get_player() -> Player:
	return player

func tier_at(pos: Vector3) -> String:
	return tiers.tier_at(pos)

func note_seen() -> void:
	alert.note_seen()

func barks(kind: String) -> Array:
	return (level_data.get("barks", {}) as Dictionary).get(kind, []) as Array

# ----------------------------------------------------------------- events ---
## Anything loud. Guards inside the radius investigate the source.
func emit_noise(pos: Vector3, radius: float) -> void:
	if not is_playing():
		return
	panic_civilians(pos, radius)
	for g in guards:
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= radius:
			gd.hear_noise(pos)
	alert.on_noise(pos, radius)

func shake_camera(amount: float) -> void:
	if player != null and player.alive:
		player.add_shake(amount)

## A guard has gone ALERT. That is NOT the alarm: he has to get to an alarm
## station and press it (`GuardBrain`), and can be killed on the way. A level
## with no stations (MERIDIAN) keeps the old rule — alert means alarm.
func guard_alerted(g: Guard) -> void:
	if not is_playing() or alert.is_alarm():
		return
	if get_tree().get_nodes_in_group("alarm_station").is_empty():
		alert.raise("CONTACT")
		return
	g.alarm_run = true

## The closest station on `from`'s floor within reach, or null. A guard walks
## straight lines, so a station a floor away or far off is no use to him.
func nearest_station(from: Vector3) -> AlarmStation:
	var best: AlarmStation = null
	var best_d := STATION_REACH
	for n in get_tree().get_nodes_in_group("alarm_station"):
		var st := n as AlarmStation
		if absf(st.global_position.y - from.y) > 2.5:
			continue
		var d := st.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = st
	return best

func on_guard_killed(g: Guard) -> void:
	stats["kills"] = int(stats["kills"]) + 1
	guards.erase(g)
	hud.add_killfeed("Guard eliminated")
	_witness_death(g)

## A guard who can see a colleague drop notices: he goes to the body, with his
## detection meter nearly full, so one glimpse of you finishes it. (A guard
## once died in front of another who carried on patrolling.) Needs a clear
## line to the body; one looking away only notices it close by.
const WITNESS_RANGE := 24.0
const WITNESS_BEHIND := 6.0

func _witness_death(dead: Guard) -> void:
	var body := dead.global_position + Vector3(0, 1.2, 0)
	for o in guards:
		var w := o as Guard
		if w == null or not w.alive or w.state == Guard.State.ALERT:
			continue
		var to := dead.global_position - w.global_position
		var d := to.length()
		if d > WITNESS_RANGE:
			continue
		var fwd := -w.global_transform.basis.z
		to.y = 0.0
		if to.length() > 0.01 and fwd.dot(to.normalized()) < -0.2 and d > WITNESS_BEHIND:
			continue
		if not w.ray(w.global_position + Vector3(0, 1.4, 0), body,
				[dead.get_rid()]).is_empty():
			continue
		w.witness_death(dead.global_position)

func on_target_killed() -> void:
	if not is_playing():
		return
	objective_stage = 2
	hud.set_objective(String(level_data.get("extract_objective",
		"TARGET ELIMINATED — REACH AN EXTRACTION POINT")))
	hud.add_killfeed("Target eliminated")
	hud.show_message("TARGET DOWN — EXTRACT", 3.0)
	AudioSynth.play(self, "hit")

func on_extraction_entered(zone_name: String) -> void:
	if not is_playing() or objective_stage != 2:
		return
	var c := CharData.get_char(selected_char)
	flow.win({
		"kills": int(stats["kills"]),
		"alarms": int(stats["alarms"]),
		"secondary": String(stats.get("secondary", "")),
		"detected": int(stats.get("detected", 0)),
		"time_sec": (Time.get_ticks_msec() - mission_start_msec) / 1000.0,
		"char_name": c["name"],
		"armor_name": ArmorData.get_armor(selected_armor)["name"],
		"mod_name": String(LoadoutData.get_mod(selected_mod)["name"]) \
			if c.has("mods") else "",
		"zone": zone_name,
		"radio": String((level_data.get("radio", {}) as Dictionary).get(zone_name, "")),
	})

func _on_player_died() -> void:
	if not is_playing():
		return
	flow.lose()

# ------------------------------------------------------- flow forwarding ---
func show_title() -> void:
	flow.show_title()

func show_select() -> void:
	flow.show_select()

func select_char(id: String) -> void:
	flow.select_char(id)

func set_armor(id: String) -> void:
	flow.set_armor(id)

func set_mod(id: String) -> void:
	flow.set_mod(id)

func deploy() -> void:
	flow.deploy()

func resume() -> void:
	flow.resume()

func restart_mission() -> void:
	flow.restart_mission()

func quit_to_select() -> void:
	flow.quit_to_select()

func quit_to_title() -> void:
	flow.quit_to_title()

## The live level behind the menus. Skipped headless (tests) and with
## `-- --no-backdrop`, where it would only cost load time.
func set_backdrop(on: bool) -> void:
	if on and backdrop == null:
		var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
		if DisplayServer.get_name() == "headless" or "--no-backdrop" in args:
			return
		backdrop = MenuBackdrop.new()
		add_child(backdrop)
		backdrop.build(screens)
	elif not on and backdrop != null:
		backdrop.queue_free()
		backdrop = null
