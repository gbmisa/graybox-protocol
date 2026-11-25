class_name SecR9Grapple
extends RefCounted
## r9 (Gregory: "the grapple should be versatile and even allow the player to
## fall off the side of the map if they're not careful. Incorporate it as a
## route tool"). High places nothing but the hook reaches, each with an ammo
## cache (MissionCompoundData.CACHES) and a light you can see from below:
##
##   BILLBOARD TOP  y 24, a 1.4m service ledge along the board's top edge,
##                  10.5m over the catwalk. Hook the board's face near its top
##                  and the hook hauls you over the lip (ToolGrapple ledges).
##                  .308 for the rifle. Nothing on the campus side but air.
##   HOLLOWAY HOUSE the tower roof at 28 over the spawn street. Shells. Its
##                  west edge is the level's west boundary: step off it and
##                  you fall past the world (PlayerHealth.KILL_Y).
##   CRANE          the Consent Tower crane's jib (24.4) and counterweight
##                  (top 24.2) are solid now (SecAnnexSite): a swing line over
##                  the site and the annex's east side. Frags.

const BEACON := Color(1.0, 0.12, 0.06)

static func build(root: Node3D, _game: GrayboxGame) -> void:
	_billboard_top(root)
	_tower_roof(root)
	_crane_light(root)

static func _billboard_top(root: Node3D) -> void:
	BuildUtils.plate(root, -14.0, 14.0, 28.2, 29.6, 24.2, 0.2, BuildUtils.METAL)
	for x in [-13.8, 13.8]:
		_beacon(root, Vector3(x, 24.45, 28.9))
	BuildUtils.lamp(root, Vector3(-11.0, 25.4, 28.9), BuildUtils.LAMP_SERVICE, 0.6, 6.0)

static func _tower_roof(root: Node3D) -> void:
	# A lift-motor room and an aerial: something to aim at from the street.
	WallUtils.block(root, -30.0, -26.0, 28.0, 30.4, 188.0, 192.0, BuildUtils.CONCRETE)
	BuildUtils.box(root, Vector3(-28.0, 33.0, 190.0), Vector3(0.12, 5.2, 0.12), BuildUtils.METAL, false)
	_beacon(root, Vector3(-28.0, 35.7, 190.0))
	BuildUtils.lamp(root, Vector3(-34.0, 29.6, 186.0), BuildUtils.LAMP_SERVICE, 0.7, 8.0)

static func _crane_light(root: Node3D) -> void:
	BuildUtils.lamp(root, Vector3(21.0, 25.6, -96.0), BuildUtils.LAMP_SERVICE, 0.6, 6.0)

## A red aircraft-warning light: emissive, no light cast.
static func _beacon(root: Node3D, at: Vector3) -> void:
	var b := BuildUtils.box(root, at, Vector3(0.3, 0.3, 0.3), BEACON, false)
	var m := StandardMaterial3D.new()
	m.albedo_color = BEACON
	m.emission_enabled = true
	m.emission = BEACON
	m.emission_energy_multiplier = 3.0
	b.material_override = m
