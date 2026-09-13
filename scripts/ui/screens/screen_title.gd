class_name ScreenTitle
extends ScreenBase
## Title card.

func build() -> void:
	var v := column(24)
	center.add_child(v)
	v.add_child(text("GRAYBOX PROTOCOL", 72, GOLD))
	v.add_child(text("MERIDIAN CAPITAL — QUARTERLY OFFSITE", 20, INFO))
	v.add_child(text("three operatives. three ways in. one target.", 22, INFO))
	v.add_child(button("BEGIN", func() -> void:
		screens.click()
		game().show_select()
	))
