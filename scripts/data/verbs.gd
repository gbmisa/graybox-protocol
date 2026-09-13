class_name VerbData
extends RefCounted
## Traversal capability matrix — the single source of truth for which operative
## can get through which obstacle.
##
## Two kinds of gate exist, and they work differently on purpose:
##
##   INTERACTION gates (lockpick / arcane / smash) are checked in script. An
##   Interactable lists the verbs that open it; a character without a listed
##   verb sees a greyed prompt naming what the obstacle needs.
##
##   CRAWL gates are NOT checked in script. They are enforced by collision:
##   crouch_h is the capsule height while crouched, and crawl gaps in the level
##   are built 1.0m high. Chad's 1.45m floor means he physically cannot enter.
##   Nothing tells him no — he just doesn't fit.

static var _verbs: Dictionary = {}

const STAND_H := 1.7
const BODY_RADIUS := 0.4

static func all() -> Dictionary:
	if _verbs.is_empty():
		_verbs = {
			"regular": {
				"lockpick": true, "arcane": false, "smash": false,
				"crouch_h": 0.85,       # fits 1.0m crawl gaps
				"mantle_h": 1.2,
			},
			"wizard": {
				"lockpick": false, "arcane": true, "smash": false,
				"crouch_h": 0.85,       # fits 1.0m crawl gaps
				"mantle_h": 1.2,
			},
			"chad": {
				"lockpick": false, "arcane": false, "smash": true,
				"crouch_h": 1.45,       # too tall for 1.0m crawl gaps
				"mantle_h": 2.5,
			},
		}
	return _verbs

static func get_verbs(char_id: String) -> Dictionary:
	return all().get(char_id, all()["regular"])

## Does this operative have the given interaction verb?
static func has_verb(char_id: String, verb: String) -> bool:
	return bool(get_verbs(char_id).get(verb, false))

static func crouch_height(char_id: String) -> float:
	return float(get_verbs(char_id).get("crouch_h", 0.85))

static func mantle_height(char_id: String) -> float:
	return float(get_verbs(char_id).get("mantle_h", 1.2))

## Verb name as it appears in the interaction prompt.
static func verb_label(verb: String) -> String:
	if verb.begins_with("key:"):
		return "USE %s" % KeyData.key_name(verb.get_slice(":", 1))
	match verb:
		"lockpick": return "PICK LOCK"
		"arcane": return "ARCANE UNLOCK"
		"smash": return "BREACH"
		_: return verb.to_upper()

## Which operative archetype a verb belongs to — used to explain locked gates.
static func verb_owner(verb: String) -> String:
	if verb.begins_with("key:"):
		return KeyData.key_name(verb.get_slice(":", 1))
	match verb:
		"lockpick": return "LOCKPICKS"
		"arcane": return "ARCANE"
		"smash": return "BRUTE FORCE"
		_: return verb.to_upper()
