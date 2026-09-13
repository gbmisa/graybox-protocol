class_name Sec2Yard
extends RefCounted
## The container yard: cover-rich ground level, the Wizard's dash line, two
## optional impound lockers [lockpick], and the crane.
##
## THE DASH LINE — the Wizard's vector. Gaps are 7m edge to edge: a running
## jump (6.6m) cannot make them, a 9.1m dash crosses with margin. The line
## itself is soft-gated by traversal; the hard gate is the warded skylight
## on the office roof at its end.
##
## The dash is perfectly horizontal (the kit zeroes vertical velocity and
## gravity is suspended mid-dash), so every platform top is 3.6m — level with
## the office roof, clearing its 3.0m east wall by 0.6m:
##
##   ramp (39.5, 0, -42) west -> P1 east edge (31, 3.6, -42), top 3.6
##   P1 (28, 3.0, -42): x [25, 31], z [-47, -37], top 3.6
##   7m dash south      -> P2 (28, 3.0, -24): x [25, 31], z [-30, -18], top 3.6
##   7m dash west       -> office roof (11..18, 3.6, -24)
##
## The ramp approaches P1 from the EAST, not the north: P1's north edge
## (z=-47) sits only 3m south of the perimeter fence (z=-50), so a north
## ramp would either start outside the fence or thread under P1 and wedge
## the climber against P1's underside (y=2.4). The east run is clear.
##
## P2 sits 7m east of the office east wall (x=18) so the second dash is a
## straight westward flight; P1 is aligned under the same x so the first
## dash is a straight southward flight. The platforms FLOAT — no solid
## plinths. (An earlier revision built 3.6m solid "supports" instead of the
## platforms and forgot the platforms entirely; the P1 support's north face
## at z=-47 walled off the ramp approach. Graybox platforms float; never
## "support" one with solid geometry on a walk line.)
##
## The yard guards patrol directly below — grouped, in the open — so the
## crossing doubles as meteor bait. Falling off means 60 HP on the ground
## with four patrols around.

static func build(root: Node3D, game: GrayboxGame) -> void:
	_containers(root)
	_dash_line(root)
	_lockers(root, game)
	_crane(root)
	_lights(root)
	_signage(root)

static func _containers(root: Node3D) -> void:
	var tints := [Color(0.42, 0.30, 0.24), Color(0.30, 0.36, 0.42),
		Color(0.40, 0.38, 0.26), Color(0.36, 0.30, 0.34)]
	var boxes := [
		Vector3(0, 1.3, -34), Vector3(36, 1.3, -30),
		Vector3(8, 1.3, -8), Vector3(28, 1.3, 6),
		Vector3(44, 1.3, 2), Vector3(12, 1.3, 18),
		Vector3(36, 1.3, -14), Vector3(-2, 1.3, 30),
	]
	var sizes := [
		Vector3(12, 2.6, 2.6), Vector3(2.6, 2.6, 12),
		Vector3(6, 2.6, 2.6), Vector3(12, 2.6, 2.6),
		Vector3(2.6, 2.6, 10), Vector3(10, 2.6, 2.6),
		Vector3(6, 2.6, 2.6), Vector3(8, 2.6, 2.6),
	]
	for i in range(boxes.size()):
		BuildUtils.box(root, boxes[i], sizes[i], tints[i % tints.size()])
	# One stacked pair for verticality in the yard itself.
	BuildUtils.box(root, Vector3(36, 3.9, -14), Vector3(6, 2.6, 2.6),
		tints[1])

static func _dash_line(root: Node3D) -> void:
	var c := Color(0.34, 0.30, 0.38)
	# Entry ramp: shared geometry, anyone can walk up. Runs westward onto
	# P1's east edge (see header for why not from the north). The line is
	# gated by the gaps and the skylight, not by the climb.
	BuildUtils.ramp(root, Vector3(39.5, 0, -42), Vector3(-1, 0, 0),
		8.5, 3.6, 3.0, c, 5)
	# Floating dash platforms, tops at 3.6m. No plinths (see header).
	BuildUtils.box(root, Vector3(28, 3.0, -42), Vector3(6, 1.2, 10), c)
	BuildUtils.box(root, Vector3(28, 3.0, -24), Vector3(6, 1.2, 12), c)
	BuildUtils.label(root, "DASH LINE — 7m GAPS",
		Vector3(28, 5.2, -33), Color(0.72, 0.45, 1.0), 30)
	BuildUtils.label(root, "ROOF →",
		Vector3(22, 5.0, -24), Color(0.72, 0.45, 1.0), 30)

## Optional lockpick content on the Regular's side of the yard: flavor intel,
## no mission-critical function. The cost is 3s of exposure each.
static func _lockers(root: Node3D, game: GrayboxGame) -> void:
	_locker(root, game, "A", Vector3(40, 0, 8), 0,
		"MANIFEST 77-B: one (1) yacht, seized. Owner deceased (allegedly).")
	_locker(root, game, "B", Vector3(-6, 0, 28), 0,
		"MANIFEST 12-C: 400 crates of 'olive oil'. Sure.")

static func _locker(root: Node3D, game: GrayboxGame, tag: String, at: Vector3,
		_rot: float, manifest: String) -> void:
	var c := BuildUtils.METAL
	# Three walls and a roof; the lockpick door fills the north face.
	BuildUtils.box(root, at + Vector3(0, 1.5, 2), Vector3(4, 3, 0.4), c)
	BuildUtils.box(root, at + Vector3(-1.8, 1.5, 0), Vector3(0.4, 3, 4), c)
	BuildUtils.box(root, at + Vector3(1.8, 1.5, 0), Vector3(0.4, 3, 4), c)
	BuildUtils.box(root, at + Vector3(0, 3.1, 0), Vector3(4.4, 0.3, 4.4), c)
	LockedDoor.create(game, root, "IMPOUND LOCKER " + tag,
		at + Vector3(0, 1.25, -2), Vector3(3.2, 2.5, 0.4), ["lockpick"])
	BuildUtils.lamp(root, at + Vector3(0, 2.7, 0), BuildUtils.LAMP_SERVICE,
		1.6, 8.0)
	BuildUtils.label(root, manifest, at + Vector3(0, 1.6, 1.6),
		Color(0.5, 0.83, 1.0), 26)

static func _crane(root: Node3D) -> void:
	var c := BuildUtils.METAL
	BuildUtils.box(root, Vector3(-30, 9, 30), Vector3(3, 18, 3), c)
	BuildUtils.box(root, Vector3(-22, 18.5, 30), Vector3(22, 2, 2.5), c)
	BuildUtils.box(root, Vector3(-38, 18, 30), Vector3(4, 3, 3), c)
	BuildUtils.box(root, Vector3(-14, 12, 30), Vector3(0.15, 13, 0.15), c)
	BuildUtils.lamp(root, Vector3(-30, 17, 30), Color(1.0, 0.4, 0.3), 2.0, 16.0)
	BuildUtils.label(root, "CRANE 2 — OUT OF SERVICE (since 2019)",
		Vector3(-30, 6, 28), Color(1.0, 0.52, 0.18), 30)

static func _lights(root: Node3D) -> void:
	BuildUtils.lamps(root, [
		Vector3(28, 7, -42), Vector3(28, 7, -24), Vector3(10, 7, 0),
		Vector3(32, 7, 14), Vector3(0, 7, 28), Vector3(-14, 7, -8),
	], BuildUtils.LAMP_SERVICE, 2.2, 18.0)

static func _signage(root: Node3D) -> void:
	BuildUtils.label(root, "IMPOUND LOT: your boat is our boat now",
		Vector3(0, 3.6, -32.6), Color(1.0, 0.52, 0.18), 34)
	BuildUtils.label(root, "DASH CAMERAS IN OPERATION (they are not)",
		Vector3(24, 3.4, -33), Color(0.6, 0.62, 0.68), 26)
