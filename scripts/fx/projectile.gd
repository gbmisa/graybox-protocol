class_name Projectile
extends Area3D
## Simple ballistic projectile (wizard fireball). Arcs under gravity,
## explodes on contact with the world or an enemy, dealing AoE damage.

var game: GrayboxGame
var vel: Vector3 = Vector3.ZERO
var fall_accel: float = 12.0
var damage: float = 35.0
var aoe_radius: float = 3.2
var life: float = 5.0
var proj_color: Color = Color(1.0, 0.45, 0.1)
var _exclude: Array = []

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
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	vel.y -= fall_accel * delta
	var from := global_position
	var to := from + vel * delta
	# manual wall check so we can explode exactly at the impact point
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = _exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position = hit["position"]
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
	_explode()

func _explode() -> void:
	if game == null:
		queue_free()
		return
	var pos := global_position
	for g in game.guards.duplicate():
		if g.alive and g.global_position.distance_to(pos) <= aoe_radius:
			g.take_damage(damage, pos)
	if game.target != null and game.target.alive \
			and game.target.global_position.distance_to(pos) <= aoe_radius:
		game.target.take_damage(damage, pos)
	game.emit_noise(pos, 35.0)
	AudioSynth.play(game, "explosion")
	queue_free()
