extends Node
## Segment physics for PORT VESPER: the Wizard's dash vs his jump across
## the 6.7m roof gap, the Regular crawling the 1.0m office vent, Chad
## physically blocked by it. Real kits, real physics, no mocks.
var _frame := 0
var _pf := 0
var _sframe := 0
var _phase := "boot"
var _game: GrayboxGame
var _bad := 0
var _max_x_above := -999.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _pf:
		return
	_pf = pf
	_frame += 1
	match _phase:
		"boot":
			_tick_boot()
		"dash":
			_tick_dash()
		"jump":
			_tick_jump()
		"vent":
			_tick_vent()
		"chad":
			_tick_chad()

func _new_mission(char_id: String) -> void:
	_game.selected_level = 2
	_game.selected_char = char_id
	_game.flow.start_mission()

func _teleport(pos: Vector3, yaw: float) -> void:
	_game.player.global_position = pos + Vector3(0, 0.1, 0)
	_game.player.velocity = Vector3.ZERO
	_game.player.rotation.y = yaw
	_game.player.camera.rotation.x = 0.0
	_game.player.health.grant_iframes(60.0)

func _tick_boot() -> void:
	if _frame == 1:
		_game = GrayboxGame.new()
		get_tree().root.add_child(_game)
		_new_mission("wizard")
	elif _frame == 8:
		_phase = "dash"
		_sframe = 0

## The dash (26 m/s x 0.35 s = 9.1m) must carry the Wizard from the
## platform edge across the 6.7m gap onto the office roof.
func _tick_dash() -> void:
	if _sframe == 0:
		_teleport(Vector3(-27.5, 4.5, -23), -PI / 2.0)
		Input.action_press("move_forward")
	_sframe += 1
	if _sframe == 5:
		# Real kit, real physics: invoke the Wizard's actual dash.
		_game.player.kit._dash()
	if _sframe >= 150:
		var p := _game.player.global_position
		if p.x > -20.0 and p.y > 3.0:
			print("  dash: landed on the roof at (%.1f, %.1f, %.1f)" % [p.x, p.y, p.z])
		else:
			_fail("dash ended at %s — never reached the roof" % p)
		Input.action_release("move_forward")
		_new_mission("wizard")
		_phase = "jump"
		_sframe = 0

## A plain jump (~4.74m) must fall short of the same gap: the Wizard
## never gets past the roof edge while airborne, and ends on the ground.
func _tick_jump() -> void:
	if _sframe == 0:
		_teleport(Vector3(-27.5, 4.5, -23), -PI / 2.0)
		Input.action_press("move_forward")
	_sframe += 1
	if _sframe == 5:
		Input.action_press("jump")
	elif _sframe == 7:
		Input.action_release("jump")
	var p := _game.player.global_position
	if p.y > 3.0:
		_max_x_above = maxf(_max_x_above, p.x)
	if _sframe >= 220:
		if _max_x_above < -20.3 and p.y < 2.0:
			print("  jump: fell short (furthest x %.1f airborne, ended y %.1f)" % [_max_x_above, p.y])
		else:
			_fail("jump crossed the gap: max airborne x %.1f, ended at %s" % [_max_x_above, p])
		Input.action_release("move_forward")
		Input.action_release("jump")
		_new_mission("regular")
		_phase = "vent"
		_sframe = 0

## The Regular (0.85m crouched) crawls the 1.0m vent into the office.
func _tick_vent() -> void:
	if _sframe == 0:
		_teleport(Vector3(-10, 0, -36), PI)
		Input.action_press("crouch")
		Input.action_press("move_forward")
	_sframe += 1
	if _sframe >= 300:
		var p := _game.player.global_position
		if p.z > -30.0 and p.y < 1.0:
			print("  vent: Regular crawled through to (%.1f, %.1f, %.1f)" % [p.x, p.y, p.z])
		else:
			_fail("Regular never cleared the vent (at %s)" % p)
		Input.action_release("crouch")
		Input.action_release("move_forward")
		_new_mission("chad")
		_phase = "chad"
		_sframe = 0

## Chad (1.45m crouched) is physically stopped by the 1.0m vent.
func _tick_chad() -> void:
	if _sframe == 0:
		_teleport(Vector3(-10, 0, -36), PI)
		Input.action_press("move_forward")
	_sframe += 1
	if _sframe >= 300:
		var p := _game.player.global_position
		if p.z < -33.5:
			print("  vent: Chad blocked at z %.1f" % p.z)
		else:
			_fail("Chad got through the vent to %s" % p)
		Input.action_release("move_forward")
		print("\n%d problem(s)" % _bad)
		get_tree().quit()

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)
