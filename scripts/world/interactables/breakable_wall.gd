class_name BreakableWall
extends Interactable
## Masonry that only brute force gets through — a hard gate for Chad.
##
## Slower and louder than kicking a door: this is the loudest thing in the
## game and it is meant to commit you to a fight.

const SMASH_METHOD := {
	"smash": {"time": 0.8, "noise": 60.0, "mana": 0.0},
}

static func create(game: GrayboxGame, parent: Node3D, display: String,
		pos: Vector3, size: Vector3) -> BreakableWall:
	var w := BreakableWall.new()
	w.position = pos
	parent.add_child(w)
	w.setup(game, display, SMASH_METHOD.duplicate(true), size,
		Color(0.40, 0.34, 0.30))
	return w

## Collapses rather than sliding: the wall drops, shrinks and fades out,
## leaving the opening clear.
func _animate_open() -> void:
	_col.set_deferred("disabled", true)
	if game != null:
		game.shake_camera(0.35)
	var mat := _mesh.material_override as StandardMaterial3D
	if mat != null:
		mat = mat.duplicate() as StandardMaterial3D
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mesh.material_override = mat
	var accent := _mesh.get_meta("accent", null) as Node3D
	if accent != null:
		accent.visible = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_mesh, "scale", Vector3(1.0, 0.05, 1.0), 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_mesh, "position",
		_mesh.position + Vector3(0, -_size.y * 0.5, 0), 0.5)
	if mat != null:
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.15)
