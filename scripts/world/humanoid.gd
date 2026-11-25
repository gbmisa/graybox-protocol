class_name Humanoid
extends Node3D
## A person: guard, civilian, the target. r7 ("do medium graphics for the
## models"): the CC0 Quaternius base bodies (~12.5k tris, rigged) with the
## Universal Animation Library's moves, baked by tools/blender/people.py into
## assets/models/people/. Still Cruelty Squad's crowd, not anyone's soldier:
## garish flat clothes painted by person.gdshader from a baked mask, skin
## tints from normal to sickly green, hats and helmets on the head bone.
##
## Feet at y=0, head centre at y~1.95 (what the guard's head collider is cut
## to — hence SCALE), facing -z.
##
## `style` keys (all optional): skin, top, bottom, accent, visor (Color),
## armed (bool), scale (float), bulk (float, girth), hat (bool), female
## (bool), hair (int, -1 = none), helmet (bool).

const MODELS := ["res://assets/models/people/person_male.glb",
	"res://assets/models/people/person_female.glb"]
const SHADER := preload("res://scripts/world/person.gdshader")
const OUTLINE := preload("res://scripts/world/person_outline.gdshader")
const SCALE := 1.15   # 1.81m model -> head at ~1.95
const HAIR := ["Hair_Buzzed", "Hair_SimpleParted", "Hair_Long", "Hair_Buns",
	"Hair_BuzzedFemale", "Hair_Beard"]
## Default flat skin colour when a style names none.
const BASE_SKIN := Color(0.78, 0.56, 0.44)
## The hair texture is near-white and made to be tinted: browns, black,
## blonde, and the odd Cruelty Squad dye job.
const HAIR_COLORS := [Color(0.25, 0.16, 0.10), Color(0.08, 0.07, 0.07), Color(0.85, 0.70, 0.40),
	Color(0.45, 0.22, 0.10), Color(0.95, 0.20, 0.55), Color(0.30, 0.90, 0.40), Color(0.55, 0.55, 0.58)]
const LOOPS := ["idle", "walk", "jog", "sprint", "pistol_idle", "aim", "cower", "talk"]

var armed: bool = false
var _model: Node3D
var _anim: AnimationPlayer
var _mat: ShaderMaterial
var _skel: Skeleton3D
var _panic := false
var _aiming := false
var _dead := false
var _current := ""
var _accents: Array[StandardMaterial3D] = []

static func create(parent: Node3D, style: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	h.name = "Humanoid"
	parent.add_child(h)
	h._build(style)
	return h

## A garish random civilian: clashing flat colours, odd sizes, any haircut.
static func random_style(rng: RandomNumberGenerator) -> Dictionary:
	var skins := [Color(0.85, 0.66, 0.52), Color(0.62, 0.42, 0.30), Color(0.45, 0.30, 0.22),
		Color(0.72, 0.85, 0.40), Color(0.80, 0.55, 0.70), Color(0.55, 0.75, 0.85)]
	var loud := [Color(0.95, 0.15, 0.55), Color(0.15, 0.85, 0.35), Color(0.98, 0.80, 0.10),
		Color(0.20, 0.45, 0.95), Color(0.95, 0.45, 0.10), Color(0.60, 0.20, 0.85),
		Color(0.10, 0.80, 0.80)]
	var female := rng.randf() < 0.5
	return {
		"skin": skins[rng.randi() % skins.size()],
		"top": loud[rng.randi() % loud.size()],
		"bottom": loud[rng.randi() % loud.size()].darkened(0.45),
		"accent": loud[rng.randi() % loud.size()],
		"scale": rng.randf_range(0.9, 1.06),
		"bulk": rng.randf_range(0.92, 1.25),
		"hat": rng.randf() < 0.3,
		"female": female,
		"hair": rng.randi() % (5 if female else 6) if rng.randf() < 0.9 else -1,
	}

func _build(s: Dictionary) -> void:
	armed = bool(s.get("armed", false))
	var female := bool(s.get("female", false))
	_model = (load(MODELS[1 if female else 0]) as PackedScene).instantiate() as Node3D
	add_child(_model)
	_model.rotation.y = PI   # the glb faces +z
	var bulk := float(s.get("bulk", 1.0))
	var sc := SCALE * float(s.get("scale", 1.0))
	_model.scale = Vector3(sc * lerpf(1.0, bulk, 0.6), sc, sc * lerpf(1.0, bulk, 0.4))
	_skel = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for n in LOOPS:
		if _anim.has_animation(n):
			_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	_skin(s)
	var hair := int(s.get("hair", 0))
	var hc: Color = s.get("hair_color", HAIR_COLORS[randi() % HAIR_COLORS.size()])
	for i in HAIR.size():
		var mi := _skel.find_child(HAIR[i], false, false) as MeshInstance3D
		if mi != null:
			mi.visible = i == hair
			if i == hair:
				var hm := (mi.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
				# Flat, like everything else in the level (r8).
				hm.albedo_texture = null
				hm.normal_enabled = false
				hm.roughness = 1.0
				hm.albedo_color = hc
				mi.material_override = hm
	if bool(s.get("helmet", false)):
		_helmet(s.get("accent", Color.YELLOW), s.get("visor", Color(0.1, 0.9, 1.0)))
	elif bool(s.get("hat", false)):
		_cap(s.get("accent", Color.YELLOW))
	if armed:
		_pistol()
	_play("pistol_idle" if armed else "idle")
	_anim.seek(randf() * 2.0, true)

func _skin(s: Dictionary) -> void:
	var body := _skel.find_child("Body", false, false) as MeshInstance3D
	var src := body.mesh.surface_get_material(0) as StandardMaterial3D
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	if src != null:
		_mat.set_shader_parameter("skin_tex", src.albedo_texture)
	var skin: Color = s.get("skin", BASE_SKIN)
	_mat.set_shader_parameter("skin_col", Vector3(skin.r, skin.g, skin.b))
	_mat.set_shader_parameter("top_col", s.get("top", Color(0.6, 0.1, 0.1)))
	_mat.set_shader_parameter("bottom_col", s.get("bottom", Color(0.12, 0.12, 0.2)))
	_mat.set_shader_parameter("shoe_col", Color(0.05, 0.05, 0.06))
	var ink := ShaderMaterial.new()
	ink.shader = OUTLINE
	_mat.next_pass = ink
	body.material_override = _mat

## Something worn or held, on a bone.
func _on_bone(bone: String) -> BoneAttachment3D:
	var at := BoneAttachment3D.new()
	at.bone_name = bone
	_skel.add_child(at)
	return at

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow := false,
		dome := false) -> void:
	var mi := MeshInstance3D.new()
	if dome:
		var sm := SphereMesh.new()
		sm.radius = size.x * 0.5
		sm.height = size.y
		sm.is_hemisphere = true
		mi.mesh = sm
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.4
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	_accents.append(m)

## Bone space is the pack's: the head bone sits at the top of the neck, its
## +y runs up through the skull, +z out of the face (the model faces +z
## before _model's turn). Hand bones: +y along the fingers, +z thumb side.
func _cap(color: Color) -> void:
	var h := _on_bone("Head")
	_box(h, Vector3(0.02, 0.16, -0.02), Vector3(0.23, 0.11, 0.23), color, false, true)
	_box(h, Vector3(0.02, 0.17, 0.11), Vector3(0.18, 0.015, 0.09), color.darkened(0.3))

func _helmet(color: Color, visor: Color) -> void:
	var h := _on_bone("Head")
	_box(h, Vector3(0.02, 0.12, -0.03), Vector3(0.27, 0.17, 0.27), color.darkened(0.55), false, true)
	_box(h, Vector3(0.02, 0.10, 0.10), Vector3(0.2, 0.04, 0.03), visor, true)

func _pistol() -> void:
	var hand := _on_bone("hand_r")
	_box(hand, Vector3(0.0, 0.11, 0.045), Vector3(0.035, 0.18, 0.045), Color(0.08, 0.08, 0.09))
	_box(hand, Vector3(0.0, 0.06, 0.0), Vector3(0.03, 0.04, 0.09), Color(0.08, 0.08, 0.09))

func _play(n: String, blend := 0.2) -> void:
	if n == _current or not _anim.has_animation(n):
		return
	_current = n
	_anim.play(n, blend)

## Pick the move for the current ground speed (m/s).
func animate(speed: float, _delta: float) -> void:
	if _dead:
		return
	if _aiming and speed < 1.5:
		_play("aim", 0.12)
		_anim.speed_scale = 1.0
		return
	if speed < 0.3:
		_play("cower" if _panic else ("pistol_idle" if armed else "idle"))
		_anim.speed_scale = 1.0
	elif speed < 2.4:
		_play("walk")
		_anim.speed_scale = clampf(speed / 1.5, 0.6, 1.6)
	elif speed < 5.0 and not _panic:
		_play("jog")
		_anim.speed_scale = clampf(speed / 3.6, 0.7, 1.4)
	else:
		_play("sprint")
		_anim.speed_scale = clampf(speed / 5.5, 0.7, 1.3)

## A panicking civilian cowers when still and sprints when not.
func set_panic(on: bool) -> void:
	_panic = on

## The guard raising his gun (the aim tell): the aim pose while it lasts.
func set_aim(on: bool) -> void:
	_aiming = on

## Fall down for good. The caller switches the colliders off.
func die() -> void:
	if _dead:
		return
	_dead = true
	_anim.speed_scale = 1.0
	_current = ""
	_play("death", 0.1)

func tint(color: Color) -> void:
	_mat.set_shader_parameter("tint_col", color)
	_mat.set_shader_parameter("tint_mix", 0.85)

func untint() -> void:
	_mat.set_shader_parameter("tint_mix", 0.0)

func flash(tweener: Node) -> void:
	var tw := tweener.create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.2)
