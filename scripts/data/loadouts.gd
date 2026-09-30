class_name LoadoutData
extends RefCounted
## Sidearm modifications, picked on the briefing screen beside armour and
## never changed mid-run. Only operatives whose CharData lists "mods" see the
## row — today that is the Regular's pistol.
##
## Suppressed trades damage for silence: 17.5 a shot, 44 on a headshot, so a
## guard takes two and the target three, and nobody hears any of them.

const DEFAULT := "suppressed"

static func all() -> Dictionary:
	return {
		"suppressed": {
			"id": "suppressed",
			"name": "SUPPRESSED",
			"desc": "Silent. 30% less damage — two to the head for a guard.",
			"damage_mul": 0.7,
			"noise": 0.0,
		},
		"loud": {
			"id": "loud",
			"name": "LOUD",
			"desc": "Full damage. Everyone within 25m hears every shot.",
			"damage_mul": 1.0,
			"noise": 25.0,
		},
	}

static func get_mod(id: String) -> Dictionary:
	return all().get(id, all()[DEFAULT])
