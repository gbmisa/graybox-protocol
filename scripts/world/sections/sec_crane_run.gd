class_name SecCraneRun
extends RefCounted
## THE CRANE RUN — playtest r6: "make an area with platforming, more things to
## jump on". A jumping route from the avenue's car-park deck over the Scoring
## Annex's dock to its roof, the checkpoint's back door. Plus the plant units
## on the main roof, a hop circuit between the plant room and the parapet.
##
## Jump numbers (movement.gd): 1.84 apex, ~5m across at a walk and ~7.5 at a
## sprint on the level. Every gap here is <= 2.5 and every rise <= 1.15, so a
## missed jump is still a mantle; a miss over the dock is a 4-6m drop into
## N2's lane, which is the price.
##
##   C1-C2    crates on the deck x [16, 17.6] (4.15, 5.3) -> the annex's south
##            wall top (6.0)
##   wall     0.4 wide, walk it east to x 16
##   catwalk  6.0, x [3, 20] z [-41.4, -40.4], along the wall's inner face
##   P1       pallet, 6.6, x [15, 17] z [-44, -42.5]
##   P2       pallet, 7.2, x [13.5, 15] z [-46, -44.8]
##   SLIDER   a pallet on a crane line, 6.6, sliding along z [-47.2, -50.2]
##            1.85 over the stacked container; ride it or drop to it
##   P3       the stacked container's top, 4.6, x [12, 15] z [-51, -48.6]
##   P4       pallet, 5.7, x [10.6, 11.8] z [-52, -50.4], pole at x 11.2
##            (N2 walks x 10)
##   P5       pallet, 6.8, x [8.6, 9.6] z [-55, -54], hung over the fire stair
##   P6       pallet, 7.4, x [6.5, 7.5] z [-57.5, -56.5]
##   roof     mantle the 8.5 parapet at x 6 -> annex roof (8.0), behind N5

const PALLET := Color(0.55, 0.42, 0.22)
const CABLE := Color(0.12, 0.12, 0.14)

static func build(root: Node3D, game: GrayboxGame) -> void:
	_climb_to_wall(root)
	_pallets(root)
	_slider(root)
	_crane(root)
	_roof_units(root)

static func _climb_to_wall(root: Node3D) -> void:
	# A catwalk along the annex wall's inner face: 0.4 of wall top alone is a
	# fence to the mantle, not a ledge.
	BuildUtils.plate(root, 3.0, 20.0, -41.4, -40.4, 6.0, 0.2, BuildUtils.METAL)
	WallUtils.block(root, 16.0, 17.6, 3.0, 4.15, -38.6, -37.0, BuildUtils.CRATE)
	WallUtils.block(root, 16.0, 17.6, 3.0, 5.3, -40.0, -38.6, BuildUtils.CRATE)

## A pallet hung on a cable from nowhere in particular (the crane is
## decoration; nobody asks what it hangs from).
static func _hung(root: Node3D, x0: float, x1: float, z0: float, z1: float, top: float) -> void:
	# 0.5 deep, not a thin pallet: a missed jump needs a face at chest height
	# to be caught by the mantle.
	WallUtils.block(root, x0, x1, top - 0.5, top, z0, z1, PALLET)
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	BuildUtils.box(root, Vector3(cx, top + 4.0, cz), Vector3(0.04, 8.0, 0.04), CABLE, false)

static func _pallets(root: Node3D) -> void:
	_hung(root, 15.0, 17.0, -44.0, -42.5, 6.6)
	_hung(root, 13.5, 15.0, -46.0, -44.8, 7.2)
	WallUtils.block(root, 10.6, 11.8, 5.0, 5.7, -52.0, -50.4, PALLET)
	BuildUtils.box(root, Vector3(11.2, 2.5, -51.2), Vector3(0.2, 5.0, 0.2), BuildUtils.PIPE)
	_hung(root, 8.6, 9.6, -55.0, -54.0, 6.8)
	_hung(root, 6.5, 7.5, -57.5, -56.5, 7.4)
	BuildUtils.lamp(root, Vector3(12, 9.0, -50), Color(1.0, 0.45, 0.85), 1.2, 12.0)

## The moving pallet: an AnimatableBody3D, so whoever stands on it rides it.
static func _slider(root: Node3D) -> void:
	var body := AnimatableBody3D.new()
	body.name = "CraneSlider"
	body.position = Vector3(13.5, 6.6 - 0.075, -47.2)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.15, 1.4)
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	BuildUtils.box(body, Vector3.ZERO, shape.size, PALLET, false)
	BuildUtils.box(body, Vector3(0, 4.0, 0), Vector3(0.04, 8.0, 0.04), CABLE, false)
	var tw := body.create_tween().set_loops()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(body, "position:z", -50.2, 2.6).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.8)
	tw.tween_property(body, "position:z", -47.2, 2.6).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.8)

## The crane itself, out of reach: a mast in the dock's NE corner and a jib
## over the run. Drawn, not solid.
static func _crane(root: Node3D) -> void:
	var y := Color(0.85, 0.65, 0.10)
	BuildUtils.box(root, Vector3(19.4, 7.0, -61.4), Vector3(0.8, 14.0, 0.8), y, false)
	BuildUtils.box(root, Vector3(13.0, 14.2, -51.0), Vector3(0.5, 0.5, 21.0), y, false)
	BuildUtils.box(root, Vector3(16.2, 14.2, -61.4), Vector3(7.0, 0.5, 0.5), y, false)

## Plant units on the main roof (8.4): cover and a hop circuit. Heights step
## 0.6 / 1.15 / 1.8 so each is a jump or a mantle from the last. Clear of the
## duct mouth (x 7, z -12), the crate-stair gap (x 10, z [-15, -13.5]), the
## scaffold and fire-escape arrivals, and the plant room's stair (x [-2, 2]).
static func _roof_units(root: Node3D) -> void:
	var r := 8.4
	var units := [
		[-17.0, -14.5, -17.5, -15.5, 0.6], [-14.0, -12.5, -17.5, -15.5, 1.15],
		[-11.5, -10.0, -17.5, -16.0, 1.8], [-18.5, -16.5, -9.5, -7.5, 1.15],
		[-14.5, -12.5, -8.0, -6.5, 0.6], [4.0, 6.0, -18.5, -16.5, 1.15],
		[7.0, 8.5, -7.5, -5.5, 0.6], [-9.0, -7.5, -6.5, -5.0, 1.15],
	]
	for u in units:
		WallUtils.block(root, u[0], u[1], r, r + float(u[4]), u[2], u[3], Color(0.36, 0.38, 0.36))
