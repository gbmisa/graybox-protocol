class_name SecMezzanine
extends RefCounted
## The convergence floor at y = 6. All three routes arrive here from different
## sides and share the rest of the way up.
##
## Openings in the floor plate, one per route:
##   x [-30, -18]  z [-8,  8]   service stairwell   REGULAR
##   x [ 10,  26]  z [-8,  0]   freight shaft       CHAD
##   x [ -2,  26]  z [ 2, 10]   vent shaft          WIZARD
##   x [ 22,  30]  z [-40, -34] drop chute          exit route
##
## With four openings the plate is built as explicit rectangles rather than
## nested hole-cutting — it is the only form that stays readable when the
## routes move.
##
## From here three stairs run north to the boardroom, each ending at a gate
## only one operative can open. The stairs themselves are open to everyone on
## purpose: you see the doors you cannot use.

const FLOOR_Y := 6.0
const SLAB_T := 0.6
const STAIR_X := [-24.0, 0.0, 22.0]

static func build(root: Node3D, game: GrayboxGame) -> void:
	_slabs(root)
	_railings(root)
	_offices(root)
	_stairs(root)
	_lights(root)
	BuildUtils.label(root, "MEZZANINE", Vector3(-8, 9, -20),
		BuildUtils.GOLD, 40)

## Office strip lighting across the plate, plus one over each of the three
## boardroom stairs so the way up is obvious from anywhere on the floor.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-20, 10, -14), Vector3(0, 10, -18), Vector3(18, 10, -16),
		Vector3(-22, 10, -30), Vector3(6, 10, -30), Vector3(24, 10, -6),
		Vector3(-10, 10, 4), Vector3(-26, 10, 2),
	], BuildUtils.LAMP_FLUORO, 2.2, 22.0)
	for x in STAIR_X:
		BuildUtils.lamp(root, Vector3(x, 10.5, -18), BuildUtils.GOLD, 1.6, 12.0)

static func _slabs(root: Node3D) -> void:
	var c := BuildUtils.FLOOR
	var y := FLOOR_Y
	# z 8..10 — north lip of the vent shaft
	BuildUtils.plate(root, -30, -2, 8, 10, y, SLAB_T, c)
	BuildUtils.plate(root, 26, 30, 8, 10, y, SLAB_T, c)
	# z 2..8 — vent shaft and stairwell both open
	BuildUtils.plate(root, -18, -2, 2, 8, y, SLAB_T, c)
	BuildUtils.plate(root, 26, 30, 2, 8, y, SLAB_T, c)
	# z 0..2 — solid strip separating the vent and freight openings
	BuildUtils.plate(root, -18, 30, 0, 2, y, SLAB_T, c)
	# z -8..0 — freight shaft and stairwell both open
	BuildUtils.plate(root, -18, 10, -8, 0, y, SLAB_T, c)
	BuildUtils.plate(root, 26, 30, -8, 0, y, SLAB_T, c)
	# z -34..-8 — the main floor plate, unbroken
	BuildUtils.plate(root, -30, 30, -34, -8, y, SLAB_T, c)
	# z -40..-34 — cut for the drop chute
	BuildUtils.plate(root, -30, 22, -40, -34, y, SLAB_T, c)

## Guarding along the open edges.
##
## The freight opening gets FULL-HEIGHT barriers rather than knee rails: the
## bay below is a 6m drop that only Chad can climb back out of, so falling in
## must take deliberate effort. The one gap is at x [10, 16] on its north edge,
## which is exactly where the container stack delivers Chad onto the floor.
## Everything else is a knee rail — those drops are all recoverable.
static func _railings(root: Node3D) -> void:
	var c := BuildUtils.METAL
	var y := FLOOR_Y + 0.5
	var tall := FLOOR_Y + 1.5
	BuildUtils.box(root, Vector3(-2.2, y, 6), Vector3(0.3, 1, 8), c)     # vent W
	BuildUtils.box(root, Vector3(26.2, y, 6), Vector3(0.3, 1, 8), c)     # vent E
	BuildUtils.box(root, Vector3(-17.8, y, 0), Vector3(0.3, 1, 16), c)   # stair E
	BuildUtils.box(root, Vector3(-24, y, -8.2), Vector3(12, 1, 0.3), c)  # stair S
	BuildUtils.box(root, Vector3(21.8, y, -37), Vector3(0.3, 1, 6), c)   # chute W
	# Freight opening — 3m barriers, open only at Chad's exit.
	BuildUtils.box(root, Vector3(9.8, tall, -4), Vector3(0.3, 3, 8), c)
	BuildUtils.box(root, Vector3(26.2, tall, -4), Vector3(0.3, 3, 8), c)
	BuildUtils.box(root, Vector3(18, tall, -8.2), Vector3(16, 3, 0.3), c)
	BuildUtils.box(root, Vector3(21, tall, 0.2), Vector3(10, 3, 0.3), c)

## Cubicle blocks and partitions — cover on an otherwise open floor plate.
## All of these sit on the unbroken z [-34, -8] band.
static func _offices(root: Node3D) -> void:
	var desks := [
		Vector3(-20, 0, -12), Vector3(-8, 0, -16), Vector3(-14, 0, -28),
		Vector3(4, 0, -14), Vector3(-4, 0, -30), Vector3(14, 0, -24),
		Vector3(24, 0, -18), Vector3(10, 0, -32),
	]
	for i in range(desks.size()):
		var tall := i % 3 == 0
		var size := Vector3(3.0, 1.8, 1.2) if tall else Vector3(2.2, 1.1, 2.2)
		BuildUtils.box(root, desks[i] + Vector3(0, FLOOR_Y + size.y * 0.5, 0),
			size, BuildUtils.METAL if tall else BuildUtils.CRATE)
	# Server cabinets flanking the Regular's stair, so his route reads as the
	# back-of-house one all the way up.
	for z in [-14.0, -18.0]:
		BuildUtils.box(root, Vector3(-27, FLOOR_Y + 1.4, z),
			Vector3(2, 2.8, 1.4), BuildUtils.PIPE)

## Three parallel flights up to the boardroom gates, z -12 to -24.
static func _stairs(root: Node3D) -> void:
	for x in STAIR_X:
		BuildUtils.stairs(root, Vector3(x, FLOOR_Y, -12), Vector3(0, 0, -1),
			12, 0.5, 1.0, 4.0, BuildUtils.CONCRETE)
