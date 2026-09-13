class_name PlayerInteractor
extends Node
## Finds Interactables in front of the player and runs the channelled use.
##
## One key (interact) with three meanings: the verb is resolved from the
## operative's capability set, so the Regular picks the lock, the Wizard
## unwards it and Chad puts his boot through it — same door, same button.

const TICK_SFX_INTERVAL := 0.35

var player: Player

var _target: Interactable = null
var _channel: float = 0.0
var _channel_time: float = 0.0
var _tick_accum: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player

func tick(delta: float) -> void:
	var found := _probe()
	if found != _target:
		_cancel()
		_target = found
	if _target == null:
		player.game.hud.hide_prompt()
		return
	var prompt := _target.prompt_for(player)
	if prompt.is_empty():
		_cancel()
		_target = null
		player.game.hud.hide_prompt()
		return
	if bool(prompt.get("usable", false)):
		_run_channel(prompt, delta)
	else:
		_cancel()
	player.game.hud.show_prompt(
		String(prompt["text"]),
		bool(prompt.get("usable", false)),
		_progress())

func _run_channel(prompt: Dictionary, delta: float) -> void:
	if not Input.is_action_pressed("interact"):
		_cancel()
		return
	_channel_time = float(prompt.get("time", 1.0))
	_channel += delta
	_channel_sfx(String(prompt.get("verb", "")), delta)
	if _channel >= _channel_time:
		_complete(prompt)

func _complete(prompt: Dictionary) -> void:
	var target := _target
	_cancel()
	if target == null or target.is_open:
		return
	var method := target.method_for(player.char_id)
	var cost := float(method.get("mana", 0.0))
	# Re-check at completion: mana can drain mid-channel.
	if cost > 0.0 and not player.spend_mana(cost):
		return
	target.open(player)
	player.game.hud.add_killfeed("%s opened" % target.display_name)

## Lockpicking clicks away audibly; breaching and unwarding are single events
## handled by the Interactable itself.
func _channel_sfx(verb: String, delta: float) -> void:
	if verb != "lockpick":
		return
	_tick_accum += delta
	if _tick_accum >= TICK_SFX_INTERVAL:
		_tick_accum = 0.0
		AudioSynth.play(player.game, "pick", -8.0)

func _cancel() -> void:
	_channel = 0.0
	_tick_accum = 0.0

func _progress() -> float:
	if _channel_time <= 0.0:
		return 0.0
	return clampf(_channel / _channel_time, 0.0, 1.0)

## Interactables are solid bodies, so the aim ray finds them directly.
func _probe() -> Interactable:
	var reach := float(AbilityData.player()["interact_range"])
	var from := player.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + player.aim_dir() * reach)
	q.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var col := hit["collider"] as Node
	if col is Interactable and not (col as Interactable).is_open:
		return col as Interactable
	return null
