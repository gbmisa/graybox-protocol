class_name ScreenCredits
extends ScreenBase
## Who made the things this game is made of. Everything third-party is CC0
## (no credit required) — credited anyway. Full list: ASSETS.md.

const LINES := [
	["GAME", "Gregory Milligan — design, direction, playtesting"],
	["", "Built with Claude Code"],
	["ENGINE", "Godot Engine 4 — godotengine.org (MIT)"],
	["MODELS · UI · SOUND", "Kenney — kenney.nl (CC0): Car, City (Commercial, Industrial,\nSuburban), Retro Urban, Survival, Furniture and Blaster kits;\nInterface, Impact and Sci-Fi sounds; Kenney Fonts"],
	["FIRST-PERSON ARMS", "WRAD ARMS by wriks — wriks.itch.io/wrad-arms (CC0)"],
	["TEXTURES", "Poly Haven — polyhaven.com (CC0)"],
	["", "Satire. Any resemblance to a real consent score is the point."],
]

func backdrop_color() -> Color:
	return Color(0.02, 0.025, 0.04, 0.88)

func build() -> void:
	var v := column(12)
	center.add_child(v)
	v.add_child(title("CREDITS", 44))
	for row_data in LINES:
		if String(row_data[0]) != "":
			v.add_child(text(String(row_data[0]), 14, UiTheme.AMBER))
		v.add_child(text(String(row_data[1]), 18, UiTheme.INK))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	v.add_child(gap)
	v.add_child(button("BACK", func() -> void:
		AudioSynth.play(screens, "back", -6.0)
		screens.show_title()
	))
