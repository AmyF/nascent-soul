extends RefCounted

const FreeCellRulesScript = preload("res://scenes/examples/freecell/freecell_rules.gd")

const TABLEAU_COUNT := 8
const FREE_CELL_COUNT := 4
const FOUNDATION_SLOT_COUNT := 4
const SUIT_ORDER = FreeCellRulesScript.SUIT_ORDER

static func build_deal_state(deal_number: int) -> Dictionary:
	var normalized_deal_number = max(1, deal_number)
	var tableaus: Array = []
	for _index in range(TABLEAU_COUNT):
		tableaus.append([])
	var deck_codes = FreeCellRulesScript.deal_codes(normalized_deal_number)
	for index in range(deck_codes.size()):
		tableaus[index % TABLEAU_COUNT].append(deck_codes[index])
	return {
		"deal_number": normalized_deal_number,
		"tableaus": tableaus,
		"free_cells": ["", "", "", ""],
		"foundation_slots": [[], [], [], []]
	}

static func normalize_state(state: Dictionary, fallback_deal_number: int = 1) -> Dictionary:
	var normalized_deal_number = max(1, int(state.get("deal_number", fallback_deal_number)))
	return {
		"deal_number": normalized_deal_number,
		"tableaus": _normalize_tableaus(state.get("tableaus", [])),
		"free_cells": _normalize_free_cells(state.get("free_cells", [])),
		"foundation_slots": _normalize_foundation_slots(state)
	}

static func serialize_state(deal_number: int, tableau_zones: Array[Zone], free_cell_zones: Array[Zone], foundation_zones: Array[Zone]) -> Dictionary:
	var tableaus: Array = []
	for zone in tableau_zones:
		tableaus.append(_zone_codes(zone))
	var free_cells: Array = []
	for zone in free_cell_zones:
		var codes = _zone_codes(zone)
		free_cells.append(codes[0] if not codes.is_empty() else "")
	var foundation_slots: Array = []
	for zone in foundation_zones:
		foundation_slots.append(_zone_codes(zone))
	return normalize_state({
		"deal_number": deal_number,
		"tableaus": tableaus,
		"free_cells": free_cells,
		"foundation_slots": foundation_slots
	}, deal_number)

static func build_zone_plan(state: Dictionary, free_cell_zones: Array[Zone], foundation_zones: Array[Zone], tableau_zones: Array[Zone]) -> Array[Dictionary]:
	var normalized_state = normalize_state(state)
	var plan: Array[Dictionary] = []
	var free_cells: Array = normalized_state.get("free_cells", [])
	for index in range(free_cell_zones.size()):
		var codes: Array[String] = []
		if index < free_cells.size():
			var code = str(free_cells[index])
			if code != "":
				codes.append(code)
		plan.append({"zone": free_cell_zones[index], "codes": codes})
	var foundation_slots: Array = normalized_state.get("foundation_slots", [])
	for index in range(foundation_zones.size()):
		var codes: Array = foundation_slots[index] if index < foundation_slots.size() else []
		plan.append({"zone": foundation_zones[index], "codes": codes})
	var tableaus: Array = normalized_state.get("tableaus", [])
	for index in range(tableau_zones.size()):
		var codes: Array = tableaus[index] if index < tableaus.size() else []
		plan.append({"zone": tableau_zones[index], "codes": codes})
	return plan

static func _normalize_tableaus(tableaus: Array) -> Array:
	var normalized: Array = []
	for index in range(TABLEAU_COUNT):
		var source = tableaus[index] if index < tableaus.size() and tableaus[index] is Array else []
		normalized.append(_normalize_code_list(source))
	return normalized

static func _normalize_free_cells(free_cells: Array) -> Array:
	var normalized: Array = []
	for index in range(FREE_CELL_COUNT):
		var code = str(free_cells[index]) if index < free_cells.size() else ""
		normalized.append(code)
	return normalized

static func _normalize_foundation_slots(state: Dictionary) -> Array:
	if state.has("foundation_slots"):
		var foundation_slots = state.get("foundation_slots", [])
		var normalized_slots: Array = []
		for index in range(FOUNDATION_SLOT_COUNT):
			var slot_values = foundation_slots[index] if index < foundation_slots.size() and foundation_slots[index] is Array else []
			normalized_slots.append(_normalize_code_list(slot_values))
		return normalized_slots
	var foundations = state.get("foundations", {})
	var normalized_from_legacy: Array = [[], [], [], []]
	for suit_name in foundations.keys():
		var suit = StringName(str(suit_name))
		var suit_index = SUIT_ORDER.find(suit)
		if suit_index < 0 or suit_index >= normalized_from_legacy.size():
			continue
		var codes = foundations[suit_name] if foundations[suit_name] is Array else []
		normalized_from_legacy[suit_index] = _normalize_code_list(codes)
	return normalized_from_legacy

static func _normalize_code_list(values: Array) -> Array[String]:
	var codes: Array[String] = []
	for value in values:
		var code = str(value)
		if code != "":
			codes.append(code)
	return codes

static func _zone_codes(zone: Zone) -> Array[String]:
	var codes: Array[String] = []
	if zone == null:
		return codes
	for item in zone.get_items():
		if item != null and item.has_method("get") and item.get("code") != null:
			codes.append(str(item.get("code")))
	return codes
