class_name KitBase
extends Node
## Shared plumbing for character kits: aiming, damage application and the
## HUD contract. Each operative's whole moveset lives in one subclass, so
## "change the Wizard" means opening exactly one file.

var player: Player

func setup(p_player: Player) -> void:
	player = p_player
	_on_setup()

## Subclass hook for kit-specific initialisation.
func _on_setup() -> void:
	pass

## Called every physics frame while the player can act. Subclasses tick their
## own cooldowns and read their own inputs.
func tick(_delta: float) -> void:
	pass

## The Wizard returns false — his Shift is the dash, not a sprint.
func allows_sprint() -> bool:
	return true

## Lines the HUD renders bottom-right, already formatted with live cooldowns.
## Keeping the text here means the HUD never branches on character.
func hud_lines() -> Array:
	return []

# --------------------------------------------------------------- helpers ---
func _hitscan(max_dist: float, spread_rad: float = 0.0) -> Dictionary:
	var from := player.camera.global_position
	var dir := player.aim_dir()
	if spread_rad > 0.0:
		var axis := dir.cross(Vector3.UP)
		if axis.length() < 0.01:
			axis = dir.cross(Vector3.RIGHT)
		dir = dir.rotated(axis.normalized(), randf_range(0.0, spread_rad))
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * max_dist)
	q.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(q)

## `noise` is the noise radius of the damaging ability; a guard killed by a
## loud blow counts as a loud kill for the alarm (see ConsequenceData).
func _damage_hit(hit: Dictionary, dmg: float, noise: float = 0.0) -> void:
	if hit.is_empty():
		return
	var col := hit["collider"] as Node
	if col == null:
		return
	if col.is_in_group("guards"):
		var g := col as Guard
		var hurt := dmg
		if g.is_head_shape(int(hit.get("shape", -1))):
			hurt = dmg * Guard.HEADSHOT_MULT
		g.take_damage(hurt, player.global_position, noise)
	elif col.is_in_group("target"):
		(col as Target).take_damage(dmg, player.global_position)
	else:
		return
	player.game.hud.show_hitmarker()
	AudioSynth.play(player.game, "hit")

## Everything hostile within `max_dist` inside a forward cone.
func _melee_targets(max_dist: float, cone: float = 0.4) -> Array:
	var out: Array = []
	var fwd := -player.global_transform.basis.z
	for g in player.game.guards:
		var gd := g as Guard
		if gd == null or not gd.alive:
			continue
		var to: Vector3 = gd.global_position - player.global_position
		if to.length() <= max_dist and fwd.dot(to.normalized()) > cone:
			out.append(gd)
	var t := player.game.target
	if t != null and t.alive:
		var to2: Vector3 = t.global_position - player.global_position
		if to2.length() <= max_dist and fwd.dot(to2.normalized()) > cone:
			out.append(t)
	return out

func _cd_text(cd: float) -> String:
	return "" if cd <= 0.0 else "  %.1fs" % cd
