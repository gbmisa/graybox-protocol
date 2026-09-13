class_name GuardData
extends RefCounted
## Guard senses, gunplay and movement tuning. Guard AI is deliberately simple
## (patrol -> suspicious -> alert, no flanking, no squad coordination) so the
## complexity budget goes to character kits and level routing instead.

static func stats() -> Dictionary:
	return {
		# --- senses ---
		"vision_range": 34.0,
		"vision_cone": 0.80,        # dot threshold, ~37 degree half-angle
		"detect_rate": 1.4,         # detection meter gain/sec when visible
		"crouch_mul": 0.45,         # gain multiplier while player crouches
		"sprint_mul": 1.6,          # gain multiplier while player sprints
		"lose_rate": 0.5,           # meter decay/sec when player is unseen
		"hearing_range": 30.0,

		# --- gun ---
		# Lethal on purpose: with no health regeneration a mission is a single
		# life, so armour choice is the difference between surviving 3 hits and
		# 9. Tuned against the aim telegraph in guard_combat — a shot you cannot
		# see coming at this damage would just be unfair.
		"gun_damage": 22.0,
		"gun_cooldown": 1.1,
		"gun_spread": 0.06,         # radians
		"gun_range": 40.0,
		"aim_time": 0.55,           # visible wind-up before firing; the dodge window

		# --- body ---
		"hp": 50.0,
		"patrol_speed": 2.6,
		"investigate_speed": 4.0,
		"chase_speed": 5.4,
		"waypoint_tolerance": 1.2,
	}
