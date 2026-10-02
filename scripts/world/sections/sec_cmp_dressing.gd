class_name SecCmpDressing
extends RefCounted
## Signage, vehicles and paint (LEVEL-compound.md §13, §9). The signs are the
## institution describing itself honestly by accident; none of them names a
## route or an exit. Wall plates are flat and depth-tested — unlike the
## billboarded debug labels this replaced, you can't read them through walls.
##
## The ways out are dressed, never labelled (`SecCmpExits`); the billboard
## and its scaffold are `SecCmpBillboard`. The painted line round the mast's
## light pool is the LIT tier's edge, so the rule reads on the ground.

const PLATE := Color(0.92, 0.90, 0.80)
const WARN := Color(1.0, 0.35, 0.25)

## text, position, yaw the plate faces (0 = +z/south, PI = north,
## PI/2 = east, -PI/2 = west), colour
## The approach's signs (sec_app_*): the estate talking about itself.
const APPROACH_SIGNS := [
	["ROUTE 41 WITHDRAWN\nINSUFFICIENT AREA SCORE", Vector3(-8, 2.0, 193.75), PI, PLATE],
	["HOLLOWAY HOUSE\nRESIDENTS' SCOREBOARD", Vector3(-23.9, 2.2, 183), PI / 2.0, PLATE],
	["LIFT OUT OF ORDER\nBLOCK SCORE TOO LOW TO REPAIR", Vector3(-19, 1.6, 187.9), PI, PLATE],
	["PLAY RESPONSIBLY\nPLAY IS SCORED", Vector3(-22, 2.8, 157.8), 0.0, PLATE],
	["SUBWAY CLOSED FOR YOUR SAFETY\nSAFETY IS SCORED", Vector3(0, 3.5, 138.05), 0.0, WARN],
	["HOLLOWAY RING ROAD · CONSENT ZONE BEGINS", Vector3(0, 5.8, 137.95), 0.0, PLATE],
	["THE GRATEFUL", Vector3(-24, -1.7, 98.05), 0.0, PLATE],
	["AUDIT DUTY ROTA — Q3\nVANDERMEER: ASSEMBLY HALL, 1F, 21:00\nIN THE EVENT OF AN EVENT: SUITE G.04, NORTH CORRIDOR",
		Vector3(25.75, 1.6, 107), -PI / 2.0, PLATE],
	["THIS PLOT HAS BEEN SCORED 3/10", Vector3(-16, 2.0, 76.15), 0.0, PLATE],
	["THIS HOUSEHOLD IS IN ARREARS OF GRATITUDE", Vector3(-10, 2.2, 61.65), PI, PLATE],
	["DECK ACCESS · RESIDENTS ONLY\nRESIDENCY IS SCORED", Vector3(-30, 5.3, 169.35), PI, PLATE],
	["HOLLOWAY PUMPING STATION\nWATER QUALITY: CONFIDENTIAL", Vector3(40, 2.4, 80.05), 0.0, PLATE],
	["UNAUTHORISED EXTENSION\nENFORCEMENT DEFERRED (SCORE 7/10)", Vector3(-35.8, 1.6, 64.05), 0.0, PLATE],
	["PEDESTRIAN OVERBRIDGE\nA GRATITUDE TOLL APPLIES", Vector3(-25.5, 3.0, 46.31), 0.0, PLATE],
]

const SIGNS := [
	["VANDERMEER INSTITUTE FOR APPLIED CONSENT\nHOLLOWAY CAMPUS\n(formerly Holloway Road Primary, 1911–2019)",
		Vector3(0, 3.4, -24.85), PI, PLATE],
	["STRUCTURAL REVIEW PENDING — Q3 2019\nDO NOT LEAN", Vector3(18.4, 2.6, 24.85), 0.0, WARN],
	["YOUR LIGHT IS PROVIDED\nBY A PARTNERSHIP", Vector3(0, 2.6, 10.25), 0.0, PLATE],
	["DECOMMISSIONED\nHEXLOCK™ ARCANE PERIMETER SOLUTIONS\nYOUR SAFETY IS WARDED",
		Vector3(-34.25, 3.0, -13), -PI / 2.0, PLATE],
	["WATER ISOLATOR\nENERGISED FOR YOUR SAFETY", Vector3(-21.76, -0.9, -9.2), PI / 2.0, PLATE],
	["ENERGISED — DO NOT ENTER", Vector3(-21.75, -1.7, -17.3), PI / 2.0, WARN],
	["ENERGISED — DO NOT ENTER", Vector3(-21.75, -1.7, -10.7), PI / 2.0, WARN],
	["SHUTTER FAULT — TICKET #4472\nPLEASE USE MAIN ENTRANCE", Vector3(28.85, 2.2, -17), PI / 2.0, PLATE],
	["WELLNESS HANGAR\nMANDATORY OPTIONAL SESSIONS TUESDAYS", Vector3(22, 3.7, 11.05), 0.0, PLATE],
	["WELCOME.\nYOUR VISIT HAS BEEN SCORED.", Vector3(1.8, 2.2, -5), -PI / 2.0, PLATE],
	["GENDER-NEUTRAL · CONSENT-VERIFIED\nNO LOITERING (LOITERING IS SCORED)", Vector3(-8, 3.0, -7.8), 0.0, PLATE],
	["RECORDS — AUTHORISED PERSONNEL\nIF YOU CAN READ THIS YOU ARE AUTHORISED", Vector3(-3, 3.0, -13.8), 0.0, PLATE],
	["CONTINUITY SUITE G.04\nIN THE EVENT OF AN EVENT", Vector3(-16, 3.0, -13.8), 0.0, PLATE],
	["DOOR RELEASE\nFOR USE ONCE THE EVENT HAS CONCLUDED", Vector3(-14.8, 1.9, -14.2), PI, PLATE],
	["Q3 GRATITUDE AUDIT\nATTENDANCE IS ITS OWN REWARD", Vector3(-2, 5.9, -19.8), 0.0, PLATE],
	["WELLNESS SUITE · FORMERLY STAFF ROOM · FORMERLY YEAR 6", Vector3(-16, 6.9, -13.8), 0.0, PLATE],
	["H · EXECUTIVE CONTINUITY ONLY", Vector3(19.95, 10.35, -6), -PI / 2.0, PLATE],
	["LIGHT OUT — TICKET #4472\nDUPLICATE OF #4472", Vector3(26, 1.8, 11.15), 0.0, PLATE],
	["PLEASE WAIT TO BE SCORED", Vector3(0, 2.2, 0.55), 0.0, PLATE],
	# Hung in the lobby's double-height void, so looking up from G13 reads
	# as an atrium someone decorated, not a missing ceiling.
	["Q3 GRATITUDE AUDIT\nTHANK YOU FOR YOUR CONSENT", Vector3(-0.5, 6.6, -5.8), 0.0, Color(1.0, 0.75, 0.31)],
	["SCAFFOLD ERECTED FOR THE Q3 GRATITUDE AUDIT\nNOT FOR USE BY THE UNGRATEFUL", Vector3(-12, 1.8, 2.2), 0.0, WARN],
	["BIN STORE\nCOLLECTION SUBJECT TO SCORE", Vector3(28.85, 2.9, 18), PI / 2.0, PLATE],
	["Q3 GRATITUDE AUDIT — ASSEMBLY HALL 21:00\nCONTINUITY: AMBER → SUITE G.04 (N. CORRIDOR)",
		Vector3(-3.5, 1.9, -19.8), 0.0, PLATE],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	for s in SIGNS + APPROACH_SIGNS:
		plate_sign(root, String(s[0]), s[1], float(s[2]), s[3])
	_ground_paint(root)
	BuildUtils.lamp(root, Vector3(-0.5, 7.4, -4.0), BuildUtils.LAMP_FLUORO, 1.4, 9.0)

static func plate_sign(root: Node3D, text: String, pos: Vector3, yaw: float,
		color: Color, font_size: int = 30, backed: bool = true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation.y = yaw
	l.modulate = color
	l.font_size = font_size
	l.pixel_size = 0.005
	l.outline_size = 6
	l.double_sided = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(l)
	if backed:
		_backing(root, l)
	return l

## A board behind the words, so a sign reads as a sign screwed to something
## and not as text hanging in the air. Sized from the label's own metrics.
static func _backing(root: Node3D, l: Label3D) -> void:
	var lines := l.text.split("\n")
	var longest := 0
	for line in lines:
		longest = maxi(longest, line.length())
	var w := float(longest) * l.font_size * 0.56 * l.pixel_size + 0.16
	var h := float(lines.size()) * l.font_size * 1.2 * l.pixel_size + 0.12
	var face := Basis(Vector3.UP, l.rotation.y)
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, 0.03)
	board.mesh = bm
	board.material_override = _board_mat(l.modulate)
	board.basis = face
	board.position = l.position - face.z * 0.025
	root.add_child(board)

static var _boards: Dictionary = {}

static func _board_mat(text_color: Color) -> StandardMaterial3D:
	var key := text_color.to_html()
	if not _boards.has(key):
		var m := StandardMaterial3D.new()
		# Warning signs on red enamel; everything else on council navy.
		m.albedo_color = Color(0.32, 0.05, 0.04) if text_color.r > 0.9 \
			and text_color.g < 0.5 else Color(0.06, 0.08, 0.14)
		m.roughness = 0.6
		_boards[key] = m
	return _boards[key]

## The mast pool's edge, and the rule painted on it.
static func _ground_paint(root: Node3D) -> void:
	var paint := Color(0.78, 0.76, 0.55)
	for x in [-12.0, 12.0]:
		BuildUtils.box(root, Vector3(x, 0.01, 10), Vector3(0.15, 0.02, 24), paint, false)
	BuildUtils.box(root, Vector3(0, 0.01, 22), Vector3(24, 0.02, 0.15), paint, false)
	var rule := plate_sign(root, "NO RUNNING · NO SHOUTING · NO UNSCORED BEHAVIOUR",
		Vector3(0, 0.03, 20.8), 0.0, paint, 72, false)
	rule.rotation = Vector3(-PI / 2.0, 0, 0)
