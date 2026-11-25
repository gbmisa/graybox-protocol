extends SceneTree
## Photographs every page of the opening (ScreenIntro, IntroScript) once all
## its panels are in, into screenshots/intro_<n>.png.
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
	for n in IntroScript.PAGES.size():
		intro._page = n
		intro._show_page()
		for i in 200:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://screenshots/intro_%d.png" % n))
	quit()
