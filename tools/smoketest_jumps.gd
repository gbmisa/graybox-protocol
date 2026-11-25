extends SceneTree
## Platforming, played: the real player holds forward from a start spot,
## presses jump once he has run `takeoff` metres (never, for a plank walk),
## lets go of forward once he is over the next platform, and must come to
## rest on it. Covers the Consent Tower site's route (SecAnnexSite): the
## plank walks, the jump onto the crane beam, the moving hook pallet and the
## hop off it. Mantles and ladders are in smoketest_compound_systems.
##
##     godot --headless --path . --script res://tools/smoketest_jumps.gd

## {name, start, aim (x, z), takeoff (-1 = walk), landing AABB, wait}
## `wait`: "" start now; "slider_south" start when the hook pallet is at its
## south stop; "on_slider" stand on the pallet at its north stop and go.
const JUMPS := [
	{"name": "plank 1 over the pit", "start": Vector3(32.8, 3.0, -61.0), "aim": Vector2(32.8, -72.0),
		"takeoff": -1.0, "land": AABB(Vector3(30, 2.9, -74), Vector3(4, 0.3, 4)), "wait": ""},
	{"name": "long plank to C1", "start": Vector3(28.6, 6.0, -76.0), "aim": Vector2(21.0, -76.0),
		"takeoff": -1.0, "land": AABB(Vector3(20.2, 5.9, -77), Vector3(1.6, 0.3, 2)), "wait": ""},
	{"name": "C1 -> crane beam", "start": Vector3(21.0, 6.0, -75.3), "aim": Vector2(21.0, -81.0),
		"takeoff": 1.3, "land": AABB(Vector3(20.6, 6.3, -86), Vector3(0.8, 0.3, 7)), "wait": ""},
	{"name": "beam -> hook pallet", "start": Vector3(21.0, 6.4, -84.6), "aim": Vector2(21.0, -89.0),
		"takeoff": 1.1, "land": "slider", "wait": "slider_south"},
	{"name": "hook pallet -> C2", "start": Vector3.ZERO, "aim": Vector2(21.2, -93.4),
		"takeoff": 0.2, "land": AABB(Vector3(20.2, 6.9, -94), Vector3(2, 0.3, 1.6)), "wait": "on_slider"},
	{"name": "roof plank onto the annex", "start": Vector3(23.0, 8.0, -95.0), "aim": Vector2(16.5, -95.0),
		"takeoff": -1.0, "land": AABB(Vector3(16.0, 7.9, -95.6), Vector3(1.5, 0.3, 1.2)), "wait": ""},
]

var _frame := 0
var _game: GrayboxGame
var _bad := 0
var _i := 0
var _t := 0.0
var _start := Vector3.ZERO
var _jumped := false
var _waiting := false
var _slider: Node3D

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _initialize() -> void:
	_game = GrayboxGame.new()
	root.add_child(_game)

func _landing() -> AABB:
	var land: Variant = JUMPS[_i]["land"]
	if land is AABB:
		return land
	var c := _slider.global_position
	return AABB(c - Vector3(0.8, 0.1, 0.7), Vector3(1.6, 0.4, 1.4))

func _physics_process(delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_game.no_guards = true
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
	if _frame < 30:
		return false
	var p := _game.get_player()
	p.health.hp = 1.0e9
	if _frame == 30:
		_slider = _game.level_root.find_child("CraneSlider", true, false) as Node3D
		_ok(_slider != null, "the hook pallet exists")
		_begin()
		return false
	if _waiting:
		_try_start()
		return false
	var j: Dictionary = JUMPS[_i]
	_t += delta
	var walk := float(j["takeoff"]) < 0.0
	var run := Vector2(p.global_position.x - _start.x, p.global_position.z - _start.z).length()
	var box := _landing()
	var c := box.get_center()
	var inside := absf(p.global_position.x - c.x) < box.size.x * 0.5 - 0.1 \
		and absf(p.global_position.z - c.z) < box.size.z * 0.5 - 0.15
	if not walk and not _jumped and run >= float(j["takeoff"]):
		_jumped = true
		Input.action_press("jump")
	elif _jumped:
		Input.action_release("jump")
	if (walk or _jumped) and inside:
		Input.action_release("move_forward")
	var settled := p.is_on_floor() and absf(p.velocity.y) < 0.1 and _t > 0.4
	var done := (walk and inside and settled) or (_jumped and settled and _t > 0.6) \
		or _t > (8.0 if walk else 3.0)
	if done:
		Input.action_release("move_forward")
		var at := p.global_position
		_ok(box.grow(0.08).has_point(at), "%s (landed %s)" % [j["name"], at.snapped(Vector3.ONE * 0.01)])
		_i += 1
		if _i >= JUMPS.size():
			print("%d problem(s)" % _bad)
			quit()
			return true
		_begin()
	return false

func _begin() -> void:
	_waiting = true
	_try_start()

func _try_start() -> void:
	var j: Dictionary = JUMPS[_i]
	var p := _game.get_player()
	match String(j["wait"]):
		"slider_south":
			if _slider.global_position.z < -88.32:
				p.global_position = Vector3(j["start"]) + Vector3(0, 0.05, 0)
				p.velocity = Vector3.ZERO
				return
		"on_slider":
			if _slider.global_position.z > -90.98:
				p.global_position = _slider.global_position + Vector3(0, 0.2, 0.4)
				p.velocity = Vector3.ZERO
				return
	_waiting = false
	_start = j["start"]
	if String(j["wait"]) == "on_slider":
		_start = _slider.global_position + Vector3(0, 0.15, 0.4)
	p.global_position = _start + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	var aim: Vector2 = j["aim"]
	var d := Vector2(aim.x - _start.x, aim.y - _start.z)
	p.rotation.y = atan2(-d.x, -d.y)
	p.camera.rotation.x = 0.0
	_t = 0.0
	_jumped = false
	Input.action_press("move_forward")
