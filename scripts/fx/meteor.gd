class_name Meteor
extends Node3D
## The Wizard's ground-targeted AoE. Three phases: a telegraphed marker with a
## falling rock, a detonation, then a burning pool that keeps ticking.
##
## The telegraph is generous by design. This is area denial and a repositioning
## tool — you place it, dash clear, and let guards walk into it — rather than a
## direct answer to someone already shooting at you.

const FALL_HEIGHT := 26.0

enum Phase { TELEGRAPH, BURN }

var game: GrayboxGame
var cfg: Dictionary = {}

var _phase: int = Phase.TELEGRAPH
var _elapsed: float = 0.0
var _tick_accum: float = 0.0
var _marker: MeshInstance3D
var _rock: MeshInstance3D
var _pool: MeshInstance3D

static func create(p_game: GrayboxGame, pos: Vector3, p_cfg: Dictionary) -> Meteor:
	var m := Meteor.new()
	m.game = p_game
	m.cfg = p_cfg
	m.position = pos + Vector3(0, 0.05, 0)
	return m

func _ready() -> void:
	_marker = _disc(float(cfg["aoe"]), Color(1.0, 0.25, 0.12, 0.30), 0.06)
	add_child(_marker)
	_rock = _sphere(0.7, Color(1.0, 0.55, 0.15))
	_rock.position = Vector3(0, FALL_HEIGHT, 0)
	add_child(_rock)

func _process(delta: float) -> void:
	_elapsed += delta
	match _phase:
		Phase.TELEGRAPH:
			_tick_telegraph(delta)
		Phase.BURN:
			_tick_burn(delta)

# ------------------------------------------------------------ telegraph ---
func _tick_telegraph(_delta: float) -> void:
	var dur := float(cfg["telegraph"])
	var t := clampf(_elapsed / dur, 0.0, 1.0)
	# Rock accelerates in; marker pulses faster as impact approaches.
	_rock.position.y = FALL_HEIGHT * (1.0 - t * t)
	var mat := _marker.material_override as StandardMaterial3D
	mat.albedo_color.a = 0.20 + absf(sin(_elapsed * (6.0 + t * 14.0))) * 0.35
	_marker.scale = Vector3.ONE * (1.0 + sin(_elapsed * 8.0) * 0.02)
	if _elapsed >= dur:
		_detonate()

func _detonate() -> void:
	_phase = Phase.BURN
	_elapsed = 0.0
	_rock.queue_free()
	_marker.queue_free()
	var pos := global_position
	var aoe := float(cfg["aoe"])
	for g in game.guards.duplicate():
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= aoe:
			gd.take_damage(float(cfg["damage"]), pos, float(cfg["noise"]))
			gd.apply_knockback(
				(gd.global_position - pos).normalized() * 8.0 + Vector3(0, 3.0, 0))
	if game.target != null and game.target.alive \
			and game.target.global_position.distance_to(pos) <= aoe:
		game.target.take_damage(float(cfg["damage"]), pos)
	game.emit_noise(pos, float(cfg["noise"]))
	game.shake_camera(0.5)
	AudioSynth.play(game, "explosion")
	_flash(aoe)
	_pool = _disc(float(cfg["burn_radius"]), Color(1.0, 0.42, 0.08, 0.45), 0.05)
	add_child(_pool)

## Expanding shell that fades out — reads the blast radius at a glance.
func _flash(radius: float) -> void:
	var s := _sphere(radius * 0.35, Color(1.0, 0.75, 0.3))
	add_child(s)
	var mat := s.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * 2.9, 0.35)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(s.queue_free)

# ----------------------------------------------------------------- burn ---
func _tick_burn(delta: float) -> void:
	var dur := float(cfg["burn_duration"])
	if _elapsed >= dur:
		queue_free()
		return
	var mat := _pool.material_override as StandardMaterial3D
	mat.albedo_color.a = (0.45 * (1.0 - _elapsed / dur)) \
		+ absf(sin(_elapsed * 9.0)) * 0.10
	_tick_accum += delta
	var interval := float(cfg["burn_tick"])
	if _tick_accum < interval:
		return
	_tick_accum = 0.0
	var dmg := float(cfg["burn_dps"]) * interval
	var radius := float(cfg["burn_radius"])
	var pos := global_position
	for g in game.guards.duplicate():
		var gd := g as Guard
		if gd != null and gd.alive and gd.global_position.distance_to(pos) <= radius:
			gd.take_damage(dmg, pos, float(cfg["noise"]))
	if game.target != null and game.target.alive \
			and game.target.global_position.distance_to(pos) <= radius:
		game.target.take_damage(dmg, pos)

# ----------------------------------------------------------------- mesh ---
func _disc(radius: float, color: Color, height: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = _emissive(color, true)
	return mi

func _sphere(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = _emissive(color, false)
	return mi

func _emissive(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
