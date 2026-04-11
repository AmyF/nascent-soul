extends RefCounted

const FreeCellCardScript = preload("res://scenes/showcases/freecell/freecell_card.gd")
const FreeCellRulesScript = preload("res://scenes/showcases/freecell/freecell_rules.gd")
const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

var _zone_info: Dictionary = {}
var _free_cell_zones: Array[Zone] = []
var _foundation_zones: Array[Zone] = []
var _tableau_zones: Array[Zone] = []

func attach(zone_info: Dictionary, free_cell_zones: Array[Zone], foundation_zones: Array[Zone], tableau_zones: Array[Zone]) -> void:
	_zone_info = zone_info
	_free_cell_zones = free_cell_zones
	_foundation_zones = foundation_zones
	_tableau_zones = tableau_zones

func evaluate_transfer(zone_role: StringName, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if request == null:
		return ZoneTransferDecision.new(false, "Missing transfer request.", ZonePlacementTarget.invalid())
	if request.source_zone is not Zone or request.target_zone is not Zone:
		return ZoneTransferDecision.new(false, "FreeCell only accepts zone-to-zone moves.", ZonePlacementTarget.invalid())
	var source_zone := request.source_zone as Zone
	var target_zone := request.target_zone as Zone
	if source_zone == target_zone:
		return ZoneTransferDecision.new(false, "Reordering within the same lane is not part of FreeCell.", ZonePlacementTarget.invalid())
	var cards = typed_cards(request.items)
	if cards.is_empty() or cards.size() != request.items.size():
		return ZoneTransferDecision.new(false, "Only FreeCell cards can move here.", ZonePlacementTarget.invalid())
	var source_validation = _validate_source_cards(source_zone, _source_role_for_zone(source_zone), cards)
	if not source_validation.allowed:
		return ZoneTransferDecision.new(false, source_validation.reason, ZonePlacementTarget.invalid())
	match zone_role:
		&"freecell":
			return _evaluate_transfer_to_free_cell(target_zone, cards)
		&"foundation":
			return _evaluate_transfer_to_foundation(target_zone, cards)
		&"tableau":
			return _evaluate_transfer_to_tableau(source_zone, target_zone, cards)
		_:
			return ZoneTransferDecision.new(false, "Unknown FreeCell destination.", ZonePlacementTarget.invalid())

func evaluate_drag_start(zone_role: StringName, context: ZoneContext, anchor_item: ZoneItemControl):
	if context == null or anchor_item is not FreeCellCardScript or not context.has_item(anchor_item):
		return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [])
	var source_cards = typed_cards(context.get_items_ordered())
	var card_index = find_card_index(source_cards, anchor_item)
	if card_index == -1:
		return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [anchor_item])
	match zone_role:
		&"tableau":
			var tail = source_cards.slice(card_index, source_cards.size())
			if tail.is_empty():
				return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [anchor_item])
			if card_index != source_cards.size() - 1 and not is_descending_alternating_run(tail):
				return ZoneDragStartDecisionScript.new(false, "Only exposed descending alternating runs can move together.", [anchor_item])
			if tail.size() == 1 and card_index != source_cards.size() - 1:
				return ZoneDragStartDecisionScript.new(false, "Only the exposed top card can move from this tableau.", [anchor_item])
			return ZoneDragStartDecisionScript.new(true, "", tail)
		&"freecell", &"foundation":
			if card_index != source_cards.size() - 1:
				return ZoneDragStartDecisionScript.new(false, "Only the exposed top card can move.", [anchor_item])
			return ZoneDragStartDecisionScript.new(true, "", [anchor_item])
		_:
			return ZoneDragStartDecisionScript.new(false, "Unknown FreeCell source lane.", [anchor_item])

func typed_cards(items: Array) -> Array:
	var cards: Array = []
	for item in items:
		if item is FreeCellCardScript and is_instance_valid(item):
			cards.append(item)
	return cards

func is_descending_alternating_run(cards: Array) -> bool:
	return FreeCellRulesScript.is_descending_alternating_run(cards)

func find_card_index(cards: Array, target: Control) -> int:
	for index in range(cards.size()):
		if cards[index] == target:
			return index
	return -1

func zone_for_item(item: Control) -> Zone:
	for zone in _all_zones():
		if zone.has_item(item):
			return zone
	return null

func is_exposed_card(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var source_zone = zone_for_item(card)
	if source_zone == null:
		return false
	var source_cards = typed_cards(source_zone.get_items())
	return not source_cards.is_empty() and source_cards[source_cards.size() - 1] == card

func can_auto_foundation(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var target_zone = foundation_zone_for_card(card)
	if target_zone == null:
		return false
	return FreeCellRulesScript.foundation_accepts_card(typed_cards(target_zone.get_items()), card)

func foundation_zone_for_card(card: FreeCellCardScript) -> Zone:
	if not is_instance_valid(card):
		return null
	var started_zone = _foundation_zone_for_suit(card.suit)
	if started_zone != null:
		return started_zone
	if card.rank_value != 1:
		return null
	return _first_empty_foundation_zone()

func _evaluate_transfer_to_free_cell(target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	if cards.size() != 1:
		return ZoneTransferDecision.new(false, "Free cells only hold one card at a time.", ZonePlacementTarget.invalid())
	if target_zone.get_item_count() > 0:
		return ZoneTransferDecision.new(false, "That free cell is already occupied.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(0))

func _evaluate_transfer_to_foundation(target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	if cards.size() != 1:
		return ZoneTransferDecision.new(false, "Foundations only accept one card at a time.", ZonePlacementTarget.invalid())
	var card = cards[0] as FreeCellCardScript
	var foundation_cards = typed_cards(target_zone.get_items())
	if not FreeCellRulesScript.foundation_accepts_card(foundation_cards, card):
		if foundation_cards.is_empty():
			return ZoneTransferDecision.new(false, "Empty foundations open with aces.", ZonePlacementTarget.invalid())
		var foundation_top = foundation_cards[foundation_cards.size() - 1] as FreeCellCardScript
		if foundation_top == null or foundation_top.suit != card.suit:
			return ZoneTransferDecision.new(false, "Started foundations continue in the same suit.", ZonePlacementTarget.invalid())
		return ZoneTransferDecision.new(false, "Foundations build upward from Ace to King.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))

func _evaluate_transfer_to_tableau(source_zone: Zone, target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	var moving_head = cards[0] as FreeCellCardScript
	var target_cards = typed_cards(target_zone.get_items())
	var capacity = _tableau_stack_capacity(source_zone, target_zone)
	if cards.size() > capacity:
		return ZoneTransferDecision.new(false, "Not enough free cells and empty tableaus to move that whole run.", ZonePlacementTarget.invalid())
	if target_cards.is_empty():
		return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))
	var target_top = target_cards[target_cards.size() - 1] as FreeCellCardScript
	if not FreeCellRulesScript.can_build_on_tableau(moving_head, target_top):
		if moving_head.is_red == target_top.is_red:
			return ZoneTransferDecision.new(false, "Tableau runs must alternate colors.", ZonePlacementTarget.invalid())
		return ZoneTransferDecision.new(false, "Tableau runs must descend by exactly one rank.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))

func _validate_source_cards(source_zone: Zone, source_role: StringName, cards: Array) -> Dictionary:
	match source_role:
		&"tableau":
			var tableau_cards = typed_cards(source_zone.get_items())
			var start_index = find_card_index(tableau_cards, cards[0])
			if start_index == -1:
				return {"allowed": false, "reason": "The selected cards are no longer in that tableau."}
			if start_index + cards.size() != tableau_cards.size():
				return {"allowed": false, "reason": "Only the exposed tail of a tableau can move."}
			for index in range(cards.size()):
				if tableau_cards[start_index + index] != cards[index]:
					return {"allowed": false, "reason": "FreeCell moves must keep the exposed tail together."}
			if cards.size() > 1 and not is_descending_alternating_run(cards):
				return {"allowed": false, "reason": "Only descending alternating runs can move together."}
			if cards.size() == 1 and start_index != tableau_cards.size() - 1:
				return {"allowed": false, "reason": "Only the exposed top card can move from this tableau."}
			return {"allowed": true, "reason": ""}
		&"freecell", &"foundation":
			if cards.size() != 1:
				return {"allowed": false, "reason": "Only one card can move out of that lane."}
			var source_cards = typed_cards(source_zone.get_items())
			if source_cards.is_empty() or source_cards[source_cards.size() - 1] != cards[0]:
				return {"allowed": false, "reason": "Only the exposed top card can move."}
			return {"allowed": true, "reason": ""}
		_:
			return {"allowed": false, "reason": "Unknown FreeCell source lane."}

func _tableau_stack_capacity(source_zone: Zone, target_zone: Zone) -> int:
	var empty_free_cells := 0
	for zone in _free_cell_zones:
		if zone.get_item_count() == 0:
			empty_free_cells += 1
	var empty_tableaus := 0
	for zone in _tableau_zones:
		if zone == source_zone or zone == target_zone:
			continue
		if zone.get_item_count() == 0:
			empty_tableaus += 1
	return FreeCellRulesScript.movable_run_capacity(empty_free_cells, empty_tableaus)

func _all_zones() -> Array[Zone]:
	var zones: Array[Zone] = []
	zones.append_array(_free_cell_zones)
	zones.append_array(_foundation_zones)
	zones.append_array(_tableau_zones)
	return zones

func _source_role_for_zone(zone: Zone) -> StringName:
	return StringName(_zone_info.get(zone, {}).get("role", &""))

func _foundation_zone_for_suit(suit: StringName) -> Zone:
	for zone in _foundation_zones:
		var cards = typed_cards(zone.get_items())
		if cards.is_empty():
			continue
		var top_card = cards[cards.size() - 1] as FreeCellCardScript
		if top_card != null and top_card.suit == suit:
			return zone
	return null

func _first_empty_foundation_zone() -> Zone:
	for zone in _foundation_zones:
		if zone.get_item_count() == 0:
			return zone
	return null
