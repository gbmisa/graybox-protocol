extends SceneTree
## Headless HOLLOWAY CAMPUS check — implements only cases 1, 25 and 26 of
## docs/LEVEL-compound.md §14 (the rest land in Block 15):
##
##     godot --headless --path . --script res://tools/smoketest_compound.gd
##
## Same reasoning as tools/smoketest.gd: nodes added to the root before the
## tree starts never get _ready called, so this waits a few frames before
## measuring anything. `LevelCompound.build()` is still empty until Block 7
## wires in the `sec_cmp_*.gd` sections, so until then every point here is
## expected to fail with "no floor" — that failure is the wiring check, not
## a bug in this file.

var _frame := 0
var _game: GrayboxGame
var _bad := 0

## label, position, headroom expectation (§0-D / case 25)
##   ""        must be standable: >= 1.8m clear (H1)
##   "crawl"   a declared crawl gap: ~1.0m
##   "squeeze" a declared squeeze gap: ~0.6m
##   "any"     transitional (a ramp, an open-air drop), height not asserted
## Built from §4's three vectors — the Regular's, Wizard's and Chad's routes,
## including the extraction options each one reaches.
const POINTS := [
	# --- THE APPROACH (sec_app_*) ---
	["A spawn", Vector3(0, 0, 190), ""],
	["A tower lobby", Vector3(-19, 0, 183), ""],
	["A garage bay 3", Vector3(21, 0, 184), ""],
	["A garage roof", Vector3(20, 2.6, 178), ""],
	["A back strip", Vector3(36, 0, 180), ""],
	["A estate yard", Vector3(0, 0, 156), ""],
	["A subway", Vector3(0, 0, 125), ""],
	["A culvert", Vector3(-30, 0, 125), "crawl"],
	["A road deck", Vector3(0, 4, 125), ""],
	["A towpath", Vector3(0, 0, 106), ""],
	["A rota hut", Vector3(23, 0, 107), ""],
	["A footbridge", Vector3(0, 0, 96), ""],
	["A canal bed", Vector3(10, -2.5, 96), ""],
	["A under the footbridge", Vector3(0, -2.5, 96), ""],
	["A boat cabin roof", Vector3(-23, 0.3, 96), ""],
	["A west slipway", Vector3(-40, -1.25, 102.5), "any"],
	["A east slipway", Vector3(40, -1.25, 89.5), "any"],
	["A allotments", Vector3(0, 0, 76), ""],
	["A shed roof", Vector3(8, 2.4, 86), ""],
	["A alley", Vector3(0, 0, 57), ""],
	["A walk-through house", Vector3(-10, 0, 57), ""],
	["A terrace front", Vector3(0, 0, 49), ""],
	# --- THE HIGH WAYS THROUGH (sec_app_heights, sec_cmp_climbs) ---
	["H deck-access balcony", Vector3(-30, 4.0, 170.7), ""],
	["H walkway over the yard", Vector3(-42.1, 4.0, 150), ""],
	["H walkway meets the road deck", Vector3(-42.1, 4.0, 137), ""],
	["H pipe bridge over the canal", Vector3(38.6, 4.0, 96), ""],
	["H pumping station roof", Vector3(40, 4.0, 77), ""],
	["H gantry over the back yards", Vector3(39.4, 4.0, 70), ""],
	["H gantry stair top", Vector3(39.4, 6.0, 61.4), ""],
	["H corridor floor over the lobby", Vector3(-0.5, 4.0, -4.0), ""],
	["H east terrace roof", Vector3(30, 6.0, 57), ""],
	["H billboard scaffold landing 1", Vector3(16.4, 4.5, 30.7), ""],
	["H billboard scaffold landing 2", Vector3(8.8, 9.0, 30.7), ""],
	["H billboard catwalk", Vector3(0, 13.5, 27.8), ""],
	["H billboard catwalk west end", Vector3(-15, 13.5, 27.8), ""],
	["H top extension", Vector3(-32.2, 5.4, 63), ""],
	["H terrace roof", Vector3(-30, 6.0, 57), ""],
	["H overbridge span", Vector3(-25.5, 5.0, 39), ""],
	["H overbridge verge landing", Vector3(-25.5, 5.0, 29), ""],
	["H compound wall top", Vector3(-25.5, 4.0, 24.4), ""],
	["H boiler climb cabinet", Vector3(-34.75, 3.2, -14.25), ""],
	["H boiler house roof", Vector3(-31, 4.0, -13), ""],
	["H fire escape landing", Vector3(-23.15, 4.0, -11.5), ""],
	["H 1F west strip", Vector3(-20.5, 4.0, -11), ""],
	["H fire escape top", Vector3(-23.15, 8.4, -2.2), ""],
	["H scaffold lift", Vector3(-8.1, 4.0, 0), ""],
	["H scaffold top", Vector3(-17.1, 8.4, 0), ""],
	# --- THE REGULAR — "Deliveries" (§4.1) ---
	["R spawn", Vector3(0, 0, 40), ""],
	["R east lane", Vector3(30, 0, 30), ""],
	["R gym shutter", Vector3(28, 0, -17), "crawl"],
	["R gym store", Vector3(22, 0, -14), ""],
	["R alley crate base", Vector3(13, 0, -17), ""],
	["R crate stack top", Vector3(11, 6.9, -14.25), ""],
	["R main roof", Vector3(9, 8.4, -14), ""],
	["R vent intake", Vector3(6, 8.4, -12), "crawl"],
	["R roof duct", Vector3(4, 8.4, -12), "crawl"],
	["R duct drop", Vector3(1.0, 7.0, -12), "crawl"],
	["R ceiling void", Vector3(-1, 7.0, -10), "crawl"],
	["R gallery under grille", Vector3(-2, 5.0, -9), ""],
	["R gallery", Vector3(-6, 5.0, -9), ""],
	["R hall floor", Vector3(-2, 4.0, -12), ""],
	["R west landing", Vector3(-15, 4.0, -10), ""],
	["R west stair top", Vector3(-13, 4.0, -4), ""],
	["R west corridor", Vector3(-20.5, 0, -6), ""],
	["R culvert", Vector3(-27, 0, 6), "crawl"],
	["R outfall / van E1", Vector3(-36.2, -2.2, 6), ""],

	# --- THE WIZARD — "Decommissioned" (§4.2) ---
	["W west alley", Vector3(-32, 0, 30), ""],
	["W outfall pit crossing", Vector3(-34, -2.2, 10), "any"],
	["W warded door", Vector3(-34, 0, -13), ""],
	["W boiler house", Vector3(-31, 0, -13), ""],
	["W boiler basement", Vector3(-31, -3.0, -15), ""],
	["R undercroft crawl, mouth", Vector3(-28, -3, -17.5), "crawl"],
	["R undercroft crawl, exit", Vector3(-22.8, -3, -17.5), "crawl"],
	["W undercroft dry floor", Vector3(-20.5, -3, -17.0), ""],
	["W spur walkway", Vector3(-16, -3, -10.3), ""],
	["W caretaker spur ramp", Vector3(-16, -1.5, -8.9), "any"],
	["W caretaker landing", Vector3(-18.5, 0, -9.0), ""],
	["R shutter crawl", Vector3(-20.5, 0, -11), "crawl"],
	["W south corridor", Vector3(-13, 4.0, -4), ""],
	["W west landing", Vector3(-15, 4.0, -10), ""],
	["W deck E2", Vector3(23.5, 11.2, -4.6), ""],

	# --- GIGA CHAD — "Structural Review" (§4.3) ---
	["C cracked wall", Vector3(22, 0, 24), ""],
	["C refuse yard", Vector3(22, 0, 18), ""],
	["C skip top", Vector3(22, 3.3, 12), ""],
	["C canopy top", Vector3(22, 4.4, 9.5), ""],
	["C gym roof", Vector3(22, 6.6, -8), ""],
	["C hatch crate top", Vector3(22, 6.2, -11), ""],
	["C mezzanine", Vector3(22, 4.0, -11), ""],
	["C bridge roof", Vector3(13, 6.6, -12), ""],
	["C east landing", Vector3(8, 4.0, -14), ""],
	["C hall rear door", Vector3(6, 4.0, -14), ""],
	["C portico roof", Vector3(0, 2.7, -1.0), ""],

	# --- SCORING ANNEX DISTRICT (r7: sec_annex, _building, _site) ---
	["N checkpoint gate", Vector3(0, 0, -40.2), ""],
	["N service crawl", Vector3(-15, 0, -40.2), "crawl"],
	["N consent way", Vector3(0, 0, -58), ""],
	["N booth", Vector3(-10, 0, -58.5), ""],
	["N under the canopy", Vector3(0, 0, -74.5), ""],
	["N car park", Vector3(-24, 0, -50), ""],
	["N back strip", Vector3(-8, 0, -101), ""],
	["N lobby", Vector3(0, 0, -79), ""],
	["N security", Vector3(-12, 0, -78), ""],
	["N hall", Vector3(-4, 0, -88), ""],
	["N stair hall", Vector3(16.5, 0, -80), ""],
	["N annex stair", Vector3(11, 2.0, -78.6), "any"],
	["N 1F corridor", Vector3(-8, 4.0, -78), ""],
	["N 1F offices", Vector3(-12, 4.0, -90), ""],
	["N server room", Vector3(0, 4.0, -90), ""],
	["N east office", Vector3(12, 4.0, -90), ""],
	["N annex roof", Vector3(-4, 8.0, -86), ""],
	["S site floor", Vector3(26, 0, -50), ""],
	["S scaffold L1", Vector3(30, 3.0, -50), ""],
	["S scaffold S1", Vector3(32.8, 3.0, -57), ""],
	["S bay S2", Vector3(31, 3.0, -72), ""],
	["S excavation", Vector3(28, -3.0, -67), ""],
	["S scaffold L2", Vector3(31, 6.0, -76), ""],
	["S tower floor 1", Vector3(28, 4.0, -102), ""],
	["S tower floor 2", Vector3(24.5, 8.0, -100), ""],
	["S tower deck", Vector3(29, 12.0, -102), ""],
	["C landing plate", Vector3(0, 4.0, -2.6), ""],
	["C south corridor west arm", Vector3(-6, 4.0, -4), ""],
	["C north corridor", Vector3(-8, 0, -12.5), ""],
	["C panic room door", Vector3(-16, 0, -14), ""],
	["C deck E2", Vector3(23.5, 11.2, -4.6), ""],
	["C helipad stair (Regular's way up)", Vector3(23.5, 8.9, -1.0), "any"],
]

## Declared openings from §2.3 / §2.4: label, door position, the axis you
## walk *through* ("x" or "z"), and the axis the 1.2m width runs *along*.
## Guessed from the plan view in §2.1 where the table doesn't say outright —
## Block 7 is where a wrong guess here shows up as a false fail, not this one.
const DOORS := [
	["west corridor <-> west yard", Vector3(-22, 0, -6), "x", "z"],
	["panic room <-> corridor", Vector3(-16, 0, -14), "z", "x"],
	["caretaker <-> west corridor", Vector3(-19, 0, -9.1), "x", "z"],
	["toilets <-> west foyer", Vector3(-8, 0, -8), "z", "x"],
	["lobby <-> portico", Vector3(0, 0, -2), "z", "x"],
	["south corridor <-> AV booth", Vector3(-9, 4, -6), "z", "x"],
	["west landing <-> staff room", Vector3(-16, 4, -14), "z", "x"],
	["west landing <-> hall main doors", Vector3(-10, 4, -11), "x", "z"],
	["east landing <-> hall rear door", Vector3(6, 4, -14), "x", "z"],
	["east landing <-> bridge door", Vector3(10, 4, -12), "x", "z"],
	["kitchen <-> canteen", Vector3(6, 0, -14), "z", "x"],
	["records <-> north corridor", Vector3(-3, 0, -14), "z", "x"],
	["north corridor <-> canteen", Vector3(3, 0, -12.5), "x", "z"],
	["CSD passage <-> canteen", Vector3(3, 0, -9.5), "x", "z"],
	["north corridor <-> CSD passage", Vector3(0, 0, -11), "z", "x"],
	["canteen <-> east stair passage", Vector3(7, 0, -8), "z", "x"],
	["canteen <-> alley (L1)", Vector3(10, 0, -12), "x", "z"],
	["gym store <-> alley", Vector3(16, 0, -17), "x", "z"],
	["gym store <-> gym floor", Vector3(22, 0, -14), "z", "x"],
	["gym floor <-> forecourt", Vector3(22, 0, 8), "z", "x"],
	["gym mezzanine <-> bridge", Vector3(16, 4, -12), "x", "z"],
	["N-stair landing <-> hall", Vector3(-10, 4, -19.2), "x", "z"],
	["gatehouse <-> north yard", Vector3(-6, 0, -24.4), "z", "x"],
	["east lane <-> refuse yard (bin gate)", Vector3(28.4, 0, 18), "x", "z"],
	["fire escape <-> 1F west strip", Vector3(-22, 4, -11.5), "x", "z"],
	["1F west strip <-> west landing", Vector3(-19, 4, -9.5), "x", "z"],
	["scaffold lift <-> 1F south corridor", Vector3(-8.1, 4, -2), "z", "x"],
]

## Explicit two-point checks §14.26 calls out by name: label, from, to,
## whether a capsule is expected to walk between them.
const LINES := [
	["subway runs through the embankment", Vector3(0, 1, 138.5), Vector3(0, 1, 111.5), true],
	["embankment is solid elsewhere", Vector3(10, 1, 138.5), Vector3(10, 1, 111.5), false],
	["culvert runs through (low)", Vector3(-30, 0.5, 138.5), Vector3(-30, 0.5, 111.5), true],
	["terrace alley goes through", Vector3(0, 1, 63), Vector3(0, 1, 51), true],
	["walk-through house goes through", Vector3(-10, 1, 63), Vector3(-10, 1, 51), true],
	["terrace block is solid", Vector3(10, 1, 63), Vector3(10, 1, 51), false],
	["approach reaches the south road", Vector3(0, 1, 47), Vector3(0, 1, 40), true],
	["east shelf -> passage E mouth", Vector3(3, 4, -4), Vector3(3, 4, -7.4), true],
	["passage E -> east landing", Vector3(3, 4, -7), Vector3(8, 4, -7), true],
	["west foyer -/-> west stair well (M8)", Vector3(-8, 0, -5), Vector3(-16, 0, -4), false],
	["road deck -> deck-access walkway", Vector3(-42.1, 4.5, 136), Vector3(-42.1, 4.5, 140), true],
	["road deck -> pipe bridge", Vector3(38.6, 4.5, 114), Vector3(38.6, 4.5, 110), true],
	["fire escape top -> roof", Vector3(-23.15, 8.9, -2.5), Vector3(-20, 8.9, -2.5), true],
	["scaffold top -> roof", Vector3(-17.1, 8.9, 0), Vector3(-17.1, 8.9, -4), true],
	# G12: the west stair's ramp used to poke 0.75m through the foyer's west
	# wall just under the ceiling ("something sticking out of the wall").
	["west foyer ceiling clear to the wall (G12)", Vector3(-5, 3.3, -4), Vector3(-12.7, 3.3, -4), true],
	["1F corridor crosses the lobby void", Vector3(-3.6, 4.4, -4.0), Vector3(2.6, 4.4, -4.0), true],
	# A tree once stood across the foot of the deck-access stair.
	["deck-access stair foot, south edge", Vector3(-8, 1.0, 169.6), Vector3(-11.5, 1.0, 169.6), true],
	["deck-access stair foot, north edge", Vector3(-8, 1.0, 171.4), Vector3(-11.5, 1.0, 171.4), true],
	["pumping station roof -> gantry", Vector3(39.4, 4.5, 76), Vector3(39.4, 4.5, 68), true],
	["scaffold top landing -> catwalk round the board", Vector3(16.4, 14.0, 30.5), Vector3(16.4, 14.0, 27.8), true],
	["helipad stair top -> deck", Vector3(23.5, 11.7, -3.0), Vector3(23.5, 11.7, -4.8), true],
]

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_game = GrayboxGame.new()
		root.add_child(_game)
		_game.selected_char = "regular"
		_game.selected_level = "compound"
		_game.flow.start_mission()
		return false
	if _frame < 8:
		return false          # let the physics server register the new bodies
	var space := _game.get_world_3d().direct_space_state
	_check_points(space)
	_check_openings(space)
	print("\n%d problem(s)" % _bad)
	return true

func _fail(msg: String) -> void:
	_bad += 1
	print("  FAIL  %s" % msg)

# ------------------------------------------------------- floor / headroom ---
## Cases 1 and 25: floor under every route point, and the general headroom
## sweep — 1.8m clear unless the point is a declared crawl (1.0) or squeeze
## (0.6). Failures are reported as coordinates, per the block spec.
func _check_points(space: PhysicsDirectSpaceState3D) -> void:
	print("-- floor and headroom (cases 1, 25) --")
	for entry in POINTS:
		var label: String = entry[0]
		var pos: Vector3 = entry[1]
		var want: String = entry[2]
		var floor_y := _floor_under(space, pos, want)
		if floor_y < -900.0:
			_fail("%s has no floor at %s" % [label, pos])
			continue
		var floor_pos := Vector3(pos.x, floor_y, pos.z)
		var head := _headroom(space, floor_pos)
		var note := ""
		if want == "crawl" and (head < 0.9 or head > 1.35):
			note = " <-- crawl gap should be ~1.0m"
			_bad += 1
		elif want == "squeeze" and (head < 0.45 or head > 0.75):
			note = " <-- squeeze gap should be ~0.6m"
			_bad += 1
		elif want == "" and head < 1.8:
			note = " <-- needs 1.8m clear headroom (H1) at %s" % floor_pos
			_bad += 1
		print("  %-28s y=%7.2f head=%5.2f%s" % [label, floor_y, head, note])

# --------------------------------------------------------------- openings ---
## Case 26: every declared opening shares at least 1.2m of edge and a 0.85
## capsule can walk through it. Approximated the same way the rest of this
## tool approximates a capsule — a raycast down the throat of the opening,
## plus one at each edge of the required 1.2m width.
func _check_openings(space: PhysicsDirectSpaceState3D) -> void:
	print("-- declared openings (case 26 / H2) --")
	for entry in DOORS:
		var label: String = entry[0]
		var pos: Vector3 = entry[1]
		var through: String = entry[2]
		var axis: String = entry[3]
		var h := pos.y + 0.9
		var centre := Vector3(pos.x, h, pos.z)
		var through_vec := Vector3(1.5, 0, 0) if through == "x" else Vector3(0, 0, 1.5)
		var axis_vec := Vector3(0.6, 0, 0) if axis == "x" else Vector3(0, 0, 0.6)
		if not _clear(space, centre - through_vec, centre + through_vec):
			_fail("%s is not open at %s" % [label, pos])
			continue
		var left_ok := _clear(space, centre - through_vec - axis_vec, centre + through_vec - axis_vec)
		var right_ok := _clear(space, centre - through_vec + axis_vec, centre + through_vec + axis_vec)
		if left_ok and right_ok:
			print("  %-34s open, >= 1.2m at %s" % [label, pos])
		else:
			_fail("%s is narrower than 1.2m at %s" % [label, pos])
		# Knee height too: furniture is under 0.9m, so the probes above pass
		# straight over a table that walls the door off (canteen, kitchen door).
		var low := Vector3(pos.x, pos.y + 0.35, pos.z)
		for lat in [-axis_vec, Vector3.ZERO, axis_vec]:
			if not _clear(space, low - through_vec + lat, low + through_vec + lat):
				_fail("%s is blocked at knee height near %s (furniture?)" % [label, pos + lat])
				break
	for entry in LINES:
		var label: String = entry[0]
		var a: Vector3 = entry[1]
		var b: Vector3 = entry[2]
		var expect_open: bool = entry[3]
		var is_open := _clear(space, a, b)
		if is_open == expect_open:
			print("  %-34s %s, as declared" % [label, "open" if is_open else "blocked"])
		else:
			_fail("%s expected %s but is %s (%s -> %s)" % [
				label, "open" if expect_open else "blocked",
				"open" if is_open else "blocked", a, b])

## Interactable doors count as openings: they are closed on purpose, and
## this case asks whether the hole behind them is the right size.
func _clear(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	var skip: Array = []
	for i in range(8):
		q.exclude = skip
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return true
		if not (hit["collider"] is Interactable):
			return false
		skip.append((hit["collider"] as CollisionObject3D).get_rid())
	return false

# ----------------------------------------------------------------- rays ---
## Starts the ray low enough for a crawl or squeeze point to begin inside
## the gap rather than on top of its ceiling.
func _floor_under(space: PhysicsDirectSpaceState3D, pos: Vector3,
		want: String = "") -> float:
	var lift := 0.3 if want == "squeeze" else (0.6 if want == "crawl" else 1.2)
	var q := PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, lift, 0), pos + Vector3(0, -5.0, 0))
	var hit := space.intersect_ray(q)
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y

func _headroom(space: PhysicsDirectSpaceState3D, floor_pos: Vector3) -> float:
	var from := floor_pos + Vector3(0, 0.06, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 6.0, 0))
	var hit := space.intersect_ray(q)
	return 99.0 if hit.is_empty() else (hit["position"] as Vector3).y - floor_pos.y
