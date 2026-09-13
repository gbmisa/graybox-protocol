extends SceneTree
## Headless P1 (fireball vs walls) + P6 (headshot multiplier) test.
## The driver does the work.
##     godot --headless --path . --script res://tools/proj_test.gd
const Driver = preload("res://tools/proj_test_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "ProjTestDriver"
	root.call_deferred("add_child", driver)
