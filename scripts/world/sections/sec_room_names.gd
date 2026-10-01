class_name SecRoomNames
extends RefCounted
## Playtest labels: every room and area of HOLLOWAY ROAD carries a floating
## "ID NAME" tag, so feedback can say "F05 is too tight" instead of
## describing where you were. Depth-tested, so a tag only shows when you can
## see the space it names. Not signage — cyan, billboarded, and switched off
## with `-- --no-room-names` (or SHOW = false once playtesting is done).
##
## Prefixes: A approach · H high routes · C campus outdoors · G main ground
## floor · F main first floor · R main roof · Y gym · U undercroft.
## Positions are where the tag floats, not the floor.

const SHOW := true
const COLOR := Color(0.35, 0.95, 1.0)

const ROOMS := [
	# Approach, spawn to south road.
	["A01", "BUS STOP", Vector3(-8, 2.2, 191)],
	["A02", "TOWER LOBBY", Vector3(-19, 2.3, 183)],
	["A03", "GARAGE BAY 3", Vector3(21, 1.9, 184)],
	["A04", "GARAGE ROOFS", Vector3(20, 4.6, 178)],
	["A05", "GARAGE BACK STRIP", Vector3(36, 2.2, 180)],
	["A06", "ESTATE YARD", Vector3(0, 2.4, 156)],
	["A07", "PLAYGROUND", Vector3(-22, 3.4, 160)],
	["A08", "SUBSTATION ROOF", Vector3(-36, 4.6, 152)],
	["A09", "SUBWAY", Vector3(0, 2.2, 130)],
	["A10", "CULVERT", Vector3(-30, 0.6, 130)],
	["A11", "RING ROAD DECK", Vector3(0, 6.2, 125)],
	["A12", "TOWPATH", Vector3(0, 2.2, 106)],
	["A13", "ROTA HUT", Vector3(23, 2.0, 107)],
	["A14", "CANAL FOOTBRIDGE", Vector3(0, 2.2, 96)],
	["A15", "CANAL BED", Vector3(10, -0.5, 96)],
	["A16", "NARROWBOAT", Vector3(-23, 2.2, 96)],
	["A17", "WEST SLIPWAY", Vector3(-40, 0.8, 103)],
	["A18", "EAST SLIPWAY", Vector3(40, 0.8, 89.5)],
	["A19", "ALLOTMENTS", Vector3(-10, 2.2, 78)],
	["A20", "SHED ROOF", Vector3(8, 4.2, 86)],
	["A21", "TERRACE BACK YARDS", Vector3(-26, 2.2, 65)],
	["A22", "TERRACE ALLEY", Vector3(0, 2.4, 57)],
	["A23", "WALK-THROUGH HOUSE", Vector3(-10, 2.2, 57)],
	["A24", "TERRACE FRONT", Vector3(10, 2.2, 49)],
	# High routes.
	["H01", "DECK-ACCESS BALCONY", Vector3(-30, 6.0, 170.7)],
	["H02", "YARD WALKWAY", Vector3(-42.1, 6.0, 154)],
	["H03", "PIPE BRIDGE", Vector3(38.6, 6.0, 100)],
	["H04", "PUMPING STATION ROOF", Vector3(40, 6.0, 77)],
	["H05", "EXTENSIONS", Vector3(-34.6, 5.4, 63)],
	["H06", "TERRACE ROOFS", Vector3(-30, 8.0, 57)],
	["H07", "OVERBRIDGE", Vector3(-25.5, 7.0, 40)],
	["H08", "COMPOUND WALL TOP", Vector3(-20, 6.0, 24.4)],
	# Campus, outdoors.
	["C01", "SOUTH ROAD", Vector3(0, 2.4, 40)],
	["C02", "VERGE", Vector3(0, 2.2, 27)],
	["C03", "EAST LANE", Vector3(32, 2.2, 10)],
	["C04", "WEST ALLEY", Vector3(-34, 2.2, 25)],
	["C05", "OUTFALL PIT", Vector3(-34, 0.0, 8)],
	["C06", "BOILER CLIMB", Vector3(-36.5, 2.4, -15)],
	["C07", "BOILER HOUSE ROOF", Vector3(-31, 6.0, -13)],
	["C08", "AVENUE", Vector3(8, 2.2, -34)],
	["C09", "GATEHOUSE", Vector3(-6, 2.2, -27)],
	["C10", "NORTH YARD", Vector3(10, 2.2, -22)],
	["C11", "WEST YARD", Vector3(-25, 2.2, 8)],
	["C12", "SMOKING SHELTER", Vector3(-25, 1.9, 16)],
	["C13", "COURTYARD", Vector3(-6, 2.4, 12)],
	["C14", "REFUSE YARD", Vector3(22, 2.2, 18)],
	["C15", "GYM FORECOURT", Vector3(22, 2.0, 9.5)],
	["C16", "CANOPY TOP", Vector3(22, 6.2, 9.5)],
	["C17", "ALLEY", Vector3(13, 2.2, -6)],
	["C18", "CRATE STAIR", Vector3(11, 8.7, -14.25)],
	["C19", "PORTICO", Vector3(0, 1.6, -1.0)],
	["C20", "FIRE ESCAPE", Vector3(-23.15, 6.0, -11.5)],
	["C21", "SCAFFOLD", Vector3(-8.1, 6.0, 0.8)],
	["C22", "CULVERT", Vector3(-27, 0.6, 6)],
	# Main block, ground floor (ceiling 3.6).
	["G01", "WEST CORRIDOR N", Vector3(-20.5, 2.3, -16)],
	["G02", "WEST CORRIDOR S", Vector3(-20.5, 2.3, -5)],
	["G03", "PANIC ROOM G.04", Vector3(-16, 2.3, -17)],
	["G04", "NORTH STAIR", Vector3(-11.5, 2.6, -14.8)],
	["G05", "RECORDS", Vector3(-3, 2.3, -17)],
	["G06", "KITCHEN", Vector3(6, 2.3, -17)],
	["G07", "NORTH CORRIDOR", Vector3(-8, 2.3, -12.5)],
	["G08", "CARETAKER", Vector3(-17.5, 2.3, -9.5)],
	["G09", "TOILETS", Vector3(-8, 2.3, -9.5)],
	["G10", "CSD PASSAGE", Vector3(0, 2.3, -9.5)],
	["G11", "CANTEEN", Vector3(6.5, 2.3, -11)],
	["G12", "WEST FOYER", Vector3(-8, 2.3, -5)],
	["G13", "LOBBY", Vector3(-0.5, 2.3, -5)],
	["G14", "WEST STAIR", Vector3(-16, 2.8, -3)],
	["G15", "EAST STAIR", Vector3(7, 2.8, -3)],
	# Main block, first floor (floor 4.0).
	["F01", "ASSEMBLY HALL", Vector3(-2, 6.3, -15)],
	["F02", "GALLERY", Vector3(-6, 6.5, -9)],
	["F03", "STAFF ROOM", Vector3(-16, 6.3, -17)],
	["F04", "NORTH STAIR LANDING", Vector3(-11.5, 6.3, -19.2)],
	["F05", "WEST LANDING", Vector3(-15, 6.3, -11)],
	["F06", "WEST STRIP", Vector3(-20.5, 6.3, -13)],
	["F07", "AV BOOTH", Vector3(-6.5, 6.3, -7)],
	["F08", "SOUTH CORRIDOR", Vector3(-8, 6.3, -4)],
	["F09", "PASSAGE EAST", Vector3(6, 6.3, -7)],
	["F10", "EAST LANDING", Vector3(8, 6.3, -14)],
	["F11", "LINK BRIDGE", Vector3(13, 5.8, -12)],
	# Main block, roof.
	["R01", "MAIN ROOF", Vector3(-10, 10.4, -11)],
	["R02", "ROOF DUCT", Vector3(4.5, 8.9, -12)],
	["R03", "CEILING VOID", Vector3(-2, 7.5, -14)],
	# Gym.
	["Y01", "GYM STORE", Vector3(22, 2.3, -17)],
	["Y02", "SHUTTER CRAWL", Vector3(29, 0.6, -17)],
	["Y03", "GYM FLOOR", Vector3(22, 2.5, 0)],
	["Y04", "MEZZANINE", Vector3(22, 6.0, -15)],
	["Y05", "GYM ROOF", Vector3(22, 8.4, 0)],
	["Y06", "HELIPAD DECK", Vector3(23, 13.0, -8)],
	# Undercroft (ceiling -0.8).
	["U01", "BOILER BASEMENT", Vector3(-31, -1.3, -11)],
	["U02", "SQUEEZE", Vector3(-25, -2.6, -17.5)],
	["U03", "WEST RUN", Vector3(-20.5, -1.3, -14)],
	["U04", "CARETAKER SPUR", Vector3(-16, -1.3, -10.3)],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if not SHOW or "--no-room-names" in args:
		return
	for r in ROOMS:
		var l := Label3D.new()
		l.name = "RoomName_%s" % r[0]
		l.text = "%s  %s" % [r[0], r[1]]
		l.position = r[2]
		l.modulate = COLOR
		l.font_size = 40
		l.pixel_size = 0.006
		l.outline_size = 8
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.add_to_group("room_name")
		root.add_child(l)
