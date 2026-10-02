class_name RemoteDoor
extends Interactable
## A door nobody opens by hand. The compound gate (opened by the gatehouse
## lever) and the CSD pair (open until ALARM, then locked for good) are both
## this: no verbs, so every operative gets the same answer — it is locked,
## and something else in the level decides when it isn't.

static func create(game: GrayboxGame, parent: Node3D, display: String,
		pos: Vector3, size: Vector3, start_open: bool) -> RemoteDoor:
	var d := RemoteDoor.new()
	d.position = pos
	parent.add_child(d)
	d.setup(game, display, {}, size, Color(0.36, 0.38, 0.30))
	if start_open:
		d._set_open(true, false)
	return d

func prompt_for(_player: Player) -> Dictionary:
	if is_open:
		return {}
	return {"text": "%s — LOCKED" % display_name, "usable": false}

func release() -> void:
	if not is_open:
		open(self)

func lock() -> void:
	if is_open:
		_set_open(false, true)
		AudioSynth.play(game, "smash", -10.0)

func _animate_open() -> void:
	_set_open(true, true)

func _set_open(value: bool, animate: bool) -> void:
	is_open = value
	_col.set_deferred("disabled", value)
	if animate:
		GuardNav.request_rebake()
	var y := -_size.y - 0.1 if value else 0.0
	if not animate:
		_mesh.position.y = y
		return
	var tw := create_tween()
	tw.tween_property(_mesh, "position:y", y, 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
