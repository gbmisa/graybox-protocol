class_name ScreenBriefing
extends ScreenBase
## Mission briefing and pre-mission loadout: armour for everyone, plus the
## sidearm mod row for operatives whose CharData lists "mods".
##
## Rebuilt on every show because the armor cards highlight the current pick,
## and picking one re-enters this screen.

const CONTROLS := {
	"regular": [
		"WASD move · MOUSE look · SPACE jump · SHIFT sprint",
		"LMB — pistol, hitscan; aim for the head (x2.5)",
		"C / CTRL — crouch to 0.85m: quieter, and the only way through 1m gaps",
		"F — use switches and levers",
	],
	"wizard": [
		"WASD move · MOUSE look · SPACE jump",
		"LMB — fireball, arcing AoE (20 mana)",
		"HOLD RMB — charged bolt, long range (35 mana)",
		"E — METEOR: ground-targeted, 1.1s delay, 90 dmg + burn pool (45 mana)",
		"SHIFT — arcane dash: i-frames, no sprint (15 mana)",
		"HOLD X — squeeze to 0.6m (drains mana, no regen while held)",
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
	var v := column(10)
	center.add_child(v)
	var level := game().selected_level
	var info := LevelText.info(level)
	var c := CharData.get_char(game().selected_char)
	v.add_child(text("%s — %s" % [Levels.NAMES[level], c["name"]], 30, GOLD))
	var brief := String(info.get("briefing", ""))
	if brief.is_empty():
		v.add_child(wrapped(String(c["desc"]), 18, 760, INFO))
	else:
		v.add_child(wrapped(brief, 14, 1040, INFO))
	v.add_child(wrapped("YOUR WAY IN — " + LevelText.route(level, game().selected_char),
		16, 1040, Color.WHITE))
	var lines: Array = CONTROLS.get(game().selected_char, CONTROLS["regular"])
	v.add_child(text("   ".join(PackedStringArray(lines.slice(1))), 13))
	v.add_child(text(String(info.get("extractions", "")), 15, INFO))
	_loadout(v)
	if c.has("mods"):
		_mods(v, c["mods"] as Array)
	v.add_child(button("DEPLOY", func() -> void:
		screens.click()
		game().deploy()
	))

func _loadout(v: VBoxContainer) -> void:
	v.add_child(text("ARMOUR — protection costs speed", 18, GOLD))
	var h := row(12)
	v.add_child(h)
	for id in ArmorData.ids():
		var aid := String(id)
		var a := ArmorData.get_armor(aid)
		var label := "%s\n%s\nDMG x%s   SPEED x%s" % [
			a["name"], a["desc"], a["dmg_mul"], a["speed_mul"]]
		var b := card(label, Vector2(240, 96), func() -> void:
			screens.click()
			game().set_armor(aid)
		)
		if aid == game().selected_armor:
			b.modulate = SELECTED
		h.add_child(b)

## The sidearm row. Chosen here, never mid-run, like armour.
func _mods(v: VBoxContainer, ids: Array) -> void:
	var h := row(12)
	v.add_child(h)
	for id in ids:
		var mid := String(id)
		var m := LoadoutData.get_mod(mid)
		var b := card("%s\n%s" % [m["name"], m["desc"]], Vector2(370, 60), func() -> void:
			screens.click()
			game().set_mod(mid)
		)
		if mid == game().selected_mod:
			b.modulate = SELECTED
		h.add_child(b)
