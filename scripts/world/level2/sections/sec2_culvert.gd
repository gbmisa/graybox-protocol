class_name Sec2Culvert
extends RefCounted
## The east drainage culvert: the Regular's vector.
##
## A concrete pipe running under the east fence at z = 20. The crawl interior
## is EXACTLY 1.0m tall — crouching Regular (0.85m) and Wizard (0.85m) fit,
## Chad (1.45m crouched) is physically blocked by pure collision. No
## character checks anywhere: the geometry is the gate.
##
##   outflow zone (extract) at (67, 0, 20)   1.0m crawl
##   concrete pipe x [59.5, 66.5], z [18.8, 21.2], under the east fence
##   culvert IN  at (60, 0, 20)              1.0m crawl
##
## The drainage outflow doubles as the Regular's extraction: crawl out,
## reach the grate, leave. Because the interior is 1.0m, Chad can never use
## it — three extractions on paper, two for Chad.

const CRAWL_H := 1.0
const CULVERT_Z := 20.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	var t := 0.4  # concrete wall thickness
	var cx := 63.0
	# The pipe: floor slab, roof slab, two side walls. Interior height is
	# exactly CRAWL_H — never touch the slabs without re-checking it.
	BuildUtils.box(root, Vector3(cx, -t * 0.5, CULVERT_Z),
		Vector3(7, t, 2.4 + 2 * t), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(cx, CRAWL_H + t * 0.5, CULVERT_Z),
		Vector3(7, t, 2.4 + 2 * t), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(cx, CRAWL_H * 0.5, CULVERT_Z - 1.2 - t * 0.5),
		Vector3(7, CRAWL_H + t, t), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(cx, CRAWL_H * 0.5, CULVERT_Z + 1.2 + t * 0.5),
		Vector3(7, CRAWL_H + t, t), BuildUtils.CONCRETE)
	BuildUtils.label(root, "DRAINAGE — KEEP CLEAR",
		Vector3(60, 2.0, CULVERT_Z), Color(0.6, 0.62, 0.68), 24)
	# A lamp at the inner mouth: the player sees the exit before they enter.
	BuildUtils.lamp(root, Vector3(60, 1.8, CULVERT_Z), Color(0.2, 1.0, 0.35),
		1.4, 6.0)
	# Extraction: the outflow mouth. Reachable only by crawling the pipe.
	BuildUtils.zone(root, game, "outflow", Vector3(67, 0, 20), 3.0)
	BuildUtils.label(root, "OUTFLOW",
		Vector3(67, 2.4, 20), Color(0.2, 1.0, 0.35), 30)
