class_name AlarmSiren
extends Node3D
## A siren horn on a mast. While the building alarm is up it wails and its
## lamp pulses — from where it is mounted, so you hear which direction the
## trouble is in and it fades as you walk away. (The first siren played from
## the player's own head and followed him everywhere.)
##
## Mounted high — roofs, the tower, the road deck — and several at once, so
## the whole level is covered and no single one is "the" sound.

var _player: AudioStreamPlayer3D
var _lamp: OmniLight3D
var _on: bool = false
var _t: float = 0.0

static func create(parent: Node3D, pos: Vector3) -> AlarmSiren:
	var s := AlarmSiren.new()
	s.name = "AlarmSiren"
	s.position = pos
	parent.add_child(s)
	s._build()
	return s

func _build() -> void:
	add_to_group("siren")
	var m := Color(0.26, 0.27, 0.30)
	BuildUtils.box(self, Vector3(0, 0.6, 0), Vector3(0.14, 1.2, 0.14), m, false)
	BuildUtils.box(self, Vector3(0, 1.3, 0), Vector3(0.5, 0.3, 0.5), Color(0.55, 0.08, 0.06), false)
	BuildUtils.box(self, Vector3(0.0, 1.3, 0.35), Vector3(0.4, 0.22, 0.3), m, false)
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0, 1.7, 0)
	_lamp.light_color = Color(1.0, 0.1, 0.05)
	_lamp.omni_range = 12.0
	_lamp.light_energy = 0.0
	add_child(_lamp)
	_player = AudioStreamPlayer3D.new()
	_player.stream = AudioSynth.siren()
	_player.position = Vector3(0, 1.4, 0)
	_player.volume_db = -9.0
	_player.unit_size = 7.0
	_player.max_distance = 90.0
	add_child(_player)

func activate(on: bool) -> void:
	_on = on
	if on:
		_t = randf() * 3.0
		_player.play(randf() * 1.6)
	else:
		_player.stop()
		_lamp.light_energy = 0.0

func _process(delta: float) -> void:
	if not _on:
		return
	_t += delta
	_lamp.light_energy = 2.5 * (0.5 + 0.5 * sin(_t * TAU * 1.1))
