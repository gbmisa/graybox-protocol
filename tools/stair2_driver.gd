extends Node
## Drives a capsule probe (player dims: r=0.4, h=1.7, feet origin) from the
## undercroft floor up the service stair to the mezzanine. Fails if any leg
## stalls (the P5 bug: a railing walled the top landing off from the floor).
const GrayboxGame = preload("res://scripts/core/game.gd")
const STEP : float = 1.0 / 60.0
# XZ waypoints: stair base -> flight1 top -> across landing -> flight2 top ->
# south across the old railing line onto the main floor plate.
const WAYPOINTS := [
	Vector2(-27, 5.5), Vector2(-21, 5.5), Vector2(-21, -5.5), Vector2(-24, -10),
]
const REACH_XZ := 0.9
const SPEED := 4.5
const BUDGET := 1500 # physics frames for the whole walk

var _game : Node = null
var _probe : CharacterBody3D = null
var _booted := false
var _leg := 0
var _leg_frames := 0
var _frames := 0
var _done := false
var _result := ""
var _last_phys := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if _done:
		return
	# Gate on physics frames: idle frames run unthrottled headless, so only
	# step once per physics tick for deterministic timing.
	var pf := Engine.get_physics_frames()
	if pf == _last_phys:
		return
	_last_phys = pf
	_frames += 1
	if not _booted:
		if _frames == 1:
			_boot()
		return
	if _frames > BUDGET:
		_finish(false, "TIMEOUT after %d frames, stalled on leg %d at %s" % [
			BUDGET, _leg, _pos_str()])
		return
	_step()

func _boot() -> void:
	_game = GrayboxGame.new()
	get_tree().root.add_child(_game)
	_game.selected_level = 1
	_game.selected_char = "regular"
	_game.flow.start_mission()
	_probe = CharacterBody3D.new()
	_probe.collision_layer = 4
	_probe.collision_mask = 1
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	var col := CollisionShape3D.new()
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	_probe.add_child(col)
	_probe.floor_snap_length = 0.5
	_game.level_root.add_child(_probe)
	_probe.position = Vector3(-27, -3.9, -7)
	_probe.add_collision_exception_with(_game.player)
	for g in _game.level_root.get_children():
		if g != _probe and g is CharacterBody3D:
			_probe.add_collision_exception_with(g)
	_booted = true

func _step() -> void:
	if _leg >= WAYPOINTS.size():
		_finish(_at_goal(), "reached=%s pos=%s" % [_at_goal(), _pos_str()])
		return
	var wp: Vector2 = WAYPOINTS[_leg]
	var p := Vector2(_probe.position.x, _probe.position.z)
	_leg_frames += 1
	if p.distance_to(wp) < REACH_XZ:
		print("[stair2] leg %d/%d done at %s (f%d)" % [
			_leg + 1, WAYPOINTS.size(), _pos_str(), _frames])
		_leg += 1
		_leg_frames = 0
		return
	if _leg_frames > 600:
		_finish(false, "STALL on leg %d heading %s, stuck at %s" % [
			_leg, wp, _pos_str()])
		return
	var d := (wp - p).normalized()
	var v := _probe.velocity
	v.x = d.x * SPEED
	v.z = d.y * SPEED
	if _probe.is_on_floor():
		v.y = -0.5
	else:
		v.y = maxf(v.y - 30.0 * STEP, -20.0)
	_probe.velocity = v
	_probe.move_and_slide()

func _at_goal() -> bool:
	var p := _probe.position
	return absf(p.y - 6.0) <= 0.5 and p.z < -8.5 and p.x > -30.0 and p.x < -18.0

func _pos_str() -> String:
	var p := _probe.position
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]

func _finish(ok: bool, detail: String) -> void:
	_done = true
	_result = "PASS" if ok else "FAIL"
	print("[stair2] %s: %s" % [_result, detail])
	print("[stair2] alarms=%d" % int(_game.stats.get("alarms", -1)))
	get_tree().quit(0 if ok else 1)
