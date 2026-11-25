class_name ToolKick
extends Node
## V: the boot. Cruelty Squad's kick, both halves of it:
##  * a body in front of you takes DAMAGE and flies back KNOCK m/s;
##  * a wall or floor in front of you throws YOU off it — kick a wall in the
##    air for a second jump, kick the floor under you (look down) to pop up.
## A kicked launch keeps its momentum until you land (movement.keep_momentum).

const REACH := 1.9
const COOLDOWN := 0.55
const DAMAGE := 13.0     # 4 kicks: an alerted guard gets one telegraphed shot off
const KNOCK := 11.0
const LAUNCH := 9.5
const LAUNCH_UP := 4.5
const STAGGER := 0.45     # a kicked guard reels this long: no aim, no thought
const STAGGER_IMMUNE := 1.5   # ...and can't be staggered again this soon (no stun-lock)
const FLOOR_UP := 10.5    # a floor kick sets (never adds to) your rise: ~2.3m, a bit over a jump, once per airtime

var player: Player
var _cd: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player

var _air_kicked := false

func tick(delta: float) -> void:
	_cd = maxf(0.0, _cd - delta)
	if player.is_on_floor():
		_air_kicked = false
	if _cd > 0.0 or not Input.is_action_just_pressed("kick"):
		return
	_cd = COOLDOWN
	player.viewmodel.dip = 0.5
	player.look.add_recoil(-0.02)
	AudioSynth.play(player.game, "kick", -4.0, randf_range(0.95, 1.05))
	var from := player.camera.global_position
	var dir := player.aim_dir()
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * REACH)
	q.exclude = [player.get_rid()]
	q.collision_mask = VerbData.BODY_MASK
	var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		_kick_bodies(dir)
		return
	var col := hit["collider"] as Node
	if col != null and (col.is_in_group("guards") or col.is_in_group("civilians")
			or col.is_in_group("target")):
		_boot(col as Node3D, dir, hit)
		return
	# Solid: push off it.
	var n: Vector3 = hit.get("normal", -dir)
	if n.length() < 0.5:
		n = -dir
	# Set the rise, never add it: a kick on top of a jump was an 11m launch
	# (combat review). A floor (n up) gives a jump's height; a wall throws you
	# off it with a hop.
	if n.y > 0.7:
		if _air_kicked:
			return
		_air_kicked = not player.is_on_floor()
		player.velocity.y = maxf(player.velocity.y, FLOOR_UP)
	else:
		player.velocity += Vector3(n.x, 0.0, n.z).normalized() * LAUNCH
		player.velocity.y = maxf(player.velocity.y, LAUNCH_UP)
	player.movement.keep_momentum = true
	player.movement.momentum_lock = 0.25
	player.add_shake(0.25)
	AudioSynth.play(player.game, "kick_wall", -2.0, randf_range(0.9, 1.1))

## Nothing under the crosshair: still boot whoever is right in front of you.
func _kick_bodies(dir: Vector3) -> void:
	for b in player.kit._melee_targets(REACH + 0.4, 0.55):
		_boot(b as Node3D, dir, {})
		return

func _boot(body: Node3D, dir: Vector3, hit: Dictionary) -> void:
	if hit.is_empty():
		body.call("take_damage", DAMAGE, player.global_position)
	else:
		body.call("take_hit", DAMAGE, player.global_position, hit)
	if body.has_method("apply_knockback"):
		var flat := Vector3(dir.x, 0.0, dir.z).normalized()
		body.call("apply_knockback", flat * KNOCK + Vector3.UP * 3.0)
	if "stagger" in body and float(body.get("stagger")) > -STAGGER_IMMUNE:
		pass   # still reeling or just recovered: no stun-lock
	elif "stagger" in body:
		body.set("stagger", STAGGER)
		if body.get("combat") != null:
			body.get("combat").call("reset_cooldown", 0.2)
	player.add_shake(0.35)
	player.game.hud.show_hitmarker()
	AudioSynth.play(player.game, "kick_hit", 0.0, randf_range(0.9, 1.1))
	player.game.emit_noise(player.global_position, 8.0)
