class_name LightTiers
extends RefCounted
## The three light tiers guards read: PITCH, DARK, LIT (D11). A level
## registers non-overlapping boxes; anywhere outside every box is LIT, so a
## level with none (MERIDIAN) plays exactly as before. Guards multiply their
## detection rate by GuardData "tier_mul" for the tier at the player's chest.
##
## A box's tier can change at runtime — the mast isolator swaps the courtyard
## disc from LIT to DARK. Swaps, never deletes: a deleted box falls back to
## LIT, the opposite of what switching a light off should do.

const DEFAULT := "LIT"

var _vols: Array = []    # [{id, aabb, tier}]

func add(id: String, x0: float, x1: float, y0: float, y1: float, z0: float,
		z1: float, tier: String) -> void:
	_vols.append({
		"id": id,
		"aabb": AABB(Vector3(x0, y0, z0), Vector3(x1 - x0, y1 - y0, z1 - z0)),
		"tier": tier,
	})

func set_tier(id: String, tier: String) -> void:
	for v in _vols:
		if v["id"] == id:
			v["tier"] = tier

func tier_at(pos: Vector3) -> String:
	for v in _vols:
		if (v["aabb"] as AABB).has_point(pos):
			return String(v["tier"])
	return DEFAULT

func volumes() -> Array:
	return _vols
