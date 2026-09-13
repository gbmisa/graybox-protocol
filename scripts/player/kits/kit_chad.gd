extends KitBase
## GIGA CHAD — punch combo, ground slam, breaching, high mantle.
##
## The only operative who opens obstacles by destroying them, which means his
## route announces itself: every gate he goes through is the loudest noise
## event in the game. 250 HP is not a comfort margin, it is the budget for the
## fight that breaching starts.
##
## Verbs (data/verbs.gd): smash, mantle to 2.5m, and NO crawl — his crouched
## height is 1.45m, so the 1.0m crawl gaps are physically closed to him.

var punch_cd: float = 0.0
var slam_cd: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0

func tick(delta: float) -> void:
	punch_cd = maxf(0.0, punch_cd - delta)
	slam_cd = maxf(0.0, slam_cd - delta)
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	if Input.is_action_pressed("attack") and punch_cd <= 0.0:
		_punch()
	if Input.is_action_just_pressed("ability"):
		_slam()

func _punch() -> void:
	var a := AbilityData.get_ability("punch")
	punch_cd = float(a["cooldown"])
	combo = (combo % 3) + 1
	combo_timer = float(a["combo_window"])
	AudioSynth.play(player.game, "punch")
	player.game.emit_noise(player.global_position, float(a["noise"]))
	for t in _melee_targets(float(a["range"])):
		var dir: Vector3 = ((t as Node3D).global_position
			- player.global_position).normalized()
		_hit_entity(t, float(a["damage"]), float(a["noise"]),
			dir * float(a["knockback"]) + Vector3(0, float(a["knockup"]), 0))

func _slam() -> void:
	var a := AbilityData.get_ability("slam")
	if slam_cd > 0.0:
		return
	slam_cd = float(a["cooldown"])
	AudioSynth.play(player.game, "slam")
	player.game.emit_noise(player.global_position, float(a["noise"]))
	player.add_shake(float(a["shake"]))
	var radius := float(a["radius"])
	# Radial, not a cone — the slam is the answer to being surrounded.
	for g in player.game.guards.duplicate():
		var gd := g as Guard
		if gd == null or not gd.alive:
			continue
		var to: Vector3 = gd.global_position - player.global_position
		if to.length() <= radius:
			_hit_entity(gd, float(a["damage"]), float(a["noise"]),
				to.normalized() * float(a["knockback"])
				+ Vector3(0, float(a["knockup"]), 0))
	var t := player.game.target
	if t != null and t.alive \
			and t.global_position.distance_to(player.global_position) <= radius:
		_hit_entity(t, float(a["damage"]), 0.0, Vector3.ZERO)

func _hit_entity(entity: Node, dmg: float, noise: float, impulse: Vector3) -> void:
	if entity is Guard:
		var g := entity as Guard
		g.take_damage(dmg, player.global_position, noise)
		if impulse != Vector3.ZERO:
			g.apply_knockback(impulse)
	elif entity is Target:
		(entity as Target).take_damage(dmg, player.global_position)
	player.game.hud.show_hitmarker()
	AudioSynth.play(player.game, "hit")

func hud_lines() -> Array:
	var punch := "LMB: PUNCH%s" % _cd_text(punch_cd)
	if combo > 0:
		punch = "LMB: PUNCH  x%d" % combo
	return [
		punch,
		"E: GROUND SLAM%s" % _cd_text(slam_cd),
		"SPACE: CLIMB (2.5m)",
		"F: BREACH",
	]
