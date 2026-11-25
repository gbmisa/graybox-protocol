class_name WeaponData
extends RefCounted
## The Regular's arsenal (r8: "create additional features, weapons, and tools
## like there's access to in Cruelty Squad"). Tuning only — the behaviour is
## player/weapons.gd. Slots are the number keys; the mouse wheel cycles.
##
## Noise rules are Cruelty Squad's: the suppressed pistol alerts nobody, every
## other gun is heard `noise` metres away. You start with what has `start`
## (the pistol, one grenade); the rest are WeaponPickups placed in the level
## (MissionCompoundData.WEAPONS). Ammo is scarce on purpose: a dead guard drops
## a few rounds (DROP) for guns you own. Guards have 50 HP (2.5x to the head):
## suppressed pistol 3 body / 2 head, loud 2 / 1, SMG 4, shotgun ~5 of 9
## pellets, rifle 1.
##
## Keys: slot, ammo (what its box says), name, model (viewmodel GLB), damage (per pellet), pellets,
## spread (radians, hip), ads_spread, rate (seconds between shots), auto
## (hold to fire), mag, reserve (spare rounds when found), start (carried
## from the start), reload (s), shell_time (s per shell: loads one at a time,
## the trigger interrupts), scope (magnification: aimed, the gun drops away and
## you look through a scope), alerts (a shot puts every guard who hears it on
## ALERT, hunting the shot — the rifle),
## range, noise (m; 0 = silent), recoil (camera kick, rad), kick (viewmodel
## kick 0..1.6), knockback (m/s on a guard), zoom (ADS world zoom), gib (an
## overkill this big splatters the body), sound.

const ORDER := ["pistol", "smg", "shotgun", "rifle", "grenade"]

static func all() -> Dictionary:
	return {
		"pistol": {
			"slot": 1, "ammo": "9MM", "name": "PISTOL", "model": "res://assets/viewmodel/viewmodel_pistol.glb",
			"damage": 25.0, "pellets": 1, "spread": 0.004, "ads_spread": 0.0,
			"rate": 0.22, "auto": false, "mag": 12, "reserve": 24, "start": true, "reload": 1.2,
			"range": 60.0, "noise": 25.0, "recoil": 0.022, "kick": 1.0,
			"knockback": 1.0, "zoom": 0.72, "gib": 999.0, "sound": "pistol",
		},
		"smg": {
			"slot": 2, "ammo": "SMG MAG", "name": "CONSENT ENFORCER SMG", "model": "res://assets/viewmodel/viewmodel_smg.glb",
			"damage": 14.0, "pellets": 1, "spread": 0.045, "ads_spread": 0.018,
			"rate": 0.075, "auto": true, "mag": 32, "reserve": 32, "reload": 1.6,
			"range": 45.0, "noise": 30.0, "recoil": 0.012, "kick": 0.45,
			"knockback": 0.6, "zoom": 0.8, "gib": 999.0, "sound": "smg",
		},
		"shotgun": {
			"slot": 3, "ammo": "SHELLS", "name": "PUMP SHOTGUN", "model": "res://assets/viewmodel/viewmodel_shotgun.glb",
			"damage": 11.0, "pellets": 9, "spread": 0.085, "ads_spread": 0.06,
			"rate": 0.8, "auto": false, "mag": 6, "reserve": 6, "reload": 2.4,
			"shell_time": 0.42,
			"range": 30.0, "noise": 40.0, "recoil": 0.07, "kick": 1.6,
			"knockback": 7.0, "zoom": 0.85, "gib": 60.0, "sound": "shotgun",
		},
		"rifle": {
			"slot": 4, "ammo": ".308", "name": "MARKSMAN RIFLE", "model": "res://assets/viewmodel/viewmodel_rifle.glb",
			"damage": 80.0, "pellets": 1, "spread": 0.02, "ads_spread": 0.0,
			"rate": 0.95, "auto": false, "mag": 5, "reserve": 5, "reload": 2.2,
			"range": 140.0, "noise": 75.0, "recoil": 0.06, "kick": 1.4,
			"knockback": 3.0, "zoom": 1.0, "scope": 3.0, "gib": 70.0, "sound": "rifle",
			"alerts": true,
		},
		"grenade": {
			"slot": 5, "ammo": "FRAGS", "name": "FRAG GRENADE", "model": "res://assets/viewmodel/viewmodel_grenade.glb",
			"damage": 130.0, "pellets": 0, "spread": 0.0, "ads_spread": 0.0,
			"rate": 0.9, "auto": false, "mag": 1, "reserve": 0, "reload": 0.0, "start": true,
			"range": 0.0, "noise": 45.0, "recoil": 0.0, "kick": 0.8,
			"knockback": 12.0, "zoom": 1.0, "gib": 40.0, "sound": "throw",
			"fuse": 2.2, "radius": 6.5, "throw_speed": 17.0,
		},
	}

static func get_weapon(id: String) -> Dictionary:
	return all().get(id, all()["pistol"])

## The aimed field of view as a fraction of the normal one. A `scope` is a
## true magnification: tan(half-FOV) shrinks by that factor at any FOV.
static func zoom_for(w: Dictionary, fov_deg: float) -> float:
	var mag := float(w.get("scope", 0.0))
	if mag <= 1.0:
		return float(w["zoom"])
	var half := deg_to_rad(fov_deg) * 0.5
	return rad_to_deg(2.0 * atan(tan(half) / mag)) / fov_deg

## What a dead guard drops. r9 ("picking up ammo picks up ammo for all weapons,
## so the SMG has tons of ammo"): guards carry pistols, so they drop pistol
## rounds and nothing else. The other guns live on what you find with them.
const DROP := {"pistol": 6}
