class_name LevelBuilder
extends RefCounted
## Assembles MERIDIAN CAPITAL from independent section builders and returns the
## data the game needs to spawn the player, guards and target.
##
## FLOOR PLAN — tower footprint x [-30, 30], z [-40, 10]
##
##   y  18.6  ROOF         helipad extraction
##   y  12.0  BOARDROOM    target; three gated doors; drop chute
##   y   6.0  MEZZANINE    convergence floor
##   y   0.0  GROUND       street, courtyard, loading dock, freight bay
##   y  -4.0  UNDERCROFT   crawl tunnels, boiler room, sump extraction
##
## THREE ROUTES — mostly hard-gated, converging on the mezzanine:
##
##   REGULAR  culvert crawl (1.0m) -> undercroft -> MAINTENANCE DOOR [lockpick]
##            -> boiler room -> service stair -> mezzanine
##            -> SERVER ACCESS [lockpick] -> boardroom
##
##   WIZARD   WARDED GATE [arcane] -> courtyard -> vent shaft (dash the gaps)
##            -> mezzanine -> WARDED DOOR [arcane] -> boardroom
##
##   CHAD     DOCK SHUTTER [smash] -> dock -> COLLAPSED WALL [smash]
##            -> freight bay -> container stacks (2.3m mantles) -> mezzanine
##            -> REINFORCED PANEL [smash] -> boardroom
##
## EXTRACTIONS  helipad (roof, all) · van (street, all) · sump (crawl only)

const PLAYER_SPAWN := Vector3(0, 0, 70)

static func build(game: GrayboxGame) -> Dictionary:
	var root := Node3D.new()
	root.name = "Level"
	game.add_child(root)
	# Shell and shared ground first, so route sections can cut into them.
	SecStreet.build(root, game)
	SecTower.build(root, game)
	# One section per route.
	SecUndercroft.build(root, game)
	SecCourtyard.build(root, game)
	SecDock.build(root, game)
	# Convergence and above.
	SecMezzanine.build(root, game)
	var target_pos := SecBoardroom.build(root, game)
	SecRoof.build(root, game)
	_spawn_target(root, game, target_pos)
	return {
		"level_root": root,
		"player_spawn": PLAYER_SPAWN,
		"guard_posts": GuardPosts.all(),
	}

static func _spawn_target(root: Node3D, game: GrayboxGame, pos: Vector3) -> void:
	var target := Target.new()
	root.add_child(target)
	# Paces the length of the room, clear of the table at x [-8, 8].
	target.setup(game, pos, [
		pos + Vector3(-10, 0, -2),
		pos + Vector3(10, 0, -2),
	])
	game.target = target
