extends SceneTree
## Headless CONSEQUENCE SPINE check (bootstrap). The driver does the work.
##     godot --headless --path . --script res://tools/alarm_test.gd
##
## Exercises the alarm director on PORT VESPER: at full alarm a guard runs for
## the nearest panel and only a panel activation trips lockdown (runner
## assignment, arrival, kill-the-runner standoff, no-alert standoff), plus
## decay after quiet, loud-kill and corpse bumps, and lockdown permanence.
const Driver = preload("res://tools/alarm_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "AlarmDriver"
	root.call_deferred("add_child", driver)
