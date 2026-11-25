class_name PostFx
extends CanvasLayer
## The screen shader (assets/shaders/trip.gdshader) between the 3D world plus
## viewmodel (layers -1 and below) and the HUD (layer 1). Driven by
## Atmosphere: `alarm` eases in with the building alarm, `hurt` kicks when the
## player takes a hit; `trip` follows TripZone.level() — the nearer a trip
## zone, the more the frame breathes and doubles. OPTIONS > TRIP FILTER
## switches the filter off (the zones' faces and eyes stay).

const SHADER := "res://assets/shaders/trip.gdshader"

var _mat: ShaderMaterial
var _rect: ColorRect
var _alarm := 0.0
var _hurt := 0.0

func _ready() -> void:
	layer = 0
	name = "PostFx"
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER) as Shader
	_rect.material = _mat
	add_child(_rect)

func kick_hurt(amount: float) -> void:
	_hurt = minf(1.0, _hurt + amount)

func tick(delta: float, alarm_on: bool) -> void:
	# Night vision needs the shader even with the TRIP FILTER off (strength 0
	# keeps only the green).
	var fx_on := bool(Settings.get_value("trip_fx"))
	_rect.visible = fx_on or ToolNightVision.current > 0.0
	_mat.set_shader_parameter("strength", 1.0 if fx_on else 0.0)
	_alarm = move_toward(_alarm, 1.0 if alarm_on else 0.0, delta * 1.5)
	_hurt = move_toward(_hurt, 0.0, delta * 2.0)
	_mat.set_shader_parameter("alarm", _alarm)
	_mat.set_shader_parameter("hurt", _hurt)
	_mat.set_shader_parameter("trip", TripZone.level())
	_mat.set_shader_parameter("nv", ToolNightVision.current)
