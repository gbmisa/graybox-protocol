class_name ToolEat
extends Node
## Hold F over a corpse: eat it (Cruelty Squad's stomach implant). HEAL HP,
## once per body, EAT_TIME of chewing with blood in your face. This is the
## only way back up — there is still no regeneration (CLAUDE.md rule 7);
## health is something you take from the dead, loudly-ish, standing still.
## Gibbed bodies are too far gone. A door or switch under the crosshair wins.

const REACH := 2.2
const EAT_TIME := 2.0
const HEAL := 5.0     # r9: Gregory, "eating corpses should heal five"

var player: Player
var _corpse: Node3D
var _t: float = 0.0
var _chew: float = 0.0

func setup(p_player: Player) -> void:
	player = p_player

## After the interactor, so its prompt doesn't hide ours (Player order).
func post_move(delta: float) -> void:
	if player.interactor.has_target():
		_corpse = null
		return
	var c := _find()
	if c != _corpse:
		_corpse = c
		_t = 0.0
	if _corpse == null:
		return
	var full := player.health.hp >= player.health.max_hp
	if Input.is_action_pressed("interact") and not full:
		_t += delta
		_chew -= delta
		if _chew <= 0.0:
			_chew = 0.32
			AudioSynth.play(player.game, "eat", -2.0, randf_range(0.85, 1.15))
			player.game.emit_noise(player.global_position, 8.0)   # chewing is loud
			Gore.burst(_corpse.get_parent() as Node3D, _corpse.global_position + Vector3(0, 0.4, 0),
				player.global_position, 6)
			player.add_shake(0.08)
		if _t >= EAT_TIME:
			_finish()
			return
	else:
		_t = 0.0
	player.game.hud.show_prompt("HOLD F — EAT" if not full else "TOO FULL TO EAT",
		not full, _t / EAT_TIME)

func _finish() -> void:
	_corpse.set_meta("eaten", true)
	player.health.hp = minf(player.health.max_hp, player.health.hp + HEAL)
	AudioSynth.play(player.game, "gulp", 0.0)
	player.game.hud.show_message("+%d HP  (DISGUSTING)" % int(HEAL), 1.6)
	player.game.stats["eaten"] = int(player.game.stats.get("eaten", 0)) + 1
	_corpse = null
	_t = 0.0
	player.game.hud.hide_prompt()

func _find() -> Node3D:
	var best: Node3D = null
	var best_d := REACH
	var fwd := player.aim_dir()
	for n in player.get_tree().get_nodes_in_group("corpses"):
		var c := n as Node3D
		if c == null or c.has_meta("eaten") or c.has_meta("gibbed"):
			continue
		var to := c.global_position + Vector3(0, 0.3, 0) - player.camera.global_position
		var d := to.length()
		if d < best_d and fwd.dot(to.normalized()) > 0.6:
			best_d = d
			best = c
	return best
