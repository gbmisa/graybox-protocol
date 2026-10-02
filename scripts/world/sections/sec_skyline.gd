class_name SecSkyline
extends RefCounted
## The city past the boundary walls: Kenney city-kit blocks in a ring well
## outside the playable area (x beyond ±52, z beyond -48 / 204), so the
## level stops ending in black fog. No collision — nobody gets there.
## The towers' own windows are in the Kenney models; the only things added
## are aircraft-warning beacons — emissive spheres, not lights. (A scatter of
## fake lit-window boxes floated off the buildings and was cut.)

const COMMERCIAL := ["building-skyscraper-a", "building-skyscraper-b",
	"building-skyscraper-c", "building-skyscraper-d", "building-skyscraper-e",
	"low-detail-building-a", "low-detail-building-c", "low-detail-building-e",
	"low-detail-building-g", "low-detail-building-wide-a"]
const INDUSTRIAL := ["building-a", "building-c", "building-e", "chimney-large",
	"water-tower", "building-k", "building-n"]

static func build(root: Node3D, game: GrayboxGame) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 912
	# West and east flanks run the whole length of the level.
	for z in range(-94, 230, 26):
		_block(root, rng, Vector3(-62 - rng.randf_range(0, 18), 0, float(z)))
		_block(root, rng, Vector3(62 + rng.randf_range(0, 18), 0, float(z)))
	# North, past the Scoring Annex: the financial district paying for all this.
	for x in range(-50, 60, 24):
		_block(root, rng, Vector3(float(x), 0, -86 - rng.randf_range(0, 14)), true)
	# South, behind the estate.
	for x in range(-50, 60, 26):
		_block(root, rng, Vector3(float(x), 0, 218 + rng.randf_range(0, 12)))

static func _block(root: Node3D, rng: RandomNumberGenerator, pos: Vector3,
		towers: bool = false) -> void:
	var industrial := not towers and rng.randf() < 0.35
	var kit := "city_industrial" if industrial else "city_commercial"
	var pool: Array = INDUSTRIAL if industrial else COMMERCIAL
	var id := "%s/%s" % [kit, pool[rng.randi() % pool.size()]]
	var s := rng.randf_range(11.0, 16.0) if not industrial else rng.randf_range(8.0, 11.0)
	if towers:
		s *= 1.3
	var n := Props.place(root, id, pos, float(rng.randi() % 4) * 90.0, s, false)
	if n == null:
		return
	# The holder carries the scale, so these bounds are already in metres.
	var box := Props.bounds(n, Transform3D.IDENTITY)
	var top := box.size.y
	if top > 25.0:
		_beacon(root, pos + Vector3(0, top + 0.6, 0))

static var _red: StandardMaterial3D = null

static func _beacon(root: Node3D, pos: Vector3) -> void:
	if _red == null:
		_red = StandardMaterial3D.new()
		_red.albedo_color = Color(1, 0.1, 0.1)
		_red.emission_enabled = true
		_red.emission = Color(1, 0.1, 0.05)
		_red.emission_energy_multiplier = 3.0
	var b := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	b.mesh = sm
	b.material_override = _red
	b.position = pos
	root.add_child(b)
