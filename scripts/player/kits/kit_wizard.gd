extends KitBase
## THE WIZARD — fireball, charged bolt, meteor, arcane dash.
##
## Sixty hit points and no cover on his route, so the kit is built around
## spending position rather than soaking damage. The dash replaces sprint
## entirely: it is short, frequent, and carries invulnerability frames, which
## makes reading an incoming shot the defence instead of running from it.
##
## Meteor is deliberately slow. The 1.1s telegraph means it cannot answer a
## guard already shooting at you — you place it, dash out, and let the ground
## do the work. That is what keeps it from simply outclassing the bolt.
##
## Verbs (data/verbs.gd): arcane, crawl at 0.85m.

var fire_cd: float = 0.0
var meteor_cd: float = 0.0
var dash_cd: float = 0.0
var charge: float = 0.0

func allows_sprint() -> bool:
	return false

func tick(delta: float) -> void:
	fire_cd = maxf(0.0, fire_cd - delta)
	meteor_cd = maxf(0.0, meteor_cd - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	_tick_fireball()
	_tick_bolt(delta)
	if Input.is_action_just_pressed("ability"):
		_cast_meteor()
	if Input.is_action_just_pressed("sprint"):
		_dash()

# ------------------------------------------------------------- fireball ---
func _tick_fireball() -> void:
	var a := AbilityData.get_ability("fireball")
	if not Input.is_action_pressed("attack") or fire_cd > 0.0:
		return
	if not player.spend_mana(float(a["mana"])):
		return
	fire_cd = float(a["cooldown"])
	var dir := player.aim_dir()
	var from := player.camera.global_position + dir * 0.8 + Vector3(0, -0.1, 0)
	var pr := Projectile.create(player.game, from, dir,
		float(a["speed"]), float(a["gravity"]), float(a["damage"]),
		float(a["aoe"]), Color(1.0, 0.45, 0.1), [player.get_rid()])
	player.game.add_child(pr)
	AudioSynth.play(player.game, "fireball")
	player.game.emit_noise(player.global_position, float(a["noise"]))

# ----------------------------------------------------------------- bolt ---
func _tick_bolt(delta: float) -> void:
	var a := AbilityData.get_ability("bolt")
	if Input.is_action_pressed("alt_attack"):
		charge = minf(1.0, charge + delta / float(a["charge_time"]))
	elif charge > 0.0:
		_release_bolt(a)
		charge = 0.0

func _release_bolt(a: Dictionary) -> void:
	if charge < float(a["min_charge"]):
		return
	if not player.spend_mana(float(a["mana"])):
		return
	AudioSynth.play(player.game, "bolt")
	player.game.emit_noise(player.global_position, float(a["noise"]))
	_damage_hit(_hitscan(float(a["range"])), float(a["damage"]))

# --------------------------------------------------------------- meteor ---
func _cast_meteor() -> void:
	var a := AbilityData.get_ability("meteor")
	if meteor_cd > 0.0:
		return
	var spot := _ground_target(float(a["cast_range"]))
	if spot == Vector3.INF:
		return
	if not player.spend_mana(float(a["mana"])):
		return
	meteor_cd = float(a["cooldown"])
	player.game.add_child(Meteor.create(player.game, spot, a))
	AudioSynth.play(player.game, "cast")

## Where the player is aiming, on the ground. Aiming at the sky drops the
## meteor straight down from the end of the aim ray instead of fizzling.
func _ground_target(max_range: float) -> Vector3:
	var from := player.camera.global_position
	var dir := player.aim_dir()
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * max_range)
	q.exclude = [player.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		return hit["position"]
	var endp := from + dir * max_range
	var down := PhysicsRayQueryParameters3D.create(endp, endp + Vector3(0, -60, 0))
	down.exclude = [player.get_rid()]
	var ghit := space.intersect_ray(down)
	return ghit["position"] if not ghit.is_empty() else Vector3.INF

# ----------------------------------------------------------------- dash ---
func _dash() -> void:
	var a := AbilityData.get_ability("dash")
	if dash_cd > 0.0:
		return
	if not player.spend_mana(float(a["mana"])):
		return
	dash_cd = float(a["cooldown"])
	player.movement_suspend = float(a["duration"])
	player.health.grant_iframes(float(a["iframes"]))
	var dir := _dash_dir()
	player.velocity = dir * float(a["speed"])
	player.velocity.y = 0.0
	AudioSynth.play(player.game, "dash")
	player.game.emit_noise(player.global_position, float(a["noise"]))

## Dashes where you are steering, or straight ahead when standing still.
func _dash_dir() -> Vector3:
	var f := Input.get_action_strength("move_forward") \
		- Input.get_action_strength("move_back")
	var s := Input.get_action_strength("move_right") \
		- Input.get_action_strength("move_left")
	var yaw := player.rotation.y
	var dir := Vector3(
		-sin(yaw) * f + cos(yaw) * s,
		0.0,
		-cos(yaw) * f - sin(yaw) * s)
	if dir.length() < 0.1:
		dir = -player.global_transform.basis.z
		dir.y = 0.0
	return dir.normalized()

# ------------------------------------------------------------------ hud ---
func hud_lines() -> Array:
	var bolt := "RMB: CHARGED BOLT"
	if charge > 0.0:
		bolt = "RMB: BOLT  %d%%" % int(charge * 100.0)
	return [
		"LMB: FIREBALL%s" % _cd_text(fire_cd),
		bolt,
		"E: METEOR%s" % _cd_text(meteor_cd),
		"SHIFT: DASH%s" % _cd_text(dash_cd),
		"F: ARCANE UNLOCK",
	]
