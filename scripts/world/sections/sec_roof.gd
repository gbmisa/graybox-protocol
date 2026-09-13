class_name SecRoof
extends RefCounted
## Helipad extraction at y = 18.6, reached by the stair at the west end of the
## boardroom. Open to all three operatives — the routes diverge on the way in,
## not on the way out.

const ROOF_Y := 18.6
const SLAB_T := 0.6

static func build(root: Node3D, game: GrayboxGame) -> void:
	_stair(root)
	_slab(root)
	_pad(root, game)
	_plant(root)

## Boardroom floor (12.0) up to the roof deck (18.6).
static func _stair(root: Node3D) -> void:
	BuildUtils.stairs(root, Vector3(-25, 12.0, -38), Vector3(0, 0, 1),
		12, 0.55, 1.0, 5.0, BuildUtils.CONCRETE)

## Cut at x [-30, -20], z [-40, -24] — the opening must span the WHOLE stair
## run, not just its top step. Cut only to z = -28 the climber's head hit the
## underside of the slab around y = 16.4 and the stair dead-ended.
static func _slab(root: Node3D) -> void:
	var deck := BuildUtils.WALL_DARK
	BuildUtils.plate(root, -30, 30, -24, 10, ROOF_Y, SLAB_T, deck)
	BuildUtils.plate(root, -20, 30, -40, -24, ROOF_Y, SLAB_T, deck)
	# Parapet, so the deck reads as a surface rather than an edge.
	var rail := BuildUtils.METAL
	var y := ROOF_Y + 0.6
	BuildUtils.box(root, Vector3(0, y, -40), Vector3(60, 1.2, 0.4), rail)
	BuildUtils.box(root, Vector3(0, y, 10), Vector3(60, 1.2, 0.4), rail)
	BuildUtils.box(root, Vector3(-30, y, -15), Vector3(0.4, 1.2, 50), rail)
	BuildUtils.box(root, Vector3(30, y, -15), Vector3(0.4, 1.2, 50), rail)

static func _pad(root: Node3D, game: GrayboxGame) -> void:
	BuildUtils.box(root, Vector3(0, ROOF_Y + 0.1, -20), Vector3(12, 0.2, 12),
		Color(0.10, 0.45, 0.22))
	# Markings are visual only — a solid 0.26m lip on the pad would trip you
	# up on the last step of the extraction.
	BuildUtils.box(root, Vector3(0, ROOF_Y + 0.16, -20), Vector3(8, 0.2, 1.2),
		BuildUtils.GREEN, false)
	BuildUtils.box(root, Vector3(0, ROOF_Y + 0.16, -20), Vector3(1.2, 0.2, 8),
		BuildUtils.GREEN, false)
	BuildUtils.label(root, "EXTRACTION — HELIPAD",
		Vector3(0, ROOF_Y + 4, -20), BuildUtils.GREEN)
	BuildUtils.zone(root, game, "helipad", Vector3(0, ROOF_Y + 1, -20), 5.0)

## Rooftop plant: cover on the pad approach, and a 2.2m block Chad can mantle
## for a shortcut the others have to walk around.
static func _plant(root: Node3D) -> void:
	BuildUtils.box(root, Vector3(18, ROOF_Y + 1.6, -32), Vector3(8, 3.2, 6),
		BuildUtils.WALL)
	BuildUtils.box(root, Vector3(-14, ROOF_Y + 1.1, -6), Vector3(6, 2.2, 6),
		BuildUtils.WALL)
	for x in [10.0, 22.0]:
		BuildUtils.box(root, Vector3(x, ROOF_Y + 0.9, -4),
			Vector3(2.4, 1.8, 2.4), BuildUtils.PIPE)
