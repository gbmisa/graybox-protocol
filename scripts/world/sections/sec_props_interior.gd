class_name SecPropsInterior
extends RefCounted
## Furniture for the campus interiors (Kenney Furniture Kit, CC0, via
## `Props`). Rooms are the r4 plan's (LEVEL-compound.md §2.3–2.5): ground
## floor y 0, first floor y 4. Everything stands against a wall, clear of
## every doorway; anything you could walk into mid-room (hall chairs,
## canteen chairs) is non-colliding, so the furniture can never close a
## route, a patrol (G6 z -12.5, G4 x 20) or the target's flee path.
##
## Rows are [model, position, yaw degrees, collide]. Furniture faces +z as
## authored; yaw 180 turns it to face north.

const G := [
	# Records (x -10..3, z -20..-14): the scores, filed.
	["furniture/bookcaseClosedWide", Vector3(-8.5, 0, -19.5), 0.0, true],
	["furniture/bookcaseClosedWide", Vector3(-6.4, 0, -19.5), 0.0, true],
	["furniture/bookcaseClosedDoors", Vector3(-4.6, 0, -19.5), 0.0, true],
	["furniture/bookcaseClosedWide", Vector3(0.8, 0, -19.5), 0.0, true],
	["furniture/desk", Vector3(-7, 0, -15), 180.0, true],
	["furniture/computerScreen", Vector3(-7, 0.76, -15.1), 180.0, false],
	["furniture/chairDesk", Vector3(-7, 0, -16.2), 0.0, false],
	["furniture/cardboardBoxClosed", Vector3(2.2, 0, -15), 20.0, false],
	["furniture/cardboardBoxOpen", Vector3(1.6, 0, -16), 0.0, false],
	# Kitchen (x 3..10, z -20..-14).
	["furniture/kitchenFridgeLarge", Vector3(3.7, 0, -19.4), 0.0, true],
	["furniture/kitchenStove", Vector3(5.4, 0, -19.5), 0.0, true],
	["furniture/kitchenStove", Vector3(6.4, 0, -19.5), 0.0, true],
	["furniture/kitchenBar", Vector3(8.0, 0, -19.6), 0.0, true],
	["furniture/kitchenBar", Vector3(3.5, 0, -16.5), 90.0, true],
	["furniture/kitchenCoffeeMachine", Vector3(3.5, 0.84, -16.5), 90.0, false],
	# Canteen (x 3..10, z -14..-8). Doors on all four sides — west x 3 at z
	# -12.5 and -9.5, east x 10 at z -12, north z -14 at x 6 (kitchen), south
	# z -8 at x 7 — so the middle stays empty and the two tables sit against
	# the east wall's corners, off every doorway (tables mid-room once walled
	# off the kitchen door and made you jump the lot).
	["furniture/tableCross", Vector3(9.0, 0, -13.3), 0.0, true],
	["furniture/tableCross", Vector3(9.0, 0, -8.7), 0.0, true],
	["furniture/chair", Vector3(8.5, 0, -9.7), 0.0, false],
	["furniture/chair", Vector3(9.6, 0, -9.7), 0.0, false],
	["furniture/trashcan", Vector3(3.5, 0, -13.7), 0.0, false],
	# Toilets (x -13..-3, z -11..-8, door at x -8 on the south wall).
	["furniture/toilet", Vector3(-12.3, 0, -10.6), 0.0, true],
	["furniture/toilet", Vector3(-11.0, 0, -10.6), 0.0, true],
	["furniture/toilet", Vector3(-4.9, 0, -10.6), 0.0, true],
	["furniture/bathroomSinkSquare", Vector3(-3.4, 0, -9.6), 270.0, true],
	# Panic room G.04 (x -19..-13, z -20..-14): continuity, upholstered.
	["furniture/loungeSofa", Vector3(-18.5, 0, -17.5), 90.0, true],
	["furniture/kitchenFridgeSmall", Vector3(-13.6, 0, -19.4), 0.0, true],
	["furniture/televisionModern", Vector3(-13.3, 1.2, -17.5), 270.0, false],
	# Lobby and west foyer.
	["furniture/pottedPlant", Vector3(-2.6, 0, -7.5), 0.0, false],
	["furniture/pottedPlant", Vector3(1.6, 0, -2.6), 0.0, false],
	["furniture/benchCushion", Vector3(-11, 0, -2.5), 180.0, true],
	["furniture/benchCushion", Vector3(-5.5, 0, -2.5), 180.0, true],
	["furniture/coatRackStanding", Vector3(-12.5, 0, -7.4), 0.0, false],
	# Caretaker: a bucket, the one tool he was scored on.
	["survival/bucket", Vector3(-18.5, 0, -8.5), 0.0, false],
	# Gym store (x 16..28, z -20..-14, PITCH) — corners only; the crawl
	# comes in at (28, -17) and leaves by (22, -14) or (16, -17).
	["survival/box-large", Vector3(17, 0, -19.3), 90.0, true],
	["survival/box-large", Vector3(26.8, 0, -19.3), 90.0, true],
	["survival/box", Vector3(26.8, 0, -14.8), 0.0, true],
	["survival/barrel", Vector3(17, 0, -14.8), 0.0, true],
	# Gym floor: benches down the east wall, out of G4's lane at x 20.
	["furniture/bench", Vector3(27.3, 0, -4), 270.0, true],
	["furniture/bench", Vector3(27.3, 0, 2), 270.0, true],
]

const F := [
	# Assembly hall (floor 4, x -10..6, z -20..-10): the audit's audience,
	# facing the lectern, speakers either side of it.
	["furniture/speaker", Vector3(-8.0, 4, -19.2), 0.0, false],
	["furniture/speaker", Vector3(-4.0, 4, -19.2), 0.0, false],
	["furniture/pottedPlant", Vector3(5.4, 4, -19.4), 0.0, false],
	# Staff room ("Wellness Suite", x -19..-13, z -20..-14): the hatch
	# and its duct box are at x -16.7..-15.3, z -17.7..-15.8 — keep clear.
	["furniture/loungeSofaLong", Vector3(-18.1, 4, -18.6), 90.0, true],
	["furniture/kitchenCoffeeMachine", Vector3(-13.5, 4.8, -19.5), 0.0, false],
	["furniture/sideTable", Vector3(-13.6, 4, -19.5), 0.0, true],
	["furniture/kitchenFridgeSmall", Vector3(-13.6, 4, -18.2), 270.0, true],
	["furniture/pottedPlant", Vector3(-18.5, 4, -14.6), 0.0, false],
	# AV booth (x -10..-3, z -8..-6): the desk under the projection slot.
	["furniture/desk", Vector3(-6.5, 4, -7.5), 0.0, true],
	["furniture/computerScreen", Vector3(-6.2, 4.76, -7.6), 0.0, false],
	["furniture/laptop", Vector3(-7.2, 4.76, -7.5), 0.0, false],
	["furniture/chairDesk", Vector3(-6.5, 4, -6.6), 180.0, false],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for c in G + F:
		Props.place(root, String(c[0]), c[1], float(c[2]), 0.0, bool(c[3]))
	_audience(root)

## Four rows of plastic chairs in front of the lectern. Non-colliding: the
## target walks out through them when the alarm goes.
static func _audience(root: Node3D) -> void:
	for z in [-14.5, -13.2, -11.9, -10.6]:
		for i in 9:
			var x := -8.0 + float(i) * 1.1
			if absf(x - (-2.5)) < 0.6:
				continue   # the aisle
			Props.place(root, "furniture/chair", Vector3(x, 4, z), 0.0, 0.0, false)
