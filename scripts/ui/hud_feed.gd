class_name HudFeed
extends HudPanel
## The top-of-screen cluster: current objective, the detection meter, the
## killfeed, and transient centre messages.
##
## The detection meter shows the worst reading across all living guards, and
## pins to full while any of them is alerted — so it answers "am I about to
## be seen" and "has the building noticed" with one bar. Below it, the alarm
## meter shows the mission-wide consequence level: loud play fills it, quiet
## play bleeds it off, past half the alarm panels are marked, and a full
## meter sends a runner for the nearest panel.

const KILLFEED_LIFETIME := 4.0

var _objective: Label
var _eye: Label
var _detect_bar: ProgressBar
var _alarm_label: Label
var _alarm_bar: ProgressBar
var _killfeed: VBoxContainer
var _message: Label
var _message_timer: float = 0.0

func build(root: Control) -> void:
	_objective = make_label("ASSASSINATE THE TARGET", 20, GOLD,
		HORIZONTAL_ALIGNMENT_CENTER)
	_objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_objective.position.y = 18
	root.add_child(_objective)
	_build_detection(root)
	_killfeed = VBoxContainer.new()
	_killfeed.add_theme_constant_override("separation", 4)
	_killfeed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_killfeed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_killfeed.position = Vector2(-340, 18)
	ignore(_killfeed)
	root.add_child(_killfeed)
	_message = make_label("", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.position.y = 160
	_message.visible = false
	root.add_child(_message)

func _build_detection(root: Control) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.position.y = 52
	ignore(row)
	_eye = make_label("◉", 28)
	row.add_child(_eye)
	_detect_bar = make_bar(120, 8)
	_detect_bar.value = 0
	_detect_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_detect_bar)
	root.add_child(row)
	_build_alarm(root)

## Compact alarm meter under the detection row: same width, thinner, labelled.
func _build_alarm(root: Control) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.position.y = 70
	ignore(row)
	_alarm_label = make_label("ALARM", 11, DIM)
	_alarm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_alarm_label)
	_alarm_bar = make_bar(120, 6)
	_alarm_bar.value = 0
	_alarm_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_alarm_bar)
	root.add_child(row)

func tick(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_message.visible = false
	if not hud.is_live():
		return
	_update_detection()
	_update_alarm()

func _update_alarm() -> void:
	var d := hud.game.director as AlarmDirector
	if d == null:
		_alarm_bar.value = 0
		return
	_alarm_bar.value = d.alarm
	# Green -> amber -> red as it fills; solid red once lockdown has tripped.
	var t := d.alarm / 100.0
	var col := Color(0.3, 0.8, 0.3).lerp(Color(1.0, 0.25, 0.25), t)
	_alarm_bar.modulate = col
	_alarm_label.modulate = RED if d.lockdown else DIM
	_alarm_label.text = "LOCKDOWN" if d.lockdown else "ALARM"

func _update_detection() -> void:
	var worst := 0.0
	var alerted := false
	for g in hud.game.guards:
		var gd := g as Guard
		if gd == null or not gd.alive:
			continue
		worst = maxf(worst, gd.detect)
		if gd.state == Guard.State.ALERT:
			alerted = true
	_detect_bar.value = 100.0 if alerted else worst * 100.0
	_eye.modulate = RED if alerted else Color(0.7, 0.7, 0.7)

# ------------------------------------------------------------ public API ---
func set_objective(text: String) -> void:
	_objective.text = text

func show_message(text: String, dur: float) -> void:
	_message.text = text
	_message.visible = true
	_message_timer = dur

## Entries expire on their own timer. Safe while paused because the HUD runs
## with PROCESS_MODE_ALWAYS.
func add_killfeed(text: String) -> void:
	var l := make_label(text, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_killfeed.add_child(l)
	var tw := create_tween()
	tw.tween_interval(KILLFEED_LIFETIME)
	tw.tween_callback(l.queue_free)
