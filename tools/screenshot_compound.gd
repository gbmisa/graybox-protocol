extends SceneTree
## Renders HOLLOWAY CAMPUS from fixed viewpoints into screenshots/ — needs a
## renderer, so NOT --headless:
##
##     godot --path . --resolution 1280x720 --script res://tools/screenshot_compound.gd
##
## The sky is magenta: inside a room, any magenta is a hole to the outside or
## the void. Hallways get one shot from each end looking along them. Areas get
## one sheet of four views from the middle: top row north | east, bottom row
## south | west. Coordinates are LEVEL-compound.md §2's, so a shot of a wall
## where a room should be is itself a finding.

const OUT_DIR := "res://screenshots"
const EYE := 1.6

## label, start (floor), end (floor), eye height
const HALLS := [
	["g_west_corridor_south", Vector3(-20.5, 0, -2.6), Vector3(-20.5, 0, -10.4), EYE],
	["g_west_corridor_north", Vector3(-20.5, 0, -11.6), Vector3(-20.5, 0, -19.4), EYE],
	["g_north_corridor", Vector3(-18.4, 0, -12.5), Vector3(2.4, 0, -12.5), EYE],
	["g_east_stair_passage", Vector3(4.6, 0, -7), Vector3(9.4, 0, -7), EYE],
	["1f_south_corridor_west_arm", Vector3(-12.4, 4, -4), Vector3(-3.4, 4, -4), EYE],
	["1f_passage_e", Vector3(2.6, 4, -7), Vector3(9.4, 4, -7), EYE],
	["1f_west_landing", Vector3(-18.4, 4, -11), Vector3(-10.6, 4, -11), EYE],
	["1f_east_landing", Vector3(8, 4, -8.6), Vector3(8, 4, -19.4), EYE],
	["1f_link_bridge", Vector3(10.6, 4, -12), Vector3(15.4, 4, -12), EYE],
	["roof_duct", Vector3(5.4, 8.4, -12), Vector3(2.4, 8.4, -12), 0.5],
	["u_west_run", Vector3(-20.5, -3, -19.4), Vector3(-20.5, -3, -8.6), EYE],
	["u_caretaker_spur", Vector3(-18.6, -3, -9.5), Vector3(-13.4, -3, -9.5), EYE],
	["u_squeeze", Vector3(-28.4, -3, -17.5), Vector3(-22.4, -3, -17.5), 0.3],
	["x_west_alley", Vector3(-34, 0, 30), Vector3(-34, 0, -22), EYE],
	["x_east_lane", Vector3(32, 0, 30), Vector3(32, 0, -22), EYE],
	["x_alley", Vector3(13, 0, -2.6), Vector3(13, 0, -19.4), EYE],
	["x_north_yard", Vector3(-27, 0, -22), Vector3(27, 0, -22), EYE],
	["x_gym_shutter", Vector3(30.5, 0, -17), Vector3(26.5, 0, -17), 0.5],
]

## label, floor point at the middle of the area
const AREAS := [
	["g_panic_room", Vector3(-16, 0, -17)],
	["g_north_stair_well", Vector3(-11.5, 0, -14.6)],
	["g_records", Vector3(-3.5, 0, -17)],
	["g_kitchen", Vector3(6.5, 0, -17)],
	["g_caretaker", Vector3(-18.3, 0, -9.5)],
	["g_toilets", Vector3(-8, 0, -9.5)],
	["g_csd_passage", Vector3(0, 0, -9.5)],
	["g_canteen", Vector3(6.5, 0, -11)],
	["g_west_foyer", Vector3(-8, 0, -5)],
	["g_lobby", Vector3(-0.5, 0, -5)],
	["g_west_stair_well_foot", Vector3(-18.5, 0, -3)],
	["g_east_stair_well_foot", Vector3(9.5, 0, -3)],
	["1f_assembly_hall", Vector3(-2, 4, -15)],
	["1f_gallery", Vector3(-2, 5, -9)],
	["1f_staff_room", Vector3(-16, 4, -17)],
	["1f_av_booth", Vector3(-6.5, 4, -7)],
	["1f_north_stair_landing", Vector3(-11.5, 4, -19.2)],
	["1f_south_corridor_east_shelf", Vector3(3, 4, -4)],
	["roof_main", Vector3(-6, 8.4, -11)],
	["roof_plant_room", Vector3(-5, 8.4, -16)],
	["gym_store", Vector3(22, 0, -17)],
	["gym_floor", Vector3(22, 0, -3)],
	["gym_mezzanine", Vector3(25.5, 4, -11)],
	["gym_roof", Vector3(22, 6.6, -2)],
	["gym_helipad_deck", Vector3(23, 11.2, -8)],
	["gym_canopy_top", Vector3(22, 4.4, 9.5)],
	["u_boiler_house", Vector3(-31, 0, -9)],
	["u_boiler_basement", Vector3(-31, -3, -16)],
	["x_spawn_road", Vector3(0, 0, 40)],
	["x_verge", Vector3(-10, 0, 28)],
	["x_courtyard_west", Vector3(-12, 0, 10)],
	["x_courtyard_east", Vector3(8, 0, 14)],
	["x_portico", Vector3(0, 0, 0)],
	["x_west_yard", Vector3(-25, 0, 0)],
	["x_refuse_yard", Vector3(22, 0, 18)],
	["x_gym_forecourt", Vector3(22, 0, 9.5)],
	["x_outfall_pit", Vector3(-36, -2.2, 8)],
	["x_avenue", Vector3(10, 0, -32)],
	["x_gatehouse", Vector3(-6, 0, -27)],
]

## label, camera position, look-at target
const OVERVIEWS := [
	["from_sw", Vector3(-50, 35, 50), Vector3(0, 0, -4)],
	["from_se", Vector3(50, 35, 50), Vector3(0, 0, -4)],
	["from_ne", Vector3(50, 35, -55), Vector3(0, 0, -4)],
	["from_nw", Vector3(-50, 35, -55), Vector3(0, 0, -4)],
	["top_down", Vector3(0, 95, -2), Vector3(0, 0, -2)],
]

## yaw per quadrant: north, east / south, west
const YAWS := [0.0, -PI / 2.0, PI, PI / 2.0]

var _cam: Camera3D

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var level := Node3D.new()
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	for we in level.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = (we as WorldEnvironment).environment
		env.background_color = Color(1, 0, 1)
		env.ambient_light_energy = 1.6
	_cam = Camera3D.new()
	_cam.fov = 75.0
	root.add_child(_cam)
	var headlamp := OmniLight3D.new()
	headlamp.omni_range = 30.0
	headlamp.light_energy = 1.2
	_cam.add_child(headlamp)
	_run()

func _run() -> void:
	for i in 5:
		await process_frame
	_cam.make_current()
	var n := 0
	for o in OVERVIEWS:
		n += 1
		var up := Vector3(0, 0, -1) if String(o[0]) == "top_down" else Vector3.UP
		_cam.fov = 60.0 if String(o[0]) == "top_down" else 75.0
		_cam.look_at_from_position(o[1], o[2], up)
		_save(await _grab(), "%02d_o_%s" % [n, o[0]])
	_cam.fov = 75.0
	for h in HALLS:
		n += 1
		var lift := Vector3(0, float(h[3]), 0)
		_cam.look_at_from_position(h[1] + lift, h[2] + lift, Vector3.UP)
		_save(await _grab(), "%02d_h_%s_start" % [n, h[0]])
		_cam.look_at_from_position(h[2] + lift, h[1] + lift, Vector3.UP)
		_save(await _grab(), "%02d_h_%s_end" % [n, h[0]])
	for a in AREAS:
		n += 1
		_save(await _sheet(a[1] + Vector3(0, EYE, 0)), "%02d_a_%s" % [n, a[0]])
	print("wrote %d viewpoints to %s" % [n, ProjectSettings.globalize_path(OUT_DIR)])
	quit()

func _sheet(eye: Vector3) -> Image:
	var sheet: Image = null
	for i in 4:
		_cam.global_position = eye
		_cam.rotation = Vector3(0, YAWS[i], 0)
		var img: Image = await _grab()
		var w := img.get_width()
		var h := img.get_height()
		if sheet == null:
			sheet = Image.create(w, h, false, Image.FORMAT_RGB8)
		img.resize(w / 2, h / 2)
		var at := Vector2i((i % 2) * (w / 2), (i / 2) * (h / 2))
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	var sw := sheet.get_width()
	var sh := sheet.get_height()
	sheet.fill_rect(Rect2i(sw / 2 - 2, 0, 4, sh), Color.BLACK)
	sheet.fill_rect(Rect2i(0, sh / 2 - 2, sw, 4), Color.BLACK)
	return sheet

func _grab() -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	return img

func _save(img: Image, file_name: String) -> void:
	img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, file_name]))
