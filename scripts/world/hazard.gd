class_name Hazard
extends Node3D
## A box that hurts the player per second while he stands in it — the
## undercroft's energised puddle. Damage goes through `player.take_damage`, so
## armour scales it and the Wizard's dash i-frames cancel it outright: that is
## the whole design of the puddle (a walk kills a 60 HP Wizard, a dash begun
## at its edge costs nothing).
##
## Applied in 0.1s ticks rather than every frame, so the hurt feedback reads
## as a buzz instead of sixty flashes a second.

const TICK := 0.1

var game: GrayboxGame
var box: AABB
var dps: float = 0.0

var _pending: float = 0.0
var _t: float = 0.0

static func create(p_game: GrayboxGame, parent: Node3D, p_box: AABB,
		p_dps: float) -> Hazard:
	var h := Hazard.new()
	h.game = p_game
	h.box = p_box
	h.dps = p_dps
	parent.add_child(h)
	return h

func _physics_process(delta: float) -> void:
	if game == null or not game.is_playing():
		return
	var p := game.get_player()
	if p == null or not p.alive:
		return
	if not box.has_point(p.global_position + Vector3(0, 0.1, 0)):
		_flush(p)
		return
	if not p.health.is_invulnerable():
		_pending += dps * delta
	_t += delta
	if _t >= TICK:
		_flush(p)

func _flush(p: Player) -> void:
	_t = 0.0
	if _pending > 0.0:
		var dmg := _pending
		_pending = 0.0
		p.take_damage(dmg)
