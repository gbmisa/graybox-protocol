extends KitBase
## THE REGULAR — the gun-carrying operative, and (r8) the whole Cruelty
## Squad toolbox: an arsenal (player/weapons.gd, data/weapons.gd) and four
## tools (player/tools/): the boot, the grappling hook, the night-vision
## implant, and eating the dead.
##
## Verbs (data/verbs.gd): lockpick, crawl at 0.85m.

var weapons: PlayerWeapons
var kick: ToolKick
var grapple: ToolGrapple
var night_vision: ToolNightVision
var eat: ToolEat

func _on_setup() -> void:
	weapons = PlayerWeapons.new()
	add_child(weapons)
	weapons.setup(player, self)
	kick = ToolKick.new()
	grapple = ToolGrapple.new()
	night_vision = ToolNightVision.new()
	eat = ToolEat.new()
	for t in [kick, grapple, night_vision, eat]:
		add_child(t)
		t.setup(player)

func tick(delta: float) -> void:
	weapons.tick(delta)
	kick.tick(delta)
	grapple.tick(delta)
	night_vision.tick(delta)

## After movement, before the slide: the rope, and the eat prompt (which must
## come after the interactor's).
func post_move(delta: float) -> void:
	grapple.post_move(delta)
	eat.post_move(delta)

func hud_lines() -> Array:
	var w := weapons.weapon()
	var a: Dictionary = weapons.ammo[weapons.current]
	var name := String(w["name"])
	if weapons.current == "pistol":
		name += " (%s)" % String(LoadoutData.get_mod(player.game.selected_mod)["name"])
	return [
		"%s   %d / %d%s" % [name, int(a["mag"]), int(a["reserve"]),
			"   RELOADING" if weapons.reloading() else ""],
		"1-5 WEAPONS  R RELOAD  RMB AIM",
		"V KICK  Q GRAPPLE  N NIGHT VISION%s" % ("  [ON]" if night_vision.on else ""),
		"F USE / EAT  C CROUCH",
	]
