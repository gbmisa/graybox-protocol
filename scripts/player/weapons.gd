class_name PlayerWeapons
extends Node
## What the Regular carries and how each gun fires (stats: data/weapons.gd).
## Owned by his kit. 1-5 pick a slot, the wheel cycles, R reloads, LMB fires
## (held for automatics), RMB aims. Switching lowers the viewmodel, swaps the
## model and raises it; a reload dips it and the mag refills at the end.
##
## Damage goes through KitBase._damage_hit (headshots, hitmarker). On top:
## knockback along the shot, and an overkill past the weapon's `gib` blows the
## body apart (`Gore.gib`). Loud guns call emit_noise; the suppressed pistol
## stays silent, per the briefing's mod.

const SWITCH_TIME := 0.28

var player: Player
var kit: KitBase
var current: String = "pistol"
var ammo := {}           # id -> {"mag": int, "reserve": int}
var owned := {}          # id -> true; start with WeaponData "start" ones
var _cd: float = 0.0
var reload: WeaponReload    # reloading lives in weapon_reload.gd
var _switch_t: float = 0.0
var _pending: String = ""
var _trigger_held: bool = false

func setup(p_player: Player, p_kit: KitBase) -> void:
	player = p_player
	kit = p_kit
	for id in WeaponData.ORDER:
		var w := WeaponData.get_weapon(id)
		var start := bool(w.get("start", false))
		ammo[id] = {"mag": int(w["mag"]) if start else 0, "reserve": int(w["reserve"]) if start else 0}
		if start:
			owned[id] = true
	reload = WeaponReload.new(self)
	player.viewmodel = PlayerViewmodel.new()
	player.viewmodel.setup(player)
	_equip(current)

func weapon() -> Dictionary:
	return WeaponData.get_weapon(current)

func busy() -> bool:
	return reload.active() or _switch_t > 0.0

func reloading() -> bool:
	return reload.active()

func start_reload() -> void:
	reload.start()

func tick(delta: float) -> void:
	_cd = maxf(0.0, _cd - delta)
	_read_switch()
	if _switch_t > 0.0:
		_switch_t -= delta
		if _pending != "" and _switch_t <= SWITCH_TIME * 0.5:
			_equip(_pending)
			_pending = ""
		player.viewmodel.dip = absf(_switch_t / SWITCH_TIME * 2.0 - 1.0) * -1.0 + 1.0
		return
	if reload.active() and reload.tick(delta):
		return
	player.viewmodel.dip = 0.0
	if Input.is_action_just_pressed("reload"):
		start_reload()
		return
	var w := weapon()
	var pressed := Input.is_action_pressed("attack")
	var fire := pressed if bool(w["auto"]) else (pressed and not _trigger_held)
	_trigger_held = pressed
	if fire and _cd <= 0.0:
		_fire(w)

# ------------------------------------------------------------ switching ---
func _read_switch() -> void:
	for id in WeaponData.ORDER:
		var w := WeaponData.get_weapon(id)
		if Input.is_action_just_pressed("weapon_%d" % int(w["slot"])):
			select(id)
	if Input.is_action_just_pressed("weapon_next"):
		_cycle(1)
	elif Input.is_action_just_pressed("weapon_prev"):
		_cycle(-1)

func _cycle(step: int) -> void:
	var i := WeaponData.ORDER.find(_pending if _pending != "" else current)
	for n in WeaponData.ORDER.size():
		i = posmod(i + step, WeaponData.ORDER.size())
		var id: String = WeaponData.ORDER[i]
		if _has_any(id):
			select(id)
			return

func select(id: String) -> void:
	if id == current and _pending == "":
		return
	if not _has_any(id):
		AudioSynth.play(player.game, "dry", -6.0)
		return
	reload.cancel()
	_pending = id
	_switch_t = SWITCH_TIME
	AudioSynth.play(player.game, "holster", -8.0, randf_range(0.95, 1.05))

func _has_any(id: String) -> bool:
	if not owned.has(id):
		return false
	var a: Dictionary = ammo[id]
	return int(a["mag"]) + int(a["reserve"]) > 0 or id == "pistol"

## A found weapon: own it with a full mag and its starting reserve, or (if
## already carried) take that many rounds. True when it's new. `count` is
## how many of a throwable.
func give(id: String, count: int = 1) -> bool:
	var w := WeaponData.get_weapon(id)
	var a: Dictionary = ammo[id]
	var fresh := not owned.has(id)
	owned[id] = true
	if id == "grenade":
		# r9 ("I threw the first grenade and picked up five more ... it showed
		# zero out of four"): one in the hand, the rest on the belt.
		var total := int(a["mag"]) + int(a["reserve"]) + count
		a["mag"] = mini(1, total)
		a["reserve"] = total - int(a["mag"])
	elif fresh:
		a["mag"] = int(w["mag"])
		a["reserve"] = int(a["reserve"]) + int(w["reserve"])
	else:
		a["reserve"] = int(a["reserve"]) + int(w["mag"])
	if fresh and id != "grenade":
		select(id)
	return fresh

func _equip(id: String) -> void:
	current = id
	var w := weapon()
	player.viewmodel.set_model(String(w["model"]), WeaponData.zoom_for(w, Settings.fov()),
		float(w.get("scope", 0.0)) > 1.0)

## A dead guard's rounds — r9: only for what he carried (WeaponData.DROP).
## False when you carry none of the guns they're for (the box stays put).
func add_ammo(amounts: Dictionary) -> bool:
	var took := false
	for id in amounts:
		if ammo.has(id) and owned.has(id):
			ammo[id]["reserve"] = int(ammo[id]["reserve"]) + int(amounts[id])
			took = true
	var g: Dictionary = ammo["grenade"]
	if int(g["mag"]) == 0 and int(g["reserve"]) > 0:   # one straight into the hand
		g["mag"] = 1
		g["reserve"] = int(g["reserve"]) - 1
	return took

# ---------------------------------------------------------------- firing ---
func _fire(w: Dictionary) -> void:
	var a: Dictionary = ammo[current]
	if int(a["mag"]) <= 0:
		AudioSynth.play(player.game, "dry", -4.0)
		_cd = 0.25
		start_reload()
		return
	a["mag"] = int(a["mag"]) - 1
	_cd = float(w["rate"])
	if current == "grenade":
		_throw(w)
	else:
		_shoot(w)
	if int(a["mag"]) <= 0 and int(a["reserve"]) > 0:
		start_reload()
	elif int(a["mag"]) <= 0 and current == "grenade":
		_cycle(-1)

func _shoot(w: Dictionary) -> void:
	var noise := float(w["noise"])
	var dmg_mul := 1.0
	if current == "pistol":
		var mod := LoadoutData.get_mod(player.game.selected_mod)
		noise = float(mod["noise"])
		dmg_mul = float(mod["damage_mul"])
	var silent := noise <= 0.0
	var snd := "pistol" if current == "pistol" and silent else String(w["sound"])
	if current == "pistol" and not silent:
		snd = "pistol_loud"
	AudioSynth.play(player.game, snd, -8.0 if silent else 0.0, randf_range(0.95, 1.05))
	player.viewmodel.fire(silent, float(w["kick"]))
	player.look.add_recoil(float(w["recoil"]))
	if not silent:
		player.game.emit_noise(player.global_position, noise, bool(w.get("alerts", false)))
	var aim: float = player.viewmodel.aim
	var spread := lerpf(float(w["spread"]), float(w["ads_spread"]), aim)
	if player.movement.is_sprinting:
		spread *= 1.8
	var per_target := {}
	for i in int(w["pellets"]):
		var hit := kit._hitscan(float(w["range"]), spread)
		if hit.is_empty():
			continue
		Impact.at(player.game, hit, player.camera.global_position)
		var col := hit["collider"] as Node
		if col != null and (col.is_in_group("guards") or col.is_in_group("target")
				or col.is_in_group("civilians")):
			per_target[col] = float(per_target.get(col, 0.0)) + float(w["damage"]) * dmg_mul
			kit._damage_hit(hit, float(w["damage"]) * dmg_mul)
	for col in per_target:
		_after_hit(col as Node3D, float(per_target[col]), w)

## Knockback for the living; the overkill splatter for the dead.
func _after_hit(body: Node3D, dmg: float, w: Dictionary) -> void:
	var dir := (body.global_position - player.global_position)
	dir.y = 0.0
	dir = dir.normalized()
	var alive: bool = body.get("alive")
	# A real hit (per shot, all pellets summed) spoils an alerted guard's aim.
	if alive and dmg >= 15.0 and body is Guard and (body as Guard).state == Guard.State.ALERT:
		(body as Guard).combat.reset_cooldown(0.35)
	if alive and body.has_method("apply_knockback"):
		body.call("apply_knockback", dir * float(w["knockback"]))
	elif not alive and dmg >= float(w["gib"]):
		Gore.gib(body, player.global_position)

func _throw(w: Dictionary) -> void:
	AudioSynth.play(player.game, "throw", -4.0)
	player.viewmodel.fire(true, float(w["kick"]))
	var from := player.camera.global_position + player.aim_dir() * 0.5
	var vel := player.aim_dir() * float(w["throw_speed"]) + Vector3(0, 3.0, 0) \
		+ player.velocity * 0.5
	Grenade.throw(player.game, from, vel, w)
