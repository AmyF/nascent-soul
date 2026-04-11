extends RefCounted

const DEAL_MAX := 1000000
const SUIT_ORDER := [&"clubs", &"diamonds", &"hearts", &"spades"]
const SUIT_CODES := ["C", "D", "H", "S"]
const RANK_LABELS := {
	1: "A",
	2: "2",
	3: "3",
	4: "4",
	5: "5",
	6: "6",
	7: "7",
	8: "8",
	9: "9",
	10: "10",
	11: "J",
	12: "Q",
	13: "K"
}

static func deal_codes(deal_number: int) -> Array[String]:
	var state = max(1, deal_number) & 0x7fffffff
	var deck: Array[String] = []
	for rank_value in range(1, 14):
		for suit_code in SUIT_CODES:
			deck.append("%s%s" % [RANK_LABELS[rank_value], suit_code])
	var dealt: Array[String] = []
	while not deck.is_empty():
		state = int((int(state) * 214013 + 2531011) & 0x7fffffff)
		var choice = int((state >> 16) % deck.size())
		var last_index = deck.size() - 1
		var card_code = deck[choice]
		deck[choice] = deck[last_index]
		deck.remove_at(last_index)
		dealt.append(card_code)
	return dealt

static func can_start_foundation(card) -> bool:
	return card != null and card.rank_value == 1

static func foundation_accepts_card(foundation_cards: Array, card) -> bool:
	if card == null:
		return false
	if foundation_cards.is_empty():
		return can_start_foundation(card)
	var top_card = foundation_cards[foundation_cards.size() - 1]
	return top_card != null and top_card.suit == card.suit and top_card.rank_value + 1 == card.rank_value

static func foundation_rank(foundation_cards: Array) -> int:
	if foundation_cards.is_empty():
		return 0
	var top_card = foundation_cards[foundation_cards.size() - 1]
	return top_card.rank_value if top_card != null else 0

static func foundation_suit(foundation_cards: Array) -> StringName:
	if foundation_cards.is_empty():
		return &""
	var top_card = foundation_cards[foundation_cards.size() - 1]
	return top_card.suit if top_card != null else &""

static func can_build_on_tableau(moving_head, target_top) -> bool:
	if moving_head == null:
		return false
	if target_top == null:
		return true
	return moving_head.is_red != target_top.is_red and moving_head.rank_value + 1 == target_top.rank_value

static func is_descending_alternating_run(cards: Array) -> bool:
	if cards.is_empty():
		return false
	for index in range(cards.size() - 1):
		var upper = cards[index]
		var lower = cards[index + 1]
		if upper == null or lower == null:
			return false
		if upper.is_red == lower.is_red:
			return false
		if upper.rank_value != lower.rank_value + 1:
			return false
	return true

static func movable_run_capacity(open_free_cells: int, open_tableaus: int) -> int:
	return (max(0, open_free_cells) + 1) * (1 << max(0, open_tableaus))

static func choose_lowest_auto_card(cards: Array) -> Variant:
	if cards.is_empty():
		return null
	var best = cards[0]
	for index in range(1, cards.size()):
		var candidate = cards[index]
		if candidate.rank_value < best.rank_value:
			best = candidate
			continue
		if candidate.rank_value == best.rank_value and String(candidate.code) < String(best.code):
			best = candidate
	return best

static func is_safe_auto_foundation_card(card, foundation_ranks: Dictionary) -> bool:
	if card == null:
		return false
	if foundation_ranks.get(card.suit, 0) + 1 != card.rank_value:
		return false
	var opposite_requirement = card.rank_value - 2
	for suit in opposite_color_suits(card.suit):
		if int(foundation_ranks.get(suit, 0)) < opposite_requirement:
			return false
	var partner_requirement = card.rank_value - 3
	if int(foundation_ranks.get(same_color_partner_suit(card.suit), 0)) < partner_requirement:
		return false
	return true

static func opposite_color_suits(suit: StringName) -> Array[StringName]:
	var suits: Array[StringName] = []
	if is_red_suit(suit):
		suits.append(&"clubs")
		suits.append(&"spades")
	else:
		suits.append(&"diamonds")
		suits.append(&"hearts")
	return suits

static func same_color_partner_suit(suit: StringName) -> StringName:
	match suit:
		&"clubs":
			return &"spades"
		&"spades":
			return &"clubs"
		&"diamonds":
			return &"hearts"
		&"hearts":
			return &"diamonds"
		_:
			return &""

static func is_red_suit(suit: StringName) -> bool:
	return suit == &"diamonds" or suit == &"hearts"
