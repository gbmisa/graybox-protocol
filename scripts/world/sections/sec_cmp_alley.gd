class_name SecCmpAlley
extends RefCounted
## Alley, x [10, 16] z [-20, -2], DARK. Its ground, the crate stair against the
## main block's east face, and the link bridge overhead. G5 walks x = 13.
##
## Six crate stacks, 2.0 x 1.5, x [10, 12], stepping 1.0m south and 1.15m up
## from z [-20, -18.5]: tops 1.15 · 2.30 · 3.45 · 4.60 · 5.75 · 6.90, so each
## leaves a 1.0m tread. Stack six ends at z -13.5, beside the roof's parapet
## gap (a 1.5m jump, not a mantle) and 0.3m above the bridge roof.

const STACK_X := 11.0
const STACK_TOPS := [1.15, 2.30, 3.45, 4.60, 5.75, 6.90]
const BRIDGE_Y := 4.0
const BRIDGE_ROOF := 6.6

static func build(root: Node3D, game: GrayboxGame) -> void:
	BuildUtils.plate(root, 10, 16, -20, -2, 0, 1.0, BuildUtils.GROUND)
	_crate_stack(root)
	_bridge(root)
	_lights(root)

static func _crate_stack(root: Node3D) -> void:
	for i in range(STACK_TOPS.size()):
		var top: float = STACK_TOPS[i]
		var z := -19.25 + float(i)
		BuildUtils.box(root, Vector3(STACK_X, top * 0.5, z), Vector3(2.0, top, 1.5),
			BuildUtils.CRATE)

## Enclosed passage from the main block's east landing to the gym mezzanine.
## Its ends meet door openings already cut in both buildings' walls; its roof
## is walkable and flush with the gym roof.
static func _bridge(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	BuildUtils.plate(root, 10, 16, -13.5, -10.5, BRIDGE_Y, 0.4, BuildUtils.FLOOR)
	var h := BRIDGE_ROOF - 0.3 - BRIDGE_Y
	var y := BRIDGE_Y + h * 0.5
	BuildUtils.box(root, Vector3(13, y, -13.5), Vector3(6, h, 0.3), c)
	BuildUtils.box(root, Vector3(13, y, -10.5), Vector3(6, h, 0.3), c)
	BuildUtils.plate(root, 10, 16, -13.65, -10.35, BRIDGE_ROOF, 0.3, c)

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(14.5, 3.0, -18), Vector3(14.5, 3.0, -6),
	], BuildUtils.LAMP_SERVICE, 0.6, 10.0)
	BuildUtils.lamp(root, Vector3(13, BRIDGE_Y + 1.8, -12), BuildUtils.LAMP_FLUORO,
		1.8, 8.0)
