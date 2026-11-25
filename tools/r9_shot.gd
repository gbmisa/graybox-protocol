extends SceneTree
## r9's visible fixes, photographed in the real game: night vision off/on in
## a PITCH space (the subway under the ring road) and out on the dark avenue,
## the rifle's scope from the billboard scaffold, and the billboard-top cache
## seen from the catwalk.
##
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/r9_shot.gd
##
## Writes screenshots/r9_*.png.

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
		ProjectSettings.globalize_path("%s/r9_%s.png" % [OUT_DIR, label]))

func _wait(n: int) -> void:
	for i in n:
		await physics_frame

func _tap(action: String) -> void:
	Input.action_press(action)
	await _wait(2)
	Input.action_release(action)

func _place(p: Player, at: Vector3, yaw: float, pitch: float) -> void:
	p.global_position = at
	p.velocity = Vector3.ZERO
	p.rotation.y = deg_to_rad(yaw)
	p.camera.rotation.x = deg_to_rad(pitch)

func _run(game: GrayboxGame) -> void:
	await _wait(30)
	game.selected_level = "compound"
	game.flow.start_mission()
	await _wait(20)
	var p := game.player
	p.health.hp = 1.0e6
	for g in game.guards:
		(g as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for spot in [["subway", Vector3(0, 0.1, 134), 0.0, 0.0], ["avenue", Vector3(0, 0.1, -36), 0.0, 2.0]]:
		_place(p, spot[1], spot[2], spot[3])
		await _wait(40)
		await _snap("nv_off_%s" % spot[0])
		await _tap("night_vision")
		await _wait(40)
		await _snap("nv_on_%s" % spot[0])
		await _tap("night_vision")
		await _wait(30)
	var w: PlayerWeapons = p.kit.get("weapons")
	w.give("rifle")
	_place(p, Vector3(12.6, 7.5, 31), 0.0, -8.0)
	await _wait(40)
	Input.action_press("alt_attack")
	await _wait(40)
	await _snap("scope")
	Input.action_release("alt_attack")
	_place(p, Vector3(-11, 13.6, 27.8), 180.0, 55.0)
	await _wait(40)
	await _snap("billboard_top_from_catwalk")
	_place(p, Vector3(-11, 24.4, 28.6), 0.0, -10.0)
	await _wait(40)
	await _snap("billboard_top")
	_place(p, Vector3(-4, 0.1, 186), 90.0, 40.0)
	await _wait(40)
	await _snap("tower_from_street")
	quit()
