class_name HUD
extends CanvasLayer
## In-game HUD. This root owns nothing but the panel list and the public API
## the rest of the game calls; every widget lives in a panel.
##
##   vitals     hp / mana bars, armor readout
##   abilities  the kit's own ability lines and cooldowns
##   feed       objective, detection meter, killfeed, centre messages
##   reticle    crosshair, hitmarker, damage vignette
##   prompt     interaction prompt and channel progress
##
## Runs with PROCESS_MODE_ALWAYS so it keeps drawing while the tree is paused.

var game: GrayboxGame = null
var player: Player = null

var vitals: HudVitals
var abilities: HudAbilities
var feed: HudFeed
var reticle: HudReticle
var prompt: HudPrompt

var _panels: Array[HudPanel] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.name = "hud_root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	vitals = HudVitals.new()
	abilities = HudAbilities.new()
	feed = HudFeed.new()
	reticle = HudReticle.new()
	prompt = HudPrompt.new()
	_panels = [vitals, abilities, feed, reticle, prompt]
	for p in _panels:
		add_child(p)
		p.setup(self, root)

func setup(p_game: GrayboxGame, p_player: Player) -> void:
	game = p_game
	player = p_player
	for p in _panels:
		p.on_player_changed()

func _process(delta: float) -> void:
	for p in _panels:
		p.tick(delta)

## True when the panels should read live mission state.
func is_live() -> bool:
	return game != null and player != null and game.is_playing()

# ------------------------------------------------------------ public API ---
func show_hitmarker() -> void:
	reticle.show_hitmarker()

func flash_damage() -> void:
	reticle.flash_damage()

func add_killfeed(text: String) -> void:
	feed.add_killfeed(text)

func set_objective(text: String) -> void:
	feed.set_objective(text)

func show_message(text: String, dur: float = 2.5) -> void:
	feed.show_message(text, dur)

func show_prompt(text: String, usable: bool, progress: float) -> void:
	prompt.show_prompt(text, usable, progress)

func hide_prompt() -> void:
	prompt.hide_prompt()
