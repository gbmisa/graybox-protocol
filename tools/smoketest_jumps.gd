extends SceneTree
## Platforming, played: the real player holds forward from a start spot,
## presses jump once he has run `takeoff` metres, lets go of forward once he
## is over the next platform, and must come to rest on it. Covers the crane run's hops (SecCraneRun) — the mantles are
## in smoketest_compound_systems.
##
##     godot --headless --path . --script res://tools/smoketest_jumps.gd

## [name, start, aim at (x, z), takeoff metres, sprint, landing AABB]
const JUMPS := [
	["catwalk -> P1", Vector3(16.0, 6.0, -40.6), Vector2(16.0, -43.3), 0.5, false,
		AABB(Vector3(15, 6.5, -44), Vector3(2, 0.3, 1.5))],
	["P1 -> P2", Vector3(16.2, 6.6, -42.8), Vector2(14.25, -45.4), 0.9, false,
		AABB(Vector3(13.5, 7.1, -46), Vector3(1.5, 0.3, 1.2))],
	["P2 -> container", Vector3(14.25, 7.2, -44.9), Vector2(13.5, -49.8), 0.8, false,
		AABB(Vector3(12, 4.5, -51), Vector3(3, 0.3, 2.4))],
	["P4 -> P5", Vector3(11.5, 5.7, -50.6), Vector2(9.1, -54.5), 1.0, false,
		AABB(Vector3(8.6, 6.7, -55), Vector3(1.0, 0.3, 1.0))],
	["P5 -> P6", Vector3(9.4, 6.8, -54.1), Vector2(7.0, -57.0), 0.6, false,
		AABB(Vector3(6.5, 7.3, -57.5), Vector3(1.0, 0.3, 1.0))],
]

var _frame := 0
var _game: GrayboxGame
var _bad := 0
var _i := 0
var _t := 0.0
var _start := Vector3.ZERO
var _jumped := false

func _ok(c: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", msg])
	if not c:
		_bad += 1

func _initialize() -> void:
	_game = GrayboxGame.new()
	root.add_child(_game)

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
		_begin()
		return false
	var j: Array = JUMPS[_i]
	_t += delta
	var run := Vector2(p.global_position.x - _start.x, p.global_position.z - _start.z).length()
	if not _jumped and run >= float(j[3]):
		_jumped = true
		Input.action_press("jump")
	elif _jumped:
		Input.action_release("jump")
		# Over the platform: let go of forward, as a player would.
		var box: AABB = j[5]
		var c := box.get_center()
		var inside := absf(p.global_position.x - c.x) < box.size.x * 0.5 - 0.15 \
			and absf(p.global_position.z - c.z) < box.size.z * 0.5 - 0.15
		if inside:
			Input.action_release("move_forward")
			Input.action_release("sprint")
	# Done: settled on a floor after the jump, or out of time.
	if (_jumped and _t > 0.4 and p.is_on_floor() and absf(p.velocity.y) < 0.1) or _t > 3.0:
		Input.action_release("move_forward")
		Input.action_release("sprint")
		var box: AABB = j[5]
		var at := p.global_position
		_ok(box.grow(0.05).has_point(at), "%s (landed %s)" % [j[0], at.snapped(Vector3.ONE * 0.01)])
		_i += 1
		if _i >= JUMPS.size():
			print("%d problem(s)" % _bad)
			quit()
			return true
		_begin()
	return false

func _begin() -> void:
	var j: Array = JUMPS[_i]
	var p := _game.get_player()
	_start = j[1]
	p.global_position = _start + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	var aim: Vector2 = j[2]
	var d := Vector2(aim.x - _start.x, aim.y - _start.z)
	p.rotation.y = atan2(-d.x, -d.y)
	p.camera.rotation.x = 0.0
	_t = 0.0
	_jumped = false
	Input.action_press("move_forward")
	if bool(j[4]):
		Input.action_press("sprint")
