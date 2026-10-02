class_name AlarmReset
extends Interactable
## The panel on an alarm station, usable by the player while the alarm is up:
## hold interact and the sirens stop. No verb needed, a little noise. Never
## latches (is_open stays false) so every station can be used again.

const USE := {"use": {"time": 1.2, "noise": 6.0, "mana": 0.0}}

static func create(p_game: GrayboxGame, station: Node3D) -> AlarmReset:
	var r := AlarmReset.new()
	r.position = Vector3(0, 1.15, 0.2)
	station.add_child(r)
	r.setup(p_game, "ALARM", USE.duplicate(true), Vector3(0.5, 0.55, 0.1),
		Color(0.5, 0.05, 0.04))
	r._mesh.visible = false
	return r

func method_for(_char_id: String) -> Dictionary:
	var m: Dictionary = USE["use"].duplicate()
	m["verb"] = "use"
	return m

func prompt_for(_player: Player) -> Dictionary:
	if game == null or not game.alert.is_alarm():
		return {}
	return {"text": "HOLD  SILENCE ALARM", "usable": true,
		"time": float(USE["use"]["time"]), "verb": "use"}

func open(opener: Node) -> void:
	if not game.alert.is_alarm():
		return
	game.emit_noise(global_position, float(USE["use"]["noise"]))
	AudioSynth.play(game, "unlock")
	game.alert.stand_down("ALARM SILENCED")
	opened.emit(opener)
