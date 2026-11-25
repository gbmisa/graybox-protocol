class_name AlarmStation
extends Node3D
## A red alarm post. The alarm is no longer raised the instant a guard sees
## you or is hit: an alerted guard has to run to one of these and press it
## (`GuardBrain._run_to_station`). Kill him first and nothing happens — that is
## the whole counterplay, and why a post is visible from a distance (a dim
## red lamp, a lit panel) and never hidden.
##
## A guard presses one to raise the alarm; while it is up the player can hold
## interact on the panel (`AlarmReset`) to silence it. Lockdown stays locked.

const PANEL_ON := Color(1.0, 0.12, 0.08)

var _panel: MeshInstance3D
var _mat: StandardMaterial3D
var _lamp: OmniLight3D

## `yaw` is the way the panel faces (0 = +z / south).
static func create(game: GrayboxGame, parent: Node3D, pos: Vector3,
		yaw: float) -> AlarmStation:
	var s := AlarmStation.new()
	s.name = "AlarmStation"
	s.position = pos
	s.rotation.y = yaw
	parent.add_child(s)
	s._build()
	AlarmReset.create(game, s)
	return s

func _build() -> void:
	add_to_group("alarm_station")
	BuildUtils.box(self, Vector3(0, 0.65, 0), Vector3(0.22, 1.3, 0.22),
		Color(0.22, 0.23, 0.26))
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.5, 0.05, 0.04)
	_mat.emission_enabled = true
	_mat.emission = PANEL_ON
	_mat.emission_energy_multiplier = 0.9
	_panel = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.5, 0.08)
	_panel.mesh = bm
	_panel.material_override = _mat
	_panel.position = Vector3(0, 1.15, 0.15)
	add_child(_panel)
	var sign := Label3D.new()
	sign.text = "REPORT AN EVENT\n(REPORTS ARE SCORED)"
	sign.font_size = 22
	sign.pixel_size = 0.0035
	sign.modulate = Color(1, 0.9, 0.85)
	sign.double_sided = false
	sign.position = Vector3(0, 1.15, 0.2)
	add_child(sign)
	Surveillance.screen(self, Vector3(0, 1.75, 0.13), 0.0,
		"REPORTER SCORE\n%d" % (100 + randi() % 800), Vector2(0.42, 0.26))
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0, 1.5, 0.3)
	_lamp.light_color = PANEL_ON
	_lamp.light_energy = 0.5
	_lamp.omni_range = 4.0
	add_child(_lamp)

## The Score is wiped: the post dies. Out of the group, so no guard runs to
## it (GrayboxGame.nearest_station) — he fights where he stands instead.
func power_off() -> void:
	remove_from_group("alarm_station")
	_mat.emission_enabled = false
	_mat.albedo_color = Color(0.12, 0.05, 0.05)
	_lamp.visible = false

## The guard's hand lands on the panel: flash and click.
func press() -> void:
	AudioSynth.play_at(self, "switch", -4.0, 0.8)
	_mat.emission_energy_multiplier = 4.0
	_lamp.light_energy = 3.0
	var tw := create_tween()
	tw.tween_property(_mat, "emission_energy_multiplier", 0.9, 0.8)
	tw.parallel().tween_property(_lamp, "light_energy", 0.5, 0.8)
