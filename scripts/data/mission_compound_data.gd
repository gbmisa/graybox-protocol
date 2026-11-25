class_name MissionCompoundData
extends RefCounted
## HOLLOWAY CAMPUS mission data — every number MissionCompound places or
## reacts to (LEVEL-compound.md §5–§9). No behaviour here.

## Extractions, unlabelled: entering the sphere wins once the target is down.
## Diegetic hints only — the van idles in the pit, the deck beacon blinks.
## r9: the avenue car (E3) is gone — it sat on the way to the annex and
## Gregory drove off in it by accident going for the secondary objective.
const EXTRACTIONS := [
	{"name": "van", "pos": Vector3(-38, -2.2, 6), "radius": 3.5},       # E1, culvert, crawl only
	{"name": "heli", "pos": Vector3(23, 11.2, -7), "radius": 3.6},      # E2, helipad stair
]

const RADIO := {
	"van": "\"Fine. Get in. Don't tell me the number.\"",
	"heli": "\"Continuity flight's cleared for one. He won't be needing it.\"",
}

## Light tiers: [id, x0, x1, y0, y1, z0, z1, tier]. Anywhere not listed is
## LIT. Nested volumes come first — the first match wins — so the duct and the
## ceiling void can sit inside the roof's and the hall's boxes.
const TIERS := [
	# Scoring Annex district (r7).
	["annex_crawl", -17, -13, 0, 3, -44, -38, "PITCH"],
	["annex_gen", -34, -26, 0, 4, -80, -70, "PITCH"],
	["annex_inside", -18, 18, 0, 8, -96, -76, "LIT"],
	["consent_way", -12, 12, 0, 10, -76, -40, "LIT"],
	["annex_site", 18.4, 34, -3, 30, -106, -40, "DARK"],
	["annex_district", -34, 34, 0, 30, -106, -40, "DARK"],
	["subway", -1.5, 1.5, 0, 3.0, 112, 138, "PITCH"],
	["app_culvert", -31, -29, 0, 1.2, 112, 138, "PITCH"],
	["tower_lobby", -24, -14, 0, 3.6, 178, 188, "LIT"],
	["road_deck", -44, 44, 4.0, 10, 112, 138, "LIT"],
	["subway_lamp", -5, 5, 0, 6, 138, 145, "LIT"],
	["footbridge", -3, 3, -0.4, 6, 91.5, 100.5, "LIT"],
	["canal_bed", -44, 44, -3, -0.4, 92, 100, "PITCH"],
	["rota_hut", 20, 26, 0, 3, 104, 110, "LIT"],
	["approach", -44, 44, -3, 40, 46, 196, "DARK"],
	["duct", 2, 7, 8.4, 9.6, -12.6, -11.4, "PITCH"],
	["ceiling_void", -10, 6, 7.0, 8.3, -20, -8, "PITCH"],
	["gallery", -10, 6, 5.0, 7.0, -10, -8, "PITCH"],
	["undercroft", -22, -13, -3.5, -0.8, -20, -8, "PITCH"],
	["squeeze", -28.8, -22, -3.5, -2.0, -18, -17, "PITCH"],
	["boiler_house", -34, -28.8, -3.5, 4.0, -18, -8, "PITCH"],
	["gym_store", 16, 28, 0, 3.6, -20, -14, "PITCH"],
	["refuse_yard", 16, 28, 0, 12, 11, 24, "PITCH"],
	["west_corridor", -22, -19, 0, 3.6, -20, -2, "DARK"],
	["west_stair", -19, -13, 0, 8.0, -8, -2, "DARK"],
	["toilets", -13, -3, 0, 3.6, -11, -8, "DARK"],
	["main_roof", -22.2, 10.2, 8.4, 13, -20.2, -1.8, "DARK"],
	["gym_roof", 16, 28.8, 6.6, 14, -20, 8, "DARK"],
	["alley_low", 10, 16, 0, 4.0, -20, -2, "DARK"],
	["alley_n", 10, 16, 4.0, 6.6, -20, -13.5, "DARK"],
	["alley_s", 10, 16, 4.0, 6.6, -10.5, -2, "DARK"],
	["alley_high", 10, 16, 6.6, 13, -20, -2, "DARK"],
	["mast_disc", -12, 12, 0, 12, -2, 22, "LIT"],     # the isolator swaps this
	["court_w", -22, -12, 0, 12, -2, 24, "DARK"],
	["court_e", 12, 16, 0, 12, -2, 24, "DARK"],
	["court_s", -12, 12, 0, 12, 22, 24, "DARK"],
	["forecourt", 16, 28, 0, 12, 8, 11, "DARK"],
	["west_yard", -28, -22, 0, 12, -20, 24, "DARK"],
	["south_road", -44, 44, 0, 12, 24.8, 46, "DARK"],
	["east_lane", 28.8, 36, 0, 12, -24.8, 24.8, "DARK"],
	["west_alley", -40, -28.8, -2.5, 12, -24.8, 24.8, "DARK"],
	["avenue", -20, 20, 0, 12, -40, -30, "DARK"],
	["avenue_w", -20, -9, 0, 12, -30, -24.8, "DARK"],
	["avenue_e", -3, 20, 0, 12, -30, -24.8, "DARK"],
]

## The energised puddle: 5m of the west run, 95/s — lethal to a walking
## Wizard in street clothes, free to one who dashes from its edge.
const HAZARD_BOX := AABB(Vector3(-22, -3.2, -16.5), Vector3(3, 1.7, 5))
const HAZARD_DPS := 95.0
## The switch that kills it, on the west run's wall opposite the spur mouth.
const ISOLATOR_POS := Vector3(-21.7, -1.6, -9.2)

## The target and where he runs. Paces the hall's lane; on ALARM runs out of
## the north-stair door, down, along the north corridor, into G.04.
const TARGET_LANE := [Vector3(-6, 4, -16), Vector3(2, 4, -16)]
## r8: his routine stop — the 1F south window, watching the score. Clear
## sightlines (measured) from H10 (the scaffold, where the rifle is) and H11.
const TARGET_VISIT := Vector3(0, 4, -2.8)
const FLEE_PATH := [
	Vector3(-8.5, 4, -15.8), Vector3(-9.3, 4, -19.2), Vector3(-11.5, 4, -19.2),
	Vector3(-11.5, 0, -13.0), Vector3(-16, 0, -12.8), Vector3(-16, 0, -14.8),
	Vector3(-17.5, 0, -18.5),
]
## G9 follows him in from the hall doors and holds the room facing its door.
const ESCORT_PATH := [
	Vector3(-9.0, 4, -11.0), Vector3(-9.3, 4, -19.2), Vector3(-11.5, 4, -19.2),
	Vector3(-11.5, 0, -13.0), Vector3(-16, 0, -12.8), Vector3(-16, 0, -14.8),
	Vector3(-14.5, 0, -18.5),
]
const PANIC_DOOR_POS := Vector3(-16, 0, -14)

## Reinforcement policy (§5): first ALARM calls R1 + R2, each later one R3;
## never more than CAP; a post within MIN_DIST of the player is swapped for R3
## so nobody spawns at your back.
const FIRST_WAVE := ["R1", "R2", "R4"]
## Defensive posts the alarm mans (DefencePlan): [floor point, facing yaw —
## 0 north, PI south, PI/2 west, -PI/2 east]. Chokepoints on the ways in and
## the high ground over them, never two within arm's reach of each other.
const POSTS := [
	[Vector3(1.2, 0, -7.0), PI],            # lobby, on the portico
	[Vector3(-6.0, 0, 3.8), PI],            # courtyard, west stack's lee
	[Vector3(3.0, 0, 3.8), PI],             # courtyard, east stack's lee
	[Vector3(-17.7, 2.85, 21.0), 0.0],      # podium, over the courtyard
	[Vector3(-27.3, 3.0, -2.0), -PI / 2.0], # west gantry, over the west yard
	[Vector3(2.5, 0, -21.0), 0.0],          # north yard, at the gate
	[Vector3(13.5, 0, -3.0), PI],           # alley mouth
	[Vector3(25.5, 4.0, -11.0), PI / 2.0],  # gym mezzanine, over the floor
	[Vector3(19.0, 0, 9.5), PI],            # gym forecourt, on the bin-store gate
	[Vector3(-5.0, 4.0, -4.5), PI / 2.0],   # 1F south corridor, on the scaffold door
	[Vector3(6.0, 8.4, -14.5), -PI / 2.0],  # main roof, on the crate stair and duct
	[Vector3(6.5, 0, -11.0), -PI / 2.0],    # canteen, on the service door
	[Vector3(-20.5, 0, -4.0), PI / 2.0],    # west corridor, on the west exit
	# Scoring Annex district (r7).
	[Vector3(-5.5, 0, -73.0), PI],          # front steps, west of the door
	[Vector3(2.0, 4.0, -77.0), PI],         # 1F corridor, barricade, over the Way
	[Vector3(0.0, 4.0, -85.5), PI],         # server anteroom
	[Vector3(-14.0, 0, -84.0), 0.0],        # hall, west door
	[Vector3(15.0, 0, -84.0), -PI / 2.0],   # hall, on the site door
	[Vector3(-9.5, 0, -61.5), PI],          # booth
]
const LATER_WAVE := ["R3", "R5"]
const CAP := 5
const MIN_DIST := 8.0

## LOCATE completes on sight of the target, or on reading the records board
## or the duty rota in the towpath hut.
const INTEL_BOXES := [
	AABB(Vector3(-10, 0, -20), Vector3(13, 3, 6)),
	AABB(Vector3(22, 0, 104), Vector3(4, 3, 6)),
]

## The approach's PA, one line each as you cross into each stretch — the
## building clearing its throat, and getting closer. Shown as a subtitle
## (HudSubtitle) under PA_SPEAKER, so it reads as the tannoy, not the game.
const PA_SPEAKER := "PUBLIC ADDRESS · VANDERMEER INSTITUTE, HOLLOWAY CAMPUS"
const PA := [
	[AABB(Vector3(-44, -5, 140), Vector3(88, 45, 31)),
		"THE Q3 GRATITUDE AUDIT BEGINS SHORTLY.\nRESIDENTS ARE REMINDED THAT LISTENING IS SCORED."],
	[AABB(Vector3(-44, -5, 108), Vector3(88, 45, 31)),
		"DR. VANDERMEER WILL ADDRESS THE HALL AT 21:00.\nAPPLAUSE WILL BE MEASURED."],
	[AABB(Vector3(-44, -5, 70), Vector3(88, 45, 31)),
		"A NON-CONSENTING INDIVIDUAL HAS BEEN REPORTED IN THE AREA.\nDO NOT ENGAGE. ENGAGEMENT IS SCORED."],
	[AABB(Vector3(-44, -5, 46), Vector3(88, 45, 20)),
		"THE GATES ARE CLOSED.\nTHE CAMPUS IS AT FULL GRATITUDE."],
	[AABB(Vector3(-28, -5, -24), Vector3(56, 45, 48)),
		"WELCOME TO HOLLOWAY CAMPUS.\nYOUR VISIT HAS BEEN SCORED."],
]
const LOCATE_RANGE := 40.0

## r8: the guns you find (WeaponPickup), each at the end of a detour.
## [weapon, where (dropped to the floor below), count]
const WEAPONS := [
	["smg", Vector3(36, 2.2, 180), 1],          # A05 garage back strip, past bay 3
	["shotgun", Vector3(-23, 2.2, 96), 1],      # A16 the narrowboat
	["grenade", Vector3(40, 6.5, 77), 2],       # H04 pumping-station roof, end of the pipe bridge
	["grenade", Vector3(-2, 7.6, -14), 2],      # R03 the ceiling void over the hall
	["grenade", Vector3(29, 14.2, -102), 3],    # S11 the Consent Tower deck, top of the site
	["rifle", Vector3(12.6, 7.4, 31), 1],       # H10 the score-maintenance scaffold: it overlooks his window
	["pistol", Vector3(-30, 6.5, 170.7), 1],    # H01 deck-access balcony: a spare mag
]

## r9: ammo caches only the grappling hook reaches (SecR9Grapple dresses the
## spots). The non-pistol guns live on these and what they came with.
## [amounts, position]
const CACHES := [
	[{"rifle": 5}, Vector3(-11.0, 24.2, 28.9)],      # on top of the billboard: the sniper's perch
	[{"shotgun": 6}, Vector3(-34.0, 28.0, 186.0)],   # HOLLOWAY HOUSE roof: west edge is the end of the world
	[{"grenade": 2}, Vector3(21.0, 24.2, -96.0)],    # the crane's counterweight over the annex
]

## Places the hook won't bite (ToolGrapple.no_anchor). r8 painted the
## compound wall top and annex roof anti-climb; r9 (Gregory: grapple as a
## route tool, versatile enough to fall off the map) emptied it.
const NO_GRAPPLE := []
