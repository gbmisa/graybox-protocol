class_name Surveillance
extends RefCounted
## Everything the Consent Score runs, and what happens when it's wiped
## (SecondaryScore). r7: "it should turn off the cctv cameras and the tracking
## eyes, visual consent scores, automatic door locks, alarm system, all their
## safety measures". So the server is the off switch for the whole level:
##
##   billboard      flickers and goes dark (groups score_board, score_board_face,
##                  score_board_light)
##   score screens  every `screen()` in the level flickers out (score_display)
##   CCTV + eyes    sag and die (WatcherEye.power_off; groups cctv, watcher_eye)
##   door locks     the mission's RemoteDoors release (mission.blackout())
##   alarm          stations die, any alarm up stands down, nothing raises it
##                  again (AlertState.shut_down)
##
## Things in the player's head (TripZone faces) are not on the grid and stay.

const SCREEN_ON := Color(0.35, 1.0, 0.55)

## A wall screen showing a score: an emissive panel and the number on it.
## `text` is what it shows while the Score is up.
static func screen(root: Node3D, pos: Vector3, yaw: float, text: String,
		size := Vector2(0.9, 0.55)) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	root.add_child(n)
	BuildUtils.box(n, Vector3(0, 0, -0.04), Vector3(size.x + 0.08, size.y + 0.08, 0.06),
		Color(0.07, 0.07, 0.08), false)
	var face := BuildUtils.box(n, Vector3.ZERO, Vector3(size.x, size.y, 0.02), Color.BLACK, false)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.06, 0.03)
	m.emission_enabled = true
	m.emission = Color(0.05, 0.35, 0.15)
	m.emission_energy_multiplier = 1.0
	face.material_override = m
	var l := Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = size.y / 220.0
	l.modulate = SCREEN_ON
	l.outline_size = 0
	l.double_sided = false
	l.position = Vector3(0, 0, 0.015)
	n.add_child(l)
	n.set_meta("face", m)
	n.set_meta("label", l)
	n.add_to_group("score_display")
	return n

static func blackout(game: GrayboxGame) -> void:
	var tree := game.get_tree()
	for l in tree.get_nodes_in_group("score_board"):
		_flicker_out(l as Node3D, func() -> void: (l as Label3D).visible = false)
	for b in tree.get_nodes_in_group("score_board_face"):
		var mi := b as MeshInstance3D
		_flicker_out(mi, func() -> void:
			var m := mi.material_override as StandardMaterial3D
			m.emission_enabled = false
			m.albedo_color = Color(0.03, 0.03, 0.035))
	for lt in tree.get_nodes_in_group("score_board_light"):
		(lt as Light3D).visible = false
	for s in tree.get_nodes_in_group("score_display"):
		var n := s as Node3D
		_flicker_out(n, func() -> void:
			(n.get_meta("face") as StandardMaterial3D).emission_enabled = false
			(n.get_meta("label") as Label3D).visible = false)
	for e in tree.get_nodes_in_group("cctv") + tree.get_nodes_in_group("watcher_eye"):
		(e as WatcherEye).power_off()
	for st in tree.get_nodes_in_group("alarm_station"):
		(st as AlarmStation).power_off()
	game.alert.shut_down()
	if game.mission != null and game.mission.has_method("blackout"):
		game.mission.blackout()

## A few stuttering blinks, then `off` for good. Staggered per object so the
## level doesn't die in one frame.
static func _flicker_out(n: Node3D, off: Callable) -> void:
	if n == null or not n.is_inside_tree():
		off.call()
		return
	var tw := n.create_tween()
	tw.tween_interval(randf() * 0.8)
	for i in 4:
		tw.tween_callback(func() -> void: n.visible = false)
		tw.tween_interval(0.05 + randf() * 0.12)
		tw.tween_callback(func() -> void: n.visible = true)
		tw.tween_interval(0.04 + randf() * 0.2)
	tw.tween_callback(off)
