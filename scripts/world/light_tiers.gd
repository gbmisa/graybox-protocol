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
var _root: Node3D
var _dress := {}         # id -> Array of nodes that make the tier visible

## r8 (Gregory: "it doesn't distinguish stealthy areas as now they look washed
## out"): the tiers are now visible in the world itself, from outside them,
## not as a dimming of your whole screen. DARK is the level's own night
## ambient. A PITCH box gets a ReflectionProbe that replaces the ambient
## inside it with near-black; a LIT box gets warm unshadowed fill lights on a
## grid under its ceiling. Swapping a box's tier swaps its dressing.
const PITCH_AMBIENT := Color(0.05, 0.05, 0.10)
const PITCH_ENERGY := 0.03
const FILL_COLOR := Color(1.0, 0.66, 0.36)
const FILL_ENERGY := 2.6
const FILL_STEP := 14.0

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
			for n in _dress.get(id, []):
				(n as Node).queue_free()
			_dress.erase(id)
			if _root != null:
				_dress_one(_root, v)

## Builds every box's dressing under `root`. Call once, after all add()s.
func dress(root: Node3D) -> void:
	_root = root
	for v in _vols:
		_dress_one(root, v)

func _dress_one(root: Node3D, v: Dictionary) -> void:
	var box := v["aabb"] as AABB
	var nodes: Array = []
	match String(v["tier"]):
		"PITCH":
			var rp := ReflectionProbe.new()
			rp.size = box.size + Vector3(0.6, 0.6, 0.6)
			rp.position = box.get_center()
			rp.interior = true
			rp.ambient_mode = ReflectionProbe.AMBIENT_COLOR
			rp.ambient_color = PITCH_AMBIENT
			rp.ambient_color_energy = PITCH_ENERGY
			rp.intensity = 0.15
			rp.blend_distance = 0.5
			rp.update_mode = ReflectionProbe.UPDATE_ONCE
			rp.add_to_group("pitch_probe")   # ToolNightVision lifts these
			root.add_child(rp)
			nodes.append(rp)
		"LIT":
			var nx := maxi(1, int(ceil(box.size.x / FILL_STEP)))
			var nz := maxi(1, int(ceil(box.size.z / FILL_STEP)))
			var y := box.position.y + minf(box.size.y * 0.8, 5.0)
			var reach := clampf(maxf(box.size.x / nx, box.size.z / nz) * 0.9, 5.0, 14.0)
			for i in nx:
				for k in nz:
					var p := Vector3(box.position.x + box.size.x * (i + 0.5) / nx, y,
						box.position.z + box.size.z * (k + 0.5) / nz)
					nodes.append(BuildUtils.lamp(root, p, FILL_COLOR, FILL_ENERGY, reach, false))
	if not nodes.is_empty():
		_dress[v["id"]] = nodes

func tier_at(pos: Vector3) -> String:
	for v in _vols:
		if (v["aabb"] as AABB).has_point(pos):
			return String(v["tier"])
	return DEFAULT

func volumes() -> Array:
	return _vols
