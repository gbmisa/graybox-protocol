class_name SecStreet
extends RefCounted
## Ground-level exterior: the approach, the perimeter, and the three route
## entrances. This is the only place all three operatives share.
##
## Coordinates (see level_builder.gd for the full floor plan):
##   tower footprint   x [-30, 30]  z [-40, 10]
##   spawn             (0, 0, 70)
##   culvert mouth     (-50, 0, 52)   REGULAR — 1.0m crawl
##   warded gate       (0, 0, 40)     WIZARD  — arcane only
##   dock shutter      (50, 0, 40)    CHAD    — smash only
##   van extraction    (-72, 0, 60)

const FENCE_H := 8.0

static func build(root: Node3D, game: GrayboxGame) -> void:
	_environment(root)
	_ground(root)
	_perimeter(root)
	_culvert_mouth(root)
	_van(root, game)
	_signage(root)

static func _environment(root: Node3D) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.52, 0.64)
	env.ambient_light_energy = 1.15
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color(0.78, 0.85, 1.0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	root.add_child(sun)
	# The culvert and the ramp below it are the darkest approach in the game.
	BuildUtils.lamps(root, [
		Vector3(-50, 0.8, 50), Vector3(-50, 0.8, 43),
		Vector3(-50, 0.6, 37), Vector3(-50, -1.6, 31),
	], BuildUtils.LAMP_SERVICE, 2.2, 11.0)

## Built as two halves so each can carry its own opening: the west half is cut
## for the culvert descent trench, the east half for the tower footprint (which
## the interior floors and the service stairwell occupy).
static func _ground(root: Node3D) -> void:
	# Hole matches the descent trench walls exactly, so there is no gap beside
	# them to slip down.
	BuildUtils.slab_with_hole(root, Vector3(-65, -0.5, 12.5), Vector2(70, 160),
		Vector2(-50, 34), Vector2(4.6, 12), 1.0, BuildUtils.STREET)
	BuildUtils.slab_with_hole(root, Vector3(35, -0.5, 12.5), Vector2(130, 160),
		Vector2(0, -15), Vector2(60, 50), 1.0, BuildUtils.STREET)

static func _perimeter(root: Node3D) -> void:
	var c := BuildUtils.WALL_DARK
	var y := FENCE_H * 0.5
	BuildUtils.box(root, Vector3(-85, y, 12), Vector3(1, FENCE_H, 152), c)
	BuildUtils.box(root, Vector3(85, y, 12), Vector3(1, FENCE_H, 152), c)
	BuildUtils.box(root, Vector3(0, y, 88), Vector3(171, FENCE_H, 1), c)
	BuildUtils.box(root, Vector3(0, y, -62), Vector3(171, FENCE_H, 1), c)

## The Regular's entrance: a 1.0m crawl through a solid embankment, then an
## enclosed ramp down to the undercroft.
##
## This must be a hole THROUGH a mass, never a pipe lying on open ground. The
## first version was a free-standing box with a 1.4m roof, and since a standing
## jump clears 1.84m you could climb on top, walk over the crawl, and drop into
## the open trench beyond — defeating the one hard gate that is supposed to be
## enforced by collision alone. Everything here exists to close that: the slot
## above the culvert is filled, the trench is roofed, and the only opening in
## the whole structure is the 1.0m mouth at z = 52.
static func _culvert_mouth(root: Node3D) -> void:
	var dark := BuildUtils.WALL_DARK
	var conc := BuildUtils.CONCRETE
	BuildUtils.tunnel(root, Vector3(-50, 0, 52), Vector3(-50, 0, 40),
		1.0, 1.6, conc)
	# Embankment shoulders either side, 4m tall.
	BuildUtils.box(root, Vector3(-58, 2.0, 40), Vector3(14, 4, 28), dark)
	BuildUtils.box(root, Vector3(-42, 2.0, 40), Vector3(14, 4, 28), dark)
	# Fill the slot directly above the culvert roof — this is the bypass.
	BuildUtils.box(root, Vector3(-50, 2.7, 46), Vector3(2, 2.6, 16), dark)
	_descent(root, dark, conc)

## Enclosed ramp from the culvert down to the undercroft floor at y = -4.
## The ceiling stays flat while the floor drops, so the passage opens out from
## crawl height into full height as you go — and is sealed from above.
static func _descent(root: Node3D, dark: Color, conc: Color) -> void:
	BuildUtils.ramp(root, Vector3(-50, -4, 28), Vector3(0, 0, 1),
		12.0, 4.0, 4.0, conc)
	BuildUtils.box(root, Vector3(-52.3, 0, 34), Vector3(0.6, 8, 12), dark)
	BuildUtils.box(root, Vector3(-47.7, 0, 34), Vector3(0.6, 8, 12), dark)
	BuildUtils.box(root, Vector3(-50, 2.6, 34), Vector3(4.6, 2.8, 12), dark)

static func _van(root: Node3D, game: GrayboxGame) -> void:
	BuildUtils.box(root, Vector3(-72, 1.5, 60), Vector3(6, 3, 2.5), Color(0.12, 0.5, 0.2))
	BuildUtils.box(root, Vector3(-72, 0.5, 60), Vector3(6.5, 1, 3), Color(0.1, 0.1, 0.12))
	BuildUtils.label(root, "EXTRACTION — VAN", Vector3(-72, 5.5, 60), BuildUtils.GREEN)
	BuildUtils.zone(root, game, "van", Vector3(-72, 0, 60), 4.5)

static func _signage(root: Node3D) -> void:
	BuildUtils.label(root, "MERIDIAN CAPITAL — QUARTERLY OFFSITE",
		Vector3(0, 12, 76), BuildUtils.GOLD, 72)
	BuildUtils.label(root, "STORM DRAIN — CRAWL ONLY\n[ THE REGULAR ]",
		Vector3(-50, 5.5, 54), Color(0.35, 0.70, 1.0), 44)
	BuildUtils.label(root, "WARDED GATE\n[ THE WIZARD ]",
		Vector3(0, 7.5, 42), Color(0.72, 0.40, 1.0), 44)
	BuildUtils.label(root, "LOADING DOCK\n[ GIGA CHAD ]",
		Vector3(50, 7.5, 42), Color(1.0, 0.52, 0.18), 44)
