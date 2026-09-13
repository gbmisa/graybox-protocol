class_name ScreenEnd
extends ScreenBase
## Mission result. One class serves both outcomes — `is_win` is set by the
## Screens router before setup, and the win variant rebuilds each time to show
## the run's stats.

var is_win: bool = false
var stats: Dictionary = {}

func refresh() -> void:
	clear(center)
	var v := column(12)
	center.add_child(v)
	if is_win:
		v.add_child(text("MISSION COMPLETE", 56, GOLD))
		for line in _stat_lines():
			v.add_child(text(line, 22))
	else:
		v.add_child(text("YOU DIED", 64, Color(1.0, 0.25, 0.25)))
	v.add_child(button("PLAY AGAIN" if is_win else "RETRY", func() -> void:
		screens.click()
		game().restart_mission()
	))
	v.add_child(button("CHANGE OPERATIVE", func() -> void:
		screens.click()
		game().quit_to_select()
	))

func _stat_lines() -> Array:
	var t := float(stats.get("time_sec", 0.0))
	var mins := int(t) / 60
	var secs := t - float(mins * 60)
	return [
		"TIME: %d:%04.1f" % [mins, secs],
		"EXTRACTED VIA: %s" % String(stats.get("zone", "")).to_upper(),
		"KILLS: %d" % int(stats.get("kills", 0)),
		"ALARMS TRIGGERED: %d" % int(stats.get("alarms", 0)),
		"OPERATIVE: %s" % String(stats.get("char_name", "")),
		"ARMOR: %s" % String(stats.get("armor_name", "")),
	]
