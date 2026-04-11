extends RefCounted

const FreeCellCardScript = preload("res://scenes/showcases/freecell/freecell_card.gd")
const FreeCellRulesScript = preload("res://scenes/showcases/freecell/freecell_rules.gd")

const SUIT_SYMBOLS := {
	&"clubs": "♣",
	&"diamonds": "♦",
	&"hearts": "♥",
	&"spades": "♠"
}
const SUIT_NAMES := {
	&"clubs": "Clubs",
	&"diamonds": "Diamonds",
	&"hearts": "Hearts",
	&"spades": "Spades"
}
const SUIT_CODE_TO_NAME := {
	"C": &"clubs",
	"D": &"diamonds",
	"H": &"hearts",
	"S": &"spades"
}
const RANK_LABELS = FreeCellRulesScript.RANK_LABELS

static func make_card_from_code(code: String) -> Control:
	var parsed = parse_card_code(code)
	if parsed.is_empty():
		return null
	var card = FreeCellCardScript.new()
	card.configure(
		parsed.code,
		parsed.suit,
		parsed.rank_value,
		parsed.rank_label,
		parsed.suit_symbol,
		parsed.suit_name,
		parsed.is_red
	)
	card.custom_minimum_size = FreeCellCardScript.CARD_SIZE
	card.size = card.custom_minimum_size
	return card

static func parse_card_code(code: String) -> Dictionary:
	if code.length() < 2:
		return {}
	var suit_code = code.right(1).to_upper()
	if not SUIT_CODE_TO_NAME.has(suit_code):
		return {}
	var rank_text = code.left(code.length() - 1).to_upper()
	var rank_value = rank_value_from_text(rank_text)
	if rank_value < 1 or not RANK_LABELS.has(rank_value):
		return {}
	var suit = SUIT_CODE_TO_NAME[suit_code]
	return {
		"code": "%s%s" % [RANK_LABELS[rank_value], suit_code],
		"suit": suit,
		"rank_value": rank_value,
		"rank_label": RANK_LABELS[rank_value],
		"suit_symbol": SUIT_SYMBOLS[suit],
		"suit_name": SUIT_NAMES[suit],
		"is_red": suit == &"diamonds" or suit == &"hearts"
	}

static func rank_value_from_text(rank_text: String) -> int:
	match rank_text:
		"A":
			return 1
		"J":
			return 11
		"Q":
			return 12
		"K":
			return 13
		_:
			return int(rank_text)

static func card_lookup_by_code(zones: Array[Zone]) -> Dictionary:
	var lookup: Dictionary = {}
	for zone in zones:
		if zone == null:
			continue
		for item in zone.get_items():
			if item is FreeCellCardScript:
				lookup[(item as FreeCellCardScript).code] = item
	return lookup
