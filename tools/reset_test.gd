extends SceneTree
## Headless runner: lockdown via a panel on PORT VESPER, then restart, then
## assert the mission resets deterministically (alarm 0, no lockdown, no
## runner, fresh guards/target/panels, klaxon stopped, old nodes freed).
##     godot --headless --path . --script res://tools/reset_test.gd
const Driver = preload("res://tools/reset_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "ResetDriver"
	root.call_deferred("add_child", driver)
