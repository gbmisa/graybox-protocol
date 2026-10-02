class_name PlayerFootsteps
extends Node
## Footfalls every STRIDE metres on the ground. Crouched steps are near
## silent; sprinting ones are louder. Sound only — guards hear gunfire and
## impacts, never feet (footstep noise would make the approach unplayable).

## Metres per footfall. The Regular walks at 7 m/s, so 3.5 is a step every half
## second — 2.1 sounded like a machine gun. The weapon bob uses the same figure.
const STRIDE := 3.5

var player: Player
var _walked: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player

func tick(delta: float) -> void:
	if not player.is_on_floor():
		return
	var v := player.velocity
	var flat := Vector2(v.x, v.z).length()
	if flat < 0.6:
		_walked = STRIDE * 0.7     # the first step lands soon after moving
		return
	_walked += flat * delta
	if _walked >= STRIDE:
		_walked = 0.0
		var db := -26.0 if player.movement.crouching else (-14.0 if flat > 8.0 else -19.0)
		AudioSynth.play(player, "step", db, randf_range(0.9, 1.1))
