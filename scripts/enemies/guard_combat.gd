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

func setup(p_guard: Guard) -> void:
	guard = p_guard

## Called by the brain while alerted and within range.
func tick(player: Player, delta: float, dist: float) -> void:
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
	AudioSynth.play(guard, "aim", -6.0)

func _tick_aim(player: Player, delta: float, gs: Dictionary) -> void:
	aiming -= delta
	if aiming > 0.0:
		return
	guard.body.set_aiming(false)
	shoot_cd = float(gs["gun_cooldown"])
	_shoot(player, gs)

func reset_cooldown(delay: float) -> void:
	shoot_cd = delay
	aiming = 0.0

func _has_los(player: Player) -> bool:
	var muzzle := guard.global_position + Vector3(0, 1.5, 0)
	var aim := player.global_position + Vector3(0, 1.2, 0)
	return guard.ray(muzzle, aim, [player.get_rid()]).is_empty()

func _shoot(player: Player, gs: Dictionary) -> void:
	var muzzle := guard.global_position + Vector3(0, 1.5, 0)
	var aim := player.global_position + Vector3(0, 1.2, 0)
	var dir := (aim - muzzle).normalized()
	var axis := dir.cross(Vector3.UP)
	if axis.length() < 0.01:
		axis = dir.cross(Vector3.RIGHT)
	dir = (Basis(axis.normalized(), randf_range(0.0, float(gs["gun_spread"])))
		* dir).normalized()
	var range_m := float(gs["gun_range"])
	var hit := guard.ray(muzzle, muzzle + dir * range_m)
	var endpoint: Vector3 = hit["position"] if not hit.is_empty() \
		else muzzle + dir * range_m
	Tracer.fire(guard.game, muzzle, endpoint)
	AudioSynth.play(guard, "guard_shot", -3.0)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group("player"):
		player.take_damage(float(gs["gun_damage"]))
