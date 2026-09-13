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
var last_seen: Vector3 = Vector3.ZERO
var investigate_pos: Vector3 = Vector3.ZERO
var knockback_vel: Vector3 = Vector3.ZERO

var body: GuardBody
var senses: GuardSenses
var brain: GuardBrain
var combat: GuardCombat

func setup(p_waypoints: Array, p_game: GrayboxGame) -> void:
	waypoints = p_waypoints
	game = p_game
	if waypoints.size() > 0:
		global_position = waypoints[0]
	add_to_group("guards")

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
	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 30.0 * delta)
	move_and_slide()

# ---------------------------------------------------------- external API ---
func hear_noise(pos: Vector3) -> void:
	if not alive or state == State.ALERT:
		return
	enter_suspicious(pos, maxf(detect, 0.5))

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
	game.alarm()
	AudioSynth.play(self, "alarm")

func enter_suspicious(pos: Vector3, meter: float) -> void:
	state = State.SUSPICIOUS
	investigate_pos = pos
	detect = meter
	brain.on_enter_suspicious()
	body.set_indicator("?", Color.YELLOW)

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
	return get_world_3d().direct_space_state.intersect_ray(q)
