class_name Player
extends CharacterBody3D
## First-person operative. This root owns shared state and orchestrates its
## components in a fixed order; it contains no gameplay logic of its own.
##
## Composition:
##   look        mouse aim, eye height, camera shake
##   movement    walk / sprint / crouch / jump / gravity, capsule resizing
##   health      hp, armor mitigation, i-frames, regen, death
##   mantle      ledge detection and climb-over
##   interactor  forward raycast, prompts, channelled use of Interactables
##   kit         the character's entire moveset (one script per operative)
##
## Ordering is explicit here rather than relying on sibling tree order, because
## mantling and dashing both need to take priority over normal movement.

signal died

var game: GrayboxGame
var char_id: String = "regular"
var char: Dictionary = {}
var armor: Dictionary = {}
var verbs: Dictionary = {}

var alive: bool = true
var mana: float = 0.0
var max_mana: float = 0.0
## Physical keys carried (KeyData ids). Doors listing "key:<id>" open for
## this player as an alternate gate — fast, silent, free.
var keys: Array[String] = []

## While > 0, the kit owns velocity and normal movement input is skipped.
## Used by the Wizard's dash.
var movement_suspend: float = 0.0

var head: Node3D
var camera: Camera3D
var collider: CollisionShape3D

var look: PlayerLook
var movement: PlayerMovement
var health: PlayerHealth
var mantle: PlayerMantle
var interactor: PlayerInteractor
var kit: KitBase

func setup(p_char_id: String, p_armor: Dictionary, p_game: GrayboxGame) -> void:
	char_id = p_char_id
	armor = p_armor
	game = p_game
	char = CharData.get_char(char_id)
	verbs = VerbData.get_verbs(char_id)
	add_to_group("player")
	if char_id == "wizard":
		max_mana = 100.0
		mana = max_mana
	_build_body()
	_build_components()

func _build_body() -> void:
	collider = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = VerbData.BODY_RADIUS
	cap.height = VerbData.STAND_H
	collider.shape = cap
	collider.position = Vector3(0, VerbData.STAND_H * 0.5, 0)
	add_child(collider)
	head = Node3D.new()
	head.position = Vector3(0, AbilityData.player()["eye_stand"], 0)
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 75.0
	camera.current = true
	head.add_child(camera)

func _build_components() -> void:
	look = PlayerLook.new()
	movement = PlayerMovement.new()
	health = PlayerHealth.new()
	mantle = PlayerMantle.new()
	interactor = PlayerInteractor.new()
	for c in [look, movement, health, mantle, interactor]:
		add_child(c)
		c.setup(self)
	health.died.connect(_on_health_died)
	kit = load(String(char["kit"])).new() as KitBase
	add_child(kit)
	kit.setup(self)

func _unhandled_input(event: InputEvent) -> void:
	if not can_act():
		return
	look.handle_input(event)

func _physics_process(delta: float) -> void:
	if not can_act():
		return
	look.tick(delta)
	health.tick(delta)
	_regen_mana(delta)
	kit.tick(delta)
	interactor.tick(delta)
	# Mantling drives position directly and bypasses physics entirely.
	if mantle.is_active():
		mantle.tick(delta)
		return
	movement.tick(delta)
	move_and_slide()

func _regen_mana(delta: float) -> void:
	if max_mana > 0.0:
		mana = minf(max_mana, mana + float(AbilityData.player()["mana_regen"]) * delta)

func can_act() -> bool:
	return alive and game != null and game.is_playing()

# ------------------------------------------------------------- forwarding ---
## Guards and explosions call this; mitigation and i-frames live in health.
func take_damage(dmg: float) -> void:
	health.take_damage(dmg)

func add_shake(amount: float) -> void:
	look.add_shake(amount)

func spend_mana(amount: float) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true

func has_verb(verb: String) -> bool:
	return bool(verbs.get(verb, false))

func has_key(id: String) -> bool:
	return keys.has(id)

func add_key(id: String) -> void:
	if not keys.has(id):
		keys.append(id)

func aim_dir() -> Vector3:
	return -camera.global_transform.basis.z

func hp() -> float:
	return health.hp

func max_hp() -> float:
	return health.max_hp

func _on_health_died() -> void:
	alive = false
	died.emit()
