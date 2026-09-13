class_name SecCourtyard
extends RefCounted
## THE WIZARD'S ROUTE — open ground at y = 0, then straight up.
##
##   WARDED GATE [arcane only]  ->  courtyard (heavy patrol)
##   ->  vent shaft, climbed by dash-jumping staggered ledges
##   ->  mezzanine (y = 6)
##
## The courtyard is deliberately the most exposed space in the level: no roof,
## thin cover, five guards. Sixty hit points does not survive standing still
## here, which is what makes Meteor and the dash load-bearing rather than
## optional.
##
## Extent: courtyard x [-30, 30], z [10, 40]. Shaft x [-2, 26], z [2, 10].

const WALL_H := 8.0
const WALL_T := 0.8

## The climb starts from a raised platform at the same height as the first
## ledge, so every gap is purely horizontal and the dash is the only thing that
## crosses one. Rises are 1.6m, under the 1.84m a jump clears, so you jump for
## height and dash for distance — the dash is flat and grants no lift.
##
## The platform matters: with the ledges reachable from the shaft floor, you
## could stand under the first one and jump straight up onto it, and the first
## 7m gap never got tested at all.
const LEDGES := [
	Vector3(13, 2.0, 5),
	Vector3(6, 3.6, 5),
	Vector3(-1, 5.2, 5),
]
const PLATFORM_Y := 2.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_walls(root, game)
	_cover(root)
	_shaft(root)
	_lights(root)
	BuildUtils.label(root, "COURTYARD", Vector3(0, 9, 26),
		Color(0.72, 0.40, 1.0), 40)

## Yard floods plus arcane tint up the shaft, so the ledges read against the
## dark and you can judge the next gap before committing to a dash.
static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(-18, 6, 32), Vector3(16, 6, 30), Vector3(-6, 6, 16),
		Vector3(22, 6, 20),
	], BuildUtils.LAMP_FLUORO, 2.4, 24.0)
	BuildUtils.lamps(root, [
		Vector3(23, 3.4, 6), Vector3(13, 3.6, 7), Vector3(6, 5.2, 7),
		Vector3(-1, 6.4, 7),
	], BuildUtils.LAMP_ARCANE, 2.6, 12.0)

static func _walls(root: Node3D, game: GrayboxGame) -> void:
	var c := BuildUtils.WALL
	var y := WALL_H * 0.5
	BuildUtils.box(root, Vector3(-30, y, 25), Vector3(WALL_T, WALL_H, 30), c)
	BuildUtils.box(root, Vector3(30, y, 25), Vector3(WALL_T, WALL_H, 30), c)
	# South wall with the gate gap at x [-3, 3].
	BuildUtils.box(root, Vector3(-16.5, y, 40), Vector3(27, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(16.5, y, 40), Vector3(27, WALL_H, WALL_T), c)
	BuildUtils.box(root, Vector3(0, 6.5, 40), Vector3(6, 3, WALL_T), c)
	WardedSeal.create(game, root, "WARDED GATE",
		Vector3(0, 2.5, 40), Vector3(6, 5, WALL_T))

static func _cover(root: Node3D) -> void:
	# Sparse and low on purpose — it breaks line of sight, it does not make
	# the courtyard safe to linger in.
	var spots := [
		Vector3(-18, 0, 32), Vector3(-8, 0, 20), Vector3(6, 0, 30),
		Vector3(20, 0, 18), Vector3(-22, 0, 14), Vector3(14, 0, 36),
	]
	for i in range(spots.size()):
		var tall := i % 2 == 0
		var size := Vector3(2.4, 1.6, 2.4) if tall else Vector3(3.0, 1.0, 2.0)
		BuildUtils.box(root, spots[i] + Vector3(0, size.y * 0.5, 0), size,
			BuildUtils.CRATE if tall else BuildUtils.METAL)

## The vent shaft: a walled void through the tower's south-east corner with
## three ledges staggered across it. The mezzanine slab is cut to match.
static func _shaft(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	# Back wall runs the full tower width so the shaft is sealed off from the
	# freight bay behind it — Chad's route and the Wizard's never meet below
	# the mezzanine.
	BuildUtils.box(root, Vector3(14, 3, 1.6), Vector3(32, 6, 0.8), c)
	BuildUtils.box(root, Vector3(-2.4, 3, 6), Vector3(0.8, 6, 8), c)    # west
	BuildUtils.box(root, Vector3(26.4, 3, 6), Vector3(0.8, 6, 8), c)    # east
	# Ramp up from the courtyard onto the launch platform.
	BuildUtils.ramp(root, Vector3(23, 0, 13), Vector3(0, 0, -1),
		5.0, PLATFORM_Y, 5.0, BuildUtils.METAL)
	BuildUtils.plate(root, 20, 26, 2, 8, PLATFORM_Y, 0.5, BuildUtils.METAL)
	# Recovery step, so falling off the climb costs time rather than the run.
	# Placed away from the first ledge so it cannot be used to shortcut a gap.
	BuildUtils.box(root, Vector3(19, 0.6, 9), Vector3(2, 1.2, 2),
		BuildUtils.CRATE)
	for l in LEDGES:
		BuildUtils.box(root, Vector3(l.x, l.y - 0.2, l.z),
			Vector3(2.6, 0.4, 2.6), BuildUtils.METAL)
		# Emissive lip so the next hop reads at a glance in the dark shaft.
		var lip := BuildUtils.box(root, Vector3(l.x, l.y + 0.04, l.z),
			Vector3(2.7, 0.08, 2.7), Color(0.72, 0.40, 1.0), false)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.40, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.72, 0.40, 1.0)
		mat.emission_energy_multiplier = 1.8
		lip.material_override = mat
	BuildUtils.label(root, "VENT SHAFT — DASH THE GAPS",
		Vector3(22, 1.2, 8), Color(0.72, 0.40, 1.0), 30)
