class_name GuardCombat
extends Node
## Guard gunplay: a telegraphed hitscan pistol with random spread.
##
## Shots are NOT instant. On acquiring a target the guard enters a visible aim
## state for `aim_time` and only then fires. That window is the player's read:
## at 22 damage with no health regeneration, a shot you cannot see coming is
## just an unannounced chunk of your health bar, and the Wizard's 0.25s dodge
## has nothing to be timed against. The wind-up is deliberately about twice the
## i-frame window so a well-timed dash beats it and a panicked one does not.
##
## Guard fire also never calls game.emit_noise — one alerted guard would
## cascade an alert through the whole building through gunfire alone.

var guard: Guard
var shoot_cd: float = 0.0
var aiming: float = 0.0
var shots: int = 0     # counted for tools/combat_probe.gd
var hits: int = 0
## r8 (combat review): the aim is only ever finished, never resumed. Any frame
## the brain doesn't tick us mid-aim drops it (`_physics_process`), and the
## last LOCK_TIME of the wind-up the aim point is fixed — a sidestep then
## beats the shot, the way the telegraph promises.
const LOCK_TIME := 0.15
var _ticked: int = -1
var _locked := Vector3.INF

func _physics_process(_delta: float) -> void:
	if not guard.alive:
		aiming = 0.0
		return
	if aiming > 0.0 and Engine.get_physics_frames() - _ticked > 1:
		cancel_aim()

func cancel_aim() -> void:
	if aiming > 0.0:
		aiming = 0.0
		if guard.alive:   # a dead man's "!" must stay down (combat review r2)
			guard.body.set_aiming(false)
	_locked = Vector3.INF

func setup(p_guard: Guard) -> void:
	guard = p_guard

## Called by the brain while alerted and within range.
func tick(player: Player, delta: float, dist: float) -> void:
	_ticked = Engine.get_physics_frames()
	var gs := GuardData.stats()
	if aiming > 0.0:
		_tick_aim(player, delta, gs)
		return
	shoot_cd = maxf(0.0, shoot_cd - delta)
	if shoot_cd > 0.0 or dist >= float(gs["gun_range"]) * 0.8:
		return
	if not _has_los(player):
		return
	aiming = float(gs["aim_time"])
	guard.body.set_aiming(true)
	AudioSynth.play_at(guard, "aim", -6.0)

func _tick_aim(player: Player, delta: float, gs: Dictionary) -> void:
	aiming -= delta
	if not _has_los(player):
		cancel_aim()
		shoot_cd = 0.2
		return
	if aiming <= LOCK_TIME and _locked == Vector3.INF:
		# Lead the lock: a steady strafe is hit; reversing, stopping or
		# ducking into cover while the tell shows is what dodges it.
		_locked = _target_point(player) + Vector3(player.velocity.x, 0, player.velocity.z) * LOCK_TIME
	if aiming > 0.0:
		return
	guard.body.set_aiming(false)
	shoot_cd = float(gs["gun_cooldown"])
	_shoot(player, gs)
	_locked = Vector3.INF

func reset_cooldown(delay: float) -> void:
	shoot_cd = delay
	cancel_aim()

## Centre of the player's capsule as it is now — crouched included. (Aiming
## at a fixed 1.2m made a crouched 0.85m player immune.)
func _target_point(player: Player) -> Vector3:
	var cap := player.collider.shape as CapsuleShape3D
	var h := cap.height if cap != null else 1.8
	return player.global_position + Vector3(0, h * 0.6, 0)

func _has_los(player: Player) -> bool:
	var muzzle := guard.global_position + Vector3(0, 1.5, 0)
	return guard.ray(muzzle, _target_point(player), [player.get_rid()]).is_empty()

func _shoot(player: Player, gs: Dictionary) -> void:
	var muzzle := guard.global_position + Vector3(0, 1.5, 0)
	var aim := _locked if _locked != Vector3.INF else _target_point(player)
	var dir := Spread.cone((aim - muzzle).normalized(), float(gs["gun_spread"]))
	var range_m := float(gs["gun_range"])
	var hit := guard.ray(muzzle, muzzle + dir * range_m)
	var endpoint: Vector3 = hit["position"] if not hit.is_empty() \
		else muzzle + dir * range_m
	shots += 1
	Tracer.fire(guard.game, muzzle, endpoint)
	guard.game.panic_civilians(muzzle, 26.0)
	AudioSynth.play_at(guard, "guard_shot", -3.0, 1.0, 80.0)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group("player"):
		hits += 1
		player.take_damage(float(gs["gun_damage"]))
