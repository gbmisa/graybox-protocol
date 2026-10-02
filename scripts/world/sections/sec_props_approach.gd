class_name SecPropsApproach
extends RefCounted
## Set dressing for the approach (Kenney CC0 kits via `Props`): parked and
## dumped cars, bins, lamp posts, trees, allotment clutter. Pure scenery —
## nothing here is a route — so every prop stays off the patrol lanes in
## `GuardPostsCompound.approach()`: A1 z 156, A3 the deck at z 125, A5 z 86,
## A6 z 44. Big props collide (cover, and something to stand on); clutter
## does not, so it never snags a foot.
##
## Rows are [model, position, yaw degrees, collide]. Kenney vehicles face +z
## as authored; yaw 90 points them +x.

const CARS := [
	# Spawn street: the bus stop's one parked customer, garage-front dumps.
	["car/sedan", Vector3(9.5, 0, 186), 180.0],
	["car/hatchback-sports", Vector3(-11, 0, 176), 0.0],
	["car/van", Vector3(10, 0, 177), 170.0],
	# Estate yard, out of A1's lane.
	["car/sedan", Vector3(-36, 0, 162), 90.0],
	["car/suv", Vector3(36, 0, 150), 270.0],
	# Ring road deck: abandoned in both carriageways, clear of A3's z 125.
	["car/delivery", Vector3(22, 4, 120), 0.0],
	["car/sedan", Vector3(-24, 4, 117.5), 95.0],
	["car/taxi", Vector3(-6, 4, 132.5), 268.0],
	["car/truck", Vector3(10, 4, 117), 84.0],
	["car/police", Vector3(-38, 4, 132), 280.0],
	# Terrace fronts, kerbside, clear of the overbridge stair (x -24..-15).
	["car/sedan", Vector3(-37, 0, 49), 90.0],
	["car/hatchback-sports", Vector3(-9, 0, 49), 90.0],
	["car/suv", Vector3(7, 0, 49), 270.0],
	["car/van", Vector3(27, 0, 49), 90.0],
	["car/sedan-sports", Vector3(39, 0, 49), 270.0],
]

const CLUTTER := [
	# Spawn street.
	["retro_urban/detail-dumpster-closed", Vector3(-15.5, 0, 191), 90.0, true],
	["retro_urban/detail-dumpster-open", Vector3(-15.5, 0, 174), 90.0, true],
	["retro_urban/detail-bench", Vector3(-8, 0, 194.4), 180.0, true],
	["retro_urban/detail-barrier-strong-type-a", Vector3(0, 0, 173.5), 0.0, true],
	["car/cone", Vector3(3, 0, 175), 0.0, false],
	["car/cone", Vector3(4.2, 0, 174.4), 0.0, false],
	# Estate yard.
	["retro_urban/detail-bench", Vector3(-14, 0, 149), 90.0, true],
	["retro_urban/detail-bench", Vector3(16, 0, 166), 270.0, true],
	["retro_urban/detail-dumpster-open", Vector3(-30, 0, 168), 0.0, true],
	["retro_urban/detail-dumpster-closed", Vector3(-26.5, 0, 168), 0.0, true],
	["survival/barrel", Vector3(12.4, 0, 149.5), 0.0, true],
	["retro_urban/detail-bricks-type-a", Vector3(8, 0, 146), 30.0, false],
	["retro_urban/pallet", Vector3(-4, 0, 167), 12.0, false],
	["car/debris-tire", Vector3(11.5, 0, 155.2), 0.0, false],
	["car/debris-door", Vector3(7.5, 0, 150), 70.0, false],
	# Ring road deck.
	["retro_urban/detail-barrier-strong-type-a", Vector3(-42, 4, 128), 90.0, true],
	["retro_urban/detail-barrier-strong-damaged", Vector3(42, 4, 121), 90.0, true],
	["car/cone", Vector3(-8, 4, 131), 0.0, false],
	["car/cone", Vector3(-10, 4, 130.5), 0.0, false],
	["car/debris-bumper", Vector3(12, 4, 120), 40.0, false],
	# Towpath.
	["retro_urban/detail-bench", Vector3(-24, 0, 110.8), 180.0, true],
	["retro_urban/detail-bench", Vector3(8, 0, 110.8), 180.0, true],
	["furniture/trashcan", Vector3(-20.5, 0, 111), 0.0, false],
	["furniture/trashcan", Vector3(11.5, 0, 111), 0.0, false],
	["survival/barrel", Vector3(27, 0, 105), 0.0, true],
	["survival/box-large", Vector3(27, 0, 108.5), 90.0, true],
	# Allotments, round the sheds; A5 walks z 86.
	["survival/barrel", Vector3(-25.2, 0, 75), 0.0, true],
	["survival/barrel-open", Vector3(-25.2, 0, 76.4), 0.0, true],
	["survival/workbench", Vector3(-28, 0, 79.3), 0.0, true],
	["survival/box-large-open", Vector3(32.8, 0, 76), 90.0, true],
	["survival/barrel", Vector3(32.8, 0, 74.5), 0.0, true],
	["survival/tool-shovel", Vector3(-17, 0, 77), 20.0, false],
	["survival/tool-hoe", Vector3(14, 0, 77.5), 75.0, false],
	["survival/bucket", Vector3(5.3, 0, 83), 0.0, false],
	["survival/signpost-single", Vector3(-6, 0, 73), 0.0, false],
	["survival/patch-grass-large", Vector3(-36, 0, 76), 0.0, false],
	["survival/patch-grass-large", Vector3(-8, 0, 75), 40.0, false],
	["survival/patch-grass-large", Vector3(18, 0, 73), 80.0, false],
	["survival/patch-grass-large", Vector3(38, 0, 84), 10.0, false],
	["survival/rock-flat-grass", Vector3(-38, 0, 89), 0.0, false],
	# Terrace back yards: each one somebody's bins.
	["furniture/trashcan", Vector3(-41, 0, 66.5), 0.0, false],
	["furniture/trashcan", Vector3(-33.5, 0, 66.5), 0.0, false],
	["retro_urban/detail-dumpster-closed", Vector3(-6, 0, 66), 0.0, true],
	["survival/box-large", Vector3(11, 0, 66), 0.0, true],
	["retro_urban/pallet", Vector3(24, 0, 65.5), 0.0, false],
	["survival/barrel", Vector3(31.5, 0, 66), 0.0, true],
	["furniture/trashcan", Vector3(40, 0, 66.5), 0.0, false],
	# Terrace fronts.
	["retro_urban/detail-dumpster-open", Vector3(-28, 0, 47.5), 90.0, true],
	["furniture/trashcan", Vector3(14, 0, 51.5), 0.0, false],
	["car/cone", Vector3(19, 0, 47), 0.0, false],
]

## Street trees and the estate's two surviving lamp posts' worth of poles.
const TREES := [
	[Vector3(-37, 0, 144)], [Vector3(-37, 0, 166)], [Vector3(40, 0, 144)],
	[Vector3(40, 0, 168)], [Vector3(-6, 0, 167.5)], [Vector3(17, 0, 142)],
	[Vector3(-41, 0, 104)], [Vector3(30, 0, 110.5)], [Vector3(-42, 0, 72)],
	[Vector3(42, 0, 88)],
]

const POLES := [
	[Vector3(12.5, 0, 191), 270.0], [Vector3(-12.5, 0, 181), 90.0],
	[Vector3(-30, 4, 113.2), 0.0], [Vector3(30, 4, 136.8), 180.0],
	[Vector3(-30, 0, 101), 0.0], [Vector3(20, 0, 101), 0.0],
	[Vector3(-30, 0, 46.6), 0.0], [Vector3(10, 0, 46.6), 0.0],
	[Vector3(34, 0, 46.6), 0.0],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for c in CARS:
		Props.vehicle(root, String(c[0]), c[1], float(c[2]))
	for c in CLUTTER:
		Props.place(root, String(c[0]), c[1], float(c[2]), 0.0, bool(c[3]))
	for i in TREES.size():
		var id := "retro_urban/tree-large" if i % 2 == 0 else "retro_urban/tree-park-large"
		Props.tree(root, id, TREES[i][0], float(i) * 47.0, 3.4)
	for p in POLES:
		street_lamp(root, p[0], float(p[1]))

## A lamp post with a sodium head that actually lights the pavement under it.
static func street_lamp(root: Node3D, pos: Vector3, yaw: float) -> void:
	Props.place(root, "retro_urban/detail-light-single", pos, yaw, 5.2)
	var arm := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, -0.9)
	BuildUtils.lamp(root, pos + Vector3(0, 4.6, 0) + arm, Color(1.0, 0.72, 0.38), 1.4, 9.0)
