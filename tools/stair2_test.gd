extends SceneTree
## P5 headless stair test: walks a player-sized probe up the undercroft
## service stair (Regular's route, Level 1) and onto the mezzanine floor.
const Driver = preload("res://tools/stair2_driver.gd")

func _initialize() -> void:
	var driver := Driver.new()
	driver.name = "Stair2Driver"
	root.call_deferred("add_child", driver)
