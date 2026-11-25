class_name ToolGrapple
extends Node
## Q: the grappling hook (Cruelty Squad's grappendix, "to a lesser extent
## Spider-Man's webs" — Gregory). Hold Q at any solid surface within RANGE:
## the hook bites and you hang on a rope that reels in at REEL m/s. You swing
## as a pendulum round the anchor; let go (or jump) and you keep the momentum.
## No marked anchor points, CS-style: anything static.
##
## The rope is a constraint applied after normal movement (`post_move`), so
## gravity and air steering still act and the rope only removes the outward
## part of the velocity.
##
## r9 (Gregory: "the grapple should be versatile and even allow the player to
## fall off the side of the map if they're not careful. Incorporate it as a
## route tool"): no surface refuses the hook any more (NO_GRAPPLE is empty,
## the anti-climb paint is gone), so the boundary walls bite too — swing over
## one and you fall past the world (PlayerHealth KILL_Y). And ("grapple does
## nothing to civilians or guards") hooking a person yanks them to your feet:
## a guard reels (stagger) and knows exactly who did it.

const RANGE := 40.0
const YANK_DECEL := 30.0      # Guard/Civilian knockback decay (m/s^2)
const YANK_MAX := 22.0
const YANK_STAGGER := 0.9
## Ledges: hook a wall face within LEDGE_REACH of its top and the anchor moves
## onto the lip; reeled in close, you're hauled up and over (LEDGE_POP m/s).
const LEDGE_REACH := 2.0
const LEDGE_HAUL := 2.4
const LEDGE_POP := 14.0    # ~4m of rise at PLAYER_GRAVITY 24: clears the lip from LEDGE_HAUL below
const REEL := 7.0
const MIN_LEN := 2.0
const RELEASE_BOOST := 2.5
const PULL := 26.0
const MAX_SPEED := 18.0

## Boxes the hook slides off (set by the level: MissionCompoundData.NO_GRAPPLE).
static var no_anchor: Array = []

var player: Player
var anchor := Vector3.INF
var ledge := false
var _len: float = 0.0
var _rope: MeshInstance3D
var _mesh: ImmediateMesh
var _flash_to := Vector3.ZERO   # a yank's rope, shown for a moment
var _flash_t: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player
	_mesh = ImmediateMesh.new()
	_rope = MeshInstance3D.new()
	_rope.mesh = _mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.15, 0.25)
	_rope.material_override = m
	_rope.top_level = true
	player.add_child(_rope)

func hooked() -> bool:
	return anchor != Vector3.INF

func tick(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_mesh.clear_surfaces()
		else:
			_line(_flash_to)
	if Input.is_action_just_pressed("grapple"):
		_fire()
	elif hooked() and (not Input.is_action_pressed("grapple")
			or Input.is_action_just_pressed("jump")):
		release()

func _fire() -> void:
	var from := player.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + player.aim_dir() * RANGE)
	q.exclude = [player.get_rid()]
	q.collision_mask = VerbData.SHOT_MASK
	var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
	AudioSynth.play(player.game, "grapple_fire", -4.0)
	if hit.is_empty():
		return
	var col := hit["collider"] as Node
	if col is CharacterBody3D:
		if col.has_method("apply_knockback") and bool(col.get("alive")):
			_yank(col as Node3D, hit["position"])
		return
	for box in no_anchor:
		if (box as AABB).has_point(hit["position"]):
			AudioSynth.play(player.game, "clack", -2.0, 0.8)
			player.game.hud.show_message("NO GRIP", 0.8)
			return
	anchor = hit["position"]
	ledge = _find_lip(hit)
	_len = maxf(MIN_LEN, from.distance_to(anchor))
	player.movement.keep_momentum = true
	AudioSynth.play(player.game, "grapple_hit", -2.0)

## A wall face hit: is there a standable top within LEDGE_REACH above? Then
## that's the anchor (in `anchor`), and true.
func _find_lip(hit: Dictionary) -> bool:
	var n: Vector3 = hit["normal"]
	if absf(n.y) > 0.3:
		return false
	var inside: Vector3 = hit["position"] - n * 0.3
	var q := PhysicsRayQueryParameters3D.create(inside + Vector3.UP * LEDGE_REACH, inside)
	q.exclude = [player.get_rid()]
	q.collision_mask = 1
	var top := player.get_world_3d().direct_space_state.intersect_ray(q)
	if top.is_empty() or (top["normal"] as Vector3).y < 0.7:
		return false
	anchor = top["position"]
	return true

## Pull a person in: a flat shove toward you sized to stop ~1.5m short.
func _yank(body: Node3D, at: Vector3) -> void:
	var to := player.global_position - body.global_position
	to.y = 0.0
	var d := to.length()
	var speed := minf(YANK_MAX, sqrt(2.0 * YANK_DECEL * maxf(0.0, d - 1.5)))
	body.call("apply_knockback", to.normalized() * speed)
	_flash_to = at
	_flash_t = 0.15
	AudioSynth.play(player.game, "grapple_hit", -2.0, 1.3)
	player.game.hud.show_hitmarker()
	if body is Guard:
		var g := body as Guard
		if g.stagger <= -ToolKick.STAGGER_IMMUNE:
			g.stagger = YANK_STAGGER
			g.combat.reset_cooldown(0.3)
		g.last_seen = player.global_position
		g.detect = 1.0
		if g.state != Guard.State.ALERT:
			g.enter_alert()
	elif body.has_method("panic"):
		body.call("panic", player.global_position)

func release() -> void:
	if not hooked():
		return
	anchor = Vector3.INF
	player.velocity += player.velocity.normalized() * RELEASE_BOOST + Vector3.UP * 1.5
	_mesh.clear_surfaces()
	AudioSynth.play(player.game, "grapple_release", -8.0)

## The rope: reel in, and never let the body drift past the rope's length.
func post_move(delta: float) -> void:
	if not hooked():
		return
	_len = maxf(MIN_LEN, _len - REEL * delta)
	var hand := player.global_position + Vector3(0, 1.3, 0)
	var off := hand - anchor
	var d := off.length()
	if ledge and d < LEDGE_HAUL:
		var flat := Vector3(-off.x, 0.0, -off.z).normalized()
		player.velocity = flat * 4.0 + Vector3.UP * LEDGE_POP
		anchor = Vector3.INF
		ledge = false
		_mesh.clear_surfaces()
		AudioSynth.play(player.game, "grapple_release", -8.0)
		return
	player.velocity -= off / maxf(d, 0.01) * PULL * delta
	if player.is_on_floor() and player.velocity.y < 3.0:
		player.velocity.y = 3.0   # unstick from the ground: the yank lifts you
	player.movement.momentum_lock = 0.1
	if d > _len:
		var n := off / d
		var outward := player.velocity.dot(n)
		if outward > 0.0:
			player.velocity -= n * outward
		# Pull back onto the sphere, gently, so a snag never teleports you.
		player.velocity -= n * minf(d - _len, 1.0) * 8.0
	if player.velocity.length() > MAX_SPEED:
		player.velocity = player.velocity.normalized() * MAX_SPEED
	player.movement.keep_momentum = true
	_draw(hand)

func _line(to: Vector3) -> void:
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var from := player.camera.global_position + player.camera.global_basis * Vector3(0.25, -0.25, -0.3)
	_mesh.surface_add_vertex(from)
	_mesh.surface_add_vertex(to)
	_mesh.surface_end()

func _draw(hand: Vector3) -> void:
	_line(anchor)
	if hand.distance_to(anchor) < MIN_LEN + 0.3 and player.is_on_floor():
		release()
