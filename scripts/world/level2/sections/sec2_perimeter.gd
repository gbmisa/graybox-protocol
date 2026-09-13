class_name Sec2Perimeter
extends RefCounted
## PORT VESPER shell: night sky, ground apron, water, perimeter fence with its
## openings, north gate checkpoint (van extraction), south pier (boat
## extraction). Every operative starts north of the fence and walks in through
## their own vector — the gate itself is just scenery with guards on it.
##
## Openings in the fence:
##   north  x [-3, 3]      open gateway (guarded checkpoint)
##   east   z = 20, the drainage culvert passes UNDER the fence through a
##          1.4m notch (built by Sec2Culvert); the lintel above the pipe is
##          what makes the 1.0m crawl unskippable
##   south  x [44, 50]     open pier walkway
##   south  x [28.5, 31.5] PIER GATE [lockpick] — the Regular's shortcut
##
## The west fence stops at the warehouse walls (z [-18, 12]): the warehouse's
## own corrugated west wall is the perimeter there, and Chad's breach goes
## through it.

const FENCE_H := 4.0
const FENCE_T := 0.6

static func build(root: Node3D, game: GrayboxGame) -> void:
	_environment(root)
	_ground(root)
	_water(root)
	_fence(root, game)
	_north_gate(root, game)
	_pier(root, game)
	_signage(root)

static func _environment(root: Node3D) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.025, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.44, 0.58)
	env.ambient_light_energy = 0.75
	we.environment = env
	root.add_child(we)
	# Moonlight: dim, blue, shadowed — the only global light. Interiors and
	# the yard get their own lamps; anything without one is a black void.
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -30, 0)
	moon.light_color = Color(0.55, 0.66, 0.92)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	root.add_child(moon)

## Apron stops at the shoreline (z = 52); the seabed continues under the water.
static func _ground(root: Node3D) -> void:
	BuildUtils.plate(root, -80, 80, -80, 52, 0.0, 1.0, BuildUtils.STREET)
	# Water strip z [45, 52] is apron — the long way to the pier on foot.
	BuildUtils.plate(root, -80, 80, 52, 90, -0.8, 1.0, BuildUtils.GROUND)

static func _water(root: Node3D) -> void:
	# Opaque night water. Non-colliding: it is a visual plane over the seabed.
	# Falling in lands on the seabed 0.8m down — mantleable by everyone, so
	# there is no soft-lock, just wet feet.
	BuildUtils.box(root, Vector3(0, -0.35, 71), Vector3(160, 0.3, 38),
		Color(0.04, 0.10, 0.20), false)

static func _fence(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL_DARK
	var y := FENCE_H * 0.5
	# North: gateway gap at x [-3, 3].
	BuildUtils.box(root, Vector3(-31.5, y, -50), Vector3(57, FENCE_H, FENCE_T), c)
	BuildUtils.box(root, Vector3(31.5, y, -50), Vector3(57, FENCE_H, FENCE_T), c)
	# East: the fence runs full height; the culvert pipe passes UNDER it through
	# a 1.4m notch. The lintel above the pipe (y 1.4–4.0) is what makes the
	# 1.0m crawl unskippable — without it the pipe's 1.4m roof is a speed
	# bump a 1.84m jump clears, and the gate means nothing.
	BuildUtils.box(root, Vector3(60, y, -15.6), Vector3(FENCE_T, FENCE_H, 68.8), c)
	BuildUtils.box(root, Vector3(60, y, 35.6), Vector3(FENCE_T, FENCE_H, 28.8), c)
	BuildUtils.box(root, Vector3(60, 2.7, 20), Vector3(FENCE_T, 2.6, 2.4), c)
	# West: warehouse walls cover z [-18, 12]; fence fills the rest.
	BuildUtils.box(root, Vector3(-60, y, -34), Vector3(FENCE_T, FENCE_H, 32), c)
	BuildUtils.box(root, Vector3(-60, y, 28.5), Vector3(FENCE_T, FENCE_H, 33), c)
	# South: open pier walkway at x [44, 50]; lockpick pier gate at x = 30.
	BuildUtils.box(root, Vector3(-16.5, y, 45), Vector3(87, FENCE_H, FENCE_T), c)
	BuildUtils.box(root, Vector3(38.5, y, 45), Vector3(11, FENCE_H, FENCE_T), c)
	BuildUtils.box(root, Vector3(55, y, 45), Vector3(10, FENCE_H, FENCE_T), c)
	# Lintel over the pier gate; the door sinks into the floor when opened.
	BuildUtils.box(root, Vector3(30, 3.5, 45), Vector3(3.6, 1.0, FENCE_T), c)
	LockedDoor.create(game, root, "PIER GATE",
		Vector3(30, 1.5, 45), Vector3(3, 3, FENCE_T), ["lockpick"])
	BuildUtils.label(root, "PIER — AUTHORIZED PERSONNEL",
		Vector3(30, 4.6, 44), Color(0.35, 0.70, 1.0), 30)

static func _north_gate(root: Node3D, game: GrayboxGame) -> void:
	# Checkpoint booth and barrier arm outside the gateway.
	BuildUtils.box(root, Vector3(6, 1.5, -54), Vector3(3, 3, 3), BuildUtils.WALL)
	BuildUtils.box(root, Vector3(0, 1.0, -52), Vector3(7, 0.25, 0.4),
		Color(0.8, 0.75, 0.2))
	BuildUtils.lamp(root, Vector3(0, 4.5, -53), BuildUtils.LAMP_SERVICE, 2.4, 18.0)
	BuildUtils.zone(root, game, "van", Vector3(0, 0, -57), 4.0)
	BuildUtils.label(root, "NORTH GATE — ALL VEHICLES SUBJECT TO SEARCH",
		Vector3(0, 5.5, -50), Color(1.0, 0.52, 0.18), 36)
	BuildUtils.label(root, "(none are)",
		Vector3(0, 4.6, -50), Color(0.6, 0.62, 0.68), 28)

static func _pier(root: Node3D, game: GrayboxGame) -> void:
	# Deck over the water, z [45, 62]. Piles down to the seabed.
	BuildUtils.plate(root, 27, 33, 45, 62, 0.0, 0.6, BuildUtils.CONCRETE)
	for px in [27.6, 32.4]:
		for pz in [48, 54, 60]:
			BuildUtils.box(root, Vector3(px, -0.6, pz), Vector3(0.5, 1.6, 0.5),
				BuildUtils.PIPE)
	# The boat: hull, cabin, a lamp. It never moves; it is an exit.
	BuildUtils.box(root, Vector3(30, 0.5, 58), Vector3(4.2, 1.4, 8.5),
		BuildUtils.METAL)
	BuildUtils.box(root, Vector3(30, 1.7, 57), Vector3(2.6, 1.6, 3.2),
		BuildUtils.WALL)
	BuildUtils.lamp(root, Vector3(30, 3.4, 58), BuildUtils.LAMP_SERVICE, 2.0, 12.0)
	BuildUtils.zone(root, game, "boat", Vector3(30, 0, 58), 4.0)
	BuildUtils.label(root, "PIER 3 — FERRY",
		Vector3(30, 4.2, 52), Color(0.2, 1.0, 0.35), 36)
	BuildUtils.label(root, "(it never comes)",
		Vector3(30, 3.4, 52), Color(0.6, 0.62, 0.68), 26)

static func _signage(root: Node3D) -> void:
	BuildUtils.label(root, "PORT VESPER CUSTOMS — Facilitating Trade",
		Vector3(-14, 6.2, -50), Color(1.0, 0.84, 0.37), 44)
	BuildUtils.label(root, "HARBORMASTER'S ROUNDS: OFFICE → WAREHOUSE → PIER",
		Vector3(-14, 5.2, -50), Color(0.5, 0.83, 1.0), 30)
