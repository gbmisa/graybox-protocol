class_name PlayerViewmodel
extends Node3D
## The hand and pistol in front of the camera, and everything that makes a
## shot feel like one: kick back and up, muzzle flash, a camera punch (via
## PlayerLook), sway against the mouse and bob with your stride.
##
## HOW IT IS RENDERED (the standard Godot viewmodel setup): the weapon is not a
## child of the player's camera. It lives in its own SubViewport, seen by its
## own Camera3D with a narrow field of view (VM_FOV) and its own near plane,
## and the result is composited over the screen on a CanvasLayer beneath the
## HUD. Two reasons:
##   * perspective — through the world's 80 degree lens a gun 15cm from the eye
##     is stretched into a long diagonal and "points" anywhere but forward; a
##     55 degree lens at a natural 35cm looks like a gun held out in front;
##   * clipping — it can never poke into a wall, whatever the capsule allows.
## The stage sits far from the level (STAGE) so no level lamp lights it; it has
## its own fill light, and the world's ambient (so it darkens in a PITCH room).
##
## The model (assets/viewmodel/viewmodel_pistol.glb) is the CC0 WRAD arm posed
## round Kenney's blaster-a by tools/blender/viewmodel_fit.py, with the eye at
## the origin and the pose already framed through a 55 degree lens: lower right,
## yawed 22 and canted 12 degrees so you see the gun's flank, not its back. Scaling
## it by RIG_SCALE about the eye changes nothing on screen, so the rest pose is
## simply the identity. (It used to be re-aimed at runtime so the barrel ran
## through the crosshair — that pointed the gun straight down the view.)
##
## AIM DOWN SIGHTS (alt_attack, right mouse): the rig swings so the sight line
## (SIGHT_REAR -> SIGHT_FRONT, written out by the fit) runs down the centre of
## the screen, and the world camera zooms by ADS_ZOOM. Shots are hitscan from
## the player's camera either way.

const MODEL := "res://assets/viewmodel/viewmodel_pistol.glb"
const LAYER := 1 << 19
const STAGE := Vector3(0, 4000, 0)
const VM_FOV := 55.0
const RIG_SCALE := 1.6
const BARREL_MESH := "silencer-small"
## Muzzle and grip in the model's own space (measured from the GLB). Kick
## rotates about the grip, so the barrel climbs and the hand stays put.
const MUZZLE := Vector3(0.031, -0.026, -0.178)
const GRIP := Vector3(0.0833, -0.0767, -0.2362)   # the fist's centre, from the Blender fit
## The sight line and the gun's up, in the model's space (also from the fit).
const SIGHT_REAR := Vector3(0.0921, -0.0396, -0.1938)
const SIGHT_FRONT := Vector3(0.0674, -0.0394, -0.2541)
const GUN_UP := Vector3(-0.1910, 0.9781, 0.0821)
## Aimed: where the rear sight sits in the viewmodel camera's view, just under
## the crosshair, and how far the world camera zooms.
const ADS_SIGHT := Vector3(0.0, -0.008, -0.27)
const ADS_ZOOM := 0.72
const ADS_TIME := 0.16        # seconds to raise or lower

const KICK_BACK := 0.045      # metres the gun travels back per shot
const KICK_PITCH := 0.32      # radians the barrel climbs per shot
const KICK_RECOVER := 11.0    # how fast it settles (1/s)
const SWAY := 0.00006         # metres per pixel of mouse travel
const SWAY_MAX := 0.012
const BOB_RATE := 1.0 / PlayerFootsteps.STRIDE   # one dip per footfall
const BOB_AMP := 0.0035

var player: Player
var _pivot: Node3D
var _cam: Camera3D
var _ads_pos := Vector3.ZERO
var _ads_rot := Quaternion.IDENTITY
## 0 at the hip, 1 aimed.
var aim: float = 0.0
var _barrel := Vector3(0, 0, -1)    # unit, model space, pointing out of the muzzle
var _muzzle := MUZZLE               # model space; measured at setup
var _grip := GRIP
var _kick: float = 0.0
var _sway := Vector2.ZERO
var _stride: float = 0.0
var _flash: OmniLight3D
var _world_flash: OmniLight3D
var _flash_mesh: MeshInstance3D
var _flash_t: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player
	name = "Viewmodel"
	_cam = ViewmodelStage.build(player, self, STAGE, VM_FOV, LAYER)
	scale = Vector3.ONE * RIG_SCALE
	_pivot = Node3D.new()
	add_child(_pivot)
	var ps := load(MODEL) as PackedScene
	if ps != null:
		var model := ps.instantiate() as Node3D
		_pivot.add_child(model)
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).layers = LAYER
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Kenney's own colours stay on the gun (a black override read as a
			# flat cut-out, "lost its texture"). The arm wears a glove.
			if mi.name == "hand":
				(mi as MeshInstance3D).material_override = ViewmodelStage.glove()
	# The world's camera must never see the weapon layer: only the stage's does.
	player.camera.cull_mask &= ~LAYER
	_measure_barrel()
	_pivot.position = _grip
	_pivot.get_child(0).position = -_grip
	_muzzle_flash()
	_solve_ads()

## The aimed pose: the sight line down the camera's -Z, gun upright, rear
## sight at ADS_SIGHT. The rest pose needs no solving (see header).
func _solve_ads() -> void:
	var fwd := (SIGHT_FRONT - SIGHT_REAR).normalized()
	var b := Basis.looking_at(fwd, GUN_UP).inverse()
	_ads_rot = b.get_rotation_quaternion()
	_ads_pos = ADS_SIGHT - b * (SIGHT_REAR * RIG_SCALE)

## Principal axis of the suppressor's vertices (power iteration on their
## covariance), signed to point out of the muzzle — away from the gun body.
func _measure_barrel() -> void:
	var model := _pivot.get_child(0) as Node3D
	var can := model.find_child(BARREL_MESH, true, false) as MeshInstance3D
	var body := model.find_child("blaster-a", true, false) as MeshInstance3D
	if can == null or body == null:
		return
	var to_model := model.global_transform.affine_inverse()
	var pts := PackedVector3Array()
	for v in can.mesh.get_faces():
		pts.append(to_model * (can.global_transform * v))
	var c := Vector3.ZERO
	for v in pts:
		c += v
	c /= float(pts.size())
	var axis := Vector3(0, 0, -1)
	for it in 24:
		var next := Vector3.ZERO
		for v in pts:
			var d := v - c
			next += d * d.dot(axis)
		axis = next.normalized()
	var body_c := to_model * (body.global_transform * body.mesh.get_aabb().get_center())
	if axis.dot(c - body_c) < 0.0:
		axis = -axis
	var far := 0.0
	for v in pts:
		far = maxf(far, (v - c).dot(axis))
	_barrel = axis
	_muzzle = c + axis * far

func _muzzle_flash() -> void:
	_flash = OmniLight3D.new()
	_flash.position = _muzzle - _grip + _barrel * 0.02
	_flash.light_color = Color(1.0, 0.75, 0.4)
	_flash.light_energy = 0.0
	_flash.omni_range = 7.0
	_pivot.add_child(_flash)
	_flash_mesh = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.022, 0.022)
	_flash_mesh.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.8, 1.0))
	g.set_color(1, Color(1.0, 0.5, 0.1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mesh.material_override = m
	_flash_mesh.position = _flash.position
	_flash_mesh.layers = LAYER
	_flash_mesh.visible = false
	_pivot.add_child(_flash_mesh)
	# The stage is far from the level, so the flash also lights the real world:
	# a second light on the player's camera, brief, that touches only the level.
	_world_flash = OmniLight3D.new()
	_world_flash.position = Vector3(0.1, -0.05, -0.5)
	_world_flash.light_color = Color(1.0, 0.75, 0.4)
	_world_flash.light_energy = 0.0
	_world_flash.omni_range = 9.0
	_world_flash.light_cull_mask = ~LAYER
	player.camera.add_child(_world_flash)

## One shot. `suppressed` keeps the flash small, as a can would.
func fire(suppressed: bool) -> void:
	_kick = minf(1.6, _kick + 1.0)
	_flash_t = 0.05
	_flash.light_energy = 0.6 if suppressed else 2.5
	_world_flash.light_energy = 0.8 if suppressed else 2.5
	_flash_mesh.scale = Vector3.ONE * (0.6 if suppressed else 1.4)
	_flash_mesh.rotation.z = randf() * TAU
	_flash_mesh.visible = true

func add_look(relative: Vector2) -> void:
	_sway = (_sway - relative * SWAY).limit_length(SWAY_MAX)

func tick(delta: float) -> void:
	var want := 1.0 if Input.is_action_pressed("alt_attack") and player.alive else 0.0
	aim = move_toward(aim, want, delta / ADS_TIME)
	var t := aim * aim * (3.0 - 2.0 * aim)
	player.look.zoom = lerpf(1.0, ADS_ZOOM, t)
	var steady := 1.0 - 0.8 * t     # sway and bob mostly die down when aimed
	_kick = move_toward(_kick, 0.0, _kick * KICK_RECOVER * delta + delta * 0.5)
	_sway = _sway.lerp(Vector2.ZERO, minf(1.0, delta * 8.0))
	var v := player.velocity
	var flat := Vector2(v.x, v.z).length()
	if player.is_on_floor() and flat > 0.5 and bool(Settings.get_value("head_bob")):
		_stride += flat * delta
	# One full left-right sway per two footfalls; the dip lands on each step.
	var bob := Vector3(cos(_stride * BOB_RATE * PI) * BOB_AMP,
		-absf(sin(_stride * BOB_RATE * PI)) * BOB_AMP, 0.0) * steady
	var k := _kick * _kick
	position = _ads_pos * t + bob + Vector3(_sway.x, -_sway.y * 0.6, 0.0) * steady \
		+ Vector3(0, k * 0.004, k * KICK_BACK * 0.25 + _kick * KICK_BACK * 0.5)
	var rot := Quaternion.IDENTITY.slerp(_ads_rot, t)
	basis = Basis(rot * Quaternion(Vector3.UP, -_sway.x * 2.0 * steady)).scaled(Vector3.ONE * RIG_SCALE)
	_pivot.rotation = Vector3(_kick * KICK_PITCH, 0, -_kick * 0.08)
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash.light_energy = 0.0
			_world_flash.light_energy = 0.0
			_flash_mesh.visible = false

## Steps land on the stride, so footsteps and bob agree.
func stride() -> float:
	return _stride
