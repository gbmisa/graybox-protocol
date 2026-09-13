class_name ScreenPause
extends ScreenBase
## Pause menu.

func build() -> void:
	var v := column(16)
	center.add_child(v)
	v.add_child(text("PAUSED", 56, GOLD))
	v.add_child(button("RESUME", func() -> void:
		screens.click()
		game().resume()
	))
	v.add_child(button("RESTART MISSION", func() -> void:
		screens.click()
		game().restart_mission()
	))
	v.add_child(button("CHANGE OPERATIVE", func() -> void:
		screens.click()
		game().quit_to_select()
	))
	v.add_child(button("EXIT", func() -> void:
		screens.click()
		get_tree().quit()
	))
