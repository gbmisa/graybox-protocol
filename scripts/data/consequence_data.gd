class_name ConsequenceData
extends RefCounted
## The consequence spine: global alarm, lockdown and guard lethality tuning.
##
## The design goal is that going loud is expensive and permanent. The alarm is
## a single 0-100 meter for the whole mission: loud noise, confirmed sightings
## and discovered bodies push it up, ten quiet seconds start a slow bleed back
## down. At 100 the mission changes shape — lockdown — and the target's
## relocation never un-happens, even after the meter drains.
##
## Every number here is read live by the alarm director, the guards and the
## HUD; nothing about the consequence layer is hardcoded in behaviour scripts.

static func alarm() -> Dictionary:
	return {
		# --- the meter ---
		"max": 100.0,
		"decay_per_sec": 2.0,        # after the delay, ~50s from full to zero
		"decay_delay": 10.0,         # seconds with no alarm event before decay

		# --- what raises it ---
		# Noise events (emit_noise radius) at or above the threshold feed the
		# meter at scale * radius. Below the threshold a noise is just a noise:
		# lockpicks (0), dashes (4), punches (8) and arcane doors (12) stay
		# quiet; pistols (25), slams (30), breaching (45-60) and meteors (45)
		# do not.
		"noise_alarm_threshold": 20.0,
		"noise_alarm_scale": 0.25,   # +15 for a 60-noise breach, +6 for a shot
		"alert_bump": 10.0,          # a guard entering ALERT
		"corpse_bump": 15.0,         # a guard spotting a body
		"loud_kill_bump": 10.0,      # killing a guard with a loud ability
		# An ability whose noise meets this makes its kills loud. Pistol (25),
		# fireball/bolt (20), slam (30), meteor (45) count; punch (8) kills
		# are quiet — but the corpse they leave behind is not.
		"loud_kill_noise": 20.0,

		# --- squad response ---
		# An alerting guard calls out: living guards inside this radius skip
		# straight to ALERT. No chain reaction — called-out guards do not
		# call out themselves.
		"callout_radius": 25.0,
	}
