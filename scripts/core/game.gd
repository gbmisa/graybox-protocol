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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	no_guards = "--no-guards" in OS.get_cmdline_args()
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
	flow = MissionFlow.new()
	add_child(flow)
	flow.setup(self)
	flow.show_title()

func _unhandled_input(event: InputEvent) -> void:
	flow.handle_pause(event)

# ---------------------------------------------------------------- mission ---
func clear_mission() -> void:
	if level_root != null and is_instance_valid(level_root):
		level_root.queue_free()
	level_root = null
	level_data = {}
	mission = null
	player = null
	guards = []
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
	_spawn_player(data["player_spawn"] as Vector3)
	if not no_guards:
		_spawn_guards(data["guard_posts"] as Array)
	mission_start_msec = Time.get_ticks_msec()
	objective_stage = 1
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
	for g in guards:
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= radius:
			gd.hear_noise(pos)
	alert.on_noise(pos, radius)

func shake_camera(amount: float) -> void:
	if player != null and player.alive:
		player.add_shake(amount)

## A guard has gone ALERT. The building-wide consequence is AlertState's.
func alarm() -> void:
	if not is_playing():
		return
	alert.raise("CONTACT")

func on_guard_killed(g: Guard) -> void:
	stats["kills"] = int(stats["kills"]) + 1
	guards.erase(g)
	hud.add_killfeed("Guard eliminated")

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
