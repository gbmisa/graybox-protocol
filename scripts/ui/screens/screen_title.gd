class_name ScreenTitle
extends ScreenBase
## Title card.

func build() -> void:
	var v := column(24)
	center.add_child(v)
	v.add_child(text("GRAYBOX PROTOCOL", 72, GOLD))
	v.add_child(text("one operative. every way in. one target.", 22, INFO))
	for id in Levels.NAMES:
		var level_id := String(id)
		v.add_child(button(String(Levels.NAMES[level_id]), func() -> void:
			screens.click()
			game().selected_level = level_id
			game().show_select()
		))
