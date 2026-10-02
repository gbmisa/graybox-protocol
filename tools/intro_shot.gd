extends SceneTree
## Photographs every scene of the opening (ScreenIntro), mid-movement, into
## screenshots/intro_<n>.png.
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/intro_shot.gd
func _initialize() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run(main as GrayboxGame)

func _run(game: GrayboxGame) -> void:
	for i in 30:
		await process_frame
	game.screens.show_intro()
	var intro := game.screens.get_children().filter(func(c): return c is ScreenIntro)[0] as ScreenIntro
	for n in ScreenIntro.SCENES.size():
		for i in 150:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://screenshots/intro_%d.png" % n))
		intro._scene = n + 1
		if intro._scene < ScreenIntro.SCENES.size():
			intro._play_scene()
	quit()
