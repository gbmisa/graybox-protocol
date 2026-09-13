class_name Sec2Culvert
extends RefCounted
## The east drainage culvert: the Regular's vector.
##
## A concrete pipe running north-south under the north fence at x = 70,
## from the outflow (outside, z=-66) to the inner mouth (z=-56). The crawl
## interior is EXACTLY 1.0m tall — crouching Regular (0.85m) and Wizard
## (0.85m) fit, Chad (1.45m crouched) is physically blocked by pure
## collision. No character checks anywhere: the geometry is the gate.
##
## The drainage outflow doubles as the crawl-only extraction: crawl out,
## reach the grate, leave. Because the interior is 1.0m, Chad can never
## use it — three extractions on paper, two for Chad.

const CRAWL_H := 1.0
const CULVERT_X := 70.0

static func build(game: GrayboxGame, root: Node3D) -> void:
	var t := 0.4  # concrete wall thickness
	var cz := -61.0  # pipe center: z[-66,-56]
	var length := 10.0
	var iw := 1.6  # interior width
	# The pipe: floor slab, roof slab, two side walls. Interior height is
	# exactly CRAWL_H — never touch the slabs without re-checking it.
	BuildUtils.box(root, Vector3(CULVERT_X, -t * 0.5, cz),
		Vector3(iw + 2 * t, t, length), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(CULVERT_X, CRAWL_H + t * 0.5, cz),
		Vector3(iw + 2 * t, t, length), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(CULVERT_X - iw * 0.5 - t * 0.5, CRAWL_H * 0.5, cz),
		Vector3(t, CRAWL_H + t, length), BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(CULVERT_X + iw * 0.5 + t * 0.5, CRAWL_H * 0.5, cz),
		Vector3(t, CRAWL_H + t, length), BuildUtils.CONCRETE)
	BuildUtils.label(root, "DRAINAGE — KEEP CLEAR",
		Vector3(CULVERT_X, 2.2, -56), Color(0.6, 0.62, 0.68), 24)
	# A lamp at the inner mouth: the player sees the exit before they enter.
	BuildUtils.lamp(root, Vector3(CULVERT_X, 1.8, -56), Color(0.2, 1.0, 0.35),
		1.4, 6.0)
	# The fence lintel above the pipe is built by Sec2Perimeter; the notch
	# x[68,72] is sealed here: concrete fill on both sides of the pipe from
	# the ground up to the lintel (y=1.6). No 0.8m squeeze gaps remain.
	BuildUtils.box(root, Vector3(68.4, 0.8, -60), Vector3(0.8, 1.6, 0.6),
		BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(71.6, 0.8, -60), Vector3(0.8, 1.6, 0.6),
		BuildUtils.CONCRETE)
	# Extraction: the outflow mouth. Reachable only by crawling the pipe.
	BuildUtils.zone(root, game, "outflow", Vector3(CULVERT_X, 0, -68), 3.0)
	BuildUtils.label(root, "OUTFLOW — EXTRACTION (CRAWL)",
		Vector3(CULVERT_X, 2.4, -68), Color(0.2, 1.0, 0.35), 30)
