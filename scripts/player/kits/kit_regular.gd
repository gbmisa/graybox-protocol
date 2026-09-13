extends KitBase
## THE REGULAR — hitscan pistol, lockpicks, fits through crawl gaps.
##
## The plainest kit in the game on purpose. His edge is not firepower, it is
## access: the service route is all corridors and locked doors, where a
## 25-damage pistol at point blank is the right tool and 100 HP is enough
## precisely because nothing can flank you in a 1.2m passage.
##
## Verbs (data/verbs.gd): lockpick, crawl at 0.85m.

var pistol_cd: float = 0.0

func tick(delta: float) -> void:
	pistol_cd = maxf(0.0, pistol_cd - delta)
	if Input.is_action_pressed("attack") and pistol_cd <= 0.0:
		_fire_pistol()

func _fire_pistol() -> void:
	var a := AbilityData.get_ability("pistol")
	pistol_cd = float(a["cooldown"])
	AudioSynth.play(player.game, "pistol")
	player.game.emit_noise(player.global_position, float(a["noise"]))
	_damage_hit(_hitscan(float(a["range"])), float(a["damage"]),
		float(a["noise"]))

func hud_lines() -> Array:
	return [
		"LMB: PISTOL%s" % _cd_text(pistol_cd),
		"C: CROUCH / CRAWL",
		"F: PICK LOCK",
	]
