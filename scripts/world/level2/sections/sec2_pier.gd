class_name Sec2Pier
extends RefCounted
## Pier district (east-center): x[25,75], z[-30,25] on land, the pier deck
## x[45,60], z[5,45] overhanging the water.
##
## The PIER GATE [lockpick | key:pier_key] seals the deck at its root (z=5).
## The fence runs x[40,65] so the gate can't be walked around on land;
## railings (1.1m) on the water sides stop wading up onto the deck.
## The dock office holds the pier key and a complaint note (optional intel).

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_dock_office(game, root)
	_build_pier_deck(game, root)
	_build_vessel(root)
	BuildUtils.label(root, "PIER 9", Vector3(52, 6.0, 20), Color(1.0, 0.84, 0.37), 48)

static func _build_dock_office(game: GrayboxGame, root: Node3D) -> void:
	# Hut x[52,58], z[-17.5,-12.5], 3m walls, open door on the west side.
	var c := Color(0.34, 0.36, 0.40)
	BuildUtils.box(root, Vector3(55, 1.5, -17.5), Vector3(6, 3, 0.4), c)
	BuildUtils.box(root, Vector3(55, 1.5, -12.5), Vector3(6, 3, 0.4), c)
	BuildUtils.box(root, Vector3(58, 1.5, -15), Vector3(0.4, 3, 5), c)
	# West wall with a 1.4m open door.
	BuildUtils.box(root, Vector3(52, 1.5, -16.4), Vector3(0.4, 3, 1.6), c)
	BuildUtils.box(root, Vector3(52, 1.5, -13.6), Vector3(0.4, 3, 1.6), c)
	BuildUtils.box(root, Vector3(52, 2.7, -15), Vector3(0.4, 0.6, 2.0), c)
	BuildUtils.box(root, Vector3(55, 3.2, -15), Vector3(6.4, 0.4, 5.4),
		Color(0.26, 0.28, 0.32))
	BuildUtils.label(root, "DOCK OFFICE", Vector3(55, 4.0, -15), Color(0.62, 0.64, 0.68), 32)
	# The pier key + a dockworker's complaint (optional intel).
	KeyItem.create(game, root, "pier_key", Vector3(54, 0, -16))
	IntelPickup.create(game, root, "complaint", Vector3(56.5, 0, -14))

static func _build_pier_deck(game: GrayboxGame, root: Node3D) -> void:
	# Deck plate x[45,60], z[5,45], top at y=0. Piles down into the water.
	BuildUtils.box(root, Vector3(52.5, -0.3, 25), Vector3(15, 0.6, 40),
		Color(0.30, 0.26, 0.20))
	for px in [46.0, 52.5, 59.0]:
		for pz in [10.0, 25.0, 40.0]:
			BuildUtils.box(root, Vector3(px, -1.0, pz), Vector3(0.5, 2.0, 0.5),
				BuildUtils.PIPE)
	# The gate fence: z=5, x[40,65], 3m tall. Gate [lockpick | key:pier_key].
	var fence_c := Color(0.25, 0.27, 0.30)
	for seg in [[40.0, 50.5], [53.5, 65.0]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		BuildUtils.box(root, Vector3((x0 + x1) * 0.5, 1.5, 5),
			Vector3(x1 - x0, 3.0, 0.25), fence_c)
	var gate := LockedDoor.create(game, root, "PIER GATE",
		Vector3(52, 1.5, 5), Vector3(3.0, 3.0, 0.3),
		["lockpick", "key:pier_key"])
	gate.exit_side = Vector3(0, 0, 1)  # free exit from the deck side
	BuildUtils.label(root, "PIER GATE — LOCKPICK OR KEY", Vector3(52, 3.8, 5), Color(0.35, 0.70, 1.00), 30)
	# Railings on the water sides: 1.1m, so the deck can't be mantled
	# from the water (0.8m step + 1.1m rail > 1.2m mantle).
	var rail_c := Color(0.50, 0.52, 0.55)
	BuildUtils.box(root, Vector3(45, 0.55, 35), Vector3(0.15, 1.1, 20), rail_c)
	BuildUtils.box(root, Vector3(60, 0.55, 35), Vector3(0.15, 1.1, 20), rail_c)
	BuildUtils.box(root, Vector3(52.5, 0.55, 45), Vector3(15, 1.1, 0.15), rail_c)
	# Deck lamps.
	BuildUtils.lamp(root, Vector3(47, 4.5, 15), BuildUtils.LAMP_SERVICE)
	BuildUtils.lamp(root, Vector3(58, 4.5, 35), BuildUtils.LAMP_SERVICE)
	# Boat extraction at the deck's south end.
	BuildUtils.label(root, "EXTRACTION — BOAT", Vector3(52.5, 2.5, 42), Color(0.35, 1.0, 0.45), 36)
	BuildUtils.zone(root, game, "boat", Vector3(52.5, 0, 42), 4.0)

static func _build_vessel(root: Node3D) -> void:
	# Moored vessel alongside the pier (east). Scenery with a lit cabin.
	var hull_c := Color(0.22, 0.24, 0.28)
	BuildUtils.box(root, Vector3(68, -0.5, 35), Vector3(6, 2.0, 14), hull_c)
	BuildUtils.box(root, Vector3(68, 0.8, 31), Vector3(4, 1.6, 4),
		Color(0.30, 0.32, 0.36))
	# Cabin windows (emissive strip).
	var win := MeshInstance3D.new()
	var wbm := BoxMesh.new()
	wbm.size = Vector3(4.1, 0.5, 4.1)
	win.mesh = wbm
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(1.0, 0.85, 0.55)
	wmat.emission_enabled = true
	wmat.emission = Color(1.0, 0.85, 0.55)
	wmat.emission_energy_multiplier = 1.5
	win.material_override = wmat
	win.position = Vector3(68, 1.1, 31)
	root.add_child(win)
	# Mooring lines to the pier.
	for mz in [30.0, 40.0]:
		BuildUtils.box(root, Vector3(64, 0.2, mz),
			Vector3(8.0, 0.08, 0.08), Color(0.15, 0.13, 0.10), false)
	BuildUtils.label(root, "M/V GRAY MANIFEST", Vector3(68, 3.2, 35), Color(0.62, 0.64, 0.68), 28)
