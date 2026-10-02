class_name SecAppHeights
extends RefCounted
## The approach's upper level: a second, higher way through each stretch, so
## the walk in is never one flat lane. No fall damage, so every one of these
## is a drop back to the ground wherever you like; getting up is the choice.
##
##   Deck access   stair up the tower's north face (x -11.6 -> -18) to a 4.0
##                 balcony, then a walkway along the west boundary, x [-43.6,
##                 -40.6], over the yard onto the road deck's west end — past
##                 A1 at a height and straight into A3's turn.
##   Pipe bridge   a 1.6m catwalk at 4.0 from the road deck's north rail, x
##                 [37.8, 39.4], over the towpath, the canal and the slipway
##                 to the pumping-station roof (x [37, 43] z [74, 80]), then
##                 a gantry on over the back yards and a short stair up to
##                 the east terrace roof (6.0) — the rooftop way the whole
##                 length of the terraces to the overbridge and the wall top.
##                 (It used to stop on the pumping station: a bridge to a
##                 dead end, "doesn't really go anywhere".)
##   Extensions    five unauthorised extensions up the back of the west
##                 terrace, x [-37.6, -31.6] z [62, 64]: 1.1 · 2.2 · 3.3 ·
##                 4.4 · 5.4, then the terrace roofs at 6.0. The alley gaps
##                 between blocks are 4m — a running jump.
##   Overbridge    a footbridge at 5.0 over the south road, x [-27, -24] z
##                 [27.8, 52]: stairs from the pavement and the verge, and
##                 the terrace roof drops onto its north landing. Its south
##                 landing is 3m and 1m down from the compound wall top.

const DECK := 4.0
const BRIDGE := 5.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_deck_access(root)
	_pipe_bridge(root)
	_extensions(root)
	_overbridge(root)
	_lights(root)

static func _deck_access(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.stairs(root, Vector3(-11.6, 0, 170.5), Vector3(-1, 0, 0),
		8, 0.5, 0.8, 2.2, c)
	BuildUtils.plate(root, -43.6, -18, 169.4, 172, DECK, 0.3, c)          # balcony
	WallUtils.block(root, -40.6, -18, DECK, DECK + 1.0, 169.4, 169.6, c)  # its parapet
	BuildUtils.plate(root, -43.6, -40.6, 138, 169.4, DECK, 0.3, c)        # walkway
	WallUtils.block(root, -40.7, -40.6, DECK, DECK + 1.0, 138, 169.4, BuildUtils.METAL)
	for z in [146.0, 154.0, 162.0]:
		BuildUtils.box(root, Vector3(-42.1, (DECK - 0.3) * 0.5, z),
			Vector3(0.5, DECK - 0.3, 0.5), c)

static func _pipe_bridge(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.plate(root, 37.8, 39.4, 80, 112, DECK, 0.2, m)
	for x in [37.8, 39.4]:
		WallUtils.block(root, x - 0.05, x + 0.05, DECK, DECK + 1.0, 80, 112, m)
	# The pipe it carries, slung under the grating.
	BuildUtils.box(root, Vector3(38.6, DECK - 0.6, 96), Vector3(0.8, 0.8, 32),
		BuildUtils.PIPE)
	for p in [Vector3(38.6, 0, 105), Vector3(38.6, -2.5, 96), Vector3(38.6, 0, 84)]:
		var h: float = DECK - 1.0 - p.y
		BuildUtils.box(root, p + Vector3(0, h * 0.5, 0), Vector3(0.4, h, 0.4), m)
	WallUtils.block(root, 37, 43, 0, DECK, 74, 80, BuildUtils.WALL)       # pumping station
	_gantry(root)

## Pumping-station roof -> over the terrace back yards -> up to the roofs.
static func _gantry(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.plate(root, 38.4, 40.4, 65.6, 74, DECK, 0.2, m)
	for x in [38.4, 40.4]:
		WallUtils.block(root, x - 0.05, x + 0.05, DECK, DECK + 1.0, 65.6, 74, m)
	for z in [67.0, 72.5]:
		for x in [38.5, 40.3]:
			BuildUtils.box(root, Vector3(x, (DECK - 0.2) * 0.5, z),
				Vector3(0.2, DECK - 0.2, 0.2), m)
	BuildUtils.stairs(root, Vector3(39.4, DECK, 65.6), Vector3(0, 0, -1),
		5, 0.4, 0.72, 2.0, m)
	# The roof itself: a tank, a vent stack, and the reason it's fenced off.
	Props.place(root, "city_industrial/detail-tank", Vector3(41.4, DECK, 78.6), 90.0, 3.2)
	BuildUtils.box(root, Vector3(37.8, DECK + 0.9, 74.8), Vector3(0.6, 1.8, 0.6),
		BuildUtils.PIPE)
	SecCmpDressing.plate_sign(root, "ROOF ACCESS BY GRATITUDE ONLY\nTHE WATER IS FINE (CONFIDENTIAL)",
		Vector3(39.4, DECK + 2.5, 74.0), 0.0, SecCmpDressing.PLATE)

## Against the back of the west terrace; each box a year of nobody enforcing.
static func _extensions(root: Node3D) -> void:
	var tops := [1.1, 2.2, 3.3, 4.4, 5.4]
	var tints := [Color(0.15, 0.25, 0.35), Color(0.40, 0.36, 0.30),
		Color(0.34, 0.27, 0.20), Color(0.36, 0.34, 0.33), Color(0.30, 0.30, 0.34)]
	for i in tops.size():
		var x0 := -37.6 + i * 1.2
		WallUtils.block(root, x0, x0 + 1.2, 0, tops[i], 62, 64, tints[i])
	# Chimney stacks along the ridge: cover from the road, and something to
	# read the roofline by.
	for x in [-38.0, -26.0, -15.0, -5.0, 6.0, 14.0, 30.0, 40.0]:
		BuildUtils.box(root, Vector3(x, 6.6, 57), Vector3(1.0, 1.2, 1.6),
			Color(0.26, 0.20, 0.18))

static func _overbridge(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, -27, -24, 27.8, 52, BRIDGE, 0.4, c)
	for x in [-27.0, -24.0]:
		WallUtils.block(root, x - 0.05, x + 0.05, BRIDGE, BRIDGE + 1.0, 32, 46,
			BuildUtils.METAL)
	for z in [46.0, 31.5]:
		BuildUtils.box(root, Vector3(-25.5, (BRIDGE - 0.4) * 0.5, z),
			Vector3(0.6, BRIDGE - 0.4, 0.6), c)
	BuildUtils.stairs(root, Vector3(-16.8, 0, 48.1), Vector3(-1, 0, 0),
		8, 0.625, 0.9, 2.2, c)                                            # pavement
	BuildUtils.stairs(root, Vector3(-16.8, 0, 29.9), Vector3(-1, 0, 0),
		8, 0.625, 0.9, 2.2, c)                                            # verge

static func _lights(root: Node3D) -> void:
	BuildUtils.lamp(root, Vector3(-30, DECK + 2.2, 170.5), BuildUtils.LAMP_SERVICE, 0.7, 9.0)
	BuildUtils.lamp(root, Vector3(38.6, DECK + 2.5, 96), BuildUtils.LAMP_SERVICE, 0.5, 8.0)
	BuildUtils.lamp(root, Vector3(38.6, DECK + 1.6, 110.5), BuildUtils.LAMP_SERVICE, 0.8, 6.0)
	BuildUtils.lamp(root, Vector3(39.4, DECK + 2.2, 70), BuildUtils.LAMP_SERVICE, 0.6, 7.0)
	BuildUtils.lamp(root, Vector3(-25.5, BRIDGE + 2.5, 39), BuildUtils.LAMP_SERVICE, 0.6, 9.0)
