class_name SecPropsCampus
extends RefCounted
## Set dressing for the campus outdoors and the streets round it (Kenney CC0
## via `Props`). Clear of the campus lanes in `GuardPostsCompound.campus()`:
## G1 z -22, G2 z 12, G3 x -25, G5 x 13, A6 z 44. Rows are [model,
## position, yaw degrees, collide].

const CARS := [
	# South road, under the billboard: the audit's guests parked on the verge
	# side, a compliance cruiser across the way.
	["car/suv-luxury", Vector3(-12, 0, 35), 90.0],
	["car/sedan", Vector3(-4, 0, 35), 90.0],
	["car/suv-luxury", Vector3(4.5, 0, 35), 90.0],
	["car/police", Vector3(22, 0, 39), 250.0],
	["car/taxi", Vector3(-38, 0, 40), 180.0],
	# Avenue: the delegates' cars, nose to the gate.
	["car/suv-luxury", Vector3(-15, 0, -37), 90.0],
	["car/sedan-sports", Vector3(12, 0, -37), 270.0],
	["car/delivery-flat", Vector3(17, 0, -29), 0.0],
	# East lane: the caterers.
	["car/delivery", Vector3(32.5, 0, -6), 180.0],
]

const CLUTTER := [
	# Billboard verge.
	["retro_urban/detail-barrier-type-a", Vector3(-8, 0, 31), 0.0, true],
	["retro_urban/detail-barrier-type-a", Vector3(8, 0, 27.5), 0.0, true],
	["car/cone", Vector3(6.5, 0, 31.5), 0.0, false],
	["car/cone", Vector3(-6, 0, 31.5), 0.0, false],
	["retro_urban/pallet", Vector3(-11, 0, 27), 20.0, false],
	["furniture/trashcan", Vector3(-20, 0, 31.4), 0.0, false],
	["furniture/trashcan", Vector3(22, 0, 31.4), 0.0, false],
	# Courtyard: benches and bins along the south wall, a lost-property heap.
	["retro_urban/detail-bench", Vector3(-15, 0, 23), 180.0, true],
	["retro_urban/detail-bench", Vector3(6, 0, 23), 180.0, true],
	["furniture/trashcan", Vector3(-11.5, 0, 23.4), 0.0, false],
	["furniture/trashcan", Vector3(9.5, 0, 23.4), 0.0, false],
	["survival/box-large-open", Vector3(15.0, 0, 7.5), 0.0, true],
	["survival/box", Vector3(15.1, 0, 9.0), 30.0, false],
	["furniture/pottedPlant", Vector3(-3.2, 0, 0.3), 0.0, false],
	["furniture/pottedPlant", Vector3(3.2, 0, 0.3), 0.0, false],
	# Refuse yard (PITCH): proper skips, pallets, the week's bags.
	["retro_urban/detail-dumpster-open", Vector3(26, 0, 22), 180.0, true],
	["retro_urban/detail-dumpster-closed", Vector3(18.6, 0, 22.4), 180.0, true],
	["retro_urban/pallet", Vector3(26.5, 0, 16), 10.0, false],
	["survival/box-large", Vector3(25.5, 0, 14), 90.0, true],
	["survival/barrel", Vector3(17.2, 0, 15.5), 0.0, true],
	# West yard, against the compound wall: G3 walks x -25.
	# (Clear of the west gantry's stairs, x [-28, -26.6] at both ends.)
	["survival/barrel", Vector3(-23.0, 0, 22.6), 0.0, true],
	["survival/barrel-open", Vector3(-24.2, 0, 23.0), 0.0, true],
	["survival/box-large", Vector3(-22.9, 0, 21.0), 0.0, true],
	# North yard edges and the gatehouse.
	["retro_urban/detail-barrier-strong-type-b", Vector3(10, 0, -24.6), 0.0, true],
	["car/cone", Vector3(-1, 0, -27), 0.0, false],
	# East lane.
	["retro_urban/detail-dumpster-closed", Vector3(34.5, 0, 12), 270.0, true],
	["survival/box-large", Vector3(34.6, 0, 6), 0.0, true],
	["retro_urban/pallet", Vector3(34, 0, -18), 0.0, false],
	# West alley.
	["retro_urban/detail-dumpster-closed", Vector3(-38.6, 0, 22), 90.0, true],
	["furniture/trashcan", Vector3(-38.8, 0, -2), 0.0, false],
]

## Clear of the podium (x [-21.6, -13.9] z [19, 23.6]) and the car-park deck
## (x [3.6, 19.8] z [-39.8, -24.8]) — a tree under a slab pokes through it.
const TREES := [
	[Vector3(-6, 0, 22.8)], [Vector3(13, 0, 20.5)], [Vector3(-19, 0, 3)],
	[Vector3(-42, 0, 44)], [Vector3(42, 0, 36)], [Vector3(-18, 0, -33)],
	[Vector3(-17, 0, -28.5)],
]

const POLES := [
	[Vector3(-30, 0, 32.6), 180.0], [Vector3(-2, 0, 32.6), 180.0],
	[Vector3(28, 0, 32.6), 180.0], [Vector3(-12, 0, -25.4), 0.0],
	[Vector3(-8, 0, -38.6), 180.0], [Vector3(35.5, 0, 0), 270.0],
	[Vector3(-39.5, 0, 26), 90.0],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for c in CARS:
		Props.vehicle(root, String(c[0]), c[1], float(c[2]))
	for c in CLUTTER:
		Props.place(root, String(c[0]), c[1], float(c[2]), 0.0, bool(c[3]))
	for i in TREES.size():
		var id := "retro_urban/tree-park-large" if i % 2 == 0 else "retro_urban/tree-large"
		Props.tree(root, id, TREES[i][0], float(i) * 61.0, 3.4)
	for p in POLES:
		SecPropsApproach.street_lamp(root, p[0], float(p[1]))
