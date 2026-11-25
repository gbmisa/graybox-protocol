class_name ToolNightVision
extends Node
## N: the night-vision implant. Green, grainy, and it brings PITCH rooms up
## out of the black: the screen shader amplifies and tints (PostFx `nv`), and
## an IR lamp on your head lights what's in front of you (only you see it —
## guards don't react to IR). Lit places blow out, so you'll want it off there.
##
## r9 ("night vision does nothing"): the shader's gain ran after the frame
## was banded, so true black stayed black, and PITCH rooms' probes zero the
## ambient. Now the gain reads the raw frame, the night's ambient is lifted
## (Atmosphere.NV_AMBIENT), PITCH probes get PROBE_LIFT, and the IR is real.

const IR_RANGE := 32.0
const IR_ENERGY := 5.0
const PROBE_LIFT := 0.45   # PITCH probe ambient energy at full strength

var player: Player
var on: bool = false
var level: float = 0.0
var _ir: SpotLight3D

func setup(p_player: Player) -> void:
	player = p_player
	_ir = SpotLight3D.new()
	_ir.light_color = Color(0.75, 1.0, 0.8)
	_ir.light_energy = 0.0
	_ir.spot_range = IR_RANGE
	_ir.spot_angle = 55.0
	_ir.spot_attenuation = 0.6
	_ir.shadow_enabled = false
	player.camera.add_child(_ir)

func tick(delta: float) -> void:
	if Input.is_action_just_pressed("night_vision"):
		on = not on
		AudioSynth.play(player.game, "nv_on" if on else "nv_off", -6.0)
	var was := level
	level = move_toward(level, 1.0 if on else 0.0, delta * 4.0)
	_ir.light_energy = IR_ENERGY * level
	ToolNightVision.current = level
	if level != was:
		for n in player.get_tree().get_nodes_in_group("pitch_probe"):
			(n as ReflectionProbe).ambient_color_energy = lerpf(LightTiers.PITCH_ENERGY, PROBE_LIFT, level)

## Read by PostFx each frame.
static var current: float = 0.0
