class_name Level2Builder
extends RefCounted
## Assembles PORT VESPER from independent section builders and returns the
## data the game needs to spawn the player, guards and target.
##
## FLOOR PLAN — a waterfront strip x [-110, 110], z [-80, 25]; water z > 25
## (no fence along it). Four districts, west to east:
##
##   x [-100,-25]  TERMINAL   container maze; Wizard dash line (z=-26) to
##                            the office roof; storage compound [key] south
##   x [-96,-64]   WAREHOUSE  z[-40,-14]; W wall [smash] (Chad); crate maze
##   x [-16,16]    OFFICE     customs office, 3.0m walls, roof slab 3.0–3.6;
##                            E door [lockpick], W door [smash], roof skylight
##                            [arcane]; target patrols inside. All three open
##                            freely from the inside (one-way locks).
##   x [25,75]     PIER       dock office (pier key + intel); pier deck
##                            x[45,60] z[5,45] over water; PIER GATE
##                            [lockpick | key:pier_key]; moored vessel; boat
##   x [75,105]    CRANE      dilapidated Crane 2 (far east); storage key;
##                            Harbormaster's routine (optional intel)
##   (70, -60)     CULVERT    1.0m crawl under the north fence (Regular)
##
## THREE VECTORS — hard-gated, entering the office from three sides:
##
##   REGULAR  east culvert (1.0m crawl) -> pier district -> EAST SERVICE
##            DOOR [lockpick] -> office interior
##
##   WIZARD   terminal ramp -> P1 (3.6m) -> 9.5m dash -> P2 (3.6m)
##            -> 9.5m dash east onto office roof (clearing the 3.0m west wall)
##            -> WARD SKYLIGHT [arcane] at (13, -20), off the dash axis
##            -> drop into office interior
##
##   CHAD     WAREHOUSE WEST WALL [smash] -> crate maze -> east personnel
##            door (open) -> terminal -> REINFORCED WEST DOOR [smash]
##            -> office interior
##
## The vectors never share a corridor: east door, roof skylight, west door.
## The office interior (where the target patrols) is the only shared space.
##
## EXTRACTIONS  boat (pier deck, all) · van (north gate, guarded, all) ·
##              drainage outflow (1.0m crawl, so Chad can never use it)
##
## SPAWN        (0,0,-74) north staging, behind a blast wall that blocks
##              every guard post's sightline (verified in smoketest2).

const PLAYER_SPAWN := Vector3(0, 0, -74)

static func build(game: GrayboxGame) -> Dictionary:
	var root := Node3D.new()
	root.name = "Level"
	game.add_child(root)
	Sec2Perimeter.build(game, root)
	Sec2Terminal.build(game, root)
	Sec2Warehouse.build(game, root)
	Sec2Office.build(game, root)
	Sec2Pier.build(game, root)
	Sec2Crane.build(game, root)
	Sec2Culvert.build(game, root)
	_spawn_target(root, game)
	return {
		"level_root": root,
		"player_spawn": PLAYER_SPAWN,
		"guard_posts": GuardPosts2.all(),
	}

## THE HARBORMASTER. Patrols three stations inside the customs office —
## east end, west end, south windows. He never leaves the building: his route
## crosses no gated doors, so the patrol can never wedge itself on one, and
## no open patrol door undermines the hard-gated entries.
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
