class_name ScreenSelect
extends ScreenBase
## Operation planning: pick a target, then an operative. Cards are rebuilt on
## every show so edits to CharData / LevelData appear without restarting.
##
## Each card leads with the route that operative is locked into, because with
## hard-gated routes the character choice is a level choice. The route shown
## is the selected level's — switching target re-labels the operatives.

const CARD_SIZE := Vector2(376, 340)
const LEVEL_CARD_SIZE := Vector2(560, 170)
## Characters per line. Three cards plus separators must fit 1280px, and a
## Button grows to fit its longest unbroken line of text.
const WRAP_AT := 44

var _cards: HBoxContainer
var _levels: HBoxContainer

func build() -> void:
	var v := column(12)
	center.add_child(v)
	v.add_child(text("PLAN THE OPERATION", 36, GOLD))
	v.add_child(text("each operative takes a different way in — pick a target, then an operative",
		16, INFO))
	_cards = row(16)
	v.add_child(_cards)
	v.add_child(text("CHOOSE YOUR TARGET", 24, GOLD))
	_levels = row(16)
	v.add_child(_levels)

func refresh() -> void:
	clear(_cards)
	for id in CharData.ids():
		_cards.add_child(_make_card(String(id)))
	clear(_levels)
	for id in LevelData.ids():
		_levels.add_child(_make_level_card(int(id)))

func _make_card(id: String) -> Button:
	var c := CharData.get_char(id)
	var verbs := VerbData.get_verbs(id)
	var lvl := LevelData.get_level(game().selected_level)
	var label := "%s\n%s\n\n%s\n\nHP %d   SPEED %.1f\n\nROUTE\n%s\n\nCAN: %s" % [
		c["name"], c["role"], _wrap(String(c["desc"])),
		int(c["hp"]), float(c["speed"]),
		_wrap(str(lvl["routes"][id])), _wrap(_verb_summary(verbs))]
	var b := card(label, CARD_SIZE, func() -> void:
		screens.click()
		game().select_char(id)
	)
	if id == game().selected_char:
		b.modulate = SELECTED
	return b

func _make_level_card(level_id: int) -> Button:
	var l := LevelData.get_level(level_id)
	var label := "%s\n%s\n\n%s" % [
		l["name"], _wrap(str(l["desc"])), _wrap(str(l["extractions"]))]
	var b := card(label, LEVEL_CARD_SIZE, func() -> void:
		screens.click()
		game().select_level(level_id)
	)
	if level_id == game().selected_level:
		b.modulate = SELECTED
	return b

## Hard-wrap to WRAP_AT columns. A Button sizes itself to its longest line, so
## an unwrapped description stretches the card to thousands of pixels and
## shoves the third operative off the side of the screen. Done manually rather
## than with Button.autowrap_mode, which needs a width constraint the HBox
## does not impose.
static func _wrap(text: String) -> String:
	var lines := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" ", false):
			if line.is_empty():
				line = word
			elif line.length() + 1 + word.length() <= WRAP_AT:
				line += " " + word
			else:
				lines.append(line)
				line = word
		lines.append(line)
	return "\n".join(lines)

## Spells out the traversal verbs, since they decide which doors open.
func _verb_summary(verbs: Dictionary) -> String:
	var out: Array = []
	if bool(verbs.get("lockpick", false)):
		out.append("pick locks")
	if bool(verbs.get("arcane", false)):
		out.append("unward seals")
	if bool(verbs.get("smash", false)):
		out.append("breach walls")
	if float(verbs.get("crouch_h", 1.0)) <= 1.0:
		out.append("crawl 1m gaps")
	else:
		out.append("NO crawling")
	out.append("climb %.1fm" % float(verbs.get("mantle_h", 1.2)))
	return ", ".join(out)
