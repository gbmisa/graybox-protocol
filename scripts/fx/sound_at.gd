class_name SoundAt
extends RefCounted
## A 3D one-shot at a point in the level rather than on a node (a bullet
## impact, a blast): an anchor that frees itself when the sound ends.

static func play(game: GrayboxGame, pos: Vector3, sfx_name: String, vol_db: float = 0.0,
		pitch: float = 1.0, reach: float = 60.0) -> void:
	if game == null or game.level_root == null:
		return
	var anchor := Node3D.new()
	game.level_root.add_child(anchor)
	anchor.global_position = pos
	AudioSynth.play_at(anchor, sfx_name, vol_db, pitch, reach)
	anchor.get_tree().create_timer(4.0).timeout.connect(anchor.queue_free)
