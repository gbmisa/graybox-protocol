class_name SecondaryScore
extends RefCounted
## HOLLOWAY ROAD's secondary objective: wipe the Collective Consent Score.
## The server is on the Scoring Annex's first floor (SecAnnexBuilding). Optional,
## never required to finish; the end screen says whether you did it.
##
## Wiping it switches the level's surveillance off (Surveillance.blackout:
## billboard, score screens, CCTV, the eyes, door locks, the alarm), the
## server's glow dies, the PA admits it, and `game.stats["secondary"]`
## records it. It is loud (WipeTerminal noise) — the server room will look.

const LINE := "OPTIONAL — WIPE THE CONSENT SCORE (SCORING ANNEX, UP CONSENT WAY)"
const DONE_LINE := "OPTIONAL — CONSENT SCORE WIPED"
const SERVER_POS := Vector3(0.0, 5.2, -94.95)

static func create(game: GrayboxGame, root: Node3D) -> void:
	WipeTerminal.create(game, root, "WIPE THE CONSENT SCORE", SERVER_POS,
		Vector3(1.2, 0.5, 0.12), func() -> void: wiped(game))
	game.hud.call_deferred("set_secondary", LINE)

static func wiped(game: GrayboxGame) -> void:
	game.stats["secondary"] = "CONSENT SCORE WIPED"
	game.hud.set_secondary(DONE_LINE)
	game.hud.add_killfeed("Consent Score wiped")
	game.hud.show_message("THE SCORE IS GONE", 3.0)
	Surveillance.blackout(game)
	for g in game.get_tree().get_nodes_in_group("score_server_glow"):
		(g as MeshInstance3D).visible = false
	game.hud.say(MissionCompoundData.PA_SPEAKER,
		"THE SCORE IS TEMPORARILY UNAVAILABLE. CAMERAS, LOCKS AND ALARMS ARE OFFLINE.\nPLEASE CONTINUE TO BEHAVE AS IF YOU ARE BEING SCORED.")
