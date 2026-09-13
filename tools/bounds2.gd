extends SceneTree
## Headless PORT VESPER world-bounds check (bootstrap). The driver does the work.
##     godot --headless --path . --script res://tools/bounds2.gd
const Driver = preload("res://tools/bounds2_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "Bounds2Driver"
	root.call_deferred("add_child", driver)
