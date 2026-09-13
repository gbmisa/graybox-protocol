class_name ScreenBriefing
extends ScreenBase
## Mission briefing and armor loadout.
##
## Rebuilt on every show because the armor cards highlight the current pick,
## and picking one re-enters this screen.

const CONTROLS := {
	"regular": [
		"WASD move · MOUSE look · SPACE jump · SHIFT sprint",
		"LMB — pistol, 25 dmg hitscan",
		"C / CTRL — crouch to 0.85m: quieter, and the only way through 1m gaps",
		"F — pick locks (3s, silent)",
	],
	"wizard": [
		"WASD move · MOUSE look · SPACE jump",
		"LMB — fireball, arcing AoE (20 mana)",
		"HOLD RMB — charged bolt, 30m range (35 mana)",
		"E — METEOR: ground-targeted, 1.1s delay, 90 dmg + burn pool (45 mana)",
		"SHIFT — arcane dash: i-frames, no sprint (15 mana)",
		"F — unward seals (25 mana)",
	],
	"chad": [
		"WASD move · MOUSE look · SHIFT sprint",
		"LMB — punch combo, 55 dmg",
		"E — ground slam, 60 dmg AoE + knockback",
		"SPACE — climb ledges up to 2.5m",
		"F — breach doors and walls (very loud)",
		"NO crawling — 1m gaps are closed to you",
	],
}

func refresh() -> void:
	clear(center)
	var v := column(8)
	center.add_child(v)
	var lvl := LevelData.get_level(game().selected_level)
	var c := CharData.get_char(game().selected_char)
	v.add_child(text("MISSION BRIEFING — %s" % lvl["name"], 32, GOLD))
	v.add_child(wrapped(str(lvl["desc"]), 18, 760, INFO))
	if lvl.has("objective"):
		v.add_child(wrapped(str(lvl["objective"]), 15, 760, Color.WHITE))
	# Single line (wide wrap): the briefing is already at the 720px limit.
	v.add_child(wrapped(
		"Loud kills raise the alarm. A full alarm means lockdown — the target relocates under guard.",
		14, 1000, INFO))
	v.add_child(text("OPERATIVE: %s — %s" % [c["name"], c["role"]], 20, GOLD))
	v.add_child(text("YOUR ROUTE", 20, GOLD))
	v.add_child(wrapped(str(lvl["routes"][game().selected_char]), 17, 760,
		Color.WHITE))
	var lines: Array = CONTROLS.get(game().selected_char, CONTROLS["regular"])
	v.add_child(text("\n".join(PackedStringArray(lines)), 15))
	v.add_child(text(str(lvl["extractions"]), 15, INFO))
	_loadout(v)
	v.add_child(button("DEPLOY", func() -> void:
		screens.click()
		game().deploy()
	))

func _loadout(v: VBoxContainer) -> void:
	v.add_child(text("LOADOUT — PICK YOUR ARMOR (protection costs speed)", 20, GOLD))
	var h := row(12)
	v.add_child(h)
	for id in ArmorData.ids():
		var aid := String(id)
		var a := ArmorData.get_armor(aid)
		var label := "%s\n%s\n\nDMG x%s   SPEED x%s" % [
			a["name"], a["desc"], a["dmg_mul"], a["speed_mul"]]
		var b := card(label, Vector2(240, 150), func() -> void:
			screens.click()
			game().set_armor(aid)
		)
		if aid == game().selected_armor:
			b.modulate = SELECTED
		h.add_child(b)
