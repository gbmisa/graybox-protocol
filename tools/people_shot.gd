extends SceneTree
## A line-up of the level's people (Humanoid) on Consent Way under its
## floodlights: guards (one aiming), civilians, the target, one dead.
##
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/people_shot.gd
##
## Writes screenshots/people_*.png.

const OUT_DIR := "res://screenshots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var level := Node3D.new()
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var guard_style := {"skin": Color(0.62, 0.78, 0.38), "top": Color(0.75, 0.08, 0.14),
		"bottom": Color(0.10, 0.10, 0.22), "accent": Color(0.98, 0.85, 0.10),
		"visor": Color(0.1, 0.95, 1.0), "armed": true, "bulk": 1.15, "helmet": true, "hair": -1}
	var figs: Array = []
	for i in 7:
		var holder := Node3D.new()
		level.add_child(holder)
		holder.position = Vector3(-4.5 + i * 1.5, 0, -60)
		holder.rotation.y = PI   # face the camera
		var st: Dictionary = guard_style if i < 2 else Humanoid.random_style(rng)
		if i == 6:
			st = {"skin": Color(0.88, 0.72, 0.62), "top": Color(0.10, 0.10, 0.12),
				"bottom": Color(0.07, 0.07, 0.09), "bulk": 1.25, "hair": 1}
		figs.append(Humanoid.create(holder, st))
	_run(figs)

func _run(figs: Array) -> void:
	var cam := Camera3D.new()
	cam.fov = 50.0
	root.add_child(cam)
	for i in 10:
		await process_frame
	cam.make_current()
	(figs[1] as Humanoid).set_aim(true)
	(figs[1] as Humanoid).animate(0.0, 0.1)
	(figs[3] as Humanoid).animate(1.4, 0.1)
	(figs[4] as Humanoid).set_panic(true)
	(figs[4] as Humanoid).animate(0.0, 0.1)
	for i in 30:
		await process_frame
	for v in [["front", Vector3(0, 1.6, -53.5), Vector3(0, 1.1, -60)],
			["close", Vector3(-3.0, 1.9, -57.6), Vector3(-3.8, 1.7, -60)]]:
		cam.look_at_from_position(v[1], v[2], Vector3.UP)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			ProjectSettings.globalize_path("%s/people_%s.png" % [OUT_DIR, v[0]]))
	quit()
