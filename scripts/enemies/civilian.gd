class_name Civilian
extends CharacterBody3D
## A bystander. Unarmed and killable with no penalty (Cruelty Squad does not
## score the dead) — the point is the crowd: they wander, and when anything
## loud happens they scream and scatter, and the panic spreads from person to
## person. A fleeing civilian is noise, cover and a thing in guards' way.
##
## Same damage API as Guard/Target (take_hit / take_damage / apply_knockback),
## so every weapon (and the hook) already works on them.

signal died(c: Civilian)

enum State { WANDER, PANIC }

const WALK_SPEED := 1.3
const RUN_SPEED := 5.0
const PANIC_TIME := 14.0
const CONTAGION_RADIUS := 9.0
const FLEE_DIST := 22.0

const PANIC_LINES := [
	"AAAAH!", "IS THIS SCORED?!", "I HAVE A GRATITUDE STREAK!", "NOT THE AUDIT!",
	"TELL HR I WAS COMPLIANT!", "I JUST GOT HERE!", "MY LANYARD!", "SOMEONE THANK SOMEONE!",
	"RUN! RUN! RUN!", "I'M NOT CONSENTING TO THIS!",
]
const IDLE_LINES := [
	"Is it Thursday?", "...", "I'd like to be thanked.", "Do you have a minute?",
	"My score dipped.", "Don't look at the billboard.",]

var alive: bool = true
var hp: float = 30.0
var state: int = State.WANDER
var game: GrayboxGame = null
var waypoints: Array = []
var knockback_vel: Vector3 = Vector3.ZERO

var _figure: Humanoid
var _head_col: CollisionShape3D
var _label: Label3D
var _label_t: float = 0.0
var _wp: int = 0
var _wait: float = 0.0
var _panic_t: float = 0.0
var _flee_to: Vector3 = Vector3.INF
var _threat: Vector3 = Vector3.ZERO
var _scream_t: float = 0.0
var _walker := NavWalker.new()
var _speed_mul: float = 1.0

func setup(p_waypoints: Array, p_game: GrayboxGame, seed_value: int = 0) -> void:
	waypoints = p_waypoints
	game = p_game
	add_to_group("civilians")
	collision_mask = VerbData.BODY_MASK
	if waypoints.size() > 0:
		global_position = waypoints[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else randi()
	var style := Humanoid.random_style(rng)
	_speed_mul = rng.randf_range(0.85, 1.2)
	_figure = Humanoid.create(self, style)
	var sc := float(style["scale"])
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	_head_col = CollisionShape3D.new()
	var hb := BoxShape3D.new()
	hb.size = Vector3(0.36, 0.32, 0.32)
	_head_col.shape = hb
	_head_col.position = Vector3(0, 1.95 * sc, 0)
	add_child(_head_col)
	_label = Label3D.new()
	_label.position = Vector3(0, 2.6, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.006
	_label.font_size = 44
	_label.outline_size = 10
	_label.modulate = Color(1.0, 0.95, 0.6)
	_label.visible = false
	add_child(_label)
	_wait = rng.randf_range(0.0, 3.0)

# ------------------------------------------------------------------ loop ---
func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	if alive and game != null and game.is_playing() and knockback_vel.length() < 2.0:   # r9: not mid-throw
		if state == State.PANIC:
			_panic(delta)
		else:
			_wander(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if _label_t > 0.0:
		_label_t -= delta
		if _label_t <= 0.0:
			_label.visible = false
	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 30.0 * delta)
	move_and_slide()
	_figure.animate(Vector2(velocity.x, velocity.z).length(), delta)

func _wander(delta: float) -> void:
	if waypoints.size() < 2:
		_stop()
		_wait -= delta
		if _wait <= 0.0:
			_wait = randf_range(8.0, 20.0)
			if randf() < 0.4:
				say(IDLE_LINES[randi() % IDLE_LINES.size()], 2.5)
		return
	var wp: Vector3 = waypoints[_wp]
	var to := wp - global_position
	to.y = 0.0
	if to.length() > 0.8:
		_move(wp, WALK_SPEED * _speed_mul, delta)
		return
	_stop()
	_wait += delta
	if _wait >= 2.0:
		_wait = 0.0
		_wp = (_wp + 1) % waypoints.size()

func _panic(delta: float) -> void:
	_panic_t -= delta
	_scream_t -= delta
	if _scream_t <= 0.0:
		_scream_t = randf_range(1.5, 3.5)
		say(PANIC_LINES[randi() % PANIC_LINES.size()], 2.0)
	if _panic_t <= 0.0:
		state = State.WANDER
		_figure.set_panic(false)
		_flee_to = Vector3.INF
		_wait = 0.0
		return
	if _flee_to == Vector3.INF or global_position.distance_to(_flee_to) < 1.5:
		_flee_to = _pick_flee_point()
	_move(_flee_to, RUN_SPEED * _speed_mul, delta)
	# Panic is contagious: running people spook the people they pass.
	if Engine.get_physics_frames() % 20 == 0:
		for n in get_tree().get_nodes_in_group("civilians"):
			var c := n as Civilian
			if c != null and c != self and c.alive and c.state == State.WANDER \
					and c.global_position.distance_to(global_position) < CONTAGION_RADIUS:
				c.panic(_threat)

## Somewhere away from the threat that is actually walkable.
func _pick_flee_point() -> Vector3:
	var away := global_position - _threat
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
	away = away.normalized()
	var best := global_position
	var best_score := -INF
	var map := get_world_3d().navigation_map
	for i in 6:
		var dir := away.rotated(Vector3.UP, randf_range(-1.3, 1.3))
		var cand := global_position + dir * randf_range(FLEE_DIST * 0.5, FLEE_DIST)
		if GuardNav.ready_map and NavigationServer3D.map_get_iteration_id(map) != 0:
			cand = NavigationServer3D.map_get_closest_point(map, cand)
			# Don't run to a different floor or into a pit.
			if absf(cand.y - global_position.y) > 2.5:
				continue
		var score := cand.distance_to(_threat) + randf() * 4.0
		if score > best_score:
			best_score = score
			best = cand
	return best

# --------------------------------------------------------------- helpers ---
func _move(target: Vector3, speed: float, delta: float) -> void:
	var step := _walker.step(self, target, delta)
	var dir := step - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		_stop()
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)

func _stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func say(text: String, secs: float = 2.0) -> void:
	_label.text = text
	_label.visible = true
	_label_t = secs

# ---------------------------------------------------------- external API ---
## Something frightening happened at `pos`.
func panic(pos: Vector3) -> void:
	if not alive:
		return
	if state == State.WANDER:
		say(PANIC_LINES[randi() % PANIC_LINES.size()], 2.0)
		_scream_t = randf_range(1.5, 3.0)
		_figure.set_panic(true)
	state = State.PANIC
	_threat = pos
	_panic_t = PANIC_TIME
	_flee_to = Vector3.INF

func take_hit(dmg: float, from_pos: Vector3, hit: Dictionary) -> void:
	var idx := int(hit.get("shape", -1))
	if idx >= 0 and shape_owner_get_owner(shape_find_owner(idx)) == _head_col:
		dmg *= float(GuardData.stats()["headshot_mul"])
	take_damage(dmg, from_pos)

func take_damage(dmg: float, from_pos: Vector3) -> void:
	if not alive:
		return
	hp -= dmg
	_figure.flash(self)
	var parent := get_parent() as Node3D
	Gore.burst(parent, global_position + Vector3(0, 1.4, 0), from_pos, 8)
	game.panic_civilians(global_position, 18.0)
	panic(from_pos)
	if hp <= 0.0:
		_die()

func apply_knockback(impulse: Vector3) -> void:
	knockback_vel += impulse

func _die() -> void:
	alive = false
	died.emit(self)
	game.on_civilian_killed(self)
	collision_layer = 0
	collision_mask = 0
	_label.visible = false
	var parent := get_parent() as Node3D
	Gore.burst(parent, global_position + Vector3(0, 1.2, 0),
		global_position - Vector3(0, 0.3, 0), 26)
	Gore.stain(parent, global_position, 1.3)
	_figure.die()
	add_to_group("corpses")
	set_physics_process(false)
