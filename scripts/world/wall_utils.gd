class_name WallUtils
extends RefCounted
## Walls with openings cut into them — doors, windows, slots — built as solid
## pieces around each hole plus a header and sill, so an opening never leaves
## a gap above the door up to the ceiling.
##
## A wall runs `along` "x" (at constant z = `at`) or "z" (at constant x = `at`)
## from a0 to a1, and spans y0..y1. Each opening is [a0, a1, y0, y1] in the
## same axes. Openings may share a stretch of wall (a window over a door) but
## must not overlap vertically where they do.

const DOOR_W := 1.4
const DOOR_H := 2.4

static func wall(parent: Node3D, along: String, at: float, a0: float, a1: float,
		y0: float, y1: float, thick: float, color: Color,
		openings: Array = []) -> void:
	# Cut the wall into vertical strips at every opening edge, then fill each
	# strip around whichever openings cover it.
	var cuts: Array = [a0, a1]
	for o in openings:
		cuts.append(clampf(float(o[0]), a0, a1))
		cuts.append(clampf(float(o[1]), a0, a1))
	cuts.sort()
	for i in range(cuts.size() - 1):
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 <= 0.01:
			continue
		var mid := (s0 + s1) * 0.5
		var holes: Array = []
		for o in openings:
			if float(o[0]) < mid and mid < float(o[1]):
				holes.append(o)
		holes.sort_custom(func(a, b) -> bool: return a[2] < b[2])
		var y := y0
		for o in holes:
			_piece(parent, along, at, s0, s1, y, float(o[2]), thick, color)
			y = maxf(y, float(o[3]))
		_piece(parent, along, at, s0, s1, y, y1, thick, color)

## A standard door opening centred on `c` along the wall, from floor `y`.
static func door(c: float, y: float = 0.0, w: float = DOOR_W,
		h: float = DOOR_H) -> Array:
	return [c - w * 0.5, c + w * 0.5, y, y + h]

## An opening given by its edges, for windows and slots.
static func hole(a0: float, a1: float, y0: float, y1: float) -> Array:
	return [a0, a1, y0, y1]

static func _piece(parent: Node3D, along: String, at: float, a0: float,
		a1: float, y0: float, y1: float, thick: float, color: Color) -> void:
	if a1 - a0 <= 0.01 or y1 - y0 <= 0.01:
		return
	var mid := (a0 + a1) * 0.5
	var y := (y0 + y1) * 0.5
	if along == "x":
		BuildUtils.box(parent, Vector3(mid, y, at), Vector3(a1 - a0, y1 - y0, thick), color)
	else:
		BuildUtils.box(parent, Vector3(at, y, mid), Vector3(thick, y1 - y0, a1 - a0), color)

## A solid block given by its edges — risers, fills, piers.
static func block(parent: Node3D, x0: float, x1: float, y0: float, y1: float,
		z0: float, z1: float, color: Color) -> MeshInstance3D:
	return BuildUtils.box(parent, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, y1 - y0, z1 - z0), color)
