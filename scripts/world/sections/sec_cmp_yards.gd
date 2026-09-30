class_name SecCmpYards
extends RefCounted
## The interior open ground: north yard, west yard, courtyard, refuse yard,
## gym forecourt. Together with the main block, gym and alley (later blocks)
## these tile the full compound footprint with no gaps and no overlaps —
## each zone's extent in §2.2 already shares an edge with its neighbours.
##
## North yard x [-28, 28] z [-24, -20], LIT. West yard x [-28, -22] z [-20, 24],
## DARK. Courtyard x [-22, 16] z [-2, 24], mast at (0, 0, 10). Refuse yard
## x [16, 28] z [11, 24], PITCH, 2.2m fence (Chad band) with a plain gate at
## (16, 0, 19). Gym forecourt x [16, 28] z [8, 11], under the canopy.
## Light tiers themselves (the Area3D volumes) are Block 11 — this file only
## places the visible lamps.

const FENCE_H := 2.2

static func build(root: Node3D, game: GrayboxGame) -> void:
	_north_yard(root)
	_west_yard(root)
	_courtyard(root)
	_refuse_yard(root)
	_forecourt(root)

static func _north_yard(root: Node3D) -> void:
	BuildUtils.plate(root, -28, 28, -24, -20, 0, 1.0, BuildUtils.GROUND)
	BuildUtils.lamps(root, [
		Vector3(-20, 3.5, -22), Vector3(0, 3.5, -22), Vector3(20, 3.5, -22),
	], BuildUtils.LAMP_FLUORO, 2.6, 16.0)

## Culvert grate and crawl itself live in `sec_cmp_perimeter._west_alley` —
## this only marks the mouth and the smoking shelter.
static func _west_yard(root: Node3D) -> void:
	BuildUtils.plate(root, -28, -22, -20, 24, 0, 1.0, BuildUtils.GROUND)
	# Smoking shelter (R3): flat roof on two posts, no walls.
	BuildUtils.box(root, Vector3(-25, 2.4, 16), Vector3(2.6, 0.15, 2.6), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(-26, 1.1, 15), Vector3(0.15, 2.2, 0.15), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(-24, 1.1, 17), Vector3(0.15, 2.2, 0.15), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(-25, 0.25, 16), Vector3(1.2, 0.5, 0.5), BuildUtils.CRATE)
	BuildUtils.lamp(root, Vector3(-25, 2.2, 16), BuildUtils.LAMP_SERVICE, 0.7, 7.0)

## Open ground only — walls for the main block, alley and gym arrive with
## those sections. The mast is the courtyard's one piece of hard cover.
static func _courtyard(root: Node3D) -> void:
	BuildUtils.plate(root, -22, 16, -2, 24, 0, 1.0, BuildUtils.GROUND)
	BuildUtils.box(root, Vector3(0, 3.75, 10), Vector3(0.4, 7.5, 0.4), BuildUtils.METAL)
	BuildUtils.box(root, Vector3(0, 7.6, 10), Vector3(1.2, 0.2, 1.2), BuildUtils.METAL)
	# Tagged so the caretaker's mast isolator can find and kill them.
	for spot in [Vector3(0.4, 7.4, 10), Vector3(-0.4, 7.4, 10.4), Vector3(0.4, 7.4, 9.6)]:
		var l := BuildUtils.lamp(root, spot, Color(0.95, 0.97, 1.0), 3.0, 17.0)
		l.add_to_group("mast_lamp")

## The 2.2m fence is Chad's band exactly (skip 2.2 -> canopy 4.4 -> ...), so
## it must read as solid, not a lattice, or his mantle's chest probe finds
## nothing to grab.
static func _refuse_yard(root: Node3D) -> void:
	BuildUtils.plate(root, 16, 28, 11, 24, 0, 1.0, BuildUtils.GROUND)
	var c := BuildUtils.WALL_DARK
	var y := FENCE_H * 0.5
	# West fence, with the plain gate gap at z [18.25, 19.75].
	BuildUtils.box(root, Vector3(16, y, 14.6), Vector3(0.2, FENCE_H, 7.2), c)
	BuildUtils.box(root, Vector3(16, y, 21.9), Vector3(0.2, FENCE_H, 4.2), c)
	# North fence, under the canopy's south edge.
	BuildUtils.box(root, Vector3(22, y, 11), Vector3(12, FENCE_H, 0.2), c)
	BuildUtils.box(root, Vector3(22, 1.1, 12), Vector3(3, 2.2, 2), BuildUtils.CRATE)

static func _forecourt(root: Node3D) -> void:
	BuildUtils.plate(root, 16, 28, 8, 11, 0, 1.0, BuildUtils.GROUND)
	# Canopy: full solid slab, not a thin roof on posts — the mantle's chest
	# probe needs real depth to find here (§2.5).
	BuildUtils.box(root, Vector3(22, 3.7, 9.5), Vector3(8, 1.4, 3), BuildUtils.CONCRETE)
