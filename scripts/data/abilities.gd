class_name AbilityData
extends RefCounted
## Tuning for every ability in the game. Kits read these dictionaries; no
## balance number is ever written inline in a kit script.

static var _abilities: Dictionary = {}

static func all() -> Dictionary:
	if _abilities.is_empty():
		_abilities = {
			# ---------------------------------------------------- regular ---
			"pistol": {
				"damage": 25.0,
				"cooldown": 0.25,
				"range": 60.0,
				"noise": 25.0,
			},

			# ----------------------------------------------------- wizard ---
			"fireball": {
				"damage": 35.0,
				"aoe": 3.2,
				"mana": 20.0,
				"cooldown": 0.5,
				"speed": 22.0,
				"gravity": 12.0,
				"noise": 20.0,
			},
			"bolt": {
				"damage": 70.0,
				"range": 30.0,            # just under guard vision (34m)
				"mana": 35.0,
				"charge_time": 1.0,       # seconds of RMB hold for a full charge
				"min_charge": 0.25,       # below this the release fizzles
				"noise": 20.0,
			},
			# Ground-targeted, telegraphed, and slow on purpose: this is area
			# denial and a repositioning tool, not a snipe. The delay is what
			# makes it pair with the dash instead of competing with the bolt.
			"meteor": {
				"damage": 90.0,
				"aoe": 7.0,
				"mana": 45.0,
				"cooldown": 5.0,
				"telegraph": 1.1,         # marker-on-ground time before impact
				"cast_range": 30.0,
				"burn_dps": 12.0,
				"burn_duration": 4.0,
				"burn_radius": 4.0,
				"burn_tick": 0.5,
				"noise": 45.0,
			},
			"dash": {
				"duration": 0.35,
				"iframes": 0.25,          # invulnerable window inside the dash
				"speed": 26.0,
				"cooldown": 1.2,
				"mana": 15.0,
				"noise": 4.0,
			},

			# ------------------------------------------------------- chad ---
			"punch": {
				"damage": 55.0,
				"cooldown": 0.45,
				"range": 2.8,
				"combo_window": 1.2,
				"knockback": 9.0,
				"knockup": 2.0,
				"noise": 8.0,
			},
			"slam": {
				"damage": 60.0,
				"radius": 5.5,
				"cooldown": 8.0,
				"knockback": 12.0,
				"knockup": 4.0,
				"shake": 0.4,
				"noise": 30.0,
			},
		}
	return _abilities

static func get_ability(id: String) -> Dictionary:
	return all().get(id, {})

## Shared player tuning that is not tied to one ability.
static func player() -> Dictionary:
	return {
		"mana_regen": 18.0,
		# No hp regen by design — see player/health.gd.
		"crouch_speed_mul": 0.5,
		"eye_stand": 1.62,
		"eye_crouch": 1.05,
		"mouse_sens": 0.0022,
		"interact_range": 2.5,
		"mantle_time": 0.3,
	}
