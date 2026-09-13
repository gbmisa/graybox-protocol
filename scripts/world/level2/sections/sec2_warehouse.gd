class_name Sec2Warehouse
extends RefCounted
## The impound warehouse: x [-60, -24], z [-18, 12], 7m walls. Chad's vector.
##
##   CORRUGATED WEST WALL (-60, 0, -3) [smash] — perimeter breach
##   east personnel door (-24, 0, -5.5)        open — exit to the yard gap
##
## The west wall IS the perimeter here (the fence stops at z = -18 and
## z = 12). The breach lands inside at (-58, 0, -3) with 60 noise, and both
## warehouse guards' patrols run through the east-personnel-door corridor —
## so the smash pulls them onto Chad's exit route. Loud is the point.
##
## Interior: pallet stacks as cover, forklift, cage. Everything off the
## patrol corridor and off the breach-to-door lane.

static func build(root: Node3D, game: GrayboxGame) -> void:
	var w := BuildUtils.WALL
	var x0 := -60.0
	var x1 := -24.0
	var z0 := -18.0
	var z1 := 12.0
	var wh := 7.0
	var t := 0.6
	# North and south walls.
	BuildUtils.box(root, Vector3(-42, wh * 0.5, z0), Vector3(36 + t, wh, t), w)
	BuildUtils.box(root, Vector3(-42, wh * 0.5, z1), Vector3(36 + t, wh, t), w)
	# West wall: corrugated, split around the 3m breach panel at z [-4.5, -1.5].
	BuildUtils.box(root, Vector3(x0, wh * 0.5, -11.25),
		Vector3(t, wh, 13.5), w)
	BuildUtils.box(root, Vector3(x0, wh * 0.5, 5.25),
		Vector3(t, wh, 13.5), w)
	BuildUtils.box(root, Vector3(x0, 5.0, -3),
		Vector3(t, 4, 3.6), w)  # lintel above the breach panel
	BreakableWall.create(game, root, "CORRUGATED WEST WALL",
		Vector3(x0, 1.5, -3), Vector3(t, 3, 3))
	# East wall: split around the open personnel door at z [-7, -4].
	BuildUtils.box(root, Vector3(x1, wh * 0.5, 4.0),
		Vector3(t, wh, 16), w)
	BuildUtils.box(root, Vector3(x1, wh * 0.5, -12.5),
		Vector3(t, wh, 11), w)
	BuildUtils.box(root, Vector3(x1, 4.75, -5.5),
		Vector3(t, 4.5, 3.6), w)  # lintel above the open door
	BuildUtils.label(root, "PERSONNEL — EAST YARD",
		Vector3(x1 + 0.4, 3.6, -5.5), Color(0.35, 0.70, 1.0), 26)
	# Roof.
	BuildUtils.box(root, Vector3(-42, wh + 0.3, -3),
		Vector3(36 + t, 0.6, 30 + t), BuildUtils.METAL)
	# Interior.
	_pallets(root)
	BuildUtils.label(root, "IMPOUND WAREHOUSE — SEIZED GOODS",
		Vector3(-42, 4.5, z0 + 0.4), Color(1.0, 0.52, 0.18), 34)
	BuildUtils.lamp(root, Vector3(-48, 5.5, -6), BuildUtils.LAMP_FLUORO,
		2.2, 14.0)
	BuildUtils.lamp(root, Vector3(-32, 5.5, 2), BuildUtils.LAMP_FLUORO,
		2.2, 14.0)
	# Forklift, parked clear of the patrol corridor.
	BuildUtils.box(root, Vector3(-50, 1.0, 8), Vector3(2.2, 2, 3.4),
		Color(0.75, 0.45, 0.1))
	BuildUtils.label(root, "FORKLIFT — DO NOT",
		Vector3(-50, 2.6, 8), Color(1.0, 0.52, 0.18), 24)

## Pallet stacks: 1.2m cover boxes, all clear of the breach-to-door lane
## (z [-7, 1] west-east) and the patrol corridor near the east door.
static func _pallets(root: Node3D) -> void:
	var c := Color(0.45, 0.36, 0.26)
	var spots := [
		Vector3(-52, 0.6, -12), Vector3(-46, 0.6, -13), Vector3(-49, 0.6, 6),
		Vector3(-36, 0.6, -14), Vector3(-30, 0.6, 8), Vector3(-38, 0.6, 9),
		Vector3(-54, 0.6, 2), Vector3(-28, 0.6, -12),
	]
	for s in spots:
		BuildUtils.box(root, s, Vector3(2.4, 1.2, 2.4), c)
