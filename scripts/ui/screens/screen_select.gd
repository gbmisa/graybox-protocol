class_name ScreenSelect
extends ScreenBase
## Operative select. Cards are rebuilt on every show so edits to CharData
## appear without restarting.
##
## Each card leads with the route that operative is locked into, because with
## hard-gated routes the character choice is a level choice.

const CARD_SIZE := Vector2(376, 340)
## Characters per line. Three cards plus separators must fit 1280px, and a
## Button grows to fit its longest unbroken line of text.
const WRAP_AT := 44

var _cards: HBoxContainer

func build() -> void:
	var v := column(18)
	center.add_child(v)
	v.add_child(text("CHOOSE YOUR OPERATIVE", 44, GOLD))
	v.add_child(text("each one takes a different way in — you cannot swap routes mid-mission",
		16, INFO))
	_cards = row(16)
	v.add_child(_cards)

func refresh() -> void:
	clear(_cards)
	for id in CharData.ids():
		_cards.add_child(_make_card(String(id)))

func _make_card(id: String) -> Button:
	var c := CharData.get_char(id)
	var verbs := VerbData.get_verbs(id)
	var label := "%s\n%s\n\n%s\n\nHP %d   SPEED %.1f\n\nROUTE\n%s\n\nCAN: %s" % [
		c["name"], c["role"], _wrap(String(c["desc"])),
		int(c["hp"]), float(c["speed"]),
		_wrap(String(c["route"])), _wrap(_verb_summary(verbs))]
	return card(label, CARD_SIZE, func() -> void:
		screens.click()
		game().select_char(id)
	)

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
