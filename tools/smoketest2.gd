extends SceneTree
## Headless PORT VESPER check (bootstrap). The driver does the work.
##     godot --headless --path . --script res://tools/smoketest2.gd
const Driver = preload("res://tools/st2_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "St2Driver"
	root.call_deferred("add_child", driver)
