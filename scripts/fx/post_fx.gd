class_name PostFx
extends CanvasLayer
## The screen shader (assets/shaders/trip.gdshader) between the 3D world plus
## viewmodel (layers -1 and below) and the HUD (layer 1). Driven by
## Atmosphere: `alarm` eases in with the building alarm, `hurt` kicks when the
## player takes a hit. OPTIONS > TRIP FILTER switches it off.

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
	_rect.visible = bool(Settings.get_value("trip_fx"))
	_alarm = move_toward(_alarm, 1.0 if alarm_on else 0.0, delta * 1.5)
	_hurt = move_toward(_hurt, 0.0, delta * 2.0)
	_mat.set_shader_parameter("alarm", _alarm)
	_mat.set_shader_parameter("hurt", _hurt)
