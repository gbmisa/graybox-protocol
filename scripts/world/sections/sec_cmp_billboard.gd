class_name SecCmpBillboard
extends RefCounted
## The billboard on the verge — the lure you've watched since the bus stop —
## and, now, a reason to go to it.
##
##   Board      x [-14, 14], y [14, 24], on two posts at x ±8, z 28.4..29.4.
##   Scaffold   a maintenance tower east of the posts: three switchback
##              flights (rise 4.5 over run 6.0 each, 0.75) on the verge at
##              x [9.6, 15.6], z [29.6, 31.8], landings at 4.5 / 9.0 / 13.5.
##   Catwalk    13.5, x [-15.5, 17.2], z [27.3, 28.4], BEHIND the board (the
##              face is for the estate; the back is for the people who set
##              the score). The top landing wraps round the board's east end
##              onto it. The best view of the campus there is: over the
##              compound wall into the floodlit courtyard, and it's open on
##              the campus side. The wall top (4.0, z 24..24.8) is a 9m drop
##              and a 3m jump north from anywhere along it — a third way onto
##              the wall, after the overbridge and the boiler house.
## The verge used to be empty under the board ("that area is pretty empty");
## the guests' cars, cones and barriers are in `SecPropsCampus`.

const FLIGHT_RUN := 6.0
const FLIGHT_RISE := 4.5
const WALK := 13.5

static func build(root: Node3D, game: GrayboxGame) -> void:
	_board(root)
	_scaffold(root)
	_catwalk(root)

static func _board(root: Node3D) -> void:
	for x in [-8.0, 8.0]:
		WallUtils.block(root, x - 0.5, x + 0.5, 0, 14, 28.4, 29.4, BuildUtils.METAL)
	var board := WallUtils.block(root, -14, 14, 14, 24, 28.6, 29.2, Color.WHITE)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.10, 0.07, 0.03)
	glow.emission_enabled = true
	glow.emission = Color(0.35, 0.20, 0.05)
	glow.emission_energy_multiplier = 1.2
	board.material_override = glow
	board.add_to_group("score_board_face")   # Surveillance.blackout darkens it
	var l := SecCmpDressing.plate_sign(root, "HOLLOWAY ROAD\nCOLLECTIVE CONSENT SCORE\n412 ▼",
		Vector3(0, 19, 29.25), 0.0, Color(1.0, 0.75, 0.3), 150, false)
	l.pixel_size = 0.02
	l.add_to_group("score_board")   # SecondaryScore rewrites it
	l.outline_size = 0
	var lamp := BuildUtils.lamp(root, Vector3(0, 19, 34), Color(1.0, 0.7, 0.35), 4.0, 22.0)
	lamp.add_to_group("score_board_light")

static func _scaffold(root: Node3D) -> void:
	var m := BuildUtils.METAL
	var y := 0.0
	for i in 3:
		var east := i % 2 == 0
		var z := 31.25 if east else 30.15
		var x0 := 9.6 if east else 15.6
		BuildUtils.ramp(root, Vector3(x0, y, z), Vector3(1 if east else -1, 0, 0),
			FLIGHT_RUN, FLIGHT_RISE, 1.1, m, 8, 0.6)
		y += FLIGHT_RISE
		if east:
			BuildUtils.plate(root, 15.6, 17.2, 27.3 if i == 2 else 29.6, 31.8, y, 0.2, m)
		else:
			BuildUtils.plate(root, 8.0, 9.6, 29.6, 31.8, y, 0.2, m)
	# Standards at the corners, ground to the top landing, and the outer rail.
	for p in [Vector3(17.35, 0, 29.5), Vector3(17.35, 0, 31.95),
			Vector3(7.85, 0, 31.95), Vector3(9.6, 0, 31.95)]:
		var h := WALK if p.x > 10.0 else FLIGHT_RISE * 2.0
		BuildUtils.box(root, p + Vector3(0, h * 0.5, 0), Vector3(0.15, h, 0.15), m)
	WallUtils.block(root, 9.6, 17.2, 0, WALK + 1.0, 31.9, 32.0, Color(0.30, 0.34, 0.40))
	SecCmpDressing.plate_sign(root, "SCORE MAINTENANCE PLATFORM\nAUTHORISED GRATITUDE ONLY",
		Vector3(12.6, 2.2, 32.05), 0.0, SecCmpDressing.WARN)

static func _catwalk(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.plate(root, -15.5, 15.6, 27.3, 28.4, WALK, 0.2, m)
	# Hand rail on the board side only; the campus side is open.
	WallUtils.block(root, -15.5, 15.6, WALK + 0.9, WALK + 1.0, 28.35, 28.45, m)
	for x in [-14.0, -4.0, 4.0, 14.0]:
		BuildUtils.box(root, Vector3(x, WALK + 0.45, 28.4), Vector3(0.08, 0.9, 0.08), m, false)
	SecCmpDressing.plate_sign(root, "THIS SIDE FACES THE PEOPLE WHO SET THE SCORE",
		Vector3(0, 16.0, 28.55), PI, SecCmpDressing.PLATE)
	BuildUtils.lamp(root, Vector3(0, WALK + 1.8, 27.8), Color(1.0, 0.8, 0.5), 0.8, 8.0)
