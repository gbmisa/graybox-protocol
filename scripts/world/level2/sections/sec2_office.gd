class_name Sec2Office
extends RefCounted
## The customs office: exterior x[-20,14], z[-32,-8], 3.0m walls, roof slab
## y[3.0,3.6]. Roughly CENTRAL in the district; the Harbormaster patrols
## the interior on three stations.
##
## FOUR gated entries, one per side, every one taking all three verbs
## (lockpick: slow/silent, arcane: mana, smash: fast/LOUD):
##   FRONT DOOR   (-4,0,-8)     south — the direct approach
##   SERVICE DOOR (14,0,-20)    east  — the water-side approach
##   WEST DOOR    (-20,0,-14)   west  — the terminal approach
##   SKYLIGHT     (0,3.6,-14)   roof  — the vertical approach
## plus a 1.0m crawl VENT through the north wall (non-Chad shortcut).
## All five open freely from the inside (exit_side): entry stays gated,
## nobody gets locked in.
##
## The SAFE ROOM is physical: hardened walls in the NE interior corner
## (interior x[6.5,13.7], z[-31.7,-23.0]), ONE three-verb door on its west
## wall, room for the target plus two bodyguards. Anchor (10,0,-28).
##
## Roof access two ways: a walkable ramp up the west face (everyone), and
## a dash-gap shortcut from the west platform (6.7m — beyond the 4.74m
## jump, inside the 9.1m dash; Wizard-flavored, never required).

const WH := 3.0
const T := 0.6

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_walls(root)
	_build_doors(game, root)
	_build_roof(root)
	_build_vent(root)
	_build_safe_room(game, root)
	_build_roof_access(game, root)
	_build_dressing(game, root)

static func _build_walls(root: Node3D) -> void:
	var w := BuildUtils.WALL
	# North wall (z=-32) with the vent notch x[-11.2,-8.8]; the tunnel's
	# own ceiling caps it, a header sits on the ceiling (no overlaps).
	BuildUtils.box(root, Vector3(-15.75, WH * 0.5, -32),
		Vector3(9.1, WH, T), w)
	BuildUtils.box(root, Vector3(2.75, WH * 0.5, -32),
		Vector3(23.1, WH, T), w)
	BuildUtils.box(root, Vector3(-10, 2.2, -32),
		Vector3(2.4, 1.6, T), w)
	# South wall (z=-8) split around the 2m front door at x[-5,-3].
	BuildUtils.box(root, Vector3(-12.65, WH * 0.5, -8),
		Vector3(15.3, WH, T), w)
	BuildUtils.box(root, Vector3(5.65, WH * 0.5, -8),
		Vector3(17.3, WH, T), w)
	# West wall (x=-20) split around the 2m west door at z[-15,-13].
	BuildUtils.box(root, Vector3(-20, WH * 0.5, -23.65),
		Vector3(T, WH, 17.3), w)
	BuildUtils.box(root, Vector3(-20, WH * 0.5, -10.35),
		Vector3(T, WH, 5.3), w)
	# East wall (x=14) split around the 2m service door at z[-21,-19].
	BuildUtils.box(root, Vector3(14, WH * 0.5, -26.65),
		Vector3(T, WH, 11.3), w)
	BuildUtils.box(root, Vector3(14, WH * 0.5, -13.35),
		Vector3(T, WH, 11.3), w)

static func _build_doors(game: GrayboxGame, root: Node3D) -> void:
	var verbs := ["lockpick", "arcane", "smash"]
	var front := LockedDoor.create(game, root, "FRONT DOOR",
		Vector3(-4, 1.5, -8), Vector3(2.0, 3.0, 0.6), verbs)
	front.exit_side = Vector3(0, 0, -1)
	var east := LockedDoor.create(game, root, "SERVICE DOOR",
		Vector3(14, 1.5, -20), Vector3(0.6, 3.0, 2.0), verbs)
	east.exit_side = Vector3(-1, 0, 0)
	var west := LockedDoor.create(game, root, "WEST DOOR",
		Vector3(-20, 1.5, -14), Vector3(0.6, 3.0, 2.0), verbs)
	west.exit_side = Vector3(1, 0, 0)
	var sky := LockedDoor.create(game, root, "SKYLIGHT HATCH",
		Vector3(0, 3.6, -14), Vector3(2.0, 0.6, 2.0),
		["lockpick", "arcane", "smash", "key:roof_key"])
	sky.exit_side = Vector3(0, -1, 0)  # interior is below the hatch
	BuildUtils.label(root, "FRONT DOOR", Vector3(-4, 3.7, -8),
		Color(0.35, 0.70, 1.0), 24)
	BuildUtils.label(root, "SERVICE DOOR", Vector3(14.7, 3.7, -20),
		Color(0.35, 0.70, 1.0), 24)
	BuildUtils.label(root, "WEST DOOR", Vector3(-20.7, 3.7, -14),
		Color(0.35, 0.70, 1.0), 24)
	BuildUtils.label(root, "SKYLIGHT", Vector3(0, 4.7, -14),
		Color(0.35, 0.70, 1.0), 24)

static func _build_roof(root: Node3D) -> void:
	# 0.6 slab, top at 3.6, holed 2x2 over the skylight.
	BuildUtils.slab_with_hole(root, Vector3(-3, 3.3, -20),
		Vector2(34.6, 24.6), Vector2(0, -14), Vector2(2, 2), 0.6,
		BuildUtils.CONCRETE)

static func _build_vent(root: Node3D) -> void:
	# 1.0m crawl through the north wall: x=-10, z[-33.8,-30.2]. The Regular
	# and Wizard clear it at 0.85m crouched; Chad (1.45m) is blocked by
	# pure collision. A shortcut — never a required path.
	BuildUtils.tunnel(root, Vector3(-10, 0, -33.8), Vector3(-10, 0, -30.2),
		1.0, 1.6, BuildUtils.CONCRETE)
	BuildUtils.label(root, "VENT — 1M", Vector3(-10, 2.2, -34.5),
		Color(0.6, 0.62, 0.68), 22)

static func _build_safe_room(game: GrayboxGame, root: Node3D) -> void:
	# Hardened room, NE interior. North/east walls are the office's own;
	# west + south are 0.4m hardened walls. ONE door on the west wall.
	var h := Color(0.26, 0.27, 0.31)
	BuildUtils.box(root, Vector3(6.3, 1.5, -29.375),
		Vector3(1.0, 3.0, 5.25), h)
	BuildUtils.box(root, Vector3(6.3, 1.5, -23.925),
		Vector3(1.0, 3.0, 2.65), h)
	BuildUtils.box(root, Vector3(10.0, 1.5, -23.2),
		Vector3(8.0, 3.0, 1.0), h)
	var door := LockedDoor.create(game, root, "SAFE ROOM DOOR",
		Vector3(6.3, 1.5, -26), Vector3(1.0, 3.0, 1.5),
		["lockpick", "arcane", "smash"])
	door.exit_side = Vector3(1, 0, 0)  # free exit from inside
	BuildUtils.lamp(root, Vector3(9.9, 2.6, -27), BuildUtils.LAMP_SERVICE,
		1.6, 8.0)
	BuildUtils.label(root, "SAFE ROOM", Vector3(6.3, 3.4, -26),
		Color(1.0, 0.45, 0.25), 24)

static func _build_roof_access(game: GrayboxGame, root: Node3D) -> void:
	var plat := Color(0.42, 0.44, 0.48)
	# The walkable way: 14m run, 3.6m rise, lands flush on the roof's
	# west edge. Everyone climbs it.
	BuildUtils.ramp(root, Vector3(-34, 0, -12), Vector3(1, 0, 0),
		14.0, 3.6, 3.0, plat)
	# The shortcut: ramp to a platform, then a 6.7m dash to the roof.
	# Jump-only (4.74m) falls short; the 9.1m dash clears it. The platform
	# sits 0.9m above the roof so the dash's fall still lands on top.
	BuildUtils.ramp(root, Vector3(-44, 0, -23), Vector3(1, 0, 0),
		8.0, 4.5, 2.5, plat)
	BuildUtils.box(root, Vector3(-34, 4.35, -23),
		Vector3(4.0, 0.3, 2.5), plat)  # walkway x[-36,-32]
	for lx in [-35.0, -33.0]:
		BuildUtils.box(root, Vector3(lx, 2.1, -23),
			Vector3(0.4, 4.2, 0.4), BuildUtils.PIPE)
	BuildUtils.box(root, Vector3(-29.5, 3.9, -23),
		Vector3(5.0, 1.2, 6.0), plat)  # P1 x[-32,-27], top 4.5
	for lx in [-31.0, -28.0]:
		for lz in [-24.5, -21.5]:
			BuildUtils.box(root, Vector3(lx, 1.65, lz),
				Vector3(0.5, 3.3, 0.5), BuildUtils.PIPE)
	BuildUtils.label(root, "DASH >", Vector3(-29.5, 4.4, -23),
		Color(0.72, 0.40, 1.0), 36)
	# The roof key rides the dash platform — the vertical approach earns
	# the skylight shortcut. Offset north of the dash line so it never
	# blocks the corridor or the tested headroom point.
	KeyItem.create(game, root, "roof_key", Vector3(-29.5, 4.6, -21))

static func _build_dressing(game: GrayboxGame, root: Node3D) -> void:
	# Interior: two lamps. Floor stays clear for patrols.
	BuildUtils.lamp(root, Vector3(-10, 2.6, -14), BuildUtils.LAMP_FLUORO,
		2.0, 12.0)
	BuildUtils.lamp(root, Vector3(0, 2.6, -26), BuildUtils.LAMP_FLUORO,
		2.0, 12.0)
	BuildUtils.label(root, "CUSTOMS OFFICE — HARBORMASTER",
		Vector3(-3, 2.2, -7.5), Color(0.5, 0.83, 1.0), 30)
	# Barred windows flanking the front door: sight-lines in, no way in.
	for wx in [-8.0, 0.0]:
		BuildUtils.box(root, Vector3(wx, 1.6, -7.6),
			Vector3(1.6, 2.0, 0.3), BuildUtils.PIPE)
		BuildUtils.label(root, "BARRED", Vector3(wx, 3.0, -7.5),
			Color(0.6, 0.62, 0.68), 18)
