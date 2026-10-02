class_name Settings
extends RefCounted
## Player options, persisted to user://settings.cfg. The OPTIONS screen
## writes through `set_value`; gameplay reads the typed getters. Applying a
## change (volume, window mode, vsync) happens in `apply()` so it takes
## effect immediately, in the menu as well as in play.

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"master_volume": 0.8,     # 0..1, linear
	"sensitivity": 1.0,       # multiplier on AbilityData's mouse_sens
	"fov": 80.0,
	"invert_y": false,
	"fullscreen": false,
	"vsync": true,
	"room_tags": true,        # the cyan playtest room IDs
	"head_bob": true,
	"trip_fx": true,          # the screen shader (fx/post_fx.gd)
}

static var _cfg: ConfigFile = null

static func _load() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(PATH)   # a missing file just means defaults
	return _cfg

static func get_value(key: String) -> Variant:
	return _load().get_value("options", key, DEFAULTS.get(key))

static func set_value(key: String, value: Variant) -> void:
	_load().set_value("options", key, value)
	_cfg.save(PATH)
	apply()

static func sensitivity() -> float:
	return float(get_value("sensitivity"))

static func fov() -> float:
	return float(get_value("fov"))

static func invert_y() -> bool:
	return bool(get_value("invert_y"))

static func room_tags() -> bool:
	return bool(get_value("room_tags"))

## Push every option that lives outside the game's own nodes.
static func apply() -> void:
	var vol := clampf(float(get_value("master_volume")), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(0, vol <= 0.001)
	if DisplayServer.get_name() == "headless":
		return
	var full := bool(get_value("fullscreen"))
	var mode := DisplayServer.window_get_mode()
	if full and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not full and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED
		if bool(get_value("vsync")) else DisplayServer.VSYNC_DISABLED)
