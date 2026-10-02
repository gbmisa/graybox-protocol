class_name AlertState
extends Node
## The building's alarm (F2): CALM or ALARM, level-wide, on top of each
## guard's own patrol -> suspicious -> alert.
##
## ALARM is raised by an alerted guard pressing an alarm station (a guard
## reaching full detection, being hit, or hearing loud noise within 12m only
## alerts him — see GrayboxGame.guard_alerted), or by a level event (Chad's
## wall). A level with no stations raises it the moment a guard is alerted. What an ALARM *does* is the level's business: GrayboxGame.mission,
## if it has `on_alarm(count, reason)`, gets the call — target flight,
## lockdown, reinforcements. A level with no mission (MERIDIAN) just counts.
##
## It stands down after DECAY seconds in which no guard has seen the player.
## Standing down calls `on_calm()`; nothing that ALARM locked is unlocked.
## An alarm must never feel like "restart" — it makes the level harder and
## different, not over.

enum Level { CALM, ALARM }

const DECAY := 60.0
const LOUD_RADIUS := 25.0
const NEAR_GUARD := 12.0

var game: GrayboxGame
var level: int = Level.CALM
var count: int = 0

var _since_seen: float = 0.0

func setup(p_game: GrayboxGame) -> void:
	game = p_game

func reset() -> void:
	if game != null and game.hud != null:
		game.hud.set_alarm(false)
	level = Level.CALM
	count = 0
	_since_seen = 0.0

func is_alarm() -> bool:
	return level == Level.ALARM

func raise(reason: String) -> void:
	if not game.is_playing():
		return
	_since_seen = 0.0
	if level == Level.ALARM:
		return
	level = Level.ALARM
	count += 1
	game.stats["alarms"] = count
	game.hud.add_killfeed("ALARM — %s" % reason)
	game.hud.set_alarm(true)
	game.atmosphere.set_alarm(true)
	var pl := game.get_player()
	game.panic_civilians(pl.global_position if pl != null else Vector3.ZERO, 400.0)
	if count == 1:
		game.hud.say("PUBLIC ADDRESS · VANDERMEER INSTITUTE, HOLLOWAY CAMPUS",
			"A CONTINUITY EVENT IS IN PROGRESS. REMAIN CALM. CALM IS SCORED.")
	if game.mission != null and game.mission.has_method("on_alarm"):
		game.mission.on_alarm(count, reason)

## Called for every emit_noise, after the guards have heard it.
func on_noise(pos: Vector3, radius: float) -> void:
	if radius < LOUD_RADIUS or level == Level.ALARM:
		return
	for g in game.guards:
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= NEAR_GUARD:
			# A guard close enough hears the shots: he is alerted, and heads for a
			# station like any other alerted guard. No instant alarm.
			if gd.state != Guard.State.ALERT:
				gd.enter_alert()
			return

func note_seen() -> void:
	_since_seen = 0.0

func _process(delta: float) -> void:
	if level != Level.ALARM or game == null or not game.is_playing():
		return
	_since_seen += delta
	if _since_seen < DECAY:
		return
	stand_down("ALARM STOOD DOWN — lockdown stays")

## Back to CALM: by decay, or by the player pressing a station's reset.
## Guards still alerted stay alerted, and a guard who sees the player again
## simply raises it anew.
func stand_down(message: String) -> void:
	if level != Level.ALARM:
		return
	level = Level.CALM
	_since_seen = 0.0
	game.hud.add_killfeed(message)
	game.hud.set_alarm(false)
	game.atmosphere.set_alarm(false)
	if game.mission != null and game.mission.has_method("on_calm"):
		game.mission.on_calm()
