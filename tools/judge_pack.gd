extends SceneTree
## The fixed evidence pack for the r8 review agents: the real game (HUD,
## viewmodel, post filter), guards frozen so nothing interrupts, a dozen
## views across HOLLOWAY ROAD with a different weapon in hand, plus the
## title screen. Small (960x540) on purpose — a judge reads every one.
##
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/judge_pack.gd
##
## Writes screenshots/judge/*.png.

const OUT_DIR := "res://screenshots/judge"
## name, position, yaw (deg), pitch (deg), weapon
const VIEWS := [
	["01_spawn_bus_stop", Vector3(0, 0.1, 190), 0.0, 4.0, "pistol"],
	["02_estate_yard", Vector3(-6, 0.1, 160), 0.0, 0.0, "smg"],
	["03_subway_mouth", Vector3(0, 0.1, 146), 0.0, 0.0, "pistol"],
	["04_towpath", Vector3(-20, 0.1, 104), -25.0, 0.0, "shotgun"],
	["05_alley_reveal", Vector3(0, 0.1, 66), 0.0, 8.0, "rifle"],
	["06_south_road", Vector3(4, 0.1, 44), 0.0, 6.0, "grenade"],
	["07_courtyard", Vector3(-6, 0.1, 18), 0.0, 0.0, "shotgun"],
	["08_consent_way", Vector3(0, 0.1, -42), 0.0, 4.0, "smg"],
	["09_tower_site", Vector3(26, 0.1, -48), 180.0, 18.0, "pistol"],
	["10_annex_hall", Vector3(0, 0.1, -80), 0.0, 0.0, "pistol"],
]

var _game: GrayboxGame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_game = (load("res://scenes/main.tscn") as PackedScene).instantiate() as GrayboxGame
	root.add_child(_game)
	_run()

func _snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, label]))

func _run() -> void:
	for i in 60:
		await process_frame
	await _snap("00_title")
	_game.selected_char = "regular"
	_game.selected_level = "compound"
	_game.flow.start_mission()
	for i in 20:
		await physics_frame
	for g in _game.guards:
		(g as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var p := _game.get_player()
	var w: PlayerWeapons = p.kit.get("weapons")
	for id in ["smg", "shotgun", "rifle", "grenade"]:
		w.give(id, 2)
	for v in VIEWS:
		p.global_position = v[1]
		p.velocity = Vector3.ZERO
		p.rotation = Vector3(0, deg_to_rad(float(v[2])), 0)
		p.camera.rotation = Vector3(deg_to_rad(float(v[3])), 0, 0)
		w.select(String(v[4]))
		for i in 45:
			await physics_frame
		p.health.hp = p.health.max_hp
		await _snap(String(v[0]))
	print("wrote %d judge shots" % (VIEWS.size() + 1))
	quit()
