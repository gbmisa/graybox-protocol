extends Node
## Ghost driver: the real player (input actions, no teleports) walks the
## Regular's Level 1 route with live guards: spawn -> undercroft -> service
## stair -> mezzanine -> boardroom door (picked, stepped inside) -> back ->
## sump extraction, asserting zero alarms. Proves a stealth ROUTE exists.
## The kill is not attempted: the pistol is loud (noise 25) and the target's
## close-protection guards sit inside the hearing radius, so a zero-alarm
## kill is impossible by design (see HANDOFF). "sneak" legs move crouched but
## freeze while any guard sees the player (GuardSenses math) and retreat to
## the leg start if stared down — the bot version of waiting out a patrol.
const Game = preload("res://scripts/core/game.gd")
const STEP := 1.0 / 60.0
# L1 guard indices (spawn order): 0,1 undercroft, 2-6 courtyard, 7-10 dock,
# 11-14 mezzanine, 15,16 boardroom.
const M1 := 11; const M2 := 12
const G1 := 1

var _game = null; var _p = null
var _ops: Array = []; var _op := 0; var _t := 0.0
var _max_detect := 0.0; var _max_state := 0
var _done := false; var _use_t := 0.0
var _stall_p := Vector3.ZERO; var _stall_t := 0.0
var _seen_t := 0.0; var _leg_start := Vector3.ZERO; var _leg_t := 0.0
var _reached_boardroom := false
var _alert_log := {}
var _last_phys := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if _done:
		return
	var pf := Engine.get_physics_frames()
	if pf == _last_phys:
		return
	_last_phys = pf
	_t += STEP
	if _game == null:
		_boot()
		return
	_track()
	if _op >= _ops.size():
		_finish(true, "route complete")
		return
	_run(_ops[_op], STEP)

func _boot() -> void:
	_game = Game.new()
	get_tree().root.add_child(_game)
	_game.selected_level = 1
	_game.selected_char = "regular"
	_game.flow.start_mission()
	_p = _game.player
	_ops = [
		["walk", Vector3(-50, 0, 70), 2.0, false],
		["walk", Vector3(-50, 0, 56), 1.0, false],
		["walk", Vector3(-50, 0, 40), 1.0, true],
		["walk", Vector3(-50, -4, 28), 1.0, true],
		["walk", Vector3(-50, -4, 23.5), 0.8, false],
		["use", 3.8],                                   # pick maintenance door
		["walk", Vector3(-50, -4, 20), 1.0, false],    # through the open door
		["walk", Vector3(-26, -4, 20), 2.0, false],    # east along wall, safe any phase
		["waitg", "g1_wb_start"],                       # g1 turned westbound (east end)
		["walk", Vector3(-32, -4, 16), 1.5, false],   # around stair north, behind g1
		["walk", Vector3(-32, -4, -8), 1.5, false],    # south, west of stair
		["walk", Vector3(-27, -4, -10), 1.2, false],   # around to stair south side
		["walk", Vector3(-27, -4, -5), 0.8, false],    # service stair flight 1 base
		["stair", Vector3(-27, 0, 5.5)],                # up flight 1 (xz only)
		["stair", Vector3(-21, 0, 5.5)],                # across to flight 2
		["stair", Vector3(-21, 0, -5.5)],               # up flight 2 (xz only)
		["stair", Vector3(-24, 0, -10)],                # onto main floor
		["waitg", "mezz_clear"],                       # east guards facing away
		["waitg", "stair_gap"],                        # west guard (M1) south, facing away
		["walk", Vector3(-27, 6, -7), 1.2, true],      # west along top landing
		["walk", Vector3(-27, 6, -14), 1.2, true],     # south to cabinet cover
		["sneak", Vector3(-24, 6, -12), 0.8],
		["walk", Vector3(-24, 12, -24), 1.0, false],
		["use", 3.8],
		["sneak", Vector3(-24, 12, -25.8), 0.6],
		["walk", Vector3(-24, 12, -24), 0.8, false],
		["walk", Vector3(-24, 6, -12), 1.0, false],
		["waitg", "stair_gap"],
		["sneak", Vector3(-19, 6, -9), 0.8],
		["walk", Vector3(-21, 6, -6), 1.0, false],
		["walk", Vector3(-21, 0, 5.5), 0.9, false],
		["walk", Vector3(-27, 0, 5.5), 0.9, false],
		["walk", Vector3(-27, -4, -5), 0.8, false],
		["walk", Vector3(-40, -4, -10), 2.0, false],   # south transit west
		["walk", Vector3(-57, -4, -10), 1.5, false],   # clear of doorway wedge
		["walk", Vector3(-60, -4, -6), 1.2, true],     # tunnel mouth, crouched
		["crawl", Vector3(-74, -4, -6), 2.0],           # sump outflow
	]

func _run(op: Array, delta: float) -> void:
	match String(op[0]):
		"walk":
			_set_crouch(bool(op[3]))
			_advance(op[1], float(op[2]), delta)
		"stair":
			_set_crouch(false)
			_advance(op[1], 0.9, delta, true)
		"sneak":
			_sneak(op[1], float(op[2]), delta)
		"crawl":
			_set_crouch(true)
			_advance(op[1], float(op[2]), delta)
			var pp: Vector3 = _p.global_position
			if Vector2(op[1].x - pp.x, op[1].z - pp.z).length() < float(op[2]):
				_finish(true, "reached sump extraction")
		"waitg":
			Input.action_release("move_forward")
			Input.action_press("crouch")  # stay low while waiting out a patrol
			if _cond(String(op[1])):
				_next()
		"use":
			_use(float(op[1]), delta)

## Step toward the target; completes the op on arrival. The stall detector
## only counts while move_forward is held (sneak pauses don't count).
func _advance(target: Vector3, tol: float, delta: float, ignore_y := false) -> void:
	var pp: Vector3 = _p.global_position
	var d := Vector2(target.x - pp.x, target.z - pp.z)
	if d.length() < tol and (ignore_y or absf(target.y - pp.y) < 1.5):
		_next()
		return
	_p.rotation.y = atan2(-d.x, -d.y)
	Input.action_press("move_forward")
	if _stall_p.distance_to(pp) > 1.0:
		_stall_p = pp
		_stall_t = 0.0
	else:
		_stall_t += delta
		if _stall_t > 2.0:
			Input.action_press("jump")  # hop over lips/steps
	if _stall_t > 10.0:
		_finish(false, "STALL to %s from %s (op %d)" % [target, pp, _op])

func _sneak(target: Vector3, tol: float, delta: float) -> void:
	_set_crouch(true)
	if _leg_t <= 0.0:
		_leg_start = _p.global_position
	_leg_t += delta
	if _leg_t > 120.0:
		_finish(false, "SNEAK TIMEOUT to %s (op %d)" % [target, _op])
		return
	if _seen_by_any():
		Input.action_release("move_forward")
		_seen_t += delta
		_stall_t = 0.0
		if _seen_t > 2.0:
			# Stared down: fall back to the leg start and retry.
			_seen_t = 0.0
			var pp: Vector3 = _p.global_position
			var b := Vector2(_leg_start.x - pp.x, _leg_start.z - pp.z)
			if b.length() > 0.8:
				_p.rotation.y = atan2(-b.x, -b.y)
				Input.action_press("move_forward")
		return
	_seen_t = 0.0
	_advance(target, tol, delta)

func _use(hold: float, delta: float) -> void:
	Input.action_release("move_forward")
	_use_t += delta
	_face(Vector3(-50, -4, 20) if _p.global_position.y < 0.0 else Vector3(-24, 12, -27))
	Input.action_press("interact")
	if _use_t >= hold:
		Input.action_release("interact")
		_next()

func _face(p: Vector3) -> void:
	var d := Vector2(p.x - _p.global_position.x, p.z - _p.global_position.z)
	if d.length() > 0.01:
		_p.rotation.y = atan2(-d.x, -d.y)

func _set_crouch(c: bool) -> void:
	if c:
		Input.action_press("crouch")
	else:
		Input.action_release("crouch")

func _next() -> void:
	_op += 1
	_t = 0.0
	_use_t = 0.0
	_stall_t = 0.0
	_seen_t = 0.0
	_leg_t = 0.0
	_stall_p = _p.global_position
	Input.action_release("move_forward")
	Input.action_release("interact")

func _fwd(g: int) -> Vector2:
	var b := (_game.guards[g] as Node3D).global_transform.basis
	return Vector2(-b.z.x, -b.z.z).normalized()

func _cond(name: String) -> bool:
	if name == "mezz_clear":
		# East mezzanine guards (12,13,14) all facing east, away from the
		# entry stair: the 2s crouched climb is safe.
		for i in [12, 13, 14]:
			if _fwd(i).x < 0.5:
				return false
		return true
	if name == "stair_gap":
		var gp: Vector3 = (_game.guards[M1] as Node3D).global_position
		return gp.z < -19.0 and _fwd(M1).y < -0.5 and _fwd(M2).x > 0.3
	if name == "g1_wb_start":
		# g1 just turned westbound at the east end: ~8s of facing away,
		# enough for the 4.5s south dash behind it.
		var gp1: Vector3 = (_game.guards[G1] as Node3D).global_position
		return gp1.x > -32.0 and _fwd(G1).x < -0.5
	return false

## Same visibility math as GuardSenses: range + cone + LOS to the chest.
func _seen_by_any() -> bool:
	var pp: Vector3 = _p.global_position
	var chest := pp + Vector3(0, 1.2, 0)
	for g in _game.guards:
		var gd := g as Guard
		if gd == null or not gd.alive:
			continue
		var to: Vector3 = pp - gd.global_position
		if Vector2(to.x, to.z).length() >= 34.0:
			continue
		var fwd := -gd.global_transform.basis.z
		if fwd.dot(to.normalized()) <= 0.8:
			continue
		var from := gd.global_position + Vector3(0, 1.6, 0)
		if gd.ray(from, chest, [_p.get_rid()]).is_empty():
			return true
	return false

func _track() -> void:
	for i in _game.guards.size():
		var gd := _game.guards[i] as Guard
		_max_detect = maxf(_max_detect, gd.detect)
		_max_state = maxi(_max_state, gd.state)
		if gd.state == Guard.State.ALERT and not _alert_log.has(i):
			_alert_log[i] = true
			var pp: Vector3 = _p.global_position
			var gp: Vector3 = gd.global_position
			print("[ghost1] ALERT g%d g@(%.1f,%.1f,%.1f) p@(%.1f,%.1f,%.1f) op=%d" % [
				i, gp.x, gp.y, gp.z, pp.x, pp.y, pp.z, _op])
	# Trace g1 vs player during the undercroft crossings.
	if _op >= 8 and _op <= 13:
		if Engine.get_physics_frames() % 60 == 0:
			var g1p: Vector3 = (_game.guards[G1] as Node3D).global_position
			var pp2: Vector3 = _p.global_position
			print("[ghost1] trace op=%d g1@(%.1f,%.1f) fwd(%.2f,%.2f) p@(%.1f,%.1f) det=%.2f" % [
				_op, g1p.x, g1p.z, _fwd(G1).x, _fwd(G1).y, pp2.x, pp2.z,
				(_game.guards[G1] as Guard).detect])
	# Trace mezzanine east guards during the climb.
	if _op >= 15 and _op <= 17:
		if Engine.get_physics_frames() % 30 == 0:
			var pp3: Vector3 = _p.global_position
			print("[ghost1] mezz op=%d p@(%.1f,%.1f,%.1f)" % [_op, pp3.x, pp3.y, pp3.z])
			for i in [12, 13, 14]:
				var gp: Vector3 = (_game.guards[i] as Node3D).global_position
				var gd := _game.guards[i] as Guard
				print("[ghost1]   g%d@(%.1f,%.1f) fwd(%.2f,%.2f) det=%.2f st=%d" % [
					i, gp.x, gp.z, _fwd(i).x, _fwd(i).y, gd.detect, gd.state])
	# Fail fast: a chase is unrecoverable for a ghost run, and the criterion
	# is zero alarms — don't burn the 120s sneak timeout after one.
	if int(_game.stats.get("alarms", 0)) > 0:
		_finish(false, "alarm raised")
		return
	if _t > 3600.0:
		_finish(false, "TIMEOUT at op %d" % _op)
	if not _reached_boardroom and _p.global_position.y > 10.0 \
			and _p.global_position.z < -24.8:
		_reached_boardroom = true
		print("[ghost1] REACHED boardroom interior")

func _finish(ok: bool, detail: String) -> void:
	_done = true
	var alarms: int = int(_game.stats.get("alarms", -1))
	var ok2: bool = ok and alarms == 0 and _reached_boardroom
	print("[ghost1] %s: %s" % ["PASS" if ok2 else "FAIL", detail])
	print("[ghost1] alarms=%d boardroom=%s max_detect=%.2f max_state=%d" % [
		alarms, _reached_boardroom, _max_detect, _max_state])
	for a in ["move_forward", "crouch", "interact"]:
		Input.action_release(a)
	get_tree().quit(0 if ok2 else 1)
