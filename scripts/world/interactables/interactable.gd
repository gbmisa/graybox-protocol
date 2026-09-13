class_name Interactable
extends StaticBody3D
## Base class for every obstacle opened with the interact key.
##
## An Interactable is solid geometry that the player's forward raycast can hit
## directly, so no trigger volumes or proximity bookkeeping are needed. It
## declares which verbs open it and what each one costs:
##
##     open_methods = {
##         "lockpick": {"time": 3.0, "noise":  0.0, "mana":  0.0},
##         "smash":    {"time": 0.4, "noise": 45.0, "mana":  0.0},
##     }
##
## Hard gates are authored by omission — a wall with only a "smash" entry is
## Chad-only, and everyone else gets a prompt naming what it would take.

signal opened(opener: Node)

const ACCENT_COLORS := {
	"lockpick": Color(0.35, 0.70, 1.00),
	"arcane": Color(0.72, 0.40, 1.00),
	"smash": Color(1.00, 0.52, 0.18),
}

var game: GrayboxGame
var display_name: String = "DOOR"
var open_methods: Dictionary = {}
var is_open: bool = false
## How far the panel travels when it opens. Defaults to sinking into the floor.
var open_offset: Vector3 = Vector3.ZERO

var _mesh: MeshInstance3D
var _col: CollisionShape3D
var _size: Vector3

func setup(p_game: GrayboxGame, p_name: String, p_methods: Dictionary,
		size: Vector3, color: Color) -> void:
	game = p_game
	display_name = p_name
	open_methods = p_methods
	_size = size
	add_to_group("interactable")
	_build_body(size, color)
	_build_accent(size)
	if open_offset == Vector3.ZERO:
		open_offset = Vector3(0, -size.y - 0.1, 0)

func _build_body(size: Vector3, color: Color) -> void:
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	_mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	_mesh.material_override = mat
	add_child(_mesh)
	_col = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	_col.shape = shape
	add_child(_col)

## A glowing stripe tinted by the primary verb, so the graybox reads at a
## glance: blue = pickable, purple = warded, orange = breachable.
func _build_accent(size: Vector3) -> void:
	var verb := primary_verb()
	if verb == "":
		return
	var accent: Color = ACCENT_COLORS.get(verb, Color.WHITE)
	var thin := MeshInstance3D.new()
	var bm := BoxMesh.new()
	# Stripe runs across the smallest face, slightly proud of the surface.
	bm.size = Vector3(minf(size.x, 0.12) if size.x < size.z else size.x * 0.6,
		0.16, minf(size.z, 0.12) if size.z <= size.x else size.z * 0.6)
	thin.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent
	mat.emission_enabled = true
	mat.emission = accent
	mat.emission_energy_multiplier = 2.0
	thin.material_override = mat
	thin.position = Vector3(0, size.y * 0.15, 0)
	add_child(thin)
	_mesh.set_meta("accent", thin)

## The verb this obstacle leads with, used for the accent color.
func primary_verb() -> String:
	for v in ["smash", "arcane", "lockpick"]:
		if open_methods.has(v):
			return v
	return ""

## The method this operative would use, or {} if they have no way through.
func method_for(char_id: String) -> Dictionary:
	for verb in open_methods.keys():
		if VerbData.has_verb(char_id, verb):
			var m: Dictionary = open_methods[verb].duplicate()
			m["verb"] = verb
			return m
	return {}

## What the HUD should draw. `usable` false means show it greyed.
func prompt_for(player: Player) -> Dictionary:
	if is_open:
		return {}
	var m := method_for(player.char_id)
	if m.is_empty():
		var needs: Array = []
		for verb in open_methods.keys():
			needs.append(VerbData.verb_owner(verb))
		return {
			"text": "%s — REQUIRES %s" % [display_name, " OR ".join(needs)],
			"usable": false,
		}
	var mana := float(m.get("mana", 0.0))
	if mana > 0.0 and player.mana < mana:
		return {
			"text": "%s — NEED %d MANA" % [display_name, int(mana)],
			"usable": false,
		}
	return {
		"text": "%s  %s" % [VerbData.verb_label(m["verb"]), display_name],
		"usable": true,
		"time": float(m.get("time", 1.0)),
		"verb": m["verb"],
	}

## Called by the interactor once the channel completes.
func open(opener: Node) -> void:
	if is_open:
		return
	is_open = true
	var m: Dictionary = {}
	if opener is Player:
		m = method_for((opener as Player).char_id)
	var noise := float(m.get("noise", 0.0))
	if noise > 0.0 and game != null:
		game.emit_noise(global_position, noise)
	_play_open_sfx(String(m.get("verb", "")))
	_animate_open()
	opened.emit(opener)

func _play_open_sfx(verb: String) -> void:
	match verb:
		"smash": AudioSynth.play(game, "smash")
		"arcane": AudioSynth.play(game, "arcane")
		_: AudioSynth.play(game, "unlock")

## Subclasses override to change how the obstacle gets out of the way.
func _animate_open() -> void:
	_col.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(_mesh, "position", _mesh.position + open_offset, 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
