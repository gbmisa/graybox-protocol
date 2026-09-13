class_name PlayerInteractor
extends Node
## Finds Interactables in front of the player and runs the channelled use.
##
## One key (interact) with three meanings: the verb is resolved from the
## operative's capability set, so the Regular picks the lock, the Wizard
## unwards it and Chad puts his boot through it — same door, same button.
##
## Also handles instant pickups (IntelPickup, KeyItem) with the same key —
## no channel, just press. While the intel reader is open the prompt stays
## hidden and a fresh press is required after the panel closes.

const TICK_SFX_INTERVAL := 0.35

var player: Player

var _target: Node3D = null
var _channel: float = 0.0
var _channel_time: float = 0.0
var _tick_accum: float = 0.0
## Set while the intel reader is open; cleared only after F is released, so
## the same press that closes the reader can never re-trigger the pickup.
var _need_release: bool = false

func setup(p_player: Player) -> void:
	player = p_player

func tick(delta: float) -> void:
	var hud := player.game.hud
	if hud.is_intel_open():
		hud.hide_prompt()
		_cancel()
		_target = null
		_need_release = true
		return
	if _need_release and not Input.is_action_pressed("interact"):
		_need_release = false
	var found := _probe()
	if found != _target:
		_cancel()
		_target = found
	if _target == null:
		hud.hide_prompt()
		return
	if _target is IntelPickup or _target is KeyItem:
		_run_pickup(_target)
		return
	_run_gate(_target as Interactable, delta, hud)

## Instant pickups: prompt while aimed, activate on a fresh press.
func _run_pickup(pickup: Node3D) -> void:
	var hud := player.game.hud
	hud.show_prompt(pickup.prompt_text(), true, 0.0)
	if _need_release:
		return
	if Input.is_action_just_pressed("interact"):
		pickup.activate(player)
		_target = null
		_need_release = true
		hud.hide_prompt()

func _run_gate(gate: Interactable, delta: float, hud: HUD) -> void:
	var prompt := gate.prompt_for(player)
	if prompt.is_empty():
		_cancel()
		_target = null
		hud.hide_prompt()
		return
	if bool(prompt.get("usable", false)):
		_run_channel(prompt, delta)
	else:
		_cancel()
	hud.show_prompt(
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
	var target := _target as Interactable
	_cancel()
	if target == null or target.is_open:
		return
	var method := target.method_for(player)
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

## The aim ray hits whatever solid is in front: a gate, an intel note, a key.
func _probe() -> Node3D:
	var reach := float(AbilityData.player()["interact_range"])
	var from := player.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + player.aim_dir() * reach)
	q.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var col := hit["collider"] as Node3D
	if col is Interactable and not (col as Interactable).is_open:
		return col
	if col is IntelPickup or col is KeyItem:
		return col
	return null
