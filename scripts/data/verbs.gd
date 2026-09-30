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

## Collision layers. Layer 2 is "bodies only": it stops capsules but not
## bullets or sight, which is what makes the panic room's barred window
## shoot-through. Bodies mask both layers; shots and line of sight mask 1.
## Godot's defaults are layer 1 / mask 1 and rays mask everything, so each of
## these has to be set explicitly wherever it matters.
const LAYER_BODY_ONLY := 2
const BODY_MASK := 3
const SHOT_MASK := 1

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
				"squeeze_h": 0.5,       # fits 0.6m squeeze gaps (held key)
				"squeeze_r": 0.25,
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

## 0.0 means this operative has no squeeze.
static func squeeze_height(char_id: String) -> float:
	return float(get_verbs(char_id).get("squeeze_h", 0.0))

static func squeeze_radius(char_id: String) -> float:
	return float(get_verbs(char_id).get("squeeze_r", BODY_RADIUS))

static func mantle_height(char_id: String) -> float:
	return float(get_verbs(char_id).get("mantle_h", 1.2))

## Verb name as it appears in the interaction prompt.
static func verb_label(verb: String) -> String:
	match verb:
		"lockpick": return "PICK LOCK"
		"arcane": return "ARCANE UNLOCK"
		"smash": return "BREACH"
		_: return verb.to_upper()

## Which operative archetype a verb belongs to — used to explain locked gates.
static func verb_owner(verb: String) -> String:
	match verb:
		"lockpick": return "LOCKPICKS"
		"arcane": return "ARCANE"
		"smash": return "BRUTE FORCE"
		_: return verb.to_upper()
