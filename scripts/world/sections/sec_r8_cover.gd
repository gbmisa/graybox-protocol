class_name SecR8Cover
extends RefCounted
## r8 level review: cover and shape where the plans were flat.
##  * Consent Way (81-103 dmg/s head-on, "a shooting gallery"): a stalled van
##    and two more barrier runs, staggered so the walk up it is cover to cover.
##  * The estate yard (A06, an 88x30m lot): two burnt-out bus shelters and a
##    low broken wall that cut it into lanes, plus a torched van.
##  * The road deck (A11, 88x26m flat at 4.0): a jack-knifed lorry and crash
##    barrier runs to fight between.
## All kept off the patrol lanes: N2 x=3 z[-47,-60]; A1 z=156; A7 z=150
## x[-28,-12]; A3 z=125 on the deck.

static func build(root: Node3D, _game: GrayboxGame) -> void:
	_consent_way(root)
	_estate_yard(root)
	_road_deck(root)

static func _consent_way(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	Props.vehicle(root, "car/van", Vector3(-3.6, 0, -51.5), 15.0)
	# Round 2 of the review: longer runs (~5m) and two more on the verges.
	for b in [[4.0, 8.6, -55.5], [-7.4, -2.6, -57.6], [4.4, 8.6, -67.5], [-11.0, -7.4, -62.0], [8.0, 11.0, -62.0]]:
		WallUtils.block(root, b[0], b[1], 0, 1.05, b[2] - 0.3, b[2] + 0.3, c)

static func _estate_yard(root: Node3D) -> void:
	for x in [-14.0, 14.0]:
		_shelter(root, x, 145.0)
	# A broken low wall between the yard and the lane, gaps every few metres.
	for seg in [[-12.0, -6.0], [-3.0, 3.0], [6.0, 11.0]]:
		WallUtils.block(root, seg[0], seg[1], 0, 1.0, 164.0, 164.5, BuildUtils.WALL_DARK)
	var burnt := Props.vehicle(root, "car/van", Vector3(-1.0, 0, 146.0), 80.0)
	if burnt != null:
		for mi in burnt.find_children("*", "MeshInstance3D", true, false):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.08, 0.07, 0.07)
			m.roughness = 1.0
			(mi as MeshInstance3D).material_override = m

## A bus shelter, gutted: back panel, roof, side, a bench of rubble.
static func _shelter(root: Node3D, x: float, z: float) -> void:
	var m := BuildUtils.METAL
	BuildUtils.box(root, Vector3(x, 1.2, z - 1.0), Vector3(4.0, 2.4, 0.12), Color(0.2, 0.22, 0.24))
	BuildUtils.box(root, Vector3(x, 2.5, z), Vector3(4.2, 0.12, 2.2), m)
	BuildUtils.box(root, Vector3(x - 2.0, 1.2, z), Vector3(0.12, 2.4, 2.0), Color(0.2, 0.22, 0.24))
	BuildUtils.box(root, Vector3(x + 2.0, 1.25, z + 1.0), Vector3(0.12, 2.5, 0.12), m)
	BuildUtils.box(root, Vector3(x, 0.25, z - 0.6), Vector3(2.6, 0.5, 0.5), BuildUtils.CONCRETE)

static func _road_deck(root: Node3D) -> void:
	var top := 4.0
	Props.vehicle(root, "car/delivery", Vector3(-14.0, top, 118.5), 70.0)
	Props.vehicle(root, "car/delivery-flat", Vector3(-6.0, top, 131.0), 120.0)
	for b in [[4.0, 12.0, 131.0], [18.0, 26.0, 119.0], [-30.0, -22.0, 131.5], [28.0, 34.0, 130.5]]:
		WallUtils.block(root, b[0], b[1], top, top + 0.9, b[2] - 0.25, b[2] + 0.25, BuildUtils.CONCRETE)
