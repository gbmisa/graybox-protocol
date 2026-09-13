extends SceneTree
## PORT VESPER enclosure proof (bootstrap). The driver does the work.
##     godot --headless --path . --script res://tools/flood2.gd
const Driver = preload("res://tools/flood2_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "Flood2Driver"
	root.call_deferred("add_child", driver)
