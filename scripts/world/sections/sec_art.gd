class_name SecArt
extends RefCounted
## The r6 look, the parts that are things rather than light: posters and
## graffiti (our own, tools/gen/make_textures.py), neon trim and signs, the
## Gratitude Eye on the courtyard mast and CCTV cameras that follow you.
##
## Posters and tags are given a rough spot and the way they face; they snap
## to the nearest wall behind that spot on the first physics frame (ArtPlacer)
## so a list entry a few cm off a wall still lands flat on it.

const GEN := "res://assets/textures/gen/%s.png"

## [kind index, rough position, facing yaw (0 = +z, PI = -z, PI/2 = +x, -PI/2 = -x)]
const POSTERS := [
	[0, Vector3(6, 1.9, -1.6), 0.0], [3, Vector3(-5, 1.9, -1.6), 0.0],     # main block, south face
	[4, Vector3(-8, 2.0, 23.3), PI], [1, Vector3(2, 2.0, 23.3), PI],       # courtyard, south wall
	[5, Vector3(9, 2.0, 23.3), PI],
	[2, Vector3(-6, 1.9, -20.4), PI], [0, Vector3(4, 1.9, -20.4), PI],      # north yard, main block
	[1, Vector3(-22.4, 1.9, -15), -PI / 2.0],                              # west face
	[3, Vector3(15.6, 1.9, -6), -PI / 2.0],                                # gym, alley side
	[5, Vector3(-9, 2.0, -45.6), 0.0], [2, Vector3(3, 2.0, -45.6), 0.0],    # annex, south face
	[4, Vector3(-8, 5.8, -50.4), 0.0], [0, Vector3(-1, 5.8, -46.4), PI],    # annex corridor
	[1, Vector3(-5, 2.0, -40.6), PI], [3, Vector3(6, 2.0, -40.6), PI],      # avenue, annex wall
	# The approach: estate walls, the embankment, the tower lobby, the hut.
	[0, Vector3(-30, 1.4, 166.0), PI], [4, Vector3(-5, 1.4, 166.0), PI],
	[2, Vector3(15, 1.4, 166.0), PI], [5, Vector3(0, 1.4, 148.6), 0.0],
	[1, Vector3(30, 1.4, 148.6), 0.0], [3, Vector3(-20, 1.8, 138.4), 0.0],
	[4, Vector3(25, 1.8, 138.4), 0.0], [0, Vector3(-13.8, 1.8, 181), PI / 2.0],
	[5, Vector3(26.2, 1.6, 107), PI / 2.0], [2, Vector3(-13.8, 1.8, 186), PI / 2.0],
	[2, Vector3(-6, 1.9, -12.9), PI], [5, Vector3(-14, 1.9, -11.1), 0.0],  # north corridor
]
const TAGS := [
	[0, Vector3(-20, 1.6, 25.2), 0.0], [1, Vector3(0, 1.4, 25.2), 0.0],     # compound wall, verge side
	[3, Vector3(18, 1.6, 25.2), 0.0],
	[2, Vector3(-29.2, 1.6, -20), -PI / 2.0], [0, Vector3(-29.2, 1.6, 20), -PI / 2.0],  # west alley
	[1, Vector3(-10, 1.6, -25.2), PI], [3, Vector3(12, 1.6, -25.2), PI],    # avenue, north wall
	[2, Vector3(-20, 1.2, 167.4), 0.0], [0, Vector3(10, 1.2, 167.4), 0.0],  # estate yard walls
	[3, Vector3(-10, 1.2, 147.1), PI], [1, Vector3(20, 1.2, 147.1), PI],
	[2, Vector3(-19.7, 1.6, -50), PI / 2.0],                               # annex yard
	[0, Vector3(-6, 1.6, 138.4), 0.0], [3, Vector3(36, 1.6, 138.4), 0.0],   # embankment
	[1, Vector3(-38, 1.2, 148.6), 0.0],
]

static func build(root: Node3D, game: GrayboxGame) -> void:
	var placer := ArtPlacer.new()
	placer.name = "ArtPlacer"
	root.add_child(placer)
	for p in POSTERS:
		placer.add(_quad(root, GEN % ("poster_%d" % int(p[0])), Vector2(1.0, 1.5)), p[1], float(p[2]))
	for t in TAGS:
		placer.add(_quad(root, GEN % ("graffiti_%d" % int(t[0])), Vector2(3.2, 1.6)), t[1], float(t[2]))
	_eye(root)
	_cameras(root)
	_statues(root)
	_neon(root)

static func _quad(root: Node3D, tex_path: String, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(tex_path) as Texture2D
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false   # until placed
	root.add_child(mi)
	return mi

## The courtyard mast's floodlight is an eye now. It follows you across the
## courtyard; the MAST ISOLATOR shuts it with the lamp (group mast_lamp).
static func _eye(root: Node3D) -> void:
	var e := WatcherEye.eyeball(root, Vector3(0, 8.6, 10), 0.9, Color(0.75, 1.0, 0.2))
	e.add_to_group("mast_lamp")
	e.reach = 40.0
	e.arc = PI
	# And a second one over the annex roof, on a pole, pink.
	WatcherEye.eyeball(root, Vector3(-4, 11.4, -51), 1.1, Color(1.0, 0.2, 0.6))
	BuildUtils.box(root, Vector3(-4, 9.15, -51), Vector3(0.3, 2.3, 0.3), BuildUtils.METAL, false)

## CONSENTO, the Score's mascot (tools/blender/mascot.py): one on the verge
## greeting the road, one in the annex yard greeting the checkpoint. Mesh
## collision, so the plinth and the raised arm are things to climb.
static func _statues(root: Node3D) -> void:
	for s in [[Vector3(17, 0, 28.6), 0.0], [Vector3(-16, 0, -44), 0.0]]:
		Props.place(root, "custom/consento", s[0], float(s[1]), 1.0, true, 0.0, true)

## Wall cameras over the ways in. [position, rotation — the camera faces -z at
## rest, so PI looks south (+z), PI/2 west (-x), -PI/2 east (+x)]
static func _cameras(root: Node3D) -> void:
	for c in [
		[Vector3(-2.6, 3.0, -1.6), PI], [Vector3(2.6, 3.0, -1.6), PI],       # portico
		[Vector3(-3.4, 3.4, -23.6), PI],                                       # gatehouse door
		[Vector3(27.6, 3.4, 16.4), PI / 2.0],                                  # bin-store gate
		[Vector3(-27.6, 3.4, 5.0), -PI / 2.0],                                 # culvert
		[Vector3(-3.6, 3.4, -45.6), PI], [Vector3(6.4, 6.6, -55.0), -PI / 2.0], # annex
		[Vector3(10.4, 3.4, -12.9), -PI / 2.0],                                # canteen service door
	]:
		WatcherEye.camera(root, c[0], float(c[1]))

## Neon: emissive tubes along the main block's roof edge, the gym's and the
## annex's, and two signs. Unshaded, bright enough to bloom.
static func _neon(root: Node3D) -> void:
	var pink := Color(1.0, 0.15, 0.6)
	var acid := Color(0.6, 1.0, 0.1)
	var cyan := Color(0.1, 0.95, 1.0)
	_tube(root, Vector3(-6, 9.05, -1.75), Vector3(32.0, 0.08, 0.08), pink)
	_tube(root, Vector3(-22.1, 9.05, -11), Vector3(0.08, 0.08, 18.0), pink)
	_tube(root, Vector3(22, 7.05, 8.1), Vector3(12.0, 0.08, 0.08), cyan)
	_tube(root, Vector3(-4, 8.55, -45.8), Vector3(20.3, 0.08, 0.08), acid)
	_tube(root, Vector3(0, 0.15, -40.0), Vector3(6.0, 0.06, 0.06), acid)
	_sign(root, "GRATITUDE", Vector3(-6, 9.9, -1.7), 0.0, pink, 1.6)
	_sign(root, "SCORING", Vector3(-4, 9.0, -45.7), 0.0, acid, 1.3)
	# The approach: the tower lobby's all-nighter, the duty-rota hut.
	_sign(root, "OPEN 24H", Vector3(-13.85, 3.8, 183), PI / 2.0, pink, 0.8)
	_sign(root, "BE GRATEFUL", Vector3(26.15, 3.2, 107), PI / 2.0, cyan, 0.6)
	for at in [Vector3(-6, 9.0, 0.5), Vector3(-4, 8.6, -44.5)]:
		var l := OmniLight3D.new()
		l.position = at
		l.light_color = pink if at.z > -10 else acid
		l.light_energy = 0.6
		l.omni_range = 7.0
		root.add_child(l)

static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color * energy
	return m

static func _tube(root: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := BuildUtils.box(root, pos, size, color, false)
	mi.material_override = _glow(color, 1.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _sign(root: Node3D, text: String, pos: Vector3, yaw: float, color: Color, h: float) -> void:
	var mi := MeshInstance3D.new()
	var tm := TextMesh.new()
	tm.text = text
	tm.font = load("res://assets/fonts/Kenney Future.ttf") as Font
	tm.font_size = 64
	tm.pixel_size = h / 64.0
	tm.depth = 0.06
	mi.mesh = tm
	mi.material_override = _glow(color, 1.7)
	mi.position = pos
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## Snaps queued quads flat onto the wall behind their rough spot, once the
## level's colliders are in the physics space, then frees itself.
class ArtPlacer extends Node3D:
	var _queue: Array = []
	var _frames := 0

	func add(mi: MeshInstance3D, at: Vector3, yaw: float) -> void:
		_queue.append([mi, at, yaw])

	func _physics_process(_delta: float) -> void:
		_frames += 1
		if _frames < 2:
			return
		var space := get_world_3d().direct_space_state
		for e in _queue:
			var mi := e[0] as MeshInstance3D
			var at: Vector3 = e[1]
			var face := Basis(Vector3.UP, float(e[2])) * Vector3(0, 0, 1)
			var q := PhysicsRayQueryParameters3D.create(at + face * 0.8, at - face * 1.5)
			q.collision_mask = 1
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var n: Vector3 = hit["normal"]
			mi.global_position = (hit["position"] as Vector3) + n * 0.015
			mi.global_basis = Basis.looking_at(-n, Vector3.UP)
			mi.visible = true
		queue_free()
