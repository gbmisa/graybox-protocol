extends SceneTree
## Photographs the trip zones (SecTrip) from inside, in the real game: the
## player stands in each, waits for the faces to come in, looks one way, then
## turns. Writes screenshots/trip_<zone>_<n>.png.
##
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/trip_shot.gd

const OUT_DIR := "res://screenshots"
## [name, position, yaw degrees (0 = north)]
const SPOTS := [
	["subway", Vector3(0, 0.1, 128), 0.0],
	["canal", Vector3(4, -2.4, 96), 90.0],
	["undercroft", Vector3(-20.5, -2.9, -18), 180.0],
	["pit", Vector3(28, -2.9, -66), 0.0],
	["server", Vector3(0, 4.1, -86), 0.0],
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run(main as GrayboxGame)

func _snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("%s/trip_%s.png" % [OUT_DIR, label]))

func _run(game: GrayboxGame) -> void:
	for i in 30:
		await process_frame
	game.no_guards = true
	game.selected_char = "regular"
	game.selected_level = "compound"
	game.flow.start_mission()
	for i in 10:
		await physics_frame
	var p := game.player
	p.health.hp = 1.0e9
	for s in SPOTS:
		p.global_position = s[1]
		p.velocity = Vector3.ZERO
		p.rotation.y = deg_to_rad(float(s[2]))
		for i in 300:
			await physics_frame
		await _snap("%s_0" % s[0])
		p.rotation.y += deg_to_rad(110)
		for i in 150:
			await physics_frame
		await _snap("%s_1" % s[0])
	quit()
