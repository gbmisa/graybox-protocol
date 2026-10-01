class_name SecCmpClimbs
extends RefCounted
## The campus's outside verticals: the ways up that aren't the crate stair.
## Each one is plainly a thing you climb, visible from where you stand.
##
##   Boiler climb  west alley: skip (1.15) -> pallets (2.3) -> meter cabinet
##                 (3.2) against the boiler house, x [-38.5, -34] z [-16.5,
##                 -13.5] -> its roof (4.0), flush with the compound wall top.
##                 Over the wall into the west yard, on G3's lane.
##   Fire escape   west yard, against the main block's west face, x [-24.15,
##                 -22.15]. Flight 1 north end (z -19.5) up to a 4.0 landing
##                 at z [-13.1, -10]: a door into the 1F west strip (x [-22,
##                 -19], above the west corridor) and from it onto the west
##                 landing behind G9. Flight 2 on to the roof at z -3, through
##                 a gap in the parapet.
##   Scaffold      courtyard, against the south face, x [-18, -7] z [-1.85,
##                 2.15]. Flight 1 (inner bay) rises east to a 4.0 lift at x
##                 [-9.2, -7] with a door into the 1F south corridor — G8's
##                 lane. Flight 2 (outer bay) rises west to 8.4 at x [-18,
##                 -16.2], through a gap in the south parapet.
## Doors and parapet gaps are cut by `sec_cmp_main_shell` / `_main_roof` /
## `_main_1f`; this file owns the structures and the strip's lamp.

const FLOOR_1F := 4.0
const ROOF := 8.4

static func build(root: Node3D, game: GrayboxGame) -> void:
	_boiler_climb(root)
	_fire_escape(root)
	_scaffold(root)

static func _boiler_climb(root: Node3D) -> void:
	WallUtils.block(root, -38.5, -35.5, 0, 1.15, -16.5, -13.5, Color(0.20, 0.30, 0.22))
	WallUtils.block(root, -35.5, -34.0, 0, 2.3, -16.5, -15.0, BuildUtils.CRATE)
	WallUtils.block(root, -35.5, -34.0, 0, 3.2, -15.0, -13.5, BuildUtils.METAL)

static func _fire_escape(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.stairs(root, Vector3(-23.15, 0, -19.5), Vector3(0, 0, 1),
		8, 0.5, 0.8, 2.0, m)
	BuildUtils.plate(root, -24.15, -22.15, -13.1, -10, FLOOR_1F, 0.3, m)
	BuildUtils.stairs(root, Vector3(-23.15, FLOOR_1F, -10), Vector3(0, 0, 1),
		8, 0.55, 0.875, 2.0, m)
	BuildUtils.plate(root, -24.15, -22.15, -3, -1.4, ROOF, 0.3, m)
	BuildUtils.lamp(root, Vector3(-23.6, FLOOR_1F + 2.2, -11.5), BuildUtils.LAMP_SERVICE,
		0.6, 7.0)
	# The 1F strip behind the door: floor is the west corridor's ceiling.
	BuildUtils.lamp(root, Vector3(-20.5, FLOOR_1F + 2.6, -11), BuildUtils.LAMP_SERVICE,
		0.5, 7.0)

static func _scaffold(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.stairs(root, Vector3(-15.6, 0, -0.85), Vector3(1, 0, 0),
		8, 0.5, 0.8, 2.0, m)
	BuildUtils.plate(root, -9.2, -7.0, -1.85, 2.15, FLOOR_1F, 0.3, m)
	BuildUtils.stairs(root, Vector3(-9.2, FLOOR_1F, 1.15), Vector3(-1, 0, 0),
		8, 0.55, 0.875, 2.0, m)
	BuildUtils.plate(root, -18.0, -16.2, -1.85, 2.15, ROOF, 0.3, m)
	# Standards: the frame, drawn but not solid, so it can't snag a climb.
	for x in [-18.0, -12.6, -7.0]:
		for z in [-1.8, 2.1]:
			BuildUtils.box(root, Vector3(x, ROOF * 0.5, z), Vector3(0.08, ROOF, 0.08),
				BuildUtils.PIPE, false)
	BuildUtils.lamp(root, Vector3(-8.1, FLOOR_1F + 2.0, 1.0), BuildUtils.LAMP_SERVICE,
		0.6, 7.0)
