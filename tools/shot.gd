extends SceneTree
## Ad-hoc eye-level shots of HOLLOWAY ROAD with real lighting. Views come
## from a text file, one per line: `name ex ey ez lx ly lz`.
##
##     xvfb-run -a godot --path . --rendering-method gl_compatibility \
##         --resolution 1280x720 --script res://tools/shot.gd -- views.txt
##
## Writes screenshots/shot_<name>.png.

const OUT_DIR := "res://screenshots"

var _cam: Camera3D
var _views: Array = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var args := OS.get_cmdline_user_args()
	var f := FileAccess.open(args[0], FileAccess.READ)
	while not f.eof_reached():
		var parts := f.get_line().strip_edges().split(" ", false)
		if parts.size() == 7:
			_views.append([parts[0],
				Vector3(float(parts[1]), float(parts[2]), float(parts[3])),
				Vector3(float(parts[4]), float(parts[5]), float(parts[6]))])
	var level := Node3D.new()
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	if "--magenta" in args:
		for we in level.find_children("*", "WorldEnvironment", true, false):
			var env: Environment = (we as WorldEnvironment).environment
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(1, 0, 1)
			env.fog_enabled = false
	_cam = Camera3D.new()
	_cam.fov = 75.0
	root.add_child(_cam)
	_run()

func _run() -> void:
	for i in 5:
		await process_frame
	_cam.make_current()
	for v in _views:
		_cam.look_at_from_position(v[1], v[2], Vector3.UP)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/shot_%s.png" % [OUT_DIR, v[0]]))
	print("wrote %d views" % _views.size())
	quit()
