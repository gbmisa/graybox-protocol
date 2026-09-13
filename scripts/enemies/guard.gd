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

## Headshot damage multiplier: hits landing on the head shape deal double.
const HEADSHOT_MULT := 2.0

var state: int = State.PATROL
var detect: float = 0.0          # 0..1, read by the HUD
var alive: bool = true
var hp: float = 50.0
## Shape index of the "HeadShape" CollisionShape3D within this body's shapes.
## Set by GuardBody at build time; -1 until then.
var head_shape_index: int = -1

var game: GrayboxGame = null
var waypoints: Array = []
var last_seen: Vector3 = Vector3.ZERO
var investigate_pos: Vector3 = Vector3.ZERO
var knockback_vel: Vector3 = Vector3.ZERO
## Noise radius of the blow that is currently hurting this guard. Read at
## death: a kill counts as loud when this meets the consequence data's
## loud_kill_noise threshold.
var kill_noise: float = 0.0
## Set by the alarm director: this guard is running for an alarm panel.
## While set, the brain ignores the player and moves for the panel.
var is_runner: bool = false
var runner_panel: AlarmPanel = null

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

func take_damage(dmg: float, from_pos: Vector3, noise: float = 0.0) -> void:
	if not alive:
		return
	hp -= dmg
	kill_noise = noise
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
## `propagate` lets the alarm director's callout skip the re-broadcast, so a
## called-out guard joins the ALERT without chain-alerting the whole map.
## Only the originating guard plays the alert cue: the callout already flips
## every guard in the shout radius on the same frame, and N identical
## one-shots stacking is the loudness spike.
func enter_alert(propagate: bool = true) -> void:
	if not alive:
		return
	state = State.ALERT
	brain.on_enter_alert()
	body.set_indicator("!", Color.RED)
	game.on_guard_alerted(self, propagate)
	if propagate:
		AudioSynth.play(self, "alarm")

## True when the killing blow came from a loud ability (see consequence data).
func loud_kill() -> bool:
	return kill_noise >= float(ConsequenceData.alarm()["loud_kill_noise"])

func enter_suspicious(pos: Vector3, meter: float) -> void:
	state = State.SUSPICIOUS
	investigate_pos = pos
	detect = meter
	brain.on_enter_suspicious()
	body.set_indicator("?", Color.YELLOW)

func enter_patrol() -> void:
	state = State.PATROL
	is_runner = false
	runner_panel = null
	body.set_indicator("", Color.YELLOW)

## Alarm-director assignment: break off whatever the guard was doing and run
## for the panel. The brain drives the movement; arrival trips lockdown.
func start_run(panel: AlarmPanel) -> void:
	is_runner = true
	runner_panel = panel
	body.set_indicator("R", Color.ORANGE)

## Back to a normal alerted guard (lockdown tripped, or the run aborted).
func clear_run() -> void:
	is_runner = false
	runner_panel = null
	if state == State.ALERT:
		body.set_indicator("!", Color.RED)

func _die() -> void:
	alive = false
	died.emit(self)
	game.on_guard_killed(self)
	collision_layer = 0
	collision_mask = 0
	body.play_death()

# ---------------------------------------------------------------- helpers ---
## True when a physics `hit["shape"]` index reported against this body is the
## head hitbox. Hitscan and projectile code branch on this for headshots.
func is_head_shape(shape_idx: int) -> bool:
	return head_shape_index >= 0 and shape_idx == head_shape_index

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
