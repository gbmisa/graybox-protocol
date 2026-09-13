extends Node
## P1 (fireball vs walls) + P6 (headshot multiplier) headless test.
## A guard is pinned 8m from a muzzle; phases:
##   1. wall between muzzle and guard -> bolt must die on the wall,
##      guard unharmed
##   2. wall gone -> clear shot -> guard takes 1x body damage (35)
##   3. caster body (player-grouped, RID-excluded) in the lane -> bolt
##      ignores the caster, guard still takes 1x
##   4. aimed at the head -> 2x damage (guard dies: 50 - 70)
## Plus instant hitscan shape-index checks: a head-aimed ray must report the
## head shape, a torso-aimed ray must not.

var _frame := 0
var _pf := 0
var _game: GrayboxGame
var _bad := 0
var _g: Guard
var _pins := {}
var _spot := Vector3.ZERO
var _hp0 := 50.0
var _wall: StaticBody3D
var _caster: StaticBody3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _pf:
		return
	_pf = pf
	_frame += 1
	_pin_guards()
	match _frame:
		1:
			_setup_game()
		8:
			_setup_scene()
		9:
			_check(_projectiles().size() == 1, "P1 bolt in flight", "P1: bolt never left the muzzle")
		83:
			_check_phase1()
		84:
			_reset_guard()
			_fire(1.0, [])
		159:
			_check_phase2()
		160:
			_reset_guard()
			_build_caster()
			_fire(1.5, [_caster.get_rid()])
		235:
			_check_phase3()
		236:
			_reset_guard()
			_fire(1.95, [])
		270:
			_check_early_death()
		311:
			_check(_projectiles().is_empty(), "P4 bolt resolved", "P4: bolt still flying")
			print("\n%d problem(s)" % _bad)
			get_tree().quit()

# ------------------------------------------------------------------ setup --
func _setup_game() -> void:
	_game = GrayboxGame.new()
	get_tree().root.add_child(_game)
	_game.selected_level = 2
	_game.selected_char = "regular"
	_game.flow.start_mission()

func _setup_scene() -> void:
	if _game.guards.is_empty():
		_fail("no guards in level 2")
		return
	_g = _game.guards[0]
	_spot = _g.global_position
	_hp0 = _g.hp
	for g in _game.guards:
		if g == _g:
			_pins[g] = _spot
		else:
			# Park everyone else far from the blast so splash can't kill them
			# (a freed guard would poison the pin table).
			var far := _spot + Vector3(120, 0, 120)
			(g as Guard).global_position = far
			_pins[g] = far
	_wall = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 3.0, 5.0)
	cs.shape = box
	_wall.add_child(cs)
	_wall.position = Vector3(_spot.x + 2.0, _spot.y + 1.5, _spot.z)
	_game.add_child(_wall)
	# Sanity: the test wall must actually block the lane.
	var space := _game.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(_spot.x + 8, _spot.y + 1.5, _spot.z),
		_spot + Vector3(0, 1.0, 0))
	q.exclude = [_g.get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty() or hit["collider"] != _wall:
		_fail("test wall does not block the firing lane")
		return
	_fire(1.5, [])

func _build_caster() -> void:
	_caster = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.5
	cs.shape = sph
	_caster.add_child(cs)
	_caster.position = Vector3(_spot.x + 4.0, _spot.y + 1.5, _spot.z)
	_caster.add_to_group("player")  # same dodge the real caster gets
	_game.add_child(_caster)

func _pin_guards() -> void:
	for g in _pins.keys():
		if not is_instance_valid(g):
			continue
		var gd := g as Guard
		if gd != null and gd.alive:
			gd.global_position = _pins[g]

## Flat fireball from 8m out at `aim_y` above the guard's feet, no gravity.
func _fire(aim_y: float, exclude: Array) -> void:
	var from := Vector3(_spot.x + 8.0, _spot.y + aim_y, _spot.z)
	var pr := Projectile.create(_game, from, Vector3(-1, 0, 0),
		22.0, 0.0, 35.0, 3.2, Color(1.0, 0.45, 0.1), exclude)
	_game.add_child(pr)

func _projectiles() -> Array:
	var out := []
	for c in _game.get_children():
		if c is Projectile:
			out.append(c)
	return out

func _reset_guard() -> void:
	# _die() zeroes the collision layers, so a revive must restore them or
	# later bolts fly straight through.
	_g.hp = _hp0
	_g.alive = true
	_g.collision_layer = 1
	_g.collision_mask = 1

# ----------------------------------------------------------------- phases --
func _check_phase1() -> void:
	_check(_projectiles().is_empty(), "P1 bolt died on the wall", "P1: bolt survived the wall")
	_check(_g.hp == _hp0, "P1 guard unharmed behind the wall",
		"P1: guard hurt through the wall (hp %.1f)" % _g.hp)
	_wall.queue_free()

func _check_phase2() -> void:
	_check(_projectiles().is_empty(), "P2 bolt resolved", "P2: bolt still flying")
	_check(_g.hp == _hp0 - 35.0, "P2 clear shot dealt 1x body damage (35)",
		"P2: clear shot dealt %.1f, expected 35" % (_hp0 - _g.hp))
	_check_shapes()

func _check_phase3() -> void:
	_check(_projectiles().is_empty(), "P3 bolt resolved", "P3: bolt still flying")
	_check(_g.hp == _hp0 - 35.0, "P3 bolt ignored the caster, guard took 1x",
		"P3: shot past the caster dealt %.1f, expected 35" % (_hp0 - _g.hp))
	_caster.queue_free()

## ~0.5s after the headshot: the guard must be freshly dead at exactly 2x.
func _check_early_death() -> void:
	if not is_instance_valid(_g):
		_fail("P4: guard freed before its hp could be read")
		return
	_check(not _g.alive, "P4 headshot killed the guard", "P4: headshot did not kill the guard")
	_check(_g.hp == _hp0 - 70.0, "P4 headshot dealt 2x damage (70)",
		"P4: headshot dealt %.1f, expected 70 (2x)" % (_hp0 - _g.hp))

## Hitscan wiring: the shape index physics reports must resolve to the head
## shape on a head-aimed ray and to the body on a torso-aimed ray.
func _check_shapes() -> void:
	var space := _game.get_world_3d().direct_space_state
	var qh := PhysicsRayQueryParameters3D.create(
		Vector3(_spot.x + 8, _spot.y + 1.95, _spot.z),
		Vector3(_spot.x - 2, _spot.y + 1.95, _spot.z))
	var hh := space.intersect_ray(qh)
	if hh.is_empty():
		_fail("P6: head-aimed ray hit nothing")
	else:
		var hc := hh["collider"] as Node
		if hc == null or not hc.is_in_group("guards"):
			_fail("P6: head-aimed ray hit %s, not the guard" % hc)
		elif not _g.is_head_shape(int(hh.get("shape", -1))):
			_fail("P6: head-aimed ray did not report the head shape")
	var qb := PhysicsRayQueryParameters3D.create(
		Vector3(_spot.x + 8, _spot.y + 1.0, _spot.z),
		Vector3(_spot.x - 2, _spot.y + 1.0, _spot.z))
	var hb := space.intersect_ray(qb)
	if hb.is_empty():
		_fail("P6: torso-aimed ray hit nothing")
	elif _g.is_head_shape(int(hb.get("shape", -1))):
		_fail("P6: torso-aimed ray wrongly reported the head shape")

# ----------------------------------------------------------------- report --
func _check(ok: bool, ok_label: String, fail_msg: String) -> void:
	if ok:
		print("  ok: %s" % ok_label)
	else:
		_fail(fail_msg)

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)
