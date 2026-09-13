class_name Sec2Perimeter
extends RefCounted
## PORT VESPER perimeter: the ground plate, the water boundary, the north
## fence, the spawn staging, and the north van extraction.
##
## The level runs east-west along the harbor: x[-110,110], z[-80,25].
## WATER is the southern boundary (z > 25) — no fence along it, the pier
## overhangs it. The north fence (z=-60) has a vehicle gateway (x[-3,3])
## and a culvert notch at x=70 (the pipe itself is built by Sec2Culvert).

const FENCE_H := 4.0
const FENCE_T := 0.4

static func build(game: GrayboxGame, root: Node3D) -> void:
	# Ground plate. The water region gets its own lower seabed plate.
	BuildUtils.box(root, Vector3(0, -0.3, -27.5), Vector3(220, 0.6, 105),
		BuildUtils.GROUND)
	BuildUtils.label(root, "PORT VESPER — CUSTOMS IMPOUND",
		Vector3(0, 5.2, -60), Color(1.0, 0.84, 0.37), 64)
	_build_water(root)
	_build_north_fence(root)
	_build_side_fences(root)
	_build_staging(root)
	_build_van(game, root)

static func _build_water(root: Node3D) -> void:
	# Seabed 0.8m below the apron; the shoreline step is mantleable so the
	# water is a soft boundary, not a trap.
	BuildUtils.box(root, Vector3(0, -1.1, 60), Vector3(220, 0.6, 70),
		Color(0.08, 0.10, 0.12))
	var water := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(220, 0.4, 70)
	water.mesh = wm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.28, 0.42, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.25
	mat.metallic = 0.1
	water.material_override = mat
	water.position = Vector3(0, -0.35, 60)
	root.add_child(water)

static func _fence_run(root: Node3D, cx: float, width: float) -> void:
	BuildUtils.box(root, Vector3(cx, FENCE_H * 0.5, -60),
		Vector3(width, FENCE_H, FENCE_T), BuildUtils.WALL_DARK)

static func _build_north_fence(root: Node3D) -> void:
	# z=-60, x[-100,100]. Gaps: vehicle gateway x[-3,3], culvert notch x[68,72].
	_fence_run(root, -51.5, 97.0)   # x[-100,-3]
	_fence_run(root, 35.5, 65.0)    # x[3,68]
	_fence_run(root, 86.0, 28.0)    # x[72,100]
	# Gateway frame: posts + lintel, 4.2m clear.
	for px in [-3.4, 3.4]:
		BuildUtils.box(root, Vector3(px, 2.1, -60), Vector3(0.8, 4.2, 0.8),
			BuildUtils.METAL)
	BuildUtils.box(root, Vector3(0, 4.5, -60), Vector3(7.6, 0.6, 0.8),
		BuildUtils.METAL)
	# Culvert notch lintel: the fence continues above the 1.0m pipe.
	BuildUtils.box(root, Vector3(70, 2.8, -60), Vector3(4.0, 2.4, FENCE_T),
		BuildUtils.WALL_DARK)
	BuildUtils.label(root, "NORTH GATE", Vector3(0, 5.6, -60), Color(1.0, 0.84, 0.37), 40)

static func _build_side_fences(root: Node3D) -> void:
	# West (x=-100) and east (x=105) world edges, z[-60,25]. The water
	# bounds the south; these close the east and west.
	BuildUtils.box(root, Vector3(-100, FENCE_H * 0.5, -17.5),
		Vector3(FENCE_T, FENCE_H, 85), BuildUtils.WALL_DARK)
	BuildUtils.box(root, Vector3(105, FENCE_H * 0.5, -17.5),
		Vector3(FENCE_T, FENCE_H, 85), BuildUtils.WALL_DARK)

static func _build_staging(root: Node3D) -> void:	# Spawn staging: a concrete blast wall between the spawn pad and the
	# gate guards' sightlines. Spawn at (0,0,-74); the wall (x[-3,3]) blocks
	# every guard-post ray to the spawn point.
	BuildUtils.box(root, Vector3(0, 1.1, -69), Vector3(6.0, 2.2, 0.6),
		BuildUtils.CONCRETE)
	BuildUtils.label(root, "STAGING", Vector3(0, 2.9, -69), Color(0.62, 0.64, 0.68), 40)
	# Spawn pad marker.
	BuildUtils.box(root, Vector3(0, 0.03, -74), Vector3(4.0, 0.06, 4.0),
		Color(0.20, 0.24, 0.20))

static func _build_van(game: GrayboxGame, root: Node3D) -> void:
	# Guarded north extraction: the van waits outside the gate at (0,0,-64).
	var body_c := Color(0.16, 0.17, 0.20)
	BuildUtils.box(root, Vector3(0, 1.15, -64), Vector3(2.2, 2.3, 5.2), body_c)
	BuildUtils.box(root, Vector3(0, 0.75, -61.0), Vector3(2.0, 1.1, 1.4),
		Color(0.10, 0.12, 0.16))
	for wx in [-1.0, 1.0]:
		for wz in [-65.8, -62.4]:
			BuildUtils.box(root, Vector3(wx, 0.35, wz), Vector3(0.3, 0.7, 0.7),
				Color(0.05, 0.05, 0.06))
	BuildUtils.label(root, "EXTRACTION — VAN", Vector3(0, 3.2, -64), Color(0.35, 1.0, 0.45), 36)
	BuildUtils.zone(root, game, "van", Vector3(0, 0, -64), 4.0)
