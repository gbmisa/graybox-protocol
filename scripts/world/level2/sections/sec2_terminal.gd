class_name Sec2Terminal
extends RefCounted
## Container terminal (west district): x[-100,-25], z[-60,25].
##
## A container maze with real lanes and cover, the Wizard's dash line to the
## office roof, and a key-gated storage compound (south) that shortcuts the
## crossing to the pier district.
##
## Dash line (axis z=-26, all tops at 3.6):
##   ramp  (-58,0,-26) -> (-46,3.6,-26)   walkable approach
##   P1    x[-46,-40], z[-31,-21]          first roof
##   9.0m dash east ->
##   P2    x[-31,-25], z[-31,-21]          second roof
##   9.0m dash east -> office west wall (x=-16), land on the roof
## Both gaps are unjumpable (empirically ~7m max) and dashable (9.1m level
## dash). The corridor x[-60,-14], z[-32,-20] is kept clear of containers.

const DASH_TOP := 3.6
const DASH_Z := -26.0

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_maze(root)
	_build_dash_line(root)
	_build_storage_compound(game, root)
	BuildUtils.label(root, "TERMINAL 7 — CONTAINERS", Vector3(-70, 6.5, -40), Color(1.0, 0.84, 0.37), 48)

static func _container(root: Node3D, pos: Vector3, size: Vector3,
		color: Color, stack: int = 1) -> void:
	# Note: BuildUtils.box does not rotate collision, so orientation is
	# baked into the size — never rotate the returned mesh.
	for i in stack:
		BuildUtils.box(root, Vector3(pos.x, pos.y + 1.3 + 2.6 * i, pos.z),
			size, color)

static func _build_maze(root: Node3D) -> void:
	var rust := Color(0.48, 0.26, 0.14)
	var blue := Color(0.16, 0.30, 0.44)
	var green := Color(0.20, 0.36, 0.22)
	var gray := Color(0.32, 0.34, 0.36)
	var ew12 := Vector3(12.2, 2.6, 2.4)
	var ns6 := Vector3(2.4, 2.6, 6.1)
	var ew6 := Vector3(6.1, 2.6, 2.4)
	# North lanes (above the dash corridor).
	_container(root, Vector3(-80, 0, -45), ew12, rust)
	_container(root, Vector3(-80, 0, -38), ew12, blue, 2)
	_container(root, Vector3(-58, 0, -50), ns6, green)
	_container(root, Vector3(-35, 0, -45), ew12, gray)
	_container(root, Vector3(-45, 0, -38), ns6, rust)
	# South lanes (below the dash corridor).
	_container(root, Vector3(-60, 0, 0), ew12, blue)
	_container(root, Vector3(-75, 0, 8), ns6, green, 2)
	_container(root, Vector3(-90, 0, -10), ew12, rust)
	_container(root, Vector3(-55, 0, 18), ns6, gray)
	_container(root, Vector3(-35, 0, 15), ns6, blue)
	_container(root, Vector3(-70, 0, -12), ew6, green)
	_container(root, Vector3(-85, 0, 20), ew12, gray)

static func _build_dash_line(root: Node3D) -> void:
	var plat := Color(0.42, 0.44, 0.48)
	# Walkable ramp: 12m run, 3.6m rise, 3m wide, heading east onto P1.
	BuildUtils.ramp(root, Vector3(-58, 0, DASH_Z), Vector3(1, 0, 0),
		12.0, DASH_TOP, 3.0, plat)
	# P1 and P2: 1.2m thick slabs, tops at 3.6.
	BuildUtils.box(root, Vector3(-43, DASH_TOP - 0.6, DASH_Z),
		Vector3(6.0, 1.2, 10.0), plat)
	BuildUtils.box(root, Vector3(-28, DASH_TOP - 0.6, DASH_Z),
		Vector3(6.0, 1.2, 10.0), plat)
	# Legs so the platforms don't float.
	for px in [-45.0, -41.0]:
		BuildUtils.box(root, Vector3(px, 1.2, DASH_Z), Vector3(0.6, 2.4, 0.6),
			BuildUtils.PIPE)
	for px in [-30.0, -26.0]:
		BuildUtils.box(root, Vector3(px, 1.2, DASH_Z), Vector3(0.6, 2.4, 0.6),
			BuildUtils.PIPE)
	# Edge chevrons: the line reads as a dash line, not decoration.
	BuildUtils.label(root, "DASH >", Vector3(-43, DASH_TOP + 0.8, DASH_Z), Color(0.72, 0.40, 1.0), 40)
	BuildUtils.label(root, "DASH >", Vector3(-28, DASH_TOP + 0.8, DASH_Z), Color(0.72, 0.40, 1.0), 40)

static func _build_storage_compound(game: GrayboxGame, root: Node3D) -> void:
	# Chain-link fence x=-40, z[-8,20], 3m tall. The gate (key or nothing)
	# is the direct crossing; without it you walk around either end.
	var fence_c := Color(0.25, 0.27, 0.30)
	for seg in [[-8.0, 4.5], [7.5, 20.0]]:
		var z0: float = seg[0]
		var z1: float = seg[1]
		BuildUtils.box(root, Vector3(-40, 1.5, (z0 + z1) * 0.5),
			Vector3(0.25, 3.0, z1 - z0), fence_c)
	# Fence posts.
	for pz in [-8.0, 4.5, 7.5, 20.0]:
		BuildUtils.box(root, Vector3(-40, 1.5, pz), Vector3(0.4, 3.0, 0.4),
			BuildUtils.PIPE)
	# The key gate itself.
	var gate := LockedDoor.create(game, root, "STORAGE GATE",
		Vector3(-40, 1.5, 6.0), Vector3(0.3, 3.0, 3.0), ["key:storage_key"])
	gate.exit_side = Vector3(1, 0, 0)  # free exit eastward (toward the pier)
	BuildUtils.label(root, "STORAGE — KEY REQUIRED", Vector3(-40, 3.8, 6.0), Color(0.85, 0.65, 0.25), 32)
	# The reward inside: the seized-goods manifest (optional intel).
	IntelPickup.create(game, root, "manifest12c", Vector3(-36, 0, 6.0))
	BuildUtils.box(root, Vector3(-36, 0.5, 8.5), Vector3(2.0, 1.0, 2.0),
		Color(0.40, 0.30, 0.18))
