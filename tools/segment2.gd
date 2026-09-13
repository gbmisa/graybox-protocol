## PORT VESPER segment physics (bootstrap). The driver does the work.
##     godot --headless --path . --script res://tools/segment2.gd
extends SceneTree
const Driver = preload("res://tools/segment2_driver.gd")

func _initialize() -> void:
	var d := Driver.new()
	root.call_deferred("add_child", d)
