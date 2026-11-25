class_name TripParts
extends RefCounted
## What a TripZone is made of: eyeballs and faces. Static builders.

const GEN := "res://assets/textures/gen/trip_face_%d.png"

static var sockets: Dictionary = {}

## A sphere eye facing -z: white, coloured iris, black pupil.
static func eyeball(parent: Node3D, r: float, iris: Color) -> Node3D:
	var e := Node3D.new()
	parent.add_child(e)
	for part in [[Vector3.ZERO, 1.0, Color(0.93, 0.9, 0.86), 0.25, Vector3.ONE],
			[Vector3(0, 0, -0.8), 0.5, iris, 0.6, Vector3(1, 1, 0.4)],
			[Vector3(0, 0, -0.93), 0.24, Color(0.01, 0.0, 0.0), 0.0, Vector3(1, 1, 0.4)]]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r * float(part[1])
		sm.height = sm.radius * 2.0
		sm.radial_segments = 16
		sm.rings = 8
		mi.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = part[2]
		m.roughness = 0.2
		if float(part[3]) > 0.0:
			m.emission_enabled = true
			m.emission = part[2]
			m.emission_energy_multiplier = float(part[3])
		mi.material_override = m
		mi.position = (part[0] as Vector3) * r
		mi.scale = part[4]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		e.add_child(mi)
	return e

static func facing(n: Vector3) -> Basis:
	return Basis.looking_at(n, Vector3.UP if absf(n.y) < 0.95 else Vector3.FORWARD)

## A face (trip_face_i) with eyeballs in its sockets and a whisper, hidden.
static func face(parent: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	if sockets.is_empty():
		var f := FileAccess.open("res://assets/textures/gen/trip_faces.json", FileAccess.READ)
		sockets = JSON.parse_string(f.get_as_text()) if f != null else {}
	var i := rng.randi() % 6
	var root := Node3D.new()
	parent.add_child(root)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	var size := rng.randf_range(1.3, 2.2)
	q.size = Vector2(size, size)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(GEN % i) as Texture2D
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.35
	m.albedo_color = Color(1, 1, 1, 0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var eyes: Array[Node3D] = []
	for s in sockets.get(str(i), []):
		var e := eyeball(root, float(s[2]) * size * 0.95, Color(0.9, 0.85, 0.2))
		e.position = Vector3((float(s[0]) - 0.5) * size, (0.5 - float(s[1])) * size, float(s[2]) * size * 0.3)
		eyes.append(e)
	var voice := AudioStreamPlayer3D.new()
	voice.stream = TripAudio.whisper()
	voice.unit_size = 2.5
	voice.max_distance = 18.0
	voice.volume_db = -60.0
	voice.pitch_scale = rng.randf_range(0.7, 1.15)
	root.add_child(voice)
	root.visible = false
	return {"node": root, "mat": m, "eyes": eyes, "voice": voice, "alpha": 0.0,
		"wait": rng.randf_range(0.5, 4.0), "stalker": false}

