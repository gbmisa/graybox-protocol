class_name GuardBody
extends Node
## Guard visuals: the figure (Humanoid), its collision capsule, the state
## indicator above its head, hit flash and the death animation.

const BASE_COLOR := Color(0.75, 0.08, 0.14)
const AIM_COLOR := Color(1.00, 0.52, 0.18)

var guard: Guard
## The head's own collider, so a shot at the head hits the head. The body
## capsule tops out at 1.75 and the head mesh spans 1.775-2.125; before this
## shape existed a headshot passed clean over the capsule and hit nothing.
var head_col: CollisionShape3D
var _indicator: Label3D
var _bark: Label3D
var _bark_t: float = 0.0
var figure: Humanoid

func setup(p_guard: Guard) -> void:
	guard = p_guard
	_build_meshes()
	_build_collision()
	_build_indicator()

func _build_meshes() -> void:
	# Security: crimson jacket, hi-vis slab, sickly green skin, cyan visor.
	# r8 (review: "guards are identical clones"): same uniform, different men —
	# build, height, skin and the helmet's paint vary per guard.
	var skins := [Color(0.62, 0.78, 0.38), Color(0.78, 0.62, 0.48), Color(0.5, 0.36, 0.26),
		Color(0.85, 0.7, 0.6), Color(0.7, 0.75, 0.55)]
	var helmets := [Color(0.98, 0.85, 0.10), Color(0.98, 0.6, 0.1), Color(0.9, 0.9, 0.2)]
	figure = Humanoid.create(guard, {
		"skin": skins[randi() % skins.size()], "top": BASE_COLOR,
		"bottom": Color(0.10, 0.10, 0.22), "accent": helmets[randi() % helmets.size()],
		"visor": Color(0.1, 0.95, 1.0), "armed": true, "bulk": randf_range(1.0, 1.35),
		"scale": randf_range(0.97, 1.03), "helmet": true, "hair": -1,
	})

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	guard.add_child(col)
	head_col = CollisionShape3D.new()
	var head := BoxShape3D.new()
	head.size = Vector3(0.36, 0.32, 0.32)
	head_col.shape = head
	head_col.position = Vector3(0, 1.95, 0)
	guard.add_child(head_col)

func _build_indicator() -> void:
	_indicator = Label3D.new()
	_indicator.position = Vector3(0, 2.4, 0)
	_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicator.no_depth_test = true
	_indicator.pixel_size = 0.01
	_indicator.font_size = 96
	_indicator.modulate = Color.YELLOW
	_indicator.visible = false
	guard.add_child(_indicator)
	_bark = Label3D.new()
	_bark.position = Vector3(0, 2.75, 0)
	_bark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark.pixel_size = 0.006
	_bark.font_size = 40
	_bark.outline_size = 10
	_bark.modulate = Color(0.95, 0.95, 0.85)
	_bark.visible = false
	guard.add_child(_bark)

## Speech over the head: satire, and a tell for where a guard is.
func say(text: String, secs: float = 3.0) -> void:
	if _bark == null or text.is_empty():
		return
	_bark.text = text
	_bark.visible = true
	_bark_t = secs

func tick(delta: float) -> void:
	if figure != null:
		figure.animate(Vector2(guard.velocity.x, guard.velocity.z).length(), delta)
	if _bark_t > 0.0:
		_bark_t -= delta
		if _bark_t <= 0.0:
			_bark.visible = false

## "?" while investigating, "!" once alerted, blank on patrol.
func set_indicator(text: String, color: Color) -> void:
	if _indicator == null:
		return
	_indicator.visible = not text.is_empty()
	_indicator.text = text
	_indicator.modulate = color

## The wind-up tell. The guard goes orange and the indicator switches to a
## reticle for the duration of the aim, which is the only cue the player gets
## that a shot is coming — and the thing the Wizard's dash is timed against.
func set_aiming(on: bool) -> void:
	if figure != null:
		figure.set_aim(on)
	if on:
		set_indicator("◎", AIM_COLOR)
		_tint(AIM_COLOR)
	else:
		set_indicator("!", Color.RED)
		_tint(BASE_COLOR)

func _tint(color: Color) -> void:
	if figure == null:
		return
	if color == BASE_COLOR:
		figure.untint()
	else:
		figure.tint(color)

func flash_hit() -> void:
	if figure != null:
		figure.flash(guard)

func play_death() -> void:
	# r8: corpses stay (Cruelty Squad: you eat them), stop falling, and drop
	# the guard's ammo.
	guard.add_to_group("corpses")
	guard.set_physics_process(false)
	AmmoPickup.drop(guard.game, guard.global_position, WeaponData.DROP)
	set_indicator("", Color.YELLOW)
	_bark.visible = false
	if figure != null:
		figure.die()

