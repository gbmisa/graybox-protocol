class_name ScreenPause
extends ScreenBase
## Pause menu, over the frozen mission.

func backdrop_color() -> Color:
	return Color(0.02, 0.025, 0.04, 0.72)

func build() -> void:
	var v := column(4)
	center.add_child(v)
	v.add_child(title("PAUSED", 52))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	v.add_child(gap)
	v.add_child(menu_entry("RESUME", func() -> void:
		screens.click()
		game().resume()
	, 26))
	v.add_child(menu_entry("RESTART MISSION", func() -> void:
		screens.click()
		game().restart_mission()
	, 26))
	v.add_child(menu_entry("OPTIONS", func() -> void:
		screens.click()
		screens.show_options("pause")
	, 26))
	v.add_child(menu_entry("QUIT TO MAIN MENU", func() -> void:
		screens.click()
		game().quit_to_title()
	, 26))
	v.add_child(menu_entry("QUIT TO DESKTOP", func() -> void:
		screens.click()
		get_tree().quit()
	, 26))
