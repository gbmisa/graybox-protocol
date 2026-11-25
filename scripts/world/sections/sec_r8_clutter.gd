class_name SecR8Clutter
extends RefCounted
## r8 graphics review: "never more than 6m of untouched surface in view". A
## seeded scatter of street mess over the open ground — rubbish bags, cans,
## flattened boxes, paper — and wet puddles (near-mirror, so the neon and the
## lamps show in them). Nothing here collides: it can never sit in a patrol
## lane or a doorway (CLAUDE.md), so it is free to be anywhere.

## [x0, x1, z0, z1, floor y, per 100 m²]
const AREAS := [
	[-40, 40, 140, 172, 0.0, 3.0],     # estate yard
	[-44, 44, 174, 196, 0.0, 2.0],     # spawn street
	[-44, 44, 100, 111, 0.0, 2.5],     # towpath
	[-44, 44, 46, 60, 0.0, 2.5],       # terrace backs
	[-44, 44, 25, 46, 0.0, 2.5],       # south road + verge
	[-12, 12, -76, -42, 0.0, 2.0],     # Consent Way
	[-34, -12, -100, -44, 0.0, 3.0],   # annex west yard
	[-20, 20, -40, -25, 0.0, 2.5],     # avenue
	[-22, -12, -2, 24, 0.0, 3.0],      # courtyard west
	[28.8, 36, -24, 24, 0.0, 3.0],     # east lane
	[-40, -28.8, -24, 24, 0.0, 3.0],   # west alley
	[-44, 44, 112, 138, 4.0, 1.5],     # road deck
]

const BAG := Color(0.06, 0.06, 0.07)
const PAPER := [Color(0.85, 0.82, 0.7), Color(0.9, 0.3, 0.55), Color(0.3, 0.8, 0.9)]
const CAN := [Color(0.9, 0.1, 0.1), Color(0.95, 0.85, 0.1), Color(0.2, 0.8, 0.3)]

static func build(root: Node3D, _game: GrayboxGame) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8008
	var wet := StandardMaterial3D.new()
	# Light and a little rough, so a missed SSR ray shows the sky, not a
	# black hole (r8 review round 3).
	wet.albedo_color = Color(0.35, 0.38, 0.45, 0.55)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.roughness = 0.15
	wet.metallic = 0.3
	var parent := Node3D.new()
	parent.name = "Clutter"
	root.add_child(parent)
	for a in AREAS:
		var area := (float(a[1]) - float(a[0])) * (float(a[3]) - float(a[2]))
		var n := int(area / 100.0 * float(a[5]))
		for i in n:
			var p := Vector3(rng.randf_range(a[0], a[1]), float(a[4]), rng.randf_range(a[2], a[3]))
			var r := rng.randf()
			if r < 0.25:
				_puddle(parent, p, rng, wet)
			elif r < 0.55:
				_bag(parent, p, rng)
			elif r < 0.8:
				_flat(parent, p, rng, PAPER[rng.randi() % PAPER.size()], Vector3(0.3, 0.01, 0.22))
			else:
				_can(parent, p, rng)

static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, yaw: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

static func _flat_mat(c: Color, rough: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

static func _puddle(parent: Node3D, p: Vector3, rng: RandomNumberGenerator, wet: Material) -> void:
	var c := CylinderMesh.new()
	c.top_radius = rng.randf_range(0.6, 1.8)
	c.bottom_radius = c.top_radius
	c.height = 0.01
	c.radial_segments = 9
	_mesh(parent, c, p + Vector3(0, 0.012, 0), rng.randf() * TAU, wet)

static func _bag(parent: Node3D, p: Vector3, rng: RandomNumberGenerator) -> void:
	for k in rng.randi_range(1, 3):
		var s := SphereMesh.new()
		s.radius = rng.randf_range(0.22, 0.34)
		s.height = s.radius * 1.6
		s.radial_segments = 7
		s.rings = 4
		var off := Vector3(rng.randf_range(-0.35, 0.35), s.height * 0.45, rng.randf_range(-0.35, 0.35))
		_mesh(parent, s, p + off, rng.randf() * TAU, _flat_mat(BAG, 0.25))

static func _flat(parent: Node3D, p: Vector3, rng: RandomNumberGenerator, c: Color, size: Vector3) -> void:
	var b := BoxMesh.new()
	b.size = size * rng.randf_range(0.8, 2.2)
	_mesh(parent, b, p + Vector3(0, 0.01, 0), rng.randf() * TAU, _flat_mat(c))

static func _can(parent: Node3D, p: Vector3, rng: RandomNumberGenerator) -> void:
	var c := CylinderMesh.new()
	c.top_radius = 0.035
	c.bottom_radius = 0.035
	c.height = 0.12
	c.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = _flat_mat(CAN[rng.randi() % CAN.size()], 0.4)
	mi.position = p + Vector3(0, 0.035, 0)
	mi.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
	parent.add_child(mi)
