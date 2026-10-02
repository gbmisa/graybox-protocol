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

func _on_setup() -> void:
	player.viewmodel = PlayerViewmodel.new()
	player.viewmodel.setup(player)

func tick(delta: float) -> void:
	pistol_cd = maxf(0.0, pistol_cd - delta)
	if Input.is_action_pressed("attack") and pistol_cd <= 0.0:
		_fire_pistol()

## The loadout's mod scales damage and replaces the pistol's noise radius.
func _fire_pistol() -> void:
	var a := AbilityData.get_ability("pistol")
	var mod := LoadoutData.get_mod(player.game.selected_mod)
	pistol_cd = float(a["cooldown"])
	var noise := float(mod["noise"])
	AudioSynth.play(player.game, "pistol", -14.0 if noise <= 0.0 else 0.0,
		randf_range(0.94, 1.06))
	player.viewmodel.fire(noise <= 0.0)
	player.look.add_recoil(0.022 if noise <= 0.0 else 0.034)
	if noise > 0.0:
		player.game.emit_noise(player.global_position, noise)
	_damage_hit(_hitscan(float(a["range"])),
		float(a["damage"]) * float(mod["damage_mul"]))

func hud_lines() -> Array:
	return [
		"LMB: PISTOL (%s)%s" % [
			String(LoadoutData.get_mod(player.game.selected_mod)["name"]),
			_cd_text(pistol_cd)],
		"RMB: AIM",
		"C: CROUCH / CRAWL",
		"F: USE",
	]
