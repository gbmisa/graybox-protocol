class_name SecondaryScore
extends RefCounted
## HOLLOWAY ROAD's secondary objective: wipe the Collective Consent Score.
## The server is on the Scoring Annex's first floor (SecAnnex). Optional,
## never required to finish; the end screen says whether you did it.
##
## Wiping it: the billboard over the south road reads ERR, the server's glow
## dies, the PA admits it, and `game.stats["secondary"]` records it. It is
## loud (WipeTerminal noise) — the server room will come and look.

const LINE := "OPTIONAL — WIPE THE CONSENT SCORE (SCORING ANNEX, NORTH OF THE AVENUE)"
const DONE_LINE := "OPTIONAL — CONSENT SCORE WIPED"
const SERVER_POS := Vector3(1.0, 5.2, -56.85)

static func create(game: GrayboxGame, root: Node3D) -> void:
	WipeTerminal.create(game, root, "WIPE THE CONSENT SCORE", SERVER_POS,
		Vector3(1.2, 0.5, 0.12), func() -> void: wiped(game))
	game.hud.call_deferred("set_secondary", LINE)

static func wiped(game: GrayboxGame) -> void:
	game.stats["secondary"] = "CONSENT SCORE WIPED"
	game.hud.set_secondary(DONE_LINE)
	game.hud.add_killfeed("Consent Score wiped")
	game.hud.show_message("THE SCORE IS GONE", 3.0)
	for l in game.get_tree().get_nodes_in_group("score_board"):
		(l as Label3D).text = "HOLLOWAY ROAD\nCOLLECTIVE CONSENT SCORE\nERR ▲▲▲"
		(l as Label3D).modulate = Color(1.0, 0.25, 0.2)
	for g in game.get_tree().get_nodes_in_group("score_server_glow"):
		(g as MeshInstance3D).visible = false
	game.hud.say(MissionCompoundData.PA_SPEAKER,
		"THE SCORE IS TEMPORARILY UNAVAILABLE. PLEASE CONTINUE TO BEHAVE AS IF YOU ARE BEING SCORED.")
