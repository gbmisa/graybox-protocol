extends SceneTree
## Renders the raw stills behind THE OPENING's comic panels (IntroScript):
## staged shots of the real level with people posed in them. Then
## `tools/gen/comicify.py` inks them into assets/intro/*.png.
##
##     xvfb-run -a godot --path . --resolution 1280x720 --script res://tools/intro_panels.gd -- <raw dir> --no-room-names
##     python3 tools/gen/comicify.py <raw dir>
##
## A drawn panel can replace any of these: drop the PNG into assets/intro/.

const TARGET := {"skin": Color(0.88, 0.72, 0.62), "top": Color(0.10, 0.10, 0.12),
	"bottom": Color(0.07, 0.07, 0.09), "bulk": 1.25, "hair": 1}
const GUARD := {"skin": Color(0.62, 0.78, 0.38), "top": Color(0.75, 0.08, 0.14),
	"bottom": Color(0.10, 0.10, 0.22), "accent": Color(0.98, 0.85, 0.10),
	"visor": Color(0.1, 0.95, 1.0), "armed": true, "bulk": 1.15, "helmet": true, "hair": -1}
const REGULAR := {"skin": Color(0.80, 0.62, 0.50), "top": Color(0.16, 0.18, 0.16),
	"bottom": Color(0.20, 0.22, 0.30), "armed": true, "hair": 0, "hair_color": Color(0.7, 0.2, 0.08),
	"hat": true, "accent": Color(0.2, 0.2, 0.22)}

## [name, size, camera, look at, people: [style, position, yaw, pose]]
## pose: "" idle, "aim", "talk", "cower".
const SHOTS := [
	["billboard", Vector2i(900, 1350), Vector3(-6, 1.7, 50), Vector3(0, 18, 29), []],
	["school", Vector2i(900, 1350), Vector3(7, 1.4, 13), Vector3(-1, 4.5, -2), []],
	["annex", Vector2i(900, 1350), Vector3(0, 1.7, -43), Vector3(0, 5, -76), []],
	["vandermeer", Vector2i(900, 1350), Vector3(-2, 5.5, -11.5), Vector3(-2, 5.6, -17),
		[["target", Vector3(-2, 4.0, -17), PI, "talk"]]],
	["regular", Vector2i(1600, 900), Vector3(-6.4, 1.1, 188.0), Vector3(-8, 1.7, 190.5),
		[["regular", Vector3(-8, 0, 190.5), -0.57, ""]]],
	["guards", Vector2i(900, 1350), Vector3(0.5, 1.5, -57), Vector3(0.5, 1.6, -62),
		[["guard", Vector3(-0.6, 0, -61.5), PI, "aim"], ["guard", Vector3(1.8, 0, -62.6), PI + 0.3, "aim"]]],
	["eyes", Vector2i(900, 1350), Vector3(0, 1.6, 131), Vector3(0, 1.6, 118), []],
	["consento", Vector2i(900, 1350), Vector3(-11.2, 1.4, -67.8), Vector3(-13, 3.2, -72), []],
]

var _out := ""

func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var level := Node3D.new()
	level.name = "Level"
	root.add_child(level)
	for sec in LevelCompound.sections().values():
		sec.build(level, null)
	_run(level)

func _run(level: Node3D) -> void:
	var eye := Camera3D.new()   # the root's camera: TripZone watches this one
	root.add_child(eye)
	var vp := SubViewport.new()
	vp.world_3d = root.world_3d
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 60.0
	vp.add_child(cam)
	for i in 10:
		await process_frame
	eye.make_current()
	cam.make_current()
	for s in SHOTS:
		vp.size = s[1]
		eye.look_at_from_position(s[2], s[3], Vector3.UP)
		cam.look_at_from_position(s[2], s[3], Vector3.UP)
		var cast: Array = []
		for p in s[4]:
			var holder := Node3D.new()
			level.add_child(holder)
			holder.position = p[1]
			holder.rotation.y = float(p[2])
			var style: Dictionary = {"target": TARGET, "guard": GUARD, "regular": REGULAR}[p[0]]
			var h := Humanoid.create(holder, style)
			if p[3] == "aim":
				h.set_aim(true)
			h.animate(0.0, 0.1)
			if p[3] == "talk":
				h._play("talk")
			cast.append(holder)
		# A key light on whoever is in shot, from beside the camera: a tight
		# spot on them, not a pool on the walls.
		var key := SpotLight3D.new()
		key.light_energy = 6.0 if s[4].size() > 0 else 0.0
		key.spot_range = 14.0
		key.spot_angle = 14.0
		level.add_child(key)
		var aim: Vector3 = (s[4][0][1] as Vector3) + Vector3(0, 1.4, 0) if s[4].size() > 0 else s[3]
		key.look_at_from_position((s[2] as Vector3) + Vector3(0.8, 1.2, 0), aim, Vector3.UP)
		cast.append(key)
		for i in 150:
			await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("%s/%s.png" % [_out, s[0]])
		for c in cast:
			c.queue_free()
	print("wrote %d raw panels to %s" % [SHOTS.size(), _out])
	quit()
