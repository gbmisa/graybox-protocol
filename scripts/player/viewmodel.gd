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
## HUD: a 55 degree lens keeps the gun's perspective sane (the world's 80
## stretches it into a diagonal), and it can never poke into a wall.
## The stage sits far from the level (STAGE) so no level lamp lights it; it has
## its own fill light, and the world's ambient (so it darkens in a PITCH room).
##
## The models are exported from art/viewmodel.blend (its export_viewmodel.py
## text block), eye at the origin. Empties in the file, read at setup: `gun`
## (barrel forward, up), `grip` (kick pivot), `muzzle`, `sight_rear` /
## `sight_front` (the aimed line) — reshape in Blender, move them, re-export.
## The rest pose is exactly what the file's EYE camera shows (55 degrees =
## VM_FOV); nothing re-poses it at runtime (r8, "the hand is facing the
## wrong direction").
##
## AIM DOWN SIGHTS (alt_attack, right mouse): the rig swings so the sight line
## (sight_rear -> sight_front) runs down the screen's centre and the world
## camera zooms; a scoped gun (r9) hides once raised and HudScope draws the
## eyepiece. Shots are hitscan from the player's camera either way.
##
## r8: one model per weapon, swapped by set_model; `dip` (0..1, from
## PlayerWeapons) lowers and tips the rig for a switch or a reload.
const LAYER := 1 << 19
const STAGE := Vector3(0, 4000, 0)
const VM_FOV := 55.0
const RIG_SCALE := 1.6
## Aimed: where the rear sight sits in the viewmodel camera's view, just under
## the crosshair, and how far the world camera zooms.
const ADS_SIGHT := Vector3(0.0, -0.008, -0.27)
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
## 0 up, 1 fully lowered (switching / reloading).
var dip: float = 0.0
var _dip: float = 0.0
var _zoom: float = 0.72
var _scope := false
var _model_path := ""
var _model: Node3D
var _scenes := {}   # per rig; a static cache crashed the engine at exit
## All in the model's own space, read from its empties at setup.
var _barrel := Vector3(0, 0, -1)    # unit, pointing out of the muzzle
var _gun_up := Vector3.UP
var _muzzle := Vector3.ZERO
var _grip := Vector3.ZERO
var _sight_rear := Vector3.ZERO
var _sight_front := Vector3(0, 0, -1)
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
	# The world's camera must never see the weapon layer: only the stage's does.
	player.camera.cull_mask &= ~LAYER
	_muzzle_flash()

## Swaps in a weapon's model (cached) and re-reads its empties.
func set_model(path: String, zoom: float, scope: bool = false) -> void:
	_zoom = zoom
	_scope = scope
	if path == _model_path:
		return
	_model_path = path
	if _model != null:
		_pivot.remove_child(_model)
		_model.queue_free()
		_model = null
	if not _scenes.has(path):
		_scenes[path] = load(path) if ResourceLoader.exists(path) else null
	var ps := _scenes[path] as PackedScene
	if ps == null:
		push_error("viewmodel: missing %s" % path)
		return
	var model := ps.instantiate() as Node3D
	_model = model
	_pivot.add_child(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = LAYER
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.position = Vector3.ZERO
	_pivot.quaternion = Quaternion.IDENTITY
	model.position = Vector3.ZERO
	_read_markers()
	_pivot.position = _grip
	model.position = -_grip
	_flash.position = _muzzle - _grip + _barrel * 0.02
	_flash_mesh.position = _flash.position
	_solve_ads()

## The aimed pose: the sight line down the camera's -Z, gun upright, rear
## sight at ADS_SIGHT. The rest pose is the file's own (see header).
func _solve_ads() -> void:
	var fwd := (_sight_front - _sight_rear).normalized()
	var b := Basis.looking_at(fwd, _gun_up).inverse()
	_ads_rot = b.get_rotation_quaternion()
	_ads_pos = ADS_SIGHT - b * (_sight_rear * RIG_SCALE)

## The gun's empties (see header), brought into the model's space.
func _read_markers() -> void:
	var model := _model
	var to_model := model.global_transform.affine_inverse()
	var at := func(n: String) -> Vector3:
		var e := _marker(model, n)
		if e == null:
			push_error("viewmodel: no '%s' empty in %s" % [n, _model_path])
			return Vector3.ZERO
		return to_model * e.global_position
	_grip = at.call("grip")
	_muzzle = at.call("muzzle")
	_sight_rear = at.call("sight_rear")
	_sight_front = at.call("sight_front")
	var gun := _marker(model, "gun")
	if gun != null:
		var gb := (to_model.basis * gun.global_transform.basis).orthonormalized()
		_barrel = -gb.z    # Blender's +Y, the barrel
		_gun_up = gb.y

## An empty by name; Blender suffixes repeats (grip.001 -> grip_001), so a
## name plus a numeric suffix counts too.
static func _marker(model: Node, n: String) -> Node3D:
	var exact := model.find_child(n, true, false) as Node3D
	if exact != null:
		return exact
	var re := RegEx.create_from_string("^%s[._]\\d+$" % n)
	for c in model.find_children("*", "Node3D", true, false):
		if re.search(String(c.name)) != null:
			return c as Node3D
	return null

func _muzzle_flash() -> void:
	_flash = OmniLight3D.new()
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

## One shot. `suppressed` keeps the flash small, as a can would; `kick` is
## the weapon's own (WeaponData).
func fire(suppressed: bool, kick: float = 1.0) -> void:
	_kick = minf(1.6, _kick + kick)
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
	player.look.zoom = lerpf(1.0, _zoom, t)
	visible = not scoped()
	_dip = lerpf(_dip, dip, minf(1.0, delta * 18.0))
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
	position = _ads_pos * t + bob + Vector3(0.02, -0.14, 0.04) * _dip + Vector3(_sway.x, -_sway.y * 0.6, 0.0) * steady \
		+ Vector3(0, k * 0.004, k * KICK_BACK * 0.25 + _kick * KICK_BACK * 0.5)
	var rot := Quaternion.IDENTITY.slerp(_ads_rot, t)
	basis = Basis(rot * Quaternion(Vector3.UP, -_sway.x * 2.0 * steady)).scaled(Vector3.ONE * RIG_SCALE)
	# Kick about the grip, on the gun's own axes.
	var kick := Quaternion.from_euler(Vector3(_kick * KICK_PITCH, 0, -_kick * 0.08))
	_pivot.quaternion = kick * Quaternion(Vector3.RIGHT, -0.9 * _dip)
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash.light_energy = 0.0
			_world_flash.light_energy = 0.0
			_flash_mesh.visible = false

func scoped() -> bool:
	return _scope and aim > 0.85

## Steps land on the stride, so footsteps and bob agree.
func stride() -> float:
	return _stride
