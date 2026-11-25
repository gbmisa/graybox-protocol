class_name WeaponReload
extends RefCounted
## Reloading for PlayerWeapons (split out in r9). A magazine gun refills in
## one go at the end of its `reload`. A throwable has no reload: the next one
## is in your hand at once. r9 ("the pump shotgun reload animation always
## reloads all six shots"): a weapon with `shell_time` loads one shell per
## step and carries on until full or out of reserve; pull the trigger with a
## shell in and it stops, pumps, and fires.

var w: PlayerWeapons
var _t: float = 0.0
var _len: float = 1.0   # this step's length: a whole mag, or one shell

func _init(p_weapons: PlayerWeapons) -> void:
	w = p_weapons

func active() -> bool:
	return _t > 0.0

func cancel() -> void:
	_t = 0.0

func start() -> void:
	var data := w.weapon()
	var a: Dictionary = w.ammo[w.current]
	if int(a["mag"]) >= int(data["mag"]) or int(a["reserve"]) <= 0:
		return
	if float(data["reload"]) <= 0.0:
		_finish()
		return
	if _per_shell():
		_len = float(data["shell_time"])
		AudioSynth.play(w.player.game, "shell_in", -4.0, randf_range(0.95, 1.05))
	else:
		_len = float(data["reload"])
		AudioSynth.play(w.player.game, "reload_%s" % w.current, -4.0)
	_t = _len

## True while the reload still owns this frame (no firing).
func tick(delta: float) -> bool:
	_t -= delta
	w.player.viewmodel.dip = sin(clampf(1.0 - _t / _len, 0.0, 1.0) * PI) * 0.7
	if Input.is_action_just_pressed("attack") and _per_shell() \
			and int(w.ammo[w.current]["mag"]) > 0:
		_t = 0.0
		_pump()
		w._trigger_held = false   # this press is the shot
		return false
	if _t <= 0.0:
		_finish()
	return true

func _per_shell() -> bool:
	return float(w.weapon().get("shell_time", 0.0)) > 0.0

func _finish() -> void:
	var data := w.weapon()
	var a: Dictionary = w.ammo[w.current]
	var room := int(data["mag"]) - int(a["mag"])
	var take := mini(1 if _per_shell() else room, int(a["reserve"]))
	a["mag"] = int(a["mag"]) + take
	a["reserve"] = int(a["reserve"]) - take
	if _per_shell():
		if int(a["mag"]) < int(data["mag"]) and int(a["reserve"]) > 0:
			start()
		else:
			_pump()

func _pump() -> void:
	AudioSynth.play(w.player.game, "pump", -4.0, randf_range(0.95, 1.05))
