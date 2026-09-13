class_name Projectile
extends Area3D
## Simple ballistic projectile (wizard fireball). Arcs under gravity,
## explodes on contact with the world or an enemy, dealing AoE damage.
##
## Two blast rules keep it honest:
##   * the bolt dies on the first solid it meets (walls included) — it never
##     flies through geometry;
##   * the explosion only hurts what it can "see": each victim needs a clear
##     line from the blast point to its chest, so a wall between eats the
##     blast instead of passing it through.
## A bolt that strikes a guard's head shape directly deals HEADSHOT_MULT.

var game: GrayboxGame
var vel: Vector3 = Vector3.ZERO
var fall_accel: float = 12.0
var damage: float = 35.0
var aoe_radius: float = 3.2
var life: float = 5.0
var proj_color: Color = Color(1.0, 0.45, 0.1)
var _exclude: Array = []
## Guard struck directly by this bolt (ray hit, not just splash), if any, and
## whether the ray entered through its head shape.
var _direct: Guard = null
var _direct_head: bool = false
## Set on the first explosion. queue_free() only deletes at frame end, so
## without this a bolt killed by body_entered would explode a second time on
## the next physics tick when its travel ray reaches the wall.
var _dead: bool = false

static func create(p_game: GrayboxGame, from: Vector3, dir: Vector3, speed: float,
		p_gravity: float, p_damage: float, p_aoe: float, p_color: Color,
		exclude_rids: Array = []) -> Projectile:
	var pr := Projectile.new()
	pr.game = p_game
	pr.vel = dir.normalized() * speed
	pr.fall_accel = p_gravity
	pr.damage = p_damage
	pr.aoe_radius = p_aoe
	pr.proj_color = p_color
	pr._exclude = exclude_rids
	pr.position = from
	return pr

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = proj_color
	mat.emission_enabled = true
	mat.emission = proj_color
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat
	add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	vel.y -= fall_accel * delta
	var from := global_position
	var to := from + vel * delta
	# manual wall check so we can explode exactly at the impact point
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.exclude = _exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position = hit["position"]
		var col := hit["collider"] as Node
		if col != null and col.is_in_group("guards"):
			_direct = col as Guard
			_direct_head = _direct.is_head_shape(int(hit.get("shape", -1)))
		_explode()
		return
	# direct enemy contact check (in case body_entered lags)
	for g in game.guards:
		if g.alive and g.global_position.distance_to(to) < 1.2:
			global_position = to
			_explode()
			return
	if game.target != null and game.target.alive and game.target.global_position.distance_to(to) < 1.4:
		global_position = to
		_explode()
		return
	global_position = to

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		return
	if body.is_in_group("guards"):
		_probe_direct()
	_explode()

## The Area3D overlap fires before the travel ray reaches the guard (the area
## is fatter than one frame of travel), so the ray alone would never report
## which shape was hit. Probe along the flight direction to find the shape we
## actually touched, for the headshot branch.
func _probe_direct() -> void:
	if vel.length() < 0.01:
		return
	var dir := vel.normalized()
	var q := PhysicsRayQueryParameters3D.create(
		global_position - dir * 0.6, global_position + dir * 0.6)
	q.collision_mask = 1
	q.exclude = _exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var col := hit["collider"] as Node
	if col != null and col.is_in_group("guards"):
		_direct = col as Guard
		_direct_head = _direct.is_head_shape(int(hit.get("shape", -1)))

func _explode() -> void:
	if _dead:
		return
	_dead = true
	if game == null:
		queue_free()
		return
	var pos := global_position
	_impact_flash(pos)
	for g in game.guards.duplicate():
		if not g.alive:
			continue
		if g.global_position.distance_to(pos) > aoe_radius:
			continue
		if not _blast_los(pos, g):
			continue  # behind cover: the wall eats the blast
		var dmg := damage
		if g == _direct and _direct_head:
			dmg *= Guard.HEADSHOT_MULT
		g.take_damage(dmg, pos, 35.0)
	if game.target != null and game.target.alive \
			and game.target.global_position.distance_to(pos) <= aoe_radius:
		game.target.take_damage(damage, pos)
	game.emit_noise(pos, 35.0)
	AudioSynth.play(game, "explosion")
	queue_free()

## True when nothing solid stands between the blast and the guard's chest.
## The ray runs chest -> blast (not the reverse): a blast exactly on a wall's
## face would start the reversed ray *inside* the wall, and rays that start
## inside a solid report no hit — the wall would be missed. From the chest the
## ray meets the wall's far face cleanly. The guard's own body and the caster
## are excluded; any other hit is cover.
func _blast_los(pos: Vector3, g: Guard) -> bool:
	var from := g.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, pos)
	q.collision_mask = 1
	q.exclude = [g.get_rid()] + _exclude
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

## Brief expanding flash at the impact point. Parented to the game (not the
## bolt) so it outlives the queue_free below.
func _impact_flash(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.8
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = proj_color
	mat.emission_enabled = true
	mat.emission = proj_color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.position = pos
	game.add_child(mi)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 3.0, 0.25)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.chain().tween_callback(mi.queue_free)
