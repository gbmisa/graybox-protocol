class_name SecCmpExits
extends RefCounted
## The ways out, dressed and never labelled (the unlabelled-exits test scans
## every Label3D). Each is something you can see and hear from a distance:
##
##   E1 van      outfall pit (-38.7, -2.2, 6): Kenney van, engine idling,
##               side light on. Only the culvert crawl reaches the pit floor.
##   E2 heli     helipad deck on the gym roof (23, 11.2, -8): Vandermeer's
##               continuity helicopter, rotor turning, beacon blinking. A
##               steel stair now climbs from the gym roof (6.6) to the deck
##               (11.2) along x [22.5, 24.5] — it was Chad's 2.2/2.4 chain
##               only, and the Regular stood under it looking up ("I can't
##               get up to what I think used to be the helipad").
##   (E3, the avenue car, removed in r9: it was in the way of the annex.)
## The trigger spheres are MissionCompoundData.EXTRACTIONS.

const DECK_Y := 11.2
const ROOF_Y := 6.6

static func build(root: Node3D, game: GrayboxGame) -> void:
	_van(root)
	_helipad_stair(root)
	_helicopter(root)

static func _van(root: Node3D) -> void:
	Props.vehicle(root, "car/van", Vector3(-38.7, -2.2, 6), 0.0)
	BuildUtils.lamp(root, Vector3(-37.2, -1.2, 5.0), BuildUtils.LAMP_SERVICE, 1.0, 6.0)
	_headlights(root, Vector3(-38.7, -1.4, 8.8), 0.0, 10.0)
	engine_loop(root, Vector3(-38.7, -1.4, 6), "res://assets/audio/scifi/engineCircular_000.ogg", -8.0)

## Two spots looking the way the vehicle faces (yaw 0 = +z).
static func _headlights(root: Node3D, front: Vector3, yaw: float, reach: float) -> void:
	for side in [-0.7, 0.7]:
		var head := SpotLight3D.new()
		head.position = front + Basis(Vector3.UP, yaw) * Vector3(side, 0, 0)
		head.rotation = Vector3(-0.08, PI + yaw, 0)
		head.light_energy = 3.0
		head.spot_range = reach
		head.spot_angle = 28.0
		root.add_child(head)

## A looping sound at a spot, audible only nearby.
static func engine_loop(root: Node3D, pos: Vector3, path: String, db: float) -> AudioStreamPlayer3D:
	var src := load(path) as AudioStreamOggVorbis
	if src == null:
		return null
	var stream := src.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.position = pos
	p.volume_db = db
	p.max_distance = 30.0
	p.unit_size = 4.0
	p.autoplay = true
	root.add_child(p)
	return p

## Gym roof -> deck: 6 m north at x [22.5, 24.5], rising 4.6 (0.77).
static func _helipad_stair(root: Node3D) -> void:
	var m := BuildUtils.METAL
	BuildUtils.stairs(root, Vector3(23.5, ROOF_Y, 2.0), Vector3(0, 0, -1),
		10, 0.46, 0.6, 2.0, m)

## A box-built helicopter: crude on purpose, like everything Vandermeer owns
## that isn't the score.
static func _helicopter(root: Node3D) -> void:
	var heli := Node3D.new()
	heli.name = "ContinuityHelicopter"
	# Tail to the north, over the deck's far edge, so the stair arrives at
	# the nose with the cabin a metre and a half away.
	heli.position = Vector3(23, DECK_Y, -7.4)
	heli.rotation.y = PI
	root.add_child(heli)
	var body := Color(0.10, 0.11, 0.13)
	var trim := Color(0.95, 0.70, 0.20)
	_part(heli, Vector3(0, 1.25, 0), Vector3(2.0, 1.7, 3.6), body)          # cabin
	_part(heli, Vector3(0, 1.45, -1.95), Vector3(1.7, 1.1, 0.5), Color(0.25, 0.35, 0.45))  # nose glass
	_part(heli, Vector3(0, 1.55, 3.9), Vector3(0.45, 0.45, 4.6), body)       # tail boom
	_part(heli, Vector3(0, 2.25, 6.0), Vector3(0.12, 1.3, 0.9), trim)        # fin
	_part(heli, Vector3(0, 0.95, 0.4), Vector3(2.04, 0.18, 2.4), trim)       # livery stripe
	for x in [-0.95, 0.95]:
		_part(heli, Vector3(x, 0.1, 0), Vector3(0.12, 0.12, 3.4), body)      # skids
		_part(heli, Vector3(x, 0.3, -0.9), Vector3(0.1, 0.4, 0.1), body)
		_part(heli, Vector3(x, 0.3, 0.9), Vector3(0.1, 0.4, 0.1), body)
	_part(heli, Vector3(0, 2.25, 0), Vector3(0.3, 0.3, 0.3), body)           # mast
	var rotor := Node3D.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 2.45, 0)
	heli.add_child(rotor)
	_part(rotor, Vector3.ZERO, Vector3(9.0, 0.06, 0.35), body)
	_part(rotor, Vector3.ZERO, Vector3(0.35, 0.06, 9.0), body)
	var spin := rotor.create_tween().set_loops()
	spin.tween_property(rotor, "rotation:y", TAU, 0.9).as_relative()
	# Collision for the cabin only — the rotor is above head height.
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.1, 3.6)
	cs.shape = shape
	cs.position = Vector3(0, 1.05, 0)
	sb.add_child(cs)
	heli.add_child(sb)
	_beacon(heli)
	engine_loop(root, Vector3(23, DECK_Y + 2.0, -7.4),
		"res://assets/audio/scifi/spaceEngineLow_000.ogg", -4.0).max_distance = 70.0

static func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.3
	m.roughness = 0.5
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)

## Red anti-collision light on the tail, blinking — visible from the courtyard.
static func _beacon(heli: Node3D) -> void:
	var l := OmniLight3D.new()
	l.position = Vector3(0, 3.0, 6.0)
	l.light_color = Color(1.0, 0.15, 0.1)
	l.omni_range = 9.0
	heli.add_child(l)
	var blink := l.create_tween().set_loops()
	blink.tween_property(l, "light_energy", 3.0, 0.05)
	blink.tween_interval(0.12)
	blink.tween_property(l, "light_energy", 0.0, 0.05)
	blink.tween_interval(1.1)
