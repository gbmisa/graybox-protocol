class_name GrayboxGame
extends Node3D
## Mission orchestrator. Spawns the level, player and guards, routes world
## events between them, and tracks the run's stats.
##
## Screen state lives in MissionFlow; the show_*/resume/restart methods here
## are thin forwards so the UI has one object to talk to.

var flow: MissionFlow
var hud: HUD
var screens: Screens

var selected_char: String = "regular"
var selected_armor: String = "none"
## 1 = MERIDIAN CAPITAL, 2 = PORT VESPER.
var selected_level: int = 1

var player: Player = null
var guards: Array = []
var target: Target = null
var level_root: Node3D = null

var objective_stage: int = 1      # 1 = assassinate, 2 = extract
var stats: Dictionary = {"kills": 0, "alarms": 0}
var mission_start_msec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputActions.register()
	screens = Screens.new()
	add_child(screens)
	screens.setup(self)
	hud = HUD.new()
	add_child(hud)
	hud.visible = false
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
	player = null
	guards = []
	target = null
	hud.visible = false

func spawn_mission() -> void:
	clear_mission()
	var data := LevelBuilder.build(self)
	level_root = data["level_root"] as Node3D
	_spawn_player(_resolve_spawn(data))
	_spawn_guards(data["guard_posts"] as Array)
	stats = {"kills": 0, "alarms": 0}
	mission_start_msec = Time.get_ticks_msec()
	objective_stage = 1
	hud.setup(self, player)
	hud.visible = true
	hud.set_objective("ASSASSINATE THE TARGET")
	hud.show_message(str(LevelData.get_level(selected_level)["infiltrate"]), 3.0)

## Per-operative spawns: {"pos": Vector3, "yaw": float}. Falls back to the
## legacy single player_spawn (yaw 0) when a level does not define them.
## Yaw 0 faces -z; every spawn faces its vector so the player never starts
## staring at a wall.
func _resolve_spawn(data: Dictionary) -> Dictionary:
	var fallback := {"pos": data["player_spawn"] as Vector3, "yaw": 0.0}
	var per: Dictionary = data.get("player_spawns", {})
	return per.get(selected_char, fallback)

func _spawn_player(spawn: Dictionary) -> void:
	player = Player.new()
	level_root.add_child(player)
	player.setup(selected_char, ArmorData.get_armor(selected_armor), self)
	player.position = spawn["pos"] as Vector3
	player.rotation.y = float(spawn["yaw"])
	player.died.connect(_on_player_died)

func _spawn_guards(posts: Array) -> void:
	for post in posts:
		var g := Guard.new()
		level_root.add_child(g)
		g.setup(post["waypoints"] as Array, self)
		guards.append(g)

func is_playing() -> bool:
	return flow.is_playing()

func get_player() -> Player:
	return player

# ----------------------------------------------------------------- events ---
## Anything loud. Guards inside the radius investigate the source.
func emit_noise(pos: Vector3, radius: float) -> void:
	if not is_playing():
		return
	for g in guards:
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= radius:
			gd.hear_noise(pos)

func shake_camera(amount: float) -> void:
	if player != null and player.alive:
		player.add_shake(amount)

func alarm() -> void:
	if not is_playing():
		return
	stats["alarms"] = int(stats["alarms"]) + 1
	hud.add_killfeed("ALARM — guards alerted")

func on_guard_killed(g: Guard) -> void:
	stats["kills"] = int(stats["kills"]) + 1
	guards.erase(g)
	hud.add_killfeed("Guard eliminated")

func on_target_killed() -> void:
	if not is_playing():
		return
	objective_stage = 2
	hud.set_objective("TARGET ELIMINATED — REACH AN EXTRACTION POINT")
	hud.add_killfeed("Target eliminated")
	hud.show_message("TARGET DOWN — EXTRACT", 3.0)
	AudioSynth.play(self, "hit")

func on_extraction_entered(zone_name: String) -> void:
	if not is_playing() or objective_stage != 2:
		return
	flow.win({
		"kills": int(stats["kills"]),
		"alarms": int(stats["alarms"]),
		"time_sec": (Time.get_ticks_msec() - mission_start_msec) / 1000.0,
		"char_name": CharData.get_char(selected_char)["name"],
		"armor_name": ArmorData.get_armor(selected_armor)["name"],
		"zone": zone_name,
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

func select_level(id: int) -> void:
	flow.select_level(id)

func set_armor(id: String) -> void:
	flow.set_armor(id)

func deploy() -> void:
	flow.deploy()

func resume() -> void:
	flow.resume()

func restart_mission() -> void:
	flow.restart_mission()

func quit_to_select() -> void:
	flow.quit_to_select()
