class_name LevelCompound
extends RefCounted
## Assembles HOLLOWAY ROAD — level one: a long walk in through the estate
## to HOLLOWAY CAMPUS (docs/LEVEL-compound.md). The Regular, base kit: no
## lockpicks, no other operatives yet.
##
## APPROACH  x [-44, 44] z [46, 196], south of the campus (sec_app_*):
##   z 172-196  spawn street: bus stop, tower lobby, garages (open bay 3)
##   z 140-172  estate yard
##   z 112-138  ring road embankment: subway (sentry) | deck (LIT) | culvert
##   z 100-112  towpath: duty-rota hut = intel
##   z  92-100  canal: footbridge | narrowboat | the bed and two slipways
##   z  70-92   allotments
##   z  46-70   terrace backs: three alleys and a walk-through house
## The campus billboard (19m, lit) and mast are visible nearly all the way;
## PA lines fire as you cross each stretch. Every stretch also has a high way
## through (sec_app_heights): the tower's deck-access walkway onto the road
## deck, the pipe bridge over the canal, the terrace roofs, and the
## overbridge whose south landing is a jump from the compound wall top.
##
## CAMPUS  compound wall x [-28, 28] z [-24, 24], 4.0 tall.
##   y   8.4  main roof · duct -> ceiling void (7.0-8.0) over the hall
##   y   6.6  gym roof · link bridge roof
##   y   4.0  main 1F: assembly hall (target), landings, corridor + void
##   y   0.0  main ground, gym, yards, courtyard, alley
##   y  -2.2  outfall pit (west alley)              van (E1)
##   y  -3.0  undercroft, via the caretaker's ramp — a dead end to look at
##
## WAYS IN: the shutter crawl (east lane) -> store -> crate stair -> roof ->
## duct -> gallery; the bin-store gate -> refuse yard -> courtyard -> portico
## or alley; gym -> mezzanine -> bridge -> hall rear; canteen service door ->
## north corridor -> north stair; over the wall from the overbridge or the
## boiler-house climb (west alley); the fire escape (west yard) to the 1F
## west strip behind G9, or the roof; the scaffold (courtyard) to the 1F
## south corridor, or the roof. WAYS OUT: culvert -> van; gate lever ->
## car (E3); or back out the way you came and walk to the van.
## HIGH LEVELS (sec_cmp_vertical): car-park deck in the avenue (3.0), west
## gantry along the wall (3.0), courtyard podium (2.85), plant-room top and
## water tank on the main roof (10.4 / 11.55) — each a mantle to the wall top.
## SCORING ANNEX (sec_annex) north of the avenue: the secondary objective —
## wipe the Consent Score server (SecondaryScore). Checkpoint or crawl in.

const PLAYER_SPAWN := Vector3(0, 0, 190)

## Geometry builders in build order, by name. The tools (screenshots, glb
## export) read this too, so a new section can't be missing from them.
static func sections() -> Dictionary:
	return {
		"perimeter": SecCmpPerimeter,
		"yards": SecCmpYards,
		"main_shell": SecCmpMainShell,
		"main_ground": SecCmpMainG,
		"main_1f": SecCmpMain1F,
		"main_roof": SecCmpMainRoof,
		"gym": SecCmpGym,
		"alley": SecCmpAlley,
		"undercroft": SecCmpUndercroft,
		"dressing": SecCmpDressing,
		"approach_estate": SecAppEstate,
		"approach_canal": SecAppCanal,
		"approach_heights": SecAppHeights,
		"climbs": SecCmpClimbs,
		"lanes": SecCmpLanes,
		"vertical": SecCmpVertical,
		"annex": SecAnnex,
		"crane_run": SecCraneRun,
		"alarm": SecAlarm,
		"billboard": SecCmpBillboard,
		"exits": SecCmpExits,
		"props_approach": SecPropsApproach,
		"props_campus": SecPropsCampus,
		"props_interior": SecPropsInterior,
		"art": SecArt,
		"skyline": SecSkyline,
		"room_names": SecRoomNames,   # playtest tags; SHOW / --no-room-names
	}

static func build(game: GrayboxGame) -> Dictionary:
	var root := Node3D.new()
	root.name = "Level"
	game.add_child(root)
	var secs := sections()
	for key in secs:
		secs[key].build(root, game)
	var text := LevelText.info("compound")
	return {
		"level_root": root,
		"player_spawn": PLAYER_SPAWN,
		"guard_posts": GuardPostsCompound.all(),
		"civilians": CivilianPostsCompound.all(),
		"mission": MissionCompound.create(game, root),
		"barks": text["barks"],
		"objective": text["objective"],
		"located_objective": text["located_objective"],
		"extract_objective": text["extract_objective"],
		"radio": MissionCompoundData.RADIO,
	}
