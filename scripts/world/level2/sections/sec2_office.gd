class_name Sec2Office
extends RefCounted
## The customs office: x [-16, 16], z [-30, -14]. Single storey — 3.0m walls,
## roof slab y [3.0, 3.6] with the warded skylight. The target patrols the
## interior on three stations; close-protection guards pace around them.
##
## The low roof is load-bearing for the Wizard's vector: his final dash is
## perfectly horizontal at 3.6m (the kit zeroes vertical velocity), so the
## east wall must stay below his line — he clears the 3.0m wall by 0.6m and
## lands on the roof by the skylight.
##
## Three hard-gated entries, one per vector, each on a different side:
##   EAST SERVICE DOOR  (16, 0, -24)   [lockpick]  Regular from the yard
##   WARD SKYLIGHT      (13, 3.6, -20) [arcane]    Wizard from the dash line
##                          (off the dash axis so the flight never clips it)
##   REINFORCED WEST DOOR (-16, 0, -24) [smash]    Chad via the warehouse
##
## The 3m doors fill the 3m walls exactly — no lintels, no jump-over. The
## windows beside the east door are bars: sight-lines in, but no way in. The
## skylight drops directly onto the office floor — the only entry that
## bypasses the interior guards.
##
## No furniture: the floor must stay clear for the target's patrol and the
## guards' routes. Clutter that doesn't serve a route is clutter.

const WH := 3.0  # wall height — must stay below the Wizard's 3.6m dash line

static func build(game: GrayboxGame, root: Node3D) -> void:
	var w := BuildUtils.WALL
	var x0 := -16.0
	var x1 := 16.0
	var z0 := -30.0
	var z1 := -14.0
	var t := 0.6
	# North and south walls.
	BuildUtils.box(root, Vector3(0, WH * 0.5, z0), Vector3(32 + t, WH, t), w)
	BuildUtils.box(root, Vector3(0, WH * 0.5, z1), Vector3(32 + t, WH, t), w)
	# West wall, split around the 3m west door at z [-25.5, -22.5].
	BuildUtils.box(root, Vector3(x0, WH * 0.5, -18.25),
		Vector3(t, WH, 8.5), w)
	BuildUtils.box(root, Vector3(x0, WH * 0.5, -27.75),
		Vector3(t, WH, 4.5), w)
	# East wall, same split around the service door.
	BuildUtils.box(root, Vector3(x1, WH * 0.5, -18.25),
		Vector3(t, WH, 8.5), w)
	BuildUtils.box(root, Vector3(x1, WH * 0.5, -27.75),
		Vector3(t, WH, 4.5), w)
	# Roof: 0.6 slab, holed 2x2 over the skylight. No cap plate — a solid cap
	# would cover the hole the Wizard needs to drop through.
	# The hole sits off the dash axis (z = -20, the dash flies at z = -24)
	# so the dash never clips the seal mid-flight; the Wizard lands, walks
	# four meters, and unwards it.
	BuildUtils.slab_with_hole(root, Vector3(0, 3.3, -22),
		Vector2(32 + t, 16 + t), Vector2(13, -20), Vector2(2, 2), 0.6,
		BuildUtils.CONCRETE)
	# Interior: two lamps, signage.
	BuildUtils.lamp(root, Vector3(-6, 2.6, -22), BuildUtils.LAMP_FLUORO,
		2.0, 12.0)
	BuildUtils.lamp(root, Vector3(8, 2.6, -22), BuildUtils.LAMP_FLUORO,
		2.0, 12.0)
	BuildUtils.label(root, "CUSTOMS OFFICE — HARBORMASTER",
		Vector3(0, 2.0, z0 + 0.4), Color(0.5, 0.83, 1.0), 30)
	# The three gated entries. All three open freely from the inside
	# (exit_side): entry stays gated, nobody gets locked in.
	var east_door := LockedDoor.create(game, root, "EAST SERVICE DOOR",
		Vector3(x1, 1.5, -24), Vector3(0.6, 3, 3), ["lockpick"])
	east_door.exit_side = Vector3(-1, 0, 0)
	var west_door := BreakableWall.create(game, root, "REINFORCED WEST DOOR",
		Vector3(x0, 1.5, -24), Vector3(0.6, 3, 3))
	west_door.exit_side = Vector3(1, 0, 0)
	var sky := WardedSeal.create(game, root, "WARD SKYLIGHT",
		Vector3(13, 3.6, -20), Vector3(2, 0.6, 2))
	sky.exit_side = Vector3(0, -1, 0)  # interior is below the seal
	# Barred windows flanking the east door: see in, never enter.
	for wz in [-21.5, -26.5]:
		BuildUtils.box(root, Vector3(x1, 1.6, wz), Vector3(0.5, 2.0, 1.6),
			BuildUtils.PIPE)
		BuildUtils.label(root, "BARRED",
			Vector3(x1 + 0.4, 2.9, wz), Color(0.6, 0.62, 0.68), 20)
	BuildUtils.label(root, "EAST SERVICE — STAFF ONLY",
		Vector3(x1 + 0.4, 3.5, -24), Color(0.35, 0.70, 1.0), 26)
