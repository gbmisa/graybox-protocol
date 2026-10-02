class_name GuardNav
extends RefCounted
## Walkable-space navigation for guards. Guards used to steer in straight
## lines and ran into any wall between them and the player. The level is
## built from code, so the navmesh is baked from its static colliders once the
## geometry is in (GrayboxGame.spawn_mission) and guards path along it.

const AGENT_RADIUS := 0.4
## A guard's head box tops out at 2.11 (GuardBody). At 1.8 the navmesh sent
## guards under the 2.0 portico roof, where they wedged their heads.
const AGENT_HEIGHT := 2.1
const AGENT_CLIMB := 0.4
const AGENT_SLOPE := 50.0
const CELL := 0.2
## Vertical cells. At 0.2 Recast rounded away a cell of headroom, so a 2.4
## door header read as too low for a 2.1 agent and the lobby became an island.
const CELL_H := 0.1

static var ready_map: bool = false
static var _region: NavigationRegion3D = null
static var _root: Node3D = null
static var _pending: bool = false

## Bakes `root`'s static geometry into a navmesh and registers it.
static func bake(root: Node3D) -> void:
	ready_map = false
	var nm := NavigationMesh.new()
	nm.agent_radius = AGENT_RADIUS
	nm.agent_height = AGENT_HEIGHT
	nm.agent_max_climb = AGENT_CLIMB
	nm.agent_max_slope = AGENT_SLOPE
	nm.cell_size = CELL
	nm.cell_height = CELL_H
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, root)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	# The map must use the mesh's cell size, or Godot cannot join the edges of
	# neighbouring polygons and paths break up (it warned on every bake).
	var map := root.get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, CELL)
	NavigationServer3D.map_set_cell_height(map, CELL_H)
	var region := NavigationRegion3D.new()
	region.name = "GuardNavRegion"
	region.navigation_mesh = nm
	root.add_child(region)
	_region = region
	_root = root
	ready_map = nm.get_polygon_count() > 0
	# Doors built open have their colliders switched off a frame later, after
	# this bake saw them shut; bake again once they have settled.
	request_rebake()

## A door opened or locked: re-bake in the background so guards stop pathing
## through a shut door (or round an open one). Debounced — a burst of doors
## is one bake — and it waits a beat for the doors' colliders to flip.
static func request_rebake() -> void:
	if _pending or _region == null or not is_instance_valid(_region):
		return
	_pending = true
	_region.get_tree().create_timer(0.3).timeout.connect(_rebake)

static func _rebake() -> void:
	_pending = false
	if _region == null or not is_instance_valid(_region) or _root == null \
			or not is_instance_valid(_root):
		return
	var nm := _region.navigation_mesh.duplicate() as NavigationMesh
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, _root)
	var region := _region
	NavigationServer3D.bake_from_source_geometry_data_async(nm, src, func() -> void:
		if is_instance_valid(region):
			region.navigation_mesh = nm)

## Path from `from` to `to`; empty when there is no navmesh yet.
static func path(world: World3D, from: Vector3, to: Vector3) -> PackedVector3Array:
	if not ready_map:
		return PackedVector3Array()
	var map := world.navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(map, from, to, true)
