class_name PlayerHealth
extends Node
## Hit points, armor mitigation and invulnerability frames.
##
## **There is no health regeneration.** Damage taken is permanent for the run,
## which is what makes the pre-mission armour choice a real decision and each
## mission a single life. Do not add regen back without asking.
##
## The i-frame window lives here rather than in the Wizard's kit so that any
## future dodge on another operative gets the same behaviour for free.

signal died

var player: Player
var hp: float = 100.0
var max_hp: float = 100.0

var _iframes: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player
	max_hp = float(player.char["hp"])
	hp = max_hp

func tick(delta: float) -> void:
	_iframes = maxf(0.0, _iframes - delta)

func is_invulnerable() -> bool:
	return _iframes > 0.0

func take_damage(dmg: float) -> void:
	if not player.can_act() or is_invulnerable():
		return
	hp -= dmg * float(player.armor["dmg_mul"])
	player.game.hud.flash_damage()
	player.add_shake(0.3)
	AudioSynth.play(player.game, "hurt")
	if hp <= 0.0:
		hp = 0.0
		died.emit()

## Grant invulnerability for a fixed window. Ticked down in tick() rather than
## awaited, so it cannot outlive a mission restart or fire on a freed node.
func grant_iframes(duration: float) -> void:
	_iframes = maxf(_iframes, duration)

func fraction() -> float:
	return 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)
