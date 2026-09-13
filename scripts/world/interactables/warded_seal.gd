class_name WardedSeal
extends Interactable
## An arcane barrier — a hard gate for the Wizard.
##
## Nothing physical opens it: no lock to pick, nothing to hit. The Regular and
## Chad get a prompt telling them what it would take and no way to act on it.

const ARCANE_METHOD := {
	"arcane": {"time": 0.6, "noise": 8.0, "mana": 25.0},
}

var _pulse_t: float = 0.0

static func create(game: GrayboxGame, parent: Node3D, display: String,
		pos: Vector3, size: Vector3) -> WardedSeal:
	var s := WardedSeal.new()
	s.position = pos
	parent.add_child(s)
	s.setup(game, display, ARCANE_METHOD.duplicate(true), size,
		Color(0.28, 0.16, 0.42))
	s._make_glow()
	return s

## Seals read as energy, not matter: emissive and faintly translucent so you
## can see the route you cannot take.
func _make_glow() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.24, 0.78, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.62, 0.34, 1.0)
	mat.emission_energy_multiplier = 1.4
	mat.roughness = 0.2
	_mesh.material_override = mat

func _process(delta: float) -> void:
	if is_open:
		return
	_pulse_t += delta
	var mat := _mesh.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = 1.4 + sin(_pulse_t * 2.2) * 0.5

func _animate_open() -> void:
	_col.set_deferred("disabled", true)
	set_process(false)
	var accent := _mesh.get_meta("accent", null) as Node3D
	if accent != null:
		accent.visible = false
	var mat := _mesh.material_override as StandardMaterial3D
	var tw := create_tween()
	tw.set_parallel(true)
	# Flares bright, then dissipates.
	if mat != null:
		tw.tween_property(mat, "emission_energy_multiplier", 6.0, 0.15)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.12)
	tw.tween_property(_mesh, "scale", Vector3(1.0, 1.08, 1.0), 0.55)
