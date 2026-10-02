class_name Surfaces
extends RefCounted
## Surface materials: the graybox palette mapped onto CC0 photo textures
## (Poly Haven, see ASSETS.md). Every box in the game gets its material from
## `BuildUtils.mat(color)`, which lands here, so the whole level re-skins
## from this one table without any geometry changing.
##
## Textures are projected world-space triplanar, so boxes need no UVs and a
## brick course lines up across two boxes that meet. Saturated colours —
## signal paint, warning red, the van, the extensions' tints — stay flat;
## they are meant to read as paint, and a texture would mute them.

const TEX_DIR := "res://assets/textures/%s_%s.jpg"

## role colour (html) -> [texture id, metres per tile, tint]
static var _roles: Dictionary = {}
static var _cache: Dictionary = {}

## Off for tools that want the bare graybox (`-- --graybox`).
static var enabled: bool = not ("--graybox" in OS.get_cmdline_user_args())

static func _table() -> Dictionary:
	if _roles.is_empty():
		_roles = {
			BuildUtils.GROUND.to_html(): ["concrete_pavement", 3.0, Color(0.55, 0.56, 0.60)],
			BuildUtils.STREET.to_html(): ["asphalt_02", 4.0, Color(0.62, 0.62, 0.66)],
			BuildUtils.WALL.to_html(): ["brick_wall_02", 2.5, Color(0.80, 0.74, 0.72)],
			BuildUtils.WALL_DARK.to_html(): ["concrete_wall_008", 3.0, Color(0.55, 0.56, 0.62)],
			BuildUtils.FLOOR.to_html(): ["gen/terrazzo", 2.5, Color(0.86, 0.84, 0.84)],
			BuildUtils.WALLPAPER.to_html(): ["gen/wallpaper", 2.2, Color(0.92, 0.92, 0.88)],
			BuildUtils.CONCRETE.to_html(): ["concrete_wall_008", 3.0, Color(0.78, 0.78, 0.80)],
			BuildUtils.CRATE.to_html(): ["plywood", 1.5, Color(0.85, 0.72, 0.58)],
			BuildUtils.METAL.to_html(): ["metal_plate_02", 2.0, Color(0.70, 0.74, 0.82)],
			BuildUtils.PIPE.to_html(): ["corrugated_iron_02", 1.0, Color(0.42, 0.46, 0.52)],
		}
	return _roles

static func mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.roughness = 1.0
	m.albedo_color = color
	if enabled and color.a > 0.99:
		var role: Array = _table().get(key, [])
		if role.is_empty() and color.s < 0.45 and color.v > 0.08:
			# Any other muted colour: keep its hue, give it a concrete grain.
			role = ["concrete_wall_008", 3.0, color * 2.1]
		if not role.is_empty():
			_texture(m, String(role[0]), float(role[1]), role[2])
	_cache[key] = m
	return m

static func _texture(m: StandardMaterial3D, id: String, tile_m: float,
		tint: Color) -> void:
	# "gen/..." are our own (tools/gen/make_textures.py): PNG, no normal map.
	var gen := id.begins_with("gen/")
	var diff := load("res://assets/textures/%s.png" % id if gen else TEX_DIR % [id, "diff"]) as Texture2D
	if diff == null:
		return
	m.albedo_texture = diff
	m.albedo_color = Color(minf(tint.r, 1.0), minf(tint.g, 1.0), minf(tint.b, 1.0))
	var nor := null if gen else load(TEX_DIR % [id, "nor_gl"]) as Texture2D
	if nor != null:
		m.normal_enabled = true
		m.normal_texture = nor
		m.normal_scale = 0.8
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile_m
	m.uv1_triplanar_sharpness = 4.0
