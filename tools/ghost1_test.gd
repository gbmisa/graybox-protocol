extends SceneTree
## P7 headless ghost test: the Regular walks Level 1 end-to-end with live
## guards — culvert, undercroft, service stair, mezzanine, boardroom kill,
## sump extraction — and must finish with zero alarms and a WIN.
const Driver = preload("res://tools/ghost1_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "Ghost1Driver"
	root.call_deferred("add_child", driver)
