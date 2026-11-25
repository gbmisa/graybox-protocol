class_name SecAnnexSite
extends RefCounted
## THE CONSENT TOWER SITE — east of the annex, x [18.4, 34] z [-106, -40]:
## the Score's next surveillance tower, going up. r7: "a much longer
## platforming option involving a plank walk ... about as long as the
## current addition area extends back ... a construction zone for a
## surveillance building ... accessible by ladder or staircase".
##
## THE ROUTE, south to north (~70m of it), all of it scaffold, planks and the
## tower's own frame. Jump numbers: 1.84 apex; every gap <= 2.0 and every
## rise <= 1.0, so a short jump is still a mantle. Missing drops you onto the
## site floor (or into the excavation, which has a ramp out); ladders put
## you back on at L1 and L2.
##
##   STAIR     scaffold stair tower x [31.7, 33.3], ground z -41.5 -> L1 (3.0)
##   L1        deck x [28, 34] z [-52, -47.5], 3.0   (ladder up its west face)
##   S1        scaffold walk x [32, 33.6] z [-62, -52], 3.0
##   PLANK 1   0.4 wide, x [32.6, 33.0] z [-70, -62], 3.0 — over the
##             excavation (x [22, 34] z [-72, -62], floor -3.0)
##   S2        bay x [30, 34] z [-74, -70], 3.0
##   LADDER    S2 -> L2 up L2's south face (x 32)
##   L2        deck x [28, 34] z [-78, -74], 6.0   (ladder from the ground on
##             its north face)
##   PLANK 2   0.4 wide, x [21.8, 28] z [-76.2, -75.8], 6.0 — west, past the
##             annex's 1F windows
##   C1        concrete pier top x [20.2, 21.8] z [-77, -75], 6.0
##   BEAM      a steel beam on the crane's hook, x [20.6, 21.4] z [-86, -79],
##             6.4: jump up onto it (2.0 gap, 0.4 rise) and walk it
##   SLIDER    a pallet on the hook, sliding z [-88.3, -91.0] at 6.6
##   C2        pier top x [20.2, 22.2] z [-94, -92.4], 7.0
##   TOWER     frame x [22.4, 32] z [-104.5, -92]: floor 1 (4.0, stair from
##             the ground on its east side), floor 2 (8.0) — mantle up from C2
##             — and a deck at 12.0 by ladder (the crane's view)
##   PLANK 3   x [18.15, 22.4] z [-95.2, -94.8], 8.0 — onto the annex roof
##             through the gap in its parapet, behind N7
##
## The crane (mast x 26, z -84, jib at 24) is the landmark from the avenue.

const PLANK := Color(0.66, 0.50, 0.28)
const SCAFF := Color(0.55, 0.57, 0.60)
const STEEL := Color(0.58, 0.20, 0.14)
const CRANE := Color(0.88, 0.66, 0.10)
const CABLE := Color(0.12, 0.12, 0.14)
const L1 := 3.0
const L2 := 6.0
const F2 := 8.0
const TOP := 12.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_ground(root)
	_stair_and_l1(root)
	_planks_and_l2(root)
	_hook_run(root)
	_tower(root)
	_crane(root)
	_dressing(root)

## Site floor with the excavation cut out, and the pit itself.
static func _ground(root: Node3D) -> void:
	var g := Color(0.26, 0.22, 0.18)   # trodden mud
	BuildUtils.plate(root, 18.4, 34.0, -62.0, -40.0, 0, 1.0, g)
	BuildUtils.plate(root, 18.4, 34.0, -106.0, -72.0, 0, 1.0, g)
	BuildUtils.plate(root, 18.4, 22.0, -72.0, -62.0, 0, 1.0, g)
	BuildUtils.plate(root, 22.0, 34.0, -72.0, -62.0, -3.0, 0.5, Color(0.20, 0.17, 0.14))
	# Pit walls (the plates above hang 1.0 below ground; these close the gap).
	WallUtils.block(root, 21.8, 22.0, -3.0, 0.0, -72.0, -62.0, g)
	WallUtils.block(root, 22.0, 34.0, -3.0, 0.0, -62.2, -62.0, g)
	WallUtils.block(root, 22.0, 34.0, -3.0, 0.0, -72.0, -71.8, g)
	# The way out: a ramp up the pit's west side to the north.
	BuildUtils.ramp(root, Vector3(23.0, -3.0, -63.0), Vector3(0, 0, -1), 8.8, 3.0, 1.6, g, 0)

static func _stair_and_l1(root: Node3D) -> void:
	BuildUtils.ramp(root, Vector3(32.5, 0, -41.5), Vector3(0, 0, -1), 6.0, L1, 1.6, SCAFF, 10)
	BuildUtils.plate(root, 28.0, 34.0, -52.0, -47.5, L1, 0.2, PLANK)
	Ladder.create(root, Vector3(27.94, 0, -50.0), L1, -PI / 2.0)
	BuildUtils.plate(root, 32.0, 33.6, -62.0, -52.0, L1, 0.2, PLANK)
	_standards(root, [Vector3(28, 0, -47.5), Vector3(28, 0, -52), Vector3(32, 0, -56),
		Vector3(32, 0, -62)], L1)
	# Outer rail on S1 (the district wall is behind it anyway).
	BuildUtils.box(root, Vector3(32.0, L1 + 1.0, -57.0), Vector3(0.05, 0.05, 10.0), SCAFF, false)

static func _planks_and_l2(root: Node3D) -> void:
	BuildUtils.plate(root, 32.6, 33.0, -70.0, -62.0, L1, 0.08, PLANK)
	BuildUtils.plate(root, 30.0, 34.0, -74.0, -70.0, L1, 0.2, PLANK)
	_standards(root, [Vector3(30, -3, -70), Vector3(30, 0, -74)], L1)
	Ladder.create(root, Vector3(32.0, L1, -73.94), L2, 0.0)
	BuildUtils.plate(root, 28.0, 34.0, -78.0, -74.0, L2, 0.2, PLANK)
	Ladder.create(root, Vector3(30.0, 0, -78.06), L2, PI)
	_standards(root, [Vector3(28, 0, -74), Vector3(28, 0, -78), Vector3(34, 0, -78)], L2)
	BuildUtils.plate(root, 21.8, 28.0, -76.2, -75.8, L2, 0.08, PLANK)
	WallUtils.block(root, 20.2, 21.8, 0, L2, -77.0, -75.0, BuildUtils.CONCRETE)   # C1

## The beam and the slider hang from the crane's jib (cables to 24).
static func _hook_run(root: Node3D) -> void:
	WallUtils.block(root, 20.6, 21.4, 6.0, 6.4, -86.0, -79.0, STEEL)
	for z in [-80.0, -85.0]:
		BuildUtils.box(root, Vector3(21.0, 15.2, z), Vector3(0.04, 17.6, 0.04), CABLE, false)
	var body := AnimatableBody3D.new()
	body.name = "CraneSlider"
	body.position = Vector3(21.0, 6.6 - 0.1, -88.3)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.2, 1.4)
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	BuildUtils.box(body, Vector3.ZERO, shape.size, PLANK, false)
	BuildUtils.box(body, Vector3(0, 8.7, 0), Vector3(0.04, 17.4, 0.04), CABLE, false)
	var tw := body.create_tween().set_loops()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(body, "position:z", -91.0, 2.8).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.9)
	tw.tween_property(body, "position:z", -88.3, 2.8).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.9)
	WallUtils.block(root, 20.2, 22.2, 0, 7.0, -94.0, -92.4, BuildUtils.CONCRETE)   # C2

static func _tower(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	BuildUtils.plate(root, 22.4, 34.0, -104.5, -100.0, 4.0, 0.3, c)
	BuildUtils.plate(root, 22.4, 32.0, -100.0, -92.0, 4.0, 0.3, c)
	BuildUtils.ramp(root, Vector3(33.2, 0, -92.0), Vector3(0, 0, -1), 8.0, 4.0, 1.4, c, 12)
	# Floor 2: slab with a pour gap, edge at x 22.4 for the mantle from C2.
	BuildUtils.plate(root, 22.4, 32.0, -104.5, -98.0, F2, 0.3, c)
	BuildUtils.plate(root, 22.4, 27.0, -98.0, -92.0, F2, 0.3, c)
	BuildUtils.plate(root, 18.15, 22.4, -95.2, -94.8, F2, 0.08, PLANK)   # PLANK 3
	# Floor 1 -> floor 2: a ladder up the slab's east edge.
	Ladder.create(root, Vector3(27.06, 4.0, -95.0), F2, PI / 2.0)
	# The deck at 12 (the crane's view over everything) by ladder.
	BuildUtils.plate(root, 26.0, 32.0, -104.5, -99.5, TOP, 0.3, STEEL)
	Ladder.create(root, Vector3(29.0, F2, -99.44), TOP, 0.0)
	# Columns and the core: the frame of a tower that will watch the estate.
	for p in [Vector2(22.6, -92.2), Vector2(31.8, -92.2), Vector2(22.6, -104.3), Vector2(31.8, -104.3)]:
		WallUtils.block(root, p.x - 0.2, p.x + 0.2, 0, TOP + 4.0, p.y - 0.2, p.y + 0.2, STEEL)
	WallUtils.block(root, 23.0, 25.5, 0, TOP + 2.0, -104.3, -101.8, c)

static func _crane(root: Node3D) -> void:
	WallUtils.block(root, 25.4, 26.6, 0, 24.0, -84.6, -83.4, CRANE)
	# Jib along z over the hook line (x 21), joined to the mast by an arm.
	# r9: solid — the jib is a grapple line over the site and the annex's east
	# side, and the counterweight (21, 24.2, -96) holds a cache (CACHES).
	BuildUtils.box(root, Vector3(21.0, 24.4, -78.0), Vector3(0.8, 0.8, 34.0), CRANE)
	BuildUtils.box(root, Vector3(23.5, 24.4, -84.0), Vector3(5.8, 0.6, 0.6), CRANE)
	BuildUtils.box(root, Vector3(26.0, 22.6, -86.0), Vector3(2.2, 2.2, 2.6), Color(0.3, 0.3, 0.32))
	BuildUtils.box(root, Vector3(21.0, 23.4, -96.0), Vector3(2.0, 1.6, 3.0), BuildUtils.CONCRETE)
	var beacon := BuildUtils.box(root, Vector3(21.0, 25.0, -61.2), Vector3(0.3, 0.3, 0.3), Color.RED, false)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 0.1, 0.05)
	m.emission_enabled = true
	m.emission = Color(1, 0.1, 0.05)
	m.emission_energy_multiplier = 3.0
	beacon.material_override = m

static func _standards(root: Node3D, at: Array, top: float) -> void:
	for p in at:
		var b: Vector3 = p
		BuildUtils.box(root, Vector3(b.x, (b.y + top) * 0.5, b.z), Vector3(0.1, top - b.y, 0.1), SCAFF, false)

static func _dressing(root: Node3D) -> void:
	# Materials on the floor, off the stair foot, the ladders and the pit ramp.
	WallUtils.block(root, 19.0, 21.0, 0, 0.9, -48.0, -44.0, PLANK)            # timber
	WallUtils.block(root, 24.0, 26.0, 0, 1.2, -56.0, -54.0, BuildUtils.CRATE)  # pallets of block
	WallUtils.block(root, 19.2, 20.4, 0, 2.3, -88.0, -86.6, Color(0.2, 0.45, 0.85))   # portaloo
	WallUtils.block(root, 19.2, 20.4, 0, 2.3, -90.0, -88.6, Color(0.2, 0.45, 0.85))
	for z in [-80.0, -82.0]:
		BuildUtils.box(root, Vector3(31.0, 0.3, z), Vector3(4.0, 0.6, 0.6), STEEL)   # rebar bundles
	BuildUtils.lamps(root, [Vector3(30, L1 + 2.2, -50), Vector3(31, L2 + 2.2, -76),
		Vector3(22, 9.5, -82), Vector3(27, F2 + 2.4, -101), Vector3(28, 0.5, -67)],
		BuildUtils.LAMP_SERVICE, 0.7, 9.0)
	SecCmpDressing.plate_sign(root, "CONSENT TOWER · PHASE 2\nNOW WATCHING FROM 2027",
		Vector3(17.95, 1.5, -70.0), -PI / 2.0, Color(1.0, 0.75, 0.31), 44)
	SecCmpDressing.plate_sign(root, "ALARM SYSTEM NOT YET INSTALLED\nPLEASE PANIC MANUALLY",
		Vector3(28.0, 1.8, -47.4), 0.0, SecCmpDressing.WARN)
