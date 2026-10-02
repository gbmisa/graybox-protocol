class_name Atmosphere
extends Node
## What the level looks and sounds like right now, driven by two things:
##
##  * the light tier you stand in (PITCH / DARK / LIT, D11). Guards already
##    scale their detection by it; this makes it visible — ambient light
##    drops with the tier, so a DARK courtyard corner and a LIT canteen
##    actually look different, with no HUD gauge (D11 forbids one). Lamps
##    still light their own pools, so a lamp in a PITCH room is a choice
##    someone made. The change is eased, never a cut.
##  * the building ALARM: the sirens wailing (3D, from where they hang), the
##    ambient light pulsing red, and a banner on the HUD. Previously the alarm locked doors and sent
##    reinforcements and the player never knew it had happened.
##
## Works on the level's WorldEnvironment, whichever level that is: it scales
## whatever ambient energy the level set, so MERIDIAN (no tiers, all LIT) is
## untouched.

## Fraction of the level's own ambient light kept in each tier.
const TIER_AMBIENT := {"LIT": 1.0, "DARK": 0.28, "PITCH": 0.05}
const EASE := 2.5
const PULSE_HZ := 1.1
const ALARM_RED := Color(1.0, 0.08, 0.05)

var game: GrayboxGame
var _env: Environment
var _base_color: Color
var _base_energy: float = 0.5
var _factor: float = 1.0
var _alarm: bool = false
var _t: float = 0.0
var _post: PostFx
var _last_hp: float = -1.0

func setup(p_game: GrayboxGame) -> void:
	game = p_game
	if _post == null:
		_post = PostFx.new()
		add_child(_post)
	_last_hp = -1.0
	_alarm = false
	_factor = 1.0
	_env = null
	var root := game.level_root
	if root == null:
		return
	for we in root.find_children("*", "WorldEnvironment", true, false):
		_env = (we as WorldEnvironment).environment
		break
	if _env != null:
		_base_color = _env.ambient_light_color
		_base_energy = _env.ambient_light_energy

## The level is going away; forget its environment.
func clear() -> void:
	set_alarm(false)
	_env = null

func set_alarm(on: bool) -> void:
	if on == _alarm:
		return
	_alarm = on
	# The wail comes from the sirens mounted round the level (AlarmSiren),
	# not from the player's own head.
	get_tree().call_group("siren", "activate", on)
	if not on and _env != null:
		_env.ambient_light_color = _base_color

func _process(delta: float) -> void:
	if _post != null:
		_post.tick(delta, _alarm)
	if _env == null or game == null:
		return
	var p := game.get_player()
	if p != null and p.health != null:
		if _last_hp >= 0.0 and p.health.hp < _last_hp and _post != null:
			_post.kick_hurt(clampf((_last_hp - p.health.hp) / 30.0, 0.3, 1.0))
		_last_hp = p.health.hp
	if p != null and game.is_playing():
		var tier := game.tier_at(p.global_position + Vector3(0, 1.0, 0))
		var want := float(TIER_AMBIENT.get(tier, 1.0))
		_factor = lerpf(_factor, want, minf(1.0, delta * EASE))
	_env.ambient_light_energy = _base_energy * _factor
	if _alarm:
		_t += delta
		var pulse := 0.5 + 0.5 * sin(_t * TAU * PULSE_HZ)
		_env.ambient_light_color = _base_color.lerp(ALARM_RED, pulse * 0.85)
		# Never let a PITCH room swallow the pulse: the alarm is for everyone.
		_env.ambient_light_energy = maxf(_env.ambient_light_energy,
			_base_energy * 0.55 * pulse)
