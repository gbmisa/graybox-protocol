class_name TripZone
extends Node3D
## A place where the trip is in the world, not just on the screen (r7: "add
## areas where there are faces and eyes that appear to watch the player ...
## make it extremely unsettling"). Not surveillance — wiping the Score does
## not touch these.
##
## Inside its box, once the level's colliders exist, it scatters onto the
## walls and ceilings:
##   EYES    clusters of real eyeballs set into the surface, every one turning
##           to follow you, blinking out of step. They never stop.
##   FACES   big pale faces (tools/gen trip_face_*, sockets with eyeballs in
##           them) that only exist at the edge of your vision: they fade in
##           where you are not looking and are gone when you look straight
##           at them — then turn up somewhere else. Each one whispers.
##   BEHIND  after a while in the zone, a face appears on the wall directly
##           behind you and stays there until you turn round. Then it's gone,
##           with a sting.
## TripZone.level() (0..1, nearest zone) drives PostFx's `trip`.

const LOOK_CONE := 0.38      # radians: inside this, a face knows it is seen
const REACH := 7.0           # metres outside the box at which it starts

static var _levels: Dictionary = {}

var box: AABB
var eye_count := 30
var face_count := 4
var _eyes: Array[Node3D] = []
var _faces: Array[Dictionary] = []
var _spots: Array = []            # [position, normal] on walls
var _rng := RandomNumberGenerator.new()
var _frames := 0
var _behind_t := 10.0
var _intensity := 0.0

static func create(root: Node3D, p_box: AABB, eyes: int, faces: int, seed_v: int) -> TripZone:
	var z := TripZone.new()
	z.name = "TripZone"
	z.box = p_box
	z.eye_count = eyes
	z.face_count = faces
	z._rng.seed = seed_v
	root.add_child(z)
	return z

## The strongest any zone is pulling right now.
static func level() -> float:
	var m := 0.0
	for k in _levels:
		if is_instance_valid(k):
			m = maxf(m, float(_levels[k]))
	return m

func _exit_tree() -> void:
	_levels.erase(self)

# ------------------------------------------------------------------ build ---
func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames != 3:
		return
	var space := get_world_3d().direct_space_state
	for i in 500:
		var o := box.position + Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * box.size
		var d := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.4, 1.0), _rng.randf_range(-1, 1)).normalized()
		var q := PhysicsRayQueryParameters3D.create(o, o + d * 10.0)
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit["collider"] is CharacterBody3D:
			continue
		var p: Vector3 = hit["position"]
		var n: Vector3 = hit["normal"]
		if n.y > 0.6 or not box.grow(0.3).has_point(p):
			continue
		_spots.append([p, n])
	if _spots.is_empty():
		push_warning("TripZone at %s found no walls" % box.position)
		return
	for i in mini(eye_count, _spots.size()):
		var s: Array = _spots[_rng.randi() % _spots.size()]
		_eye_cluster(s[0], s[1], space)
	for i in face_count:
		_faces.append(TripParts.face(self, _rng))

func _eye_cluster(at: Vector3, n: Vector3, space: PhysicsDirectSpaceState3D) -> void:
	var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := n.cross(t1)
	for k in _rng.randi_range(2, 7):
		var off := t1 * _rng.randf_range(-0.7, 0.7) + t2 * _rng.randf_range(-0.6, 0.6)
		var q := PhysicsRayQueryParameters3D.create(at + off + n * 0.3, at + off - n * 0.3)
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var r := _rng.randf_range(0.04, 0.16) * (2.2 if _rng.randf() < 0.08 else 1.0)
		var e := TripParts.eyeball(self, r, Color.from_hsv(_rng.randf(), 0.8, 0.9))
		var hn: Vector3 = hit["normal"]
		e.global_position = (hit["position"] as Vector3) + hn * r * 0.35
		e.set_meta("n", hn)
		e.set_meta("blink", _rng.randf_range(1.0, 6.0))
		e.global_basis = TripParts.facing(hn)
		_eyes.append(e)

# ------------------------------------------------------------------- live ---
func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _spots.is_empty():
		return
	var head := cam.global_position
	var d := _dist_to_box(head)
	_intensity = move_toward(_intensity, clampf(1.0 - d / REACH, 0.0, 1.0), delta * 0.8)
	_levels[self] = _intensity
	if _intensity <= 0.0:
		return
	var fwd := -cam.global_basis.z
	for e in _eyes:
		_track(e, head, e.get_meta("n"), 1.3, delta)
		var b: float = e.get_meta("blink") - delta
		if b <= 0.0:
			b = _rng.randf_range(1.5, 7.0)
			var tw := e.create_tween()
			tw.tween_property(e, "scale:y", 0.06, 0.06)
			tw.tween_property(e, "scale:y", 1.0, 0.1)
		e.set_meta("blink", b)
	for f in _faces:
		_face_tick(f, head, fwd, delta)
	if d <= 0.0:
		_behind_t -= delta
		if _behind_t <= 0.0:
			_behind_t = _rng.randf_range(9.0, 18.0)
			_stalk(head, fwd)

func _track(e: Node3D, head: Vector3, n: Vector3, cone: float, delta: float) -> void:
	var to := head - e.global_position
	var want := TripParts.facing(n)
	if to.length() > 0.2 and n.angle_to(to) < cone:
		want = Basis.looking_at(to.normalized(), Vector3.UP if absf(to.normalized().y) < 0.95 else Vector3.FORWARD)
	var sc := e.scale
	var cur := e.global_basis.orthonormalized().get_rotation_quaternion()
	e.global_basis = Basis(cur.slerp(want.get_rotation_quaternion(), minf(1.0, delta * 5.0)))
	e.scale = sc

func _face_tick(f: Dictionary, head: Vector3, fwd: Vector3, delta: float) -> void:
	var node: Node3D = f["node"]
	var seen := node.visible and fwd.angle_to(node.global_position - head) < LOOK_CONE
	if not node.visible:
		f["wait"] = float(f["wait"]) - delta
		if float(f["wait"]) <= 0.0:
			_place(f, head, fwd, false)
		return
	var a: float = f["alpha"]
	if seen:
		if f["stalker"] and a > 0.4 and not f.get("stung", false):
			f["stung"] = true
			_sting(node)
		a = move_toward(a, 0.0, delta * (9.0 if f["stalker"] else 4.0))
	else:
		a = move_toward(a, 0.9 * _intensity, delta * (2.0 if f["stalker"] else 0.45))
	f["alpha"] = a
	(f["mat"] as StandardMaterial3D).albedo_color.a = a
	(f["voice"] as AudioStreamPlayer3D).volume_db = linear_to_db(maxf(a, 0.001)) - 8.0
	for e in f["eyes"]:
		_track(e, head, node.global_basis.z, 1.2, delta)
	if seen and a <= 0.02:
		node.visible = false
		(f["voice"] as AudioStreamPlayer3D).stop()
		f["wait"] = _rng.randf_range(1.5, 5.0)
		f["stalker"] = false
		f["stung"] = false

## Put a face on a wall spot the player is not looking at (or, for the
## stalker, one right behind him).
func _place(f: Dictionary, head: Vector3, fwd: Vector3, behind: bool) -> bool:
	var best: Array = []
	var best_score := -INF
	for k in 24:
		var s: Array = _spots[_rng.randi() % _spots.size()]
		var to: Vector3 = (s[0] as Vector3) - head
		if absf((s[1] as Vector3).y) > 0.5 or to.length() < 2.0 or to.length() > 16.0:
			continue
		var score := -fwd.dot(to.normalized()) if behind else (fwd.angle_to(to) - LOOK_CONE) * 2.0
		if not behind and score < 0.0:
			continue
		score -= absf(to.length() - 5.0) * 0.05
		if score > best_score:
			best_score = score
			best = s
	if best.is_empty():
		f["wait"] = 1.0
		return false
	var node: Node3D = f["node"]
	node.global_position = (best[0] as Vector3) + (best[1] as Vector3) * 0.03
	node.global_basis = Basis.looking_at(-(best[1] as Vector3), Vector3.UP)
	node.visible = true
	f["alpha"] = 0.0
	(f["voice"] as AudioStreamPlayer3D).play(_rng.randf() * 3.0)
	return true

func _stalk(head: Vector3, fwd: Vector3) -> void:
	for f in _faces:
		if not (f["node"] as Node3D).visible:
			if _place(f, head, fwd, true):
				f["stalker"] = true
			return

## Caught it: a wrong chord from where it was.
func _sting(node: Node3D) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = TripAudio.sting()
	p.unit_size = 4.0
	p.volume_db = -4.0
	node.get_parent().add_child(p)
	p.global_position = node.global_position
	p.play()
	p.finished.connect(p.queue_free)

func _dist_to_box(p: Vector3) -> float:
	var c := p.clamp(box.position, box.end)
	return c.distance_to(p)
