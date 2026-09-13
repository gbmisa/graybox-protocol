extends SceneTree
## PORT VESPER bot playthroughs: spawn -> vector -> gate verb -> kill the
## Harbormaster -> extraction -> WIN, per operative. Teleports hop between
## validated waypoints; gates, dashes, kills, extractions use real mechanics.
## Also runs the close-range detection timing test.
##     godot --headless --path . --script res://tools/playthrough2.gd
var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _phase := "detect"
var _steps: Array = []
var _step := 0
var _sframe := 0
var _hold_until := 0
var _t0 := 0
var _hp0 := 0.0
var _bad := 0

func _process(_delta: float) -> bool:
	var pf := Engine.get_physics_frames()  # idle frames run unthrottled headless
	if pf == _pf:
		return false
	_pf = pf
	_frame += 1
	if _frame == 1:
		_new_game("regular")
	elif _phase == "detect":
		_tick_detect()
	elif _phase in ["regular", "wizard", "chad"]:
		_tick_steps()
	elif _phase == "done":
		print("\n%d problem(s)" % _bad)
		return true
	return false

func _new_game(char: String) -> void:
	if _game != null:
		_game.queue_free()
	_game = GrayboxGame.new()
	root.add_child(_game)
	_game.selected_level = 2
	_game.selected_char = char
	_game.flow.start_mission()
	_t0 = Time.get_ticks_msec()
	_hp0 = _game.player.hp()

# ---------------------------------------------------------- detection ---
## Guard faces the player at 14m, standing, exposed. Expect ALERT in ~1s.
## The guard's transform is forced every frame so its patrol brain can't
## turn it away mid-test.
func _tick_detect() -> void:
	var g: Guard = _game.guards[0]
	g.global_position = Vector3(0, 0, -50)
	g.rotation.y = PI  # face +z, toward the player
	_game.player.global_position = Vector3(0, 0, -36)
	_game.player.rotation.y = 0.0
	_sframe += 1
	if g.state == Guard.State.ALERT or g.detect >= 1.0:
		var t := _sframe / 60.0
		print("-- detection: ALERT in %.2fs at 14m --" % t)
		if t < 0.6 or t > 1.3:
			_fail("detection took %.2fs, expected ~1s" % t)
		_start_run("regular", PtSteps.regular())
	elif _sframe > 180:
		_fail("guard never alerted in 3s (detect=%.2f)" % g.detect)
		_start_run("regular", PtSteps.regular())

func _start_run(phase: String, steps: Array) -> void:
	_phase = phase
	_steps = steps
	_step = 0
	_sframe = 0
	_new_game(phase)

# ---------------------------------------------------------------- steps ---
func _tick_steps() -> void:
	if _step >= _steps.size():
		_finish_run()
		return
	var s: Dictionary = _steps[_step]
	match String(s["t"]):
		"t_spawn":
			_check_spawn(String(s["char"]))
			_next()
		"t_tp":
			if _sframe == 0:
				_teleport(s["p"])
			_sframe += 1
			if _sframe >= 5:
				if not _grounded(s["p"]):
					_fail("%s: waypoint %s not standable" % [_phase, s["p"]])
				_next()
		"t_gate":
			_tick_gate(s)
		"t_dash":
			_tick_dash(s)
		"t_kill":
			_tick_kill()
		"t_extract":
			if _sframe == 0:
				_teleport(s["p"])
			_sframe += 1
			if _sframe >= 30:
				if _game.flow.state != MissionFlow.State.WIN:
					_fail("%s: no WIN at extraction" % _phase)
				_next()

func _next() -> void:
	_step += 1
	_sframe = 0
	_hold_until = 0
	Input.action_release("interact")
	Input.action_release("attack")

func _check_spawn(char: String) -> void:
	var p := _game.player
	if p.char_id != char:
		_fail("spawned as %s, expected %s" % [p.char_id, char])
	var want: Vector3 = (Level2Builder.player_spawns()[char] as Dictionary)["pos"]
	if p.global_position.distance_to(want) > 0.5:
		_fail("%s spawned at %s" % [char, p.global_position])

func _teleport(pos: Vector3) -> void:
	_game.player.global_position = pos + Vector3(0, 0.1, 0)
	_game.player.velocity = Vector3.ZERO

func _grounded(pos: Vector3) -> bool:
	var space := _game.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, 1.0, 0), pos + Vector3(0, -3.0, 0)))
	return not hit.is_empty()

func _aim_at(world: Vector3) -> void:
	var p := _game.player
	var d: Vector3 = world - p.global_position
	p.rotation.y = atan2(-d.x, -d.z)
	var flat := Vector2(d.x, d.z).length()
	p.camera.rotation.x = atan2(d.y - 1.5, flat)

func _door_at(pos: Vector3) -> Interactable:
	for d in _interactables():
		if (d as Node3D).global_position.distance_to(pos) < 2.0:
			return d
	return null

func _interactables() -> Array:
	var out: Array = []
	_collect(_game.level_root, out)
	return out

func _collect(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Interactable:
			out.append(child)
		_collect(child, out)

## Stand before the door, aim, hold interact through the channel.
func _tick_gate(s: Dictionary) -> void:
	var door := _door_at(s["door"])
	if door == null:
		_fail("%s: no door at %s" % [_phase, s["door"]])
		_next()
		return
	if _sframe == 0:
		_teleport(s["at"])
		_aim_at((s["door"] as Vector3) + Vector3(0, -0.3, 0))
		_hold_until = _sframe + int(float(s["hold"]) * 60.0) + 5
	_sframe += 1
	_aim_at((s["door"] as Vector3) + Vector3(0, -0.3, 0))
	Input.action_press("interact")
	if door.is_open:
		print("  %s: gate open (%s)" % [_phase, door.display_name])
		_next()
	elif _sframe > _hold_until + 120:
		_fail("%s: gate never opened (%s)" % [_phase, door.display_name])
		_next()

## A real dash: place at the edge, face along +x, press sprint once.
## Waits out the 1.2s dash cooldown before pressing.
func _tick_dash(s: Dictionary) -> void:
	if _sframe == 0:
		_teleport(s["from"])
		_game.player.rotation.y = float(s["yaw"])
		_game.player.camera.rotation.x = 0.0
	_sframe += 1
	if _sframe == 80:
		Input.action_press("sprint")
	elif _sframe == 82:
		Input.action_release("sprint")
	if _sframe >= 120:
		var p := _game.player.global_position
		if p.x < float(s["x0"]) or p.x > float(s["x1"]) \
				or absf(p.y - float(s["y"])) > 1.0:
			_fail("%s: dash landed at %s, expected x[%s,%s]" % \
				[_phase, p, s["x0"], s["x1"]])
		else:
			print("  %s: dash landed at (%.1f, %.1f)" % [_phase, p.x, p.y])
		_next()

## Track the target and hold attack until it dies. Sticks to the target so
## melee range holds even as it patrols.
func _tick_kill() -> void:
	var t := _game.target
	if t == null:
		_fail("%s: no target" % _phase)
		_next()
		return
	if _sframe == 0 and not t.alive:
		_fail("%s: target already dead" % _phase)
		_next()
		return
	if not t.alive:
		if _game.objective_stage != 2:
			_fail("%s: target dead but objective not advanced" % _phase)
		else:
			print("  %s: target down" % _phase)
		_next()
		return
	var p := _game.player
	if _sframe == 0:
		print("  %s: kill step, target hp=%.0f at %s" % [_phase, t.hp, t.global_position])
	# Stay at 2m so the punch (2.8m range) always connects.
	var to_t: Vector3 = t.global_position - p.global_position
	to_t.y = 0.0
	if to_t.length() > 2.2:
		p.global_position = t.global_position - to_t.normalized() * 2.0 + Vector3(0, 0.1, 0)
		p.velocity = Vector3.ZERO
	_sframe += 1
	_aim_at(t.global_position + Vector3(0, 1.2, 0))
	Input.action_press("attack")
	if _sframe > 1200:
		_fail("%s: target survived 20s of fire (hp=%.0f)" % [_phase, t.hp])
		_next()

func _finish_run() -> void:
	var secs := (Time.get_ticks_msec() - _t0) / 1000.0
	var dmg := _hp0 - _game.player.hp()
	var alarms := int(_game.stats["alarms"])
	print("-- %s: WIN in %.1fs, damage %.0f, alarms %d --" % [_phase, secs, dmg, alarms])
	if _phase == "regular":
		_start_run("wizard", PtSteps.wizard())
	elif _phase == "wizard":
		_start_run("chad", PtSteps.chad())
	else:
		_phase = "done"

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

