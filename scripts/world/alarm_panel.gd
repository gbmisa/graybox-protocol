class_name AlarmPanel
extends Node3D
## A physical alarm panel: red pedestal, floating "ALARM PANEL" label, and a
## beacon diamond that lights up once the director reveals the panels (meter
## past half) and goes dark green once tripped.
##
## Spawned per mission by spawn_all() from AlarmPanelData, parented to the
## level root so mission reset tears them down with everything else. The
## guard AI's runner moves for the nearest one; arrival calls activate(),
## which trips the director's lockdown exactly once.

var game: GrayboxGame = null
var panel_name: String = ""
var activated: bool = false
var revealed: bool = false

var _label: Label3D = null
var _beacon: MeshInstance3D = null
var _t: float = 0.0

static func spawn_all(p_game: GrayboxGame, root: Node3D) -> Array:
	var out: Array = []
	for d in AlarmPanelData.get_panels(p_game.selected_level):
		var p := AlarmPanel.new()
		root.add_child(p)
		p.setup(p_game, d["pos"] as Vector3, String(d["name"]))
		out.append(p)
	return out

func setup(p_game: GrayboxGame, pos: Vector3, p_name: String) -> void:
	game = p_game
	panel_name = p_name
	position = pos
	BuildUtils.box(self, Vector3(0, 0.65, 0), Vector3(0.7, 1.3, 0.5),
		BuildUtils.RED)
	_label = BuildUtils.label(self, "ALARM PANEL", Vector3(0, 2.1, 0),
		Color(0.55, 0.55, 0.55), 40)
	_beacon = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.35, 0.35)
	_beacon.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.2, 0.2)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.2, 0.2)
	_beacon.material_override = m
	_beacon.position = Vector3(0, 2.7, 0)
	_beacon.rotation.z = PI / 4.0
	_beacon.visible = false
	add_child(_beacon)

func _process(delta: float) -> void:
	if _beacon == null or not _beacon.visible:
		return
	_t += delta
	var s := 1.0 + 0.25 * sin(_t * 6.0)
	_beacon.scale = Vector3(s, s, s)
	_beacon.rotate_y(2.0 * delta)

## The director calls this when the meter first passes half: the beacon
## lights and the label goes red — the panel is now a known objective.
func set_revealed() -> void:
	if revealed:
		return
	revealed = true
	_beacon.visible = true
	_label.modulate = Color(1.0, 0.25, 0.25)

## A runner reached this panel. One-shot: trips the mission lockdown.
func activate() -> void:
	if activated:
		return
	activated = true
	_beacon.visible = false
	_label.modulate = Color(0.3, 1.0, 0.3)
	_label.text = "ALARM PANEL — TRIPPED"
	game.director.trigger_lockdown()
