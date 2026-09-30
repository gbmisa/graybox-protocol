class_name LevelText
extends RefCounted
## Per-level words: select-screen card, briefing, each operative's route line,
## the extraction note, objectives and guard barks. Screens and the game read
## this instead of hard-coding one level's copy.
##
## Route lines hint at an operative's way in without naming it. Extractions
## are deliberately not listed for HOLLOWAY CAMPUS — you find out a spot is a
## way out by reaching it.

static func info(level_id: String) -> Dictionary:
	match level_id:
		"compound":
			return _compound()
		_:
			return _meridian()

## Route line for an operative on a level; falls back to CharData's.
static func route(level_id: String, char_id: String) -> String:
	var routes: Dictionary = info(level_id).get("routes", {})
	return String(routes.get(char_id, CharData.get_char(char_id)["route"]))

static func _meridian() -> Dictionary:
	return {
		"briefing": "",
		"extractions": "EXTRACTIONS: helipad (roof) · van (street) · sump outflow (crawl only)",
		"routes": {},
	}

static func _compound() -> Dictionary:
	return {
		"card": "A primary school until the council sold it for a pound. Now it scores your neighbourhood's behavioural credit. Tonight the Chief Consent Officer hosts the Q3 Gratitude Audit in the old assembly hall. Attendance is mandatory. His is optional.",
		"briefing": "TARGET: Dr. Aurelio Vandermeer, Chief Consent Officer.\nHe built the Consent Score on a school playground and the playground is still there, floodlit, with a sign about running. Every tenant east of the ring road has a number now and the number decides whether the bins get collected. Assembly hall, first floor, 21:00. Compliance staff on site, contracted, armed, underpaid — they'll shoot you because the incident form is shorter than the one for letting you go. The car drops you at the bus stop on the estate — nothing runs past the ring road any more. Walk it. The campus is the one lit thing on the skyline; the billboard will tell you how the neighbourhood is doing. Get in however you get in. Try not to make it a school shooting. It's a school.",
		"extractions": "When it's done, leave by whatever's open. Nobody's coming for you.",
		"routes": {
			"regular": "THE LONG WAY — the estate, the ring road, the canal, the terraces. Then a school with more ways in than it admits to: shutters stick, crates stack, and nobody watches a roof.",
			"wizard": "DECOMMISSIONED — the boiler house is warded and the basement is live. You fit where nobody else does, and the dash doesn't touch the water.",
			"chad": "STRUCTURAL REVIEW — the south wall is on a list. So is every roof you can climb. The building hears you coming. Let it.",
		},
		"objective": "LOCATE VANDERMEER",
		"located_objective": "KILL VANDERMEER",
		"extract_objective": "VANDERMEER DOWN — LEAVE BY WHATEVER'S OPEN",
		"barks": {
			"patrol": [
				"Bins Thursday. If your number's good.",
				"He said 'gratitude' four times in the briefing. Four.",
				"They scored the caretaker. Caretaker's gone.",
			],
			"suspicious": [
				"That's not a scored noise.",
				"Ticket that. Ticket everything.",
				"If that's the boiler I'm not paid for the boiler.",
			],
			"alert": [
				"CONTACT — non-consenting!",
				"Continuity! Get him to G.04!",
				"Shoot first, the form's shorter.",
			],
			"wall": ["THE WALL — it was on the review!"],
		},
	}
