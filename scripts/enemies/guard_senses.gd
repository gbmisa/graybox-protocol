class_name GuardSenses
extends Node
## Vision and the detection meter.
##
## A guard sees the player when they are inside the vision range, inside the
## cone, and there is clear line of sight to their chest. The meter then fills
## faster the closer the player is, slower while they are crouched, faster
## while they sprint — which is what makes the crouch worth its speed cost on
## the Regular's route.

var guard: Guard

func setup(p_guard: Guard) -> void:
	guard = p_guard

func tick(player: Player, delta: float) -> void:
	var gs := GuardData.stats()
	var to_p: Vector3 = player.global_position - guard.global_position
	var dist := Vector3(to_p.x, 0.0, to_p.z).length()
	var seen := _can_see(player, to_p, dist, gs)
	if seen:
		guard.last_seen = player.global_position
		guard.detect = minf(1.0, guard.detect + _rate(player, dist, gs) * delta)
	else:
		guard.detect = maxf(0.0, guard.detect - float(gs["lose_rate"]) * delta)
	_escalate()

func _can_see(player: Player, to_p: Vector3, dist: float, gs: Dictionary) -> bool:
	if dist >= float(gs["vision_range"]):
		return false
	var forward := -guard.global_transform.basis.z
	if forward.dot(to_p.normalized()) <= float(gs["vision_cone"]):
		return false
	var from := guard.global_position + Vector3(0, 1.6, 0)
	var chest := player.global_position + Vector3(0, 1.2, 0)
	# The player must be excluded, or the ray terminates inside their own
	# capsule and a clear view reads as "blocked".
	return guard.ray(from, chest, [player.get_rid()]).is_empty()

## Closer is faster; stance scales it. Crouching roughly halves the rate.
func _rate(player: Player, dist: float, gs: Dictionary) -> float:
	var rate := float(gs["detect_rate"]) \
		* (1.0 - dist / float(gs["vision_range"]))
	if player.movement.crouching:
		rate *= float(gs["crouch_mul"])
	if player.movement.is_sprinting:
		rate *= float(gs["sprint_mul"])
	return rate

func _escalate() -> void:
	if guard.detect >= 1.0 and guard.state != Guard.State.ALERT:
		guard.enter_alert()
	elif guard.detect >= 0.35 and guard.state == Guard.State.PATROL:
		guard.enter_suspicious(guard.last_seen, guard.detect)
