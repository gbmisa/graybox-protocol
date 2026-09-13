class_name Level2Builder
extends RefCounted
## Assembles PORT VESPER from independent section builders and returns the
## data the game needs to spawn the player, guards and target.
##
## FLOOR PLAN — ONE continuous waterfront district, x[-110,110], z[-80,25];
## water z > 25 (no south fence). The customs office sits roughly CENTRAL;
## the terminal sprawls west, the pier and the dead crane east. No lanes,
## no per-operative corridors, no authored vectors.
##
##   TERMINAL   x[-100,-25]  container maze; key-locked storage (routine)
##   WAREHOUSE  x[-96,-64] z[-58,-38]; 3-verb north door, open east gap,
##                           crate maze (seized log, manifest 12-C)
##   OFFICE     x[-20,14] z[-32,-8]; 4 gated entries (front, service,
##              west, skylight) each [lockpick|arcane|smash], 1.0m crawl
##              vent north (non-Chad shortcut), walkable west ramp + 6.7m
##              dash-gap shortcut to the roof; hardened SAFE ROOM in the
##              NE interior (ONE door, west side); target patrols inside
##   PIER       dock office (pier key, lockdown protocol, complaint);
##              pier gate [3 verbs|pier key]; boat extraction (fast,
##              exposed)
##   CRANE      dilapidated Crane 2 (far east); storage key
##   NORTH      fence z=-60: open vehicle gateway, 3-verb fence door
##              (x=-60), 1.0m crawl culvert (x=70); gatehouse (roster);
##              van extraction (guarded); drainage outflow (crawl only)
##
## Every gate on every approach accepts all three verbs with different
## costs — lockpick (slow, silent), arcane (mana), smash (fast, LOUD, feeds
## the alarm). Keys and the crawl spaces are shortcuts, never requirements.
##
## SPAWN — one staging pad at (60,0,-72), outside the north fence, facing
## the district, 25m+ from every guard post and out of all sightlines
## (raycast-verified in smoketest2).

const PLAYER_SPAWN := Vector3(60, 0, -72)

static func _yaw_to(from: Vector3, look: Vector3) -> float:
	var d := look - from
	return atan2(-d.x, -d.z)

static func player_spawns() -> Dictionary:
	# One pad for every operative — routes are not authored, so neither
	# are spawns. All face the district (+z).
	var entry := {"pos": PLAYER_SPAWN,
		"yaw": _yaw_to(PLAYER_SPAWN, Vector3(60, 0, -40))}
	return {"regular": entry, "wizard": entry, "chad": entry}

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
	Sec2Cover.build(game, root)
	_spawn_target(root, game)
	return {
		"level_root": root,
		"player_spawn": PLAYER_SPAWN,
		"player_spawns": player_spawns(),
		"guard_posts": GuardPosts2.all(),
	}

## THE HARBORMASTER. Patrols three stations inside the customs office —
## west end, mid floor, south windows. He never leaves the building: his
## route crosses no gated doors, so the patrol can never wedge itself on
## one, and no open patrol door undermines the gated entries.
static func _spawn_target(root: Node3D, game: GrayboxGame) -> void:
	var target := Target.new()
	root.add_child(target)
	var pos := Vector3(-12, 0, -12)
	target.setup(game, pos, [
		Vector3(-12, 0, -12),
		Vector3(-16, 0, -22),
		Vector3(-8, 0, -26),
	])
	game.target = target
