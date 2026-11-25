extends SceneTree
## Top-down plans of HOLLOWAY ROAD for review (r8's level-design judge): an
## orthographic camera straight down, flat bright light, fog off, room tags
## on. Per half (south = approach, north = campus + annex): a ROOFS view from
## high up, and a GROUND plan cut at 3.3m (the camera sits under the ceilings,
## so you see floors, walls and doors). ~10 px per metre.
##
##     xvfb-run -a godot --path . --resolution 1000x1600 --script res://tools/map_shot.gd
##
## Writes screenshots/map_{north,south}_{ground,roofs}.png.

const OUT_DIR := "res://screenshots"
## name, centre z, span z (metres)
const HALVES := [["north", -40.0, 160.0], ["south", 120.0, 160.0]]
const CUTS := [["ground", 3.3], ["roofs", 150.0]]

var _cam: Camera3D

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var level := Node3D.new()
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	for we in level.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = (we as WorldEnvironment).environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.1, 0.1, 0.12)
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ambient_light_energy = 1.6
		env.ssao_enabled = false
		env.glow_enabled = false
	for l in level.find_children("*", "Label3D", true, false):
		(l as Label3D).pixel_size *= 3.0
		(l as Label3D).no_depth_test = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-70, 30, 0)
	sun.light_energy = 1.2
	root.add_child(sun)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.far = 400.0
	root.add_child(_cam)
	_run()

func _run() -> void:
	for i in 5:
		await process_frame
	_cam.make_current()
	for h in HALVES:
		for c in CUTS:
			_cam.size = float(h[2])
			_cam.near = 0.05
			_cam.global_transform = Transform3D(Basis.from_euler(Vector3(-PI / 2, 0, 0)),
				Vector3(0, float(c[1]), float(h[1])))
			for i in 3:
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				ProjectSettings.globalize_path("%s/map_%s_%s.png" % [OUT_DIR, h[0], c[0]]))
	print("wrote 4 maps")
	quit()
