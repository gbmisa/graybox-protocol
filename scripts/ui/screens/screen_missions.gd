class_name ScreenMissions
extends ScreenBase
## Mission select: every level in `Levels.NAMES`, with its card copy.
## HOLLOWAY ROAD is the game; MERIDIAN CAPITAL is the original testbed.

func backdrop_color() -> Color:
	return Color(0.02, 0.025, 0.04, 0.82)

func refresh() -> void:
	clear(center)
	var v := column(14)
	center.add_child(v)
	v.add_child(title("MISSIONS", 44))
	for id in ["compound", "meridian"]:
		if not Levels.NAMES.has(id):
			continue
		var level_id := String(id)
		var info := LevelText.info(level_id)
		var blurb := String(info.get("card", "The original three-operative testbed: a five-floor tower, three hard-gated routes, three extractions."))
		var label := "%s\n%s" % [Levels.NAMES[level_id], ScreenSelect._wrap(blurb)]
		v.add_child(card(label, Vector2(620, 0), func() -> void:
			screens.click()
			game().selected_level = level_id
			game().show_select()
		))
	v.add_child(button("BACK", func() -> void:
		AudioSynth.play(screens, "back", -6.0)
		screens.show_title()
	))
