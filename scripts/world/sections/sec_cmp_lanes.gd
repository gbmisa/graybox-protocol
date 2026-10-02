class_name SecCmpLanes
extends RefCounted
## Playtest r5: "not enough verticality, very wide open, getting to the target
## is very straightforward". Two areas were simply too open — the estate yard
## on the approach and the campus courtyard — so they are cut into lanes and
## given a high level, without touching any existing door, lane or route.
##
##   Estate yard   two 2.3m walls across the yard, gaps at opposite ends, so
##                 the way north is a zigzag with A1's patrol (z 156) inside
##                 the corridor between them. Each wall has a crate stair
##                 (1.15 rises) so it can be climbed instead.
##   Courtyard     two container stacks across the south half, a 9m gap
##                 between them on the line to the portico door, and a
##                 catwalk at 4.6 over that gap joining their tops. Stairs:
##                 crates at 1.15 / 2.3 / 3.45, every rise 1.15 (shared band).
##
## Every rise here is <= 1.15 so each climb is a mantle from the last crate.

const YARD_WALL_H := 2.3
const WALL_T := 1.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_estate_zigzag(root)
	_courtyard_stacks(root)

# ------------------------------------------------------------ estate yard ---
static func _estate_zigzag(root: Node3D) -> void:
	var c := BuildUtils.CONCRETE
	var c2 := Color(0.42, 0.38, 0.30)
	# W1 (z 166-167): gap on the east, x [24, 29]. Seen from the spawn street
	# you must go along it to get through.
	_wall_x(root, 166.5, -44, 24, c)
	_wall_x(root, 166.5, 29, 44, c)
	# W2 (z 147.5-148.5): gap on the west, x [-30, -25], beside the substation.
	_wall_x(root, 148.0, -44, -30, c2)
	_wall_x(root, 148.0, -25, 44, c2)
	# Crate stairs, one per wall, away from the gap: mantle crate -> wall top.
	_crate_stair(root, Vector3(-8, 0, 167.0), 1.0, c)    # south face of W1
	_crate_stair(root, Vector3(16, 0, 147.5), -1.0, c2)  # north face of W2
	# Lamps at the gaps so the way through reads in the dark.
	BuildUtils.lamp(root, Vector3(26.5, 3.0, 164.5), Color(1.0, 0.78, 0.45), 1.6, 9.0)
	BuildUtils.lamp(root, Vector3(-27.5, 3.0, 150.5), Color(1.0, 0.78, 0.45), 1.6, 9.0)

static func _wall_x(root: Node3D, z: float, x0: float, x1: float, color: Color) -> void:
	WallUtils.block(root, x0, x1, 0, YARD_WALL_H, z - WALL_T * 0.5, z + WALL_T * 0.5, color)

## Two crates: 1.15 against the wall's face, climbable from the ground. They
## sit on the `side` (+1 = south of the wall) so you mantle onto the wall top.
static func _crate_stair(root: Node3D, at: Vector3, side: float, color: Color) -> void:
	var z0 := at.z
	WallUtils.block(root, at.x - 1.0, at.x + 1.0, 0, 1.15,
		z0 if side > 0.0 else z0 - 1.2, z0 + 1.2 if side > 0.0 else z0, BuildUtils.CRATE)

# --------------------------------------------------------------- courtyard ---
const CONTAINER_H := 2.3

static func _courtyard_stacks(root: Node3D) -> void:
	var rust := Color(0.55, 0.22, 0.14)
	var teal := Color(0.14, 0.42, 0.44)
	var ochre := Color(0.62, 0.48, 0.12)
	# West stack: lower row x [-16, -6], upper container on its east half.
	WallUtils.block(root, -16, -11, 0, CONTAINER_H, 5, 7.4, rust)
	WallUtils.block(root, -11, -6, 0, CONTAINER_H, 5, 7.4, teal)
	WallUtils.block(root, -11, -6, CONTAINER_H, CONTAINER_H * 2.0, 5, 7.4, ochre)
	# East stack, mirrored: lower row x [3, 13], upper on its west half.
	WallUtils.block(root, 3, 8, 0, CONTAINER_H, 5, 7.4, teal)
	WallUtils.block(root, 8, 13, 0, CONTAINER_H, 5, 7.4, rust)
	WallUtils.block(root, 3, 8, CONTAINER_H, CONTAINER_H * 2.0, 5, 7.4, ochre)
	# Stairs, west: ground crate (west end) -> lower roof -> roof crate -> upper.
	WallUtils.block(root, -17.2, -16, 0, 1.15, 5.0, 6.2, BuildUtils.CRATE)
	WallUtils.block(root, -12.2, -11, CONTAINER_H, CONTAINER_H + 1.15, 5.0, 6.2, BuildUtils.CRATE)
	# Stairs, east: ground crate (east end) -> lower roof -> roof crate -> upper.
	WallUtils.block(root, 13, 14.2, 0, 1.15, 5.0, 6.2, BuildUtils.CRATE)
	WallUtils.block(root, 9, 10.2, CONTAINER_H, CONTAINER_H + 1.15, 5.0, 6.2, BuildUtils.CRATE)
	# The catwalk over the portico approach, joining the two upper tops.
	BuildUtils.plate(root, -6, 3, 5.4, 7.0, CONTAINER_H * 2.0, 0.25, BuildUtils.METAL)
	BuildUtils.lamps(root, [Vector3(-1.5, 4.0, 6.2), Vector3(-13, 3.6, 8.0), Vector3(10, 3.6, 8.0)],
		BuildUtils.LAMP_SERVICE, 0.9, 9.0)
