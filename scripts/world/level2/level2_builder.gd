class_name Level2Builder
extends RefCounted
## Assembles PORT VESPER from independent section builders and returns the
## data the game needs to spawn the player, guards and target.
##
## FLOOR PLAN — dockyard footprint x [-60, 60], z [-50, 45]; water z > 52
##
##   z  58     PIER         boat extraction (south, over water)
##   z  45     SOUTH FENCE  pier walkway gap (open) · pier gate [lockpick]
##   z  30     EAST         drainage culvert IN (Regular) · outflow (extract)
##   z [-30,-14] OFFICE     customs office, 3.0m walls, roof slab 3.0–3.6;
##                          E door [lockpick], W door [smash], roof skylight
##                          [arcane]; target patrols inside. The low walls
##                          are load-bearing: the Wizard's dash is perfectly
##                          horizontal at 3.6m and must clear the east wall.
##   z [-18,12] WAREHOUSE   x [-60,-24]; W corrugated wall [smash]
##   z [-50,-19] YARD       containers; Wizard dash line at x = 28
##   z -50     NORTH FENCE  gate (open, guarded); van extraction outside
##   (0,0,-62) SPAWN        north of the fence
##
## THREE VECTORS — hard-gated, entering the office from three different sides:
##
##   REGULAR  east drainage culvert (1.0m crawl) -> container yard
##            -> EAST SERVICE DOOR [lockpick] -> office interior
##            optional: 2 impound lockers [lockpick], pier shortcut gate
##
##   WIZARD   north fence ramp -> container tops (3.6m)
##            -> 7m dash gap -> 7m dash gap -> 7m dash west onto office roof
##            (3.6m, clearing the 3.0m east wall)
##            -> WARD SKYLIGHT [arcane] at (13, -20), off the dash axis
##            -> drop into office interior
##
##   CHAD     CORRUGATED WALL [smash, west perimeter] -> warehouse
##            -> east personnel door (open) -> yard gap
##            -> REINFORCED WEST DOOR [smash] -> office interior
##
## The vectors never share a corridor: east door, roof skylight, west door.
## The office interior (where the target patrols) is the only shared space.
##
## EXTRACTIONS  boat (pier, all) · van (north gate, all) · drainage outflow
##              (1.0m crawl, so Chad can never use it)

const PLAYER_SPAWN := Vector3(0, 0, -62)

static func build(game: GrayboxGame) -> Dictionary:
	var root := Node3D.new()
	root.name = "Level"
	game.add_child(root)
	Sec2Perimeter.build(root, game)
	Sec2Yard.build(root, game)
	Sec2Culvert.build(root, game)
	Sec2Office.build(root, game)
	Sec2Warehouse.build(root, game)
	_spawn_target(root, game)
	return {
		"level_root": root,
		"player_spawn": PLAYER_SPAWN,
		"guard_posts": GuardPosts2.all(),
	}

## THE HARBORMASTER. Patrols three stations inside the customs office —
## east end, west end, south windows. He never leaves the building: his route
## crosses no gated doors, so the patrol can never wedge itself on one, and
## no open patrol door undermines the hard-gated entries. The signage
## ("ROUNDS: OFFICE -> WAREHOUSE -> PIER") preserves the fiction and the
## find-him friction.
static func _spawn_target(root: Node3D, game: GrayboxGame) -> void:
	var target := Target.new()
	root.add_child(target)
	var pos := Vector3(6, 0, -24)
	target.setup(game, pos, [
		Vector3(6, 0, -24),
		Vector3(-8, 0, -20),
		Vector3(0, 0, -16),
	])
	game.target = target
