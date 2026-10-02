class_name MenuBackdrop
extends Node3D
## The live scene behind the main menu: HOLLOWAY ROAD at night, built from
## the same sections as the mission (minus the playtest room tags), with a
## camera drifting slowly along a few hand-placed shots — the billboard over
## the terraces, the floodlit courtyard, the estate tower. No guards, no
## mission, no physics anyone uses; freed the moment a mission starts.

## Each shot is [from, to, look_at]; the camera eases from -> to over SHOT_TIME.
const SHOTS := [
	[Vector3(-30, 9, 70), Vector3(-10, 10, 64), Vector3(0, 16, 26)],
	[Vector3(26, 13, 24), Vector3(12, 12, 30), Vector3(-2, 2, 4)],
	[Vector3(16, 3, 176), Vector3(6, 4, 168), Vector3(-24, 12, 186)],
	[Vector3(-26, 7.5, 36), Vector3(-16, 8, 38), Vector3(4, 18, 29)],
]
const SHOT_TIME := 14.0
const FADE := 1.2

var _cam: Camera3D
var _shot: int = 0
var _t: float = 0.0
var _fade: ColorRect

func build(fade_layer: CanvasLayer) -> void:
	name = "MenuBackdrop"
	var secs := LevelCompound.sections()
	secs.erase("room_names")
	for key in secs:
		secs[key].build(self, null)
	_cam = Camera3D.new()
	_cam.fov = 62.0
	add_child(_cam)
	_cam.make_current()
	# A black curtain between shots, on the menu's own canvas layer (behind
	# the menu, in front of the 3D).
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	fade_layer.move_child(_fade, 0)
	_shot = randi() % SHOTS.size()
	_place(0.0)

func _exit_tree() -> void:
	if is_instance_valid(_fade):
		_fade.queue_free()

func _process(delta: float) -> void:
	_t += delta
	if _t >= SHOT_TIME:
		_t = 0.0
		_shot = (_shot + 1) % SHOTS.size()
	_place(_t / SHOT_TIME)
	var edge := minf(_t, SHOT_TIME - _t)
	_fade.color.a = clampf(1.0 - edge / FADE, 0.0, 1.0)

func _place(f: float) -> void:
	var s: Array = SHOTS[_shot]
	var e := f * f * (3.0 - 2.0 * f)   # smoothstep
	var from: Vector3 = (s[0] as Vector3).lerp(s[1], e)
	_cam.look_at_from_position(from, s[2], Vector3.UP)
