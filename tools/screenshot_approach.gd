extends SceneTree
## Eye-level shots along HOLLOWAY ROAD's approach, looking north, with the
## level's real night lighting and fog — the check for whether the campus
## (billboard, mast) reads as the thing you're walking toward:
##
##     xvfb-run -a godot --path . --rendering-method gl_compatibility \
##         --resolution 1280x720 --script res://tools/screenshot_approach.gd
##
## Writes screenshots/approach_*.png.

const OUT_DIR := "res://screenshots"

## label, eye position, look-at
const VIEWS := [
	["01_bus_stop", Vector3(0, 1.6, 190), Vector3(0, 6, 60)],
	["02_garage_roof", Vector3(20, 4.2, 175), Vector3(0, 4, 100)],
	["03_estate_yard", Vector3(-6, 1.6, 160), Vector3(0, 3, 138)],
	["04_subway", Vector3(0, 1.6, 136), Vector3(0, 1.6, 110)],
	["05_road_deck", Vector3(30, 5.6, 126), Vector3(0, 6, 40)],
	["06_towpath", Vector3(-20, 1.6, 104), Vector3(0, 2, 70)],
	["07_canal_bed", Vector3(20, -0.9, 96), Vector3(-10, -1, 96)],
	["08_allotments", Vector3(10, 4.0, 86), Vector3(0, 5, 30)],
	["09_alley_reveal", Vector3(0, 1.6, 66), Vector3(0, 6, 20)],
	["10_south_road", Vector3(4, 1.6, 44), Vector3(0, 5, 0)],
]

var _cam: Camera3D

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var level := Node3D.new()
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	_cam = Camera3D.new()
	_cam.fov = 75.0
	root.add_child(_cam)
	_run()

func _run() -> void:
	for i in 5:
		await process_frame
	_cam.make_current()
	for v in VIEWS:
		_cam.look_at_from_position(v[1], v[2], Vector3.UP)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/approach_%s.png" % [OUT_DIR, v[0]]))
	print("wrote %d approach views" % VIEWS.size())
	quit()
