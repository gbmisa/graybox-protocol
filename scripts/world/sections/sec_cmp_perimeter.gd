class_name SecCmpPerimeter
extends RefCounted
## The shell: streets, the compound wall, the gatehouse, and the Regular's
## exit-only outfall. Built first so the other sections cut into shared ground.
##
## Compound wall x [-28, 28], z [-24, 24], height 4.0, thickness 0.8 — the
## numbers here are the wall's *inner* faces; the wall itself hangs 0.8m
## outward, so the outer face is x/z ± 0.4 past those figures, which is
## exactly where the streets outside it begin (e.g. west alley starts at
## x = -28.8). One opening is left for `MissionCompound`: the north GATE at
## x [-3, 3], opened by the gatehouse lever. The gatehouse door, the bin-store
## gate on the east lane and the culvert outfall are plain openings. (Chad's
## cracked wall at x [20, 24] is sealed while level one is Regular-only.)
##
## Streets: south road z [32, 46]; verge z [24.8, 32]; avenue z [-40, -24.8]
## (north approach, gatehouse cut into it); east lane x [28.8, 36]; west
## alley x [-40, -28.8], dipping to the outfall pit at y -2.2 over z [4, 12].
## The gym's own east wall (z [-20, 8]) is left to `sec_cmp_gym` — it is the
## same wall carrying the roller-shutter tunnel.

const WALL_H := 4.0
const WALL_T := 0.8
const BOUND_H := 6.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_environment(root)
	_streets(root)
	_boundary(root)
	_compound_wall(root)
	_gatehouse(root)
	_west_alley(root)

static func _environment(root: Node3D) -> void:
	var we := WorldEnvironment.new()
	we.environment = night()
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color(0.70, 0.78, 1.0)
	sun.light_energy = 0.3
	sun.shadow_enabled = true
	root.add_child(sun)

## The night (r6 look): a shader sky (assets/shaders/sky.gdshader), filmic
## tonemap, bloom so signs and neon bleed, SSAO in the corners, and a
## volumetric haze the lamps cut shafts through. Low ambient so the three
## light tiers still read by eye; Atmosphere scales it by tier.
static func night() -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/sky.gdshader") as Shader
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.40, 0.62)
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_strength = 1.1
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for i in [2, 3, 4, 5]:
		env.set_glow_level(i, true)
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.04, 0.09)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.35
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0045
	env.volumetric_fog_albedo = Color(0.55, 0.52, 0.7)
	env.volumetric_fog_emission = Color(0.006, 0.002, 0.01)
	env.volumetric_fog_emission_energy = 1.0
	env.volumetric_fog_length = 80.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.2
	return env

static func _streets(root: Node3D) -> void:
	var c := BuildUtils.STREET
	BuildUtils.plate(root, -44, 44, 32, 46, 0, 1.0, c)
	BuildUtils.plate(root, -28.8, 28.8, 24.8, 32, 0, 1.0, c)
	BuildUtils.plate(root, 28.8, 36, -24.8, 32, 0, 1.0, c)
	# Avenue, with the gatehouse footprint cut out.
	BuildUtils.slab_with_hole(root, Vector3(0, -0.5, -32.4), Vector2(40, 15.2),
		Vector2(-6, -27), Vector2(7, 7), 1.0, c)
	# Minibus cover, spawn-side.
	BuildUtils.box(root, Vector3(8, 0.9, 36), Vector3(2.2, 1.8, 5.5), BuildUtils.METAL)
	BuildUtils.lamps(root, [
		Vector3(-30, 5, 40), Vector3(30, 5, 40), Vector3(-10, 5, -36),
		Vector3(32, 3, 0),
	], BuildUtils.LAMP_SERVICE, 0.8, 16.0)

## Outer edges of the street network, so a walk in any direction ends at a
## wall instead of open air. Road overhangs the alley/lane by 4m on each
## side (x [-44,-40] and [36,44] at z [32,46]) with nothing north of it —
## capped separately.
static func _boundary(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	var y := BOUND_H * 0.5
	var segs := [
		# Avenue north, now the Scoring Annex's south wall (SecAnnex): the
		# checkpoint gap x [-3, 3] and a 1.0m crawl under it at x [14, 15.2].
		[Vector3(-11.8, y, -40.2), Vector3(17.6, BOUND_H, 0.4)],
		[Vector3(8.5, y, -40.2), Vector3(11.0, BOUND_H, 0.4)],
		[Vector3(17.9, y, -40.2), Vector3(5.4, BOUND_H, 0.4)],
		[Vector3(14.6, 1.0 + (BOUND_H - 1.0) * 0.5, -40.2), Vector3(1.2, BOUND_H - 1.0, 0.4)],
		[Vector3(-20.2, y, -32.5), Vector3(0.4, BOUND_H, 15.4)],   # avenue west
		[Vector3(20.2, y, -32.5), Vector3(0.4, BOUND_H, 15.4)],    # avenue east
		[Vector3(-34.4, y, -24.6), Vector3(11.2, BOUND_H, 0.4)],   # alley north cap
		[Vector3(32.4, y, -24.6), Vector3(7.2, BOUND_H, 0.4)],     # lane north cap
		[Vector3(-40.2, y, 3.6), Vector3(0.4, BOUND_H, 56.8)],     # alley west
		[Vector3(36.2, y, 3.6), Vector3(0.4, BOUND_H, 56.8)],      # lane east
		[Vector3(-44.2, y, 39), Vector3(0.4, BOUND_H, 14)],        # road west
		[Vector3(44.2, y, 39), Vector3(0.4, BOUND_H, 14)],         # road east
		[Vector3(-42, y, 31.8), Vector3(4, BOUND_H, 0.4)],         # road overhang cap W
		[Vector3(42, y, 31.8), Vector3(4, BOUND_H, 0.4)],          # road overhang cap E
	]
	for s in segs:
		BuildUtils.box(root, s[0], s[1], c)

## The compound wall proper. North and south each leave one gap for a later
## Interactable (the gate, the cracked wall); west leaves a gap for the
## culvert crawl; east skips the gym's stretch entirely (§2.2 — that wall is
## the gym's, built in Block 5).
static func _compound_wall(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var y := WALL_H * 0.5
	var segs := [
		[Vector3(-28.4, y, -9.8), Vector3(WALL_T, WALL_H, 30.0)],   # west, north of culvert
		[Vector3(-28.4, y, 15.8), Vector3(WALL_T, WALL_H, 18.0)],   # west, south of culvert
		[Vector3(28.4, y, -22.4), Vector3(WALL_T, WALL_H, 4.8)],    # east, north of gym
		[Vector3(28.4, y, 12.65), Vector3(WALL_T, WALL_H, 9.3)],    # east, south of gym
		[Vector3(28.4, y, 21.75), Vector3(WALL_T, WALL_H, 6.1)],    # east, south of bin gate
		[Vector3(28.4, 3.2, 18.0), Vector3(WALL_T, 1.6, 1.4)],      # header over bin gate
		[Vector3(-18.9, y, -24.4), Vector3(19.8, WALL_H, WALL_T)],  # north, west of gatehouse
		[Vector3(15.9, y, -24.4), Vector3(25.8, WALL_H, WALL_T)],   # north, east of gate
		[Vector3(0, y, 24.4), Vector3(57.6, WALL_H, WALL_T)],       # south (crack sealed for now)
	]
	for s in segs:
		BuildUtils.box(root, s[0], s[1], c)
	# Ground under the two openings, so neither is a slot into the void. The
	# gate and the cracked wall themselves are Interactables (MissionCompound).
	BuildUtils.plate(root, -3, 3, -24.8, -24, 0, 1.0, BuildUtils.STREET)
	BuildUtils.plate(root, 28, 28.8, 17.3, 18.7, 0, 1.0, BuildUtils.STREET)   # bin gate

## Outside the wall, its south wall doubling as the compound's north wall.
## Plain door (no verb) at (-6, 0, -24); the north window is fixed and barred
## — no passage, so it stays part of the solid wall.
static func _gatehouse(root: Node3D) -> void:
	var c := BuildUtils.WALL
	var y := WALL_H * 0.5
	BuildUtils.plate(root, -9, -3, -30, -24, 0, 1.0, BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(-6, y, -30), Vector3(6.4, WALL_H, 0.4), c)
	BuildUtils.box(root, Vector3(-9, y, -27), Vector3(0.4, WALL_H, 6.4), c)
	BuildUtils.box(root, Vector3(-3, y, -27), Vector3(0.4, WALL_H, 6.4), c)
	# South wall (= compound wall here) with a 1.2m door gap centred x = -6.
	BuildUtils.box(root, Vector3(-7.9, y, -24.4), Vector3(2.2, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(-4.1, y, -24.4), Vector3(2.2, WALL_H, WALL_T), c)
	BuildUtils.plate(root, -9.2, -2.8, -30.2, -24.0, 4.0, 0.3, c)
	# Barred window, north face — decorative, non-colliding, no passage.
	for i in range(4):
		var bar := BuildUtils.box(root, Vector3(-7.5 + i * 0.5, 2.0, -29.9),
			Vector3(0.06, 1.4, 0.06), Color(0.1, 0.1, 0.12), false)
		bar.name = "GatehouseBar%d" % i
	BuildUtils.lamp(root, Vector3(-6, 3.4, -27), BuildUtils.LAMP_SERVICE, 2.0, 10.0)

## West alley: the outfall pit and its two ramps, plus the crawl that
## connects the west yard's grate through the wall to the pit floor.
## Floor stays out of the boiler house's footprint (x [-34, -28.8],
## z [-18, -8]) — that patch is Block 5's.
static func _west_alley(root: Node3D) -> void:
	var c := BuildUtils.STREET
	BuildUtils.plate(root, -40, -28.8, -24.8, -18, 0, 1.0, c)
	BuildUtils.plate(root, -40, -34, -18, -8, 0, 1.0, c)
	BuildUtils.plate(root, -40, -28.8, -8, 0, 0, 1.0, c)
	BuildUtils.plate(root, -40, -28.8, 4, 12, -2.2, 1.0, c)
	BuildUtils.plate(root, -40, -28.8, 16, 32, 0, 1.0, c)
	BuildUtils.ramp(root, Vector3(-34.4, -2.2, 4), Vector3(0, 0, -1), 4.0, 2.2, 11.2, c)
	BuildUtils.ramp(root, Vector3(-34.4, -2.2, 12), Vector3(0, 0, 1), 4.0, 2.2, 11.2, c)
	# Retaining walls down both sides of the pit, so the walls above it (the
	# compound wall, the boundary) don't float over a slot into the void.
	WallUtils.block(root, -28.8, -28.0, -2.4, 0.0, -0.5, 16.5, BuildUtils.WALL)
	WallUtils.block(root, -40.4, -40.0, -2.4, 0.0, -0.5, 16.5, BuildUtils.WALL_DARK)
	# The culvert: grate mouth at (-26, 0, 6) in the west yard, level, through
	# the wall to the outfall — whose lip is 2.2m above the pit floor, which is
	# what makes it exit-only. The mouth sits 1m west of G3's lane so he walks
	# past it rather than into it.
	BuildUtils.tunnel(root, Vector3(-26, 0, 6), Vector3(-28.8, 0, 6), 1.0, 1.6,
		BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(-28.4, 2.7, 6), Vector3(WALL_T, 2.6, 2.4), BuildUtils.WALL)
	BuildUtils.lamp(root, Vector3(-27.4, 0.6, 6), BuildUtils.LAMP_SERVICE, 0.4, 4.0)
	BuildUtils.lamps(root, [
		Vector3(-34.4, 3.0, -21), Vector3(-37, 3.0, 24),
	], BuildUtils.LAMP_SERVICE, 0.6, 12.0)
