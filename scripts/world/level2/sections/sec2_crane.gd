class_name Sec2Crane
extends RefCounted
## The far-east crane zone: x[75,105], z[-30,25].
##
## CRANE 2 is visibly dilapidated — the geometry sells the gag, not the sign:
## a leaning tower, a jib collapsed nose-down, a snapped cable dangling to
## the dirt, a cracked counterweight, rust tones, and a debris field. The
## storage key sits by a crate here (guarded).

static func build(game: GrayboxGame, root: Node3D) -> void:
	_build_crane(root)
	_build_debris(root)
	KeyItem.create(game, root, "storage_key", Vector3(88, 0, 8))
	BuildUtils.label(root, "CRANE 2 — OUT OF SERVICE SINCE 2019",
		Vector3(88, 3.4, 2.5), Color(1.0, 0.45, 0.25), 40)
	BuildUtils.label(root, "FAR EAST — DEAD CRANE", Vector3(90, 7.0, -18), Color(1.0, 0.84, 0.37), 44)
	BuildUtils.lamp(root, Vector3(88, 6.0, 8), Color(1.0, 0.7, 0.4), 1.2, 18.0)

## A solid box whose collision rotates WITH the mesh (BuildUtils.box splits
## them, which is wrong for tilted wreckage).
static func _part(root: Node3D, pos: Vector3, size: Vector3, color: Color,
		rot: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = BuildUtils.mat(color)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)

static func _build_crane(root: Node3D) -> void:
	var rust := Color(0.48, 0.26, 0.13)
	var rust_dark := Color(0.36, 0.19, 0.10)
	var steel := Color(0.30, 0.31, 0.34)
	# Concrete pedestal, slightly settled (2° list).
	_part(root, Vector3(88, 1.0, 0), Vector3(4.5, 2.0, 4.5),
		BuildUtils.CONCRETE, Vector3(0, 4, 2))
	# Tower: 14m, leaning 7° east and 3° south — the first thing that reads
	# "this machine is not okay".
	_part(root, Vector3(88.9, 9.0, 0.4), Vector3(1.6, 14.0, 1.6), rust,
		Vector3(3, 0, -7))
	# Operator cab with a dark window band, riding the lean.
	_part(root, Vector3(89.8, 8.2, 0.5), Vector3(2.6, 2.2, 2.6), rust_dark,
		Vector3(3, 0, -7))
	BuildUtils.box(root, Vector3(90.4, 8.5, 0.5), Vector3(1.4, 0.8, 2.7),
		Color(0.08, 0.10, 0.14), false)
	# Jib: collapsed nose-down 28° instead of level — hydraulics gave out.
	# Root at the tower top, tip nearly touching the dirt to the east.
	_part(root, Vector3(94.5, 13.2, 0.6), Vector3(13.0, 1.0, 1.0), rust,
		Vector3(0, 0, -28))
	# The break: the last 4m snapped off and dangles, twisted 40°.
	_part(root, Vector3(99.8, 8.6, 0.7), Vector3(4.2, 0.8, 0.8), rust_dark,
		Vector3(0, 0, -68))
	# Snapped cable: thin segments from the break down to the ground, with
	# a loose coil where it landed.
	_part(root, Vector3(100.6, 6.0, 0.7), Vector3(0.09, 5.0, 0.09),
		Color(0.12, 0.12, 0.13), Vector3(0, 0, 6))
	_part(root, Vector3(100.9, 3.2, 0.7), Vector3(0.09, 2.6, 0.09),
		Color(0.12, 0.12, 0.13), Vector3(0, 0, -14))
	BuildUtils.box(root, Vector3(101.2, 0.25, 0.7), Vector3(1.6, 0.5, 1.6),
		Color(0.14, 0.13, 0.12))
	# Counter-jib (west) with a CRACKED counterweight: two halves, split.
	_part(root, Vector3(84.8, 15.2, 0.3), Vector3(5.0, 0.9, 0.9), rust,
		Vector3(0, 0, 6))
	_part(root, Vector3(82.6, 14.2, 0.3), Vector3(1.4, 1.8, 1.6),
		BuildUtils.CONCRETE, Vector3(0, 0, -12))
	_part(root, Vector3(82.6, 12.3, 0.3), Vector3(1.4, 1.6, 1.6),
		BuildUtils.CONCRETE, Vector3(0, 0, 9))

static func _build_debris(root: Node3D) -> void:
	# Debris field: fallen panels, a cable spool, scattered crates.
	var junk := Color(0.30, 0.22, 0.15)
	_part(root, Vector3(93, 0.3, 6), Vector3(3.2, 0.6, 1.8), junk,
		Vector3(0, 24, 0))
	_part(root, Vector3(85, 0.4, -3), Vector3(2.4, 0.8, 2.0), junk,
		Vector3(0, -18, 0))
	BuildUtils.box(root, Vector3(91, 0.5, -8), Vector3(2.0, 1.0, 2.0), junk)
	BuildUtils.box(root, Vector3(95, 0.5, 10), Vector3(1.6, 1.0, 1.6), junk)
	# The key crate and the intel crate.
	BuildUtils.box(root, Vector3(88, 0.5, 8), Vector3(2.0, 1.0, 2.0),
		Color(0.42, 0.32, 0.20))
	BuildUtils.box(root, Vector3(84, 0.5, -6), Vector3(2.0, 1.0, 2.0),
		Color(0.42, 0.32, 0.20))
	# Cable spool on its side.
	_part(root, Vector3(80, 0.8, 10), Vector3(1.6, 1.6, 1.2),
		Color(0.35, 0.24, 0.14), Vector3(0, 0, 90))
