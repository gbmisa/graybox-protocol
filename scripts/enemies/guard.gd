class_name Guard
extends CharacterBody3D
## Enemy guard. This root owns the shared state the components read and write
## (state, detection meter, last known player position) and drives them in
## order; the behaviour itself lives in the components.
##
##   body     meshes, collision, state indicator, hit flash, death
##   senses   vision cone, line of sight, detection meter
##   brain    patrol -> suspicious -> alert movement
##   combat   hitscan pistol with spread
##
## The AI stays deliberately dumb: no flanking, no squad coordination. The
## complexity budget goes to character kits and level routing instead.

signal died(g: Guard)

enum State { PATROL, SUSPICIOUS, ALERT }

var state: int = State.PATROL
var detect: float = 0.0          # 0..1, read by the HUD
var alive: bool = true
var hp: float = 50.0

var game: GrayboxGame = null
var waypoints: Array = []
## Post options (guard_posts): a sentry's yaw, per-waypoint waits, and whether
## the route is walked once and held (an escort, a reinforcement) or looped.
var post_id: String = ""
var has_facing: bool = false
var facing: float = 0.0
var waits: Array = []
var one_way: bool = false
var last_seen: Vector3 = Vector3.ZERO
var investigate_pos: Vector3 = Vector3.ZERO
var knockback_vel: Vector3 = Vector3.ZERO

var body: GuardBody
var senses: GuardSenses
var brain: GuardBrain
var combat: GuardCombat

func setup(p_waypoints: Array, p_game: GrayboxGame, opts: Dictionary = {}) -> void:
	waypoints = p_waypoints
	game = p_game
	post_id = String(opts.get("id", ""))
	has_facing = opts.has("facing")
	facing = float(opts.get("facing", 0.0))
	waits = opts.get("waits", []) as Array
	one_way = bool(opts.get("one_way", false))
	if waypoints.size() > 0:
		global_position = waypoints[0]
	if has_facing:
		rotation.y = facing
	add_to_group("guards")
	collision_mask = VerbData.BODY_MASK

## Pause at waypoint `i` before moving on; 1.0s unless the post says.
func wait_at(i: int) -> float:
	return float(waits[i]) if i < waits.size() else 1.0

## Hand the guard a new route mid-mission — the panic-room escort.
func set_route(points: Array, p_one_way: bool, yaw: float) -> void:
	waypoints = points
	one_way = p_one_way
	has_facing = true
	facing = yaw
	brain.reset_route()
	enter_patrol()

func _ready() -> void:
	hp = float(GuardData.stats()["hp"])
	body = GuardBody.new()
	senses = GuardSenses.new()
	brain = GuardBrain.new()
	combat = GuardCombat.new()
	for c in [body, senses, brain, combat]:
		add_child(c)
		c.setup(self)

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	if not alive or game == null or not game.is_playing():
		move_and_slide()
		return
	var player := game.get_player()
	if player != null and player.alive:
		senses.tick(player, delta)
	brain.tick(player, delta)
	body.tick(delta)
	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 30.0 * delta)
	move_and_slide()

# ---------------------------------------------------------- external API ---
func hear_noise(pos: Vector3) -> void:
	if not alive or state == State.ALERT:
		return
	enter_suspicious(pos, maxf(detect, 0.5))

## A hitscan hit, with the collider shape it struck: the head takes
## `headshot_mul`. Area damage (fireball, meteor, slam) uses take_damage.
func take_hit(dmg: float, from_pos: Vector3, hit: Dictionary) -> void:
	if is_head_shape(int(hit.get("shape", -1))):
		dmg *= float(GuardData.stats()["headshot_mul"])
	take_damage(dmg, from_pos)

func is_head_shape(shape_idx: int) -> bool:
	if shape_idx < 0 or body == null or body.head_col == null:
		return false
	return shape_owner_get_owner(shape_find_owner(shape_idx)) == body.head_col

func take_damage(dmg: float, from_pos: Vector3) -> void:
	if not alive:
		return
	hp -= dmg
	body.flash_hit()
	if hp <= 0.0:
		_die()
		return
	# Being shot is its own alert: the guard knows where it came from.
	last_seen = from_pos
	detect = 1.0
	if state != State.ALERT:
		enter_alert()

func apply_knockback(impulse: Vector3) -> void:
	knockback_vel += impulse

# ------------------------------------------------------- state transitions ---
func enter_alert() -> void:
	state = State.ALERT
	brain.on_enter_alert()
	body.set_indicator("!", Color.RED)
	bark("alert")
	game.alarm()
	AudioSynth.play(self, "alarm")

func enter_suspicious(pos: Vector3, meter: float) -> void:
	if state != State.SUSPICIOUS and randf() < 0.6:
		bark("suspicious")
	state = State.SUSPICIOUS
	investigate_pos = pos
	detect = meter
	brain.on_enter_suspicious()
	body.set_indicator("?", Color.YELLOW)

## A random line of the given kind from this level's bark table, if any.
func bark(kind: String) -> void:
	var lines: Array = game.barks(kind) if game != null else []
	if not lines.is_empty():
		body.say(String(lines[randi() % lines.size()]))

func enter_patrol() -> void:
	state = State.PATROL
	body.set_indicator("", Color.YELLOW)

func _die() -> void:
	alive = false
	died.emit(self)
	game.on_guard_killed(self)
	collision_layer = 0
	collision_mask = 0
	body.play_death()

# ---------------------------------------------------------------- helpers ---
## Walk toward a point and face the direction of travel.
func move_to(target: Vector3, speed: float, delta: float) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		stop()
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	face(atan2(-dir.x, -dir.z), delta)

func stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func face(yaw: float, delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, yaw, 8.0 * delta)

## Line-of-sight helper. Pass the target's RID in `also_exclude` when asking
## "is anything BETWEEN us" — otherwise the ray ends inside the target's own
## capsule, reports a hit, and every sight check fails.
func ray(from: Vector3, to: Vector3, also_exclude: Array = []) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()] + also_exclude
	# Shot mask: guards see and shoot through the barred window's rods.
	q.collision_mask = VerbData.SHOT_MASK
	return get_world_3d().direct_space_state.intersect_ray(q)
