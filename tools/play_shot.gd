extends SceneTree
## Boots the real game into HOLLOWAY ROAD and photographs the player's own
## view — viewmodel, HUD and all — at rest and mid-recoil. Also shoots the
## title screen first.
##
##     xvfb-run -a godot --path . --rendering-method gl_compatibility \
##         --resolution 1280x720 --script res://tools/play_shot.gd [-- x y z yaw]
##
## Writes screenshots/play_*.png.

const OUT_DIR := "res://screenshots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run(main as GrayboxGame)

func _snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("%s/play_%s.png" % [OUT_DIR, label]))

func _run(game: GrayboxGame) -> void:
	for i in 60:
		await process_frame
	await _snap("title")
	game.screens.show_options("title")
	for i in 10:
		await process_frame
	await _snap("options")
	game.screens.show_credits()
	for i in 10:
		await process_frame
	await _snap("credits")
	game.screens.show_missions()
	for i in 10:
		await process_frame
	await _snap("missions")
	game.show_select()
	for i in 10:
		await process_frame
	await _snap("select")
	game.selected_level = "compound"
	game.flow.start_mission()
	for i in 10:
		await physics_frame
	var args := OS.get_cmdline_user_args()
	var p := game.player
	if args.size() >= 4:
		p.global_position = Vector3(float(args[0]), float(args[1]), float(args[2]))
		p.rotation.y = deg_to_rad(float(args[3]))
	for i in 20:
		await physics_frame
	await _snap("rest")
	# Aim down sights (right mouse), held for long enough to settle.
	Input.action_press("alt_attack")
	for i in 30:
		await physics_frame
	await _snap("ads")
	Input.action_release("alt_attack")
	for i in 30:
		await physics_frame
	# Light tiers: stand in the DARK courtyard corner, then a PITCH store.
	p.global_position = Vector3(-20, 0.1, 18)
	p.rotation.y = deg_to_rad(-90)
	for i in 90:
		await physics_frame
	await _snap("tier_dark")
	p.global_position = Vector3(0, 0.1, 6)
	p.rotation.y = deg_to_rad(180)
	for i in 90:
		await physics_frame
	await _snap("tier_lit")
	Engine.time_scale = 0.05   # slow the recovery so the kick is on camera
	p.kit.call("_fire_pistol")
	for i in 2:
		await physics_frame
	await _snap("kick")
	for i in 6:
		await physics_frame
	await _snap("kick2")
	Engine.time_scale = 1.0
	game.alert.raise("TEST")
	for i in 40:
		await physics_frame
	await _snap("alarm_a")
	for i in 20:
		await physics_frame
	await _snap("alarm_b")
	game.flow.pause()
	for i in 10:
		await process_frame
	await _snap("pause")
	quit()
