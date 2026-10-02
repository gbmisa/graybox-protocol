class_name Humanoid
extends Node3D
## A crude low-poly person — Cruelty Squad's gallery of lumpy, garishly
## coloured bodies rather than anyone's idea of a soldier. Feet at y=0, head
## centre at y=1.95 (what the guard's head collider is cut to), facing -z.
## Built from boxes on pivots so the limbs can swing when it walks.
##
## `style` keys (all optional): skin, top, bottom, accent, visor (Color),
## armed (bool), scale (float), bulk (float, torso width), tall (float, head
## height multiplier), hat (bool).

var armed: bool = false
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _torso: MeshInstance3D
var _head: MeshInstance3D
var _uniform: Array[StandardMaterial3D] = []   # what tint() recolours
var _all: Array[StandardMaterial3D] = []
var _base: Dictionary = {}                     # material -> its own colour
var _phase: float = 0.0
var _amp: float = 0.0

static func create(parent: Node3D, style: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	h.name = "Humanoid"
	parent.add_child(h)
	h._build(style)
	return h

## A garish random civilian: clashing flat colours, wrong-sized everything.
static func random_style(rng: RandomNumberGenerator) -> Dictionary:
	var skins := [Color(0.85, 0.66, 0.52), Color(0.62, 0.42, 0.30), Color(0.45, 0.30, 0.22),
		Color(0.72, 0.85, 0.40), Color(0.80, 0.55, 0.70), Color(0.55, 0.75, 0.85)]
	var loud := [Color(0.95, 0.15, 0.55), Color(0.15, 0.85, 0.35), Color(0.98, 0.80, 0.10),
		Color(0.20, 0.45, 0.95), Color(0.95, 0.45, 0.10), Color(0.60, 0.20, 0.85),
		Color(0.10, 0.80, 0.80)]
	return {
		"skin": skins[rng.randi() % skins.size()],
		"top": loud[rng.randi() % loud.size()],
		"bottom": loud[rng.randi() % loud.size()].darkened(0.45),
		"accent": loud[rng.randi() % loud.size()],
		"visor": Color(0.05, 0.05, 0.05),
		"scale": rng.randf_range(0.88, 1.08),
		"bulk": rng.randf_range(0.85, 1.35),
		"hat": rng.randf() < 0.4,
	}

func _build(s: Dictionary) -> void:
	var skin: Color = s.get("skin", Color(0.8, 0.6, 0.5))
	var top: Color = s.get("top", Color(0.6, 0.1, 0.1))
	var bottom: Color = s.get("bottom", Color(0.12, 0.12, 0.2))
	var accent: Color = s.get("accent", Color(0.9, 0.8, 0.1))
	var visor: Color = s.get("visor", Color(0.1, 0.9, 1.0))
	var bulk: float = s.get("bulk", 1.0)
	armed = bool(s.get("armed", false))
	scale = Vector3.ONE * float(s.get("scale", 1.0))
	# Pelvis + torso + a slab across the chest in the accent colour.
	_part(self, Vector3(0.48 * bulk, 0.22, 0.30), Vector3(0, 0.98, 0), bottom, false)
	_torso = _part(self, Vector3(0.62 * bulk, 0.62, 0.34), Vector3(0, 1.38, 0), top, true)
	_part(self, Vector3(0.64 * bulk, 0.14, 0.36), Vector3(0, 1.58, 0), accent, true)
	_part(self, Vector3(0.12, 0.10, 0.12), Vector3(0, 1.74, 0), skin, false)   # neck
	_head = _part(self, Vector3(0.36, 0.35, 0.35), Vector3(0, 1.95, 0), skin, false)
	_face(int(s.get("face", randi() % FACES)))
	_part(_head, Vector3(0.30, 0.10, 0.04), Vector3(0, 0.03, -0.18), visor, false, true)
	if bool(s.get("hat", false)):
		_part(_head, Vector3(0.42, 0.08, 0.42), Vector3(0, 0.2, 0), accent, false)
		_part(_head, Vector3(0.28, 0.14, 0.28), Vector3(0, 0.3, 0), accent, false)
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0.15 * sx * bulk, 0.92, 0)
		add_child(leg)
		_part(leg, Vector3(0.22, 0.90, 0.24), Vector3(0, -0.45, 0), bottom, false)
		_part(leg, Vector3(0.25, 0.10, 0.34), Vector3(0, -0.88, -0.05), Color(0.08, 0.08, 0.08), false)
		_legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3((0.42 * bulk) * sx, 1.64, 0)
		add_child(arm)
		_part(arm, Vector3(0.18, 0.68, 0.18), Vector3(0, -0.34, 0), top, true)
		_part(arm, Vector3(0.16, 0.14, 0.16), Vector3(0, -0.72, 0), skin, false)
		_arms.append(arm)
	if armed:
		# Right arm up and out, a blocky blaster in the fist.
		_arms[1].rotation.x = deg_to_rad(-80.0)
		_part(_arms[1], Vector3(0.10, 0.16, 0.52), Vector3(0, -0.78, -0.2), Color(0.1, 0.1, 0.12), false)

## One box. `uniform` parts are recoloured by tint(); `glow` is emissive.
## A drawn face on the front of the head (tools/gen/make_textures.py), under
## the visor. One material per face, shared.
const FACES := 8
static var _face_mats: Dictionary = {}

func _face(i: int) -> void:
	if not _face_mats.has(i):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/textures/gen/face_%d.png" % i) as Texture2D
		m.roughness = 0.8
		_face_mats[i] = m
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.34, 0.33)
	mi.mesh = q
	mi.material_override = _face_mats[i]
	mi.position = Vector3(0, 0, -0.177)
	mi.rotation.y = PI
	_head.add_child(mi)

func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color,
		uniform: bool, glow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.5
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	_all.append(m)
	_base[m] = color
	if uniform:
		_uniform.append(m)
	return mi

## Swing the limbs for the current ground speed (m/s).
func animate(speed: float, delta: float) -> void:
	var want := clampf(speed / 4.0, 0.0, 1.0) * 0.9
	_amp = lerpf(_amp, want, minf(1.0, delta * 10.0))
	_phase += speed * delta * 2.4
	var swing := sin(_phase) * _amp
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing
	_arms[0].rotation.x = -swing * 0.8
	if not armed:
		_arms[1].rotation.x = swing * 0.8
	# A little bounce and lean when running.
	_torso.position.y = 1.38 + absf(sin(_phase)) * 0.03 * _amp

## Hands up and shaking — a panicking civilian. Arms stay raised.
func set_panic(on: bool) -> void:
	if armed:
		return
	_arms[0].rotation.z = deg_to_rad(40.0) if on else 0.0
	_arms[1].rotation.z = deg_to_rad(-40.0) if on else 0.0

func tint(color: Color) -> void:
	for m in _uniform:
		m.albedo_color = color

func untint() -> void:
	for m in _uniform:
		m.albedo_color = _base[m]

func flash(tweener: Node) -> void:
	var tw := tweener.create_tween()
	tw.set_parallel(true)
	for m in _all:
		tw.tween_property(m, "albedo_color", Color.WHITE, 0.05)
	tw.chain().set_parallel(true)
	for m in _all:
		tw.tween_property(m, "albedo_color", _base[m], 0.15)
