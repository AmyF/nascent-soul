extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const FreeCellCardScript = preload("res://scenes/examples/freecell/freecell_card.gd")
const FreeCellCardDisplayScript = preload("res://scenes/examples/freecell/freecell_card_display.gd")
const FreeCellTableauLayoutScript = preload("res://scenes/examples/freecell/freecell_tableau_layout.gd")
const FreeCellZonePolicyScript = preload("res://scenes/examples/freecell/freecell_zone_policy.gd")
const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_STATUS_COLOR := Color(0.96, 0.60, 0.56)
const WIN_STATUS_COLOR := Color(0.93, 0.88, 0.62)
const SUIT_ORDER := [&"clubs", &"diamonds", &"hearts", &"spades"]
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

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var toolbar: Control = $RootMargin/RootVBox/Toolbar
@onready var new_game_button: Button = $RootMargin/RootVBox/Toolbar/NewGameButton
@onready var replay_seed_button: Button = $RootMargin/RootVBox/Toolbar/ReplaySeedButton
@onready var seed_label: Label = $RootMargin/RootVBox/Toolbar/SeedLabel
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var victory_label: Label = $RootMargin/RootVBox/VictoryLabel
@onready var top_row: HFlowContainer = $RootMargin/RootVBox/TopRow
@onready var free_cells_column: VBoxContainer = $RootMargin/RootVBox/TopRow/FreeCellsColumn
@onready var foundations_column: VBoxContainer = $RootMargin/RootVBox/TopRow/FoundationsColumn
@onready var free_cells_slots_row: HFlowContainer = $RootMargin/RootVBox/TopRow/FreeCellsColumn/SlotsRow
@onready var foundations_slots_row: HFlowContainer = $RootMargin/RootVBox/TopRow/FoundationsColumn/SlotsRow
@onready var tableau_scroll: ScrollContainer = $RootMargin/RootVBox/TableauScroll
@onready var tableau_row: HBoxContainer = $RootMargin/RootVBox/TableauScroll/TableauRow

var _tableau_zones: Array[Zone] = []
var _free_cell_zones: Array[Zone] = []
var _foundation_zones: Array[Zone] = []
var _foundation_by_suit: Dictionary = {}
var _zone_info: Dictionary = {}
var _card_bindings: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _last_seed: int = 0
var _game_won: bool = false

func _ready() -> void:
	_build_zones()
	_wire_controls()
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	start_new_game()

func _exit_tree() -> void:
	for policy in _collect_zone_policies():
		policy.controller = null
	_disconnect_card_bindings()

func start_new_game(seed: int = -1) -> void:
	_last_seed = seed if seed >= 0 else int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	_game_won = false
	victory_label.visible = false
	_clear_all_cards()
	var deck_codes = _shuffled_deck_codes(_last_seed)
	for index in range(deck_codes.size()):
		var zone = _tableau_zones[index % _tableau_zones.size()]
		zone.add_item(_make_card_from_code(deck_codes[index]))
	_refresh_summary()
	_set_status("New FreeCell game ready. Drag cards between tableau columns, free cells, and foundations.")

func load_debug_state(state: Dictionary) -> void:
	_game_won = false
	victory_label.visible = false
	_clear_all_cards()
	var tableaus: Array = state.get("tableaus", [])
	for index in range(min(tableaus.size(), _tableau_zones.size())):
		for code in tableaus[index]:
			_tableau_zones[index].add_item(_make_card_from_code(str(code)))
	var free_cells: Array = state.get("free_cells", [])
	for index in range(min(free_cells.size(), _free_cell_zones.size())):
		var code = str(free_cells[index])
		if code != "":
			_free_cell_zones[index].add_item(_make_card_from_code(code))
	var foundations = state.get("foundations", {})
	for suit_name in foundations.keys():
		var suit = StringName(str(suit_name))
		var zone = _foundation_by_suit.get(suit, null) as Zone
		if zone == null:
			continue
		for code in foundations[suit_name]:
			zone.add_item(_make_card_from_code(str(code)))
	_refresh_summary()
	_update_victory_state()
	_set_status("FreeCell debug state loaded.")

func get_tableau_zones() -> Array[Zone]:
	return _tableau_zones.duplicate()

func get_free_cell_zones() -> Array[Zone]:
	return _free_cell_zones.duplicate()

func get_foundation_zones() -> Array[Zone]:
	return _foundation_zones.duplicate()

func get_card_by_code(code: String) -> Control:
	for zone in _all_zones():
		for item in zone.get_items():
			if item is FreeCellCardScript and (item as FreeCellCardScript).code == code:
				return item
	return null

func has_won() -> bool:
	return _game_won

func foundation_total() -> int:
	var count := 0
	for zone in _foundation_zones:
		count += zone.get_item_count()
	return count

func try_move_cards(items: Array[ZoneItemControl], target_zone: Zone) -> bool:
	if items.is_empty() or target_zone == null:
		return false
	var source_zone = _zone_for_item(items[0])
	if source_zone == null:
		return false
	return ExampleSupport.transfer_items(source_zone, items, target_zone, ZonePlacementTarget.linear(target_zone.get_item_count()))

func try_auto_foundation(card: Control) -> bool:
	if card is not FreeCellCardScript:
		return false
	var freecell_card := card as FreeCellCardScript
	var source_zone = _zone_for_item(freecell_card)
	if source_zone == null:
		return false
	var target_zone = _foundation_by_suit.get(freecell_card.suit, null) as Zone
	if target_zone == null:
		return false
	return ExampleSupport.move_item(source_zone, freecell_card, target_zone, ZonePlacementTarget.linear(target_zone.get_item_count()))

func evaluate_freecell_transfer(zone_role: StringName, zone_index: int, _context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if request == null:
		return ZoneTransferDecision.new(false, "Missing transfer request.", ZonePlacementTarget.invalid())
	if request.source_zone is not Zone or request.target_zone is not Zone:
		return ZoneTransferDecision.new(false, "FreeCell only accepts zone-to-zone moves.", ZonePlacementTarget.invalid())
	var source_zone := request.source_zone as Zone
	var target_zone := request.target_zone as Zone
	if source_zone == target_zone:
		return ZoneTransferDecision.new(false, "Reordering within the same lane is not part of FreeCell.", ZonePlacementTarget.invalid())
	var cards = _typed_cards(request.items)
	if cards.is_empty() or cards.size() != request.items.size():
		return ZoneTransferDecision.new(false, "Only FreeCell cards can move here.", ZonePlacementTarget.invalid())
	var source_info = _zone_info.get(source_zone, {})
	var source_role = source_info.get("role", &"")
	var source_validation = _validate_source_cards(source_zone, StringName(source_role), cards)
	if not source_validation.allowed:
		return ZoneTransferDecision.new(false, source_validation.reason, ZonePlacementTarget.invalid())
	match zone_role:
		&"freecell":
			return _evaluate_transfer_to_free_cell(target_zone, cards)
		&"foundation":
			return _evaluate_transfer_to_foundation(zone_index, target_zone, cards)
		&"tableau":
			return _evaluate_transfer_to_tableau(source_zone, target_zone, cards)
		_:
			return ZoneTransferDecision.new(false, "Unknown FreeCell destination.", ZonePlacementTarget.invalid())

func evaluate_freecell_drag_start(zone_role: StringName, _zone_index: int, context: ZoneContext, anchor_item: ZoneItemControl, _selected_items: Array[ZoneItemControl]):
	if context == null or anchor_item is not FreeCellCardScript or not context.has_item(anchor_item):
		return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [])
	var source_cards = _typed_cards(context.get_items_ordered())
	var card_index = _find_card_index(source_cards, anchor_item)
	if card_index == -1:
		return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [anchor_item])
	match zone_role:
		&"tableau":
			var tail = source_cards.slice(card_index, source_cards.size())
			if tail.is_empty():
				return ZoneDragStartDecisionScript.new(false, "This card can no longer move.", [anchor_item])
			if card_index != source_cards.size() - 1 and not _is_descending_alternating_run(tail):
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

func _build_zones() -> void:
	if not _tableau_zones.is_empty():
		return
	var interaction := ZoneInteraction.new()
	interaction.drag_enabled = true
	interaction.select_on_click = true
	interaction.multi_select_enabled = false
	interaction.ctrl_toggles_selection = false
	interaction.shift_range_select_enabled = false
	interaction.keyboard_navigation_enabled = false
	var display_style := FreeCellCardDisplayScript.new()
	display_style.selected_scale = 1.01
	display_style.selected_lift = 1.0
	var drag_factory := ZoneConfigurableDragVisualFactory.new()
	drag_factory.ghost_fill_color = Color(0.98, 0.95, 0.82, 0.08)
	drag_factory.ghost_border_color = Color(0.93, 0.78, 0.46, 0.75)
	drag_factory.proxy_modulate = Color(1, 1, 1, 0.94)
	var single_slot_layout := ZoneHBoxLayout.new()
	single_slot_layout.item_spacing = 0.0
	single_slot_layout.padding_left = 6.0
	single_slot_layout.padding_top = 8.0
	for index in range(free_cells_slots_row.get_child_count()):
		var host = free_cells_slots_row.get_child(index).get_node("ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"freecell"
		policy.zone_index = index
		var zone = ExampleSupport.make_zone(host, "FreeCellSlot%d" % index, single_slot_layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"freecell", index)
		_bind_zone_events(zone)
		_free_cell_zones.append(zone)
	for index in range(foundations_slots_row.get_child_count()):
		var host = foundations_slots_row.get_child(index).get_node("ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"foundation"
		policy.zone_index = index
		var zone = ExampleSupport.make_zone(host, "Foundation%s" % String(SUIT_ORDER[index]).capitalize(), single_slot_layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"foundation", index, SUIT_ORDER[index])
		_bind_zone_events(zone)
		_foundation_zones.append(zone)
		_foundation_by_suit[SUIT_ORDER[index]] = zone
	for index in range(tableau_row.get_child_count()):
		var host = tableau_row.get_child(index).get_node("ZonePanel/ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"tableau"
		policy.zone_index = index
		var layout = FreeCellTableauLayoutScript.new()
		var zone = ExampleSupport.make_zone(host, "Tableau%d" % index, layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"tableau", index)
		_bind_zone_events(zone)
		_tableau_zones.append(zone)

func _wire_controls() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	replay_seed_button.pressed.connect(_on_replay_seed_pressed)

func _bind_zone_events(zone: Zone) -> void:
	zone.item_transferred.connect(_on_item_transferred.bind(zone))
	zone.drop_rejected.connect(_on_drop_rejected.bind(zone))
	zone.drag_start_rejected.connect(_on_drag_start_rejected.bind(zone))
	zone.item_double_clicked.connect(_on_item_double_clicked.bind(zone))
	if _zone_info.get(zone, {}).get("role", &"") == &"tableau":
		zone.item_clicked.connect(_on_tableau_item_clicked.bind(zone))

func _register_zone(zone: Zone, role: StringName, index: int, suit: StringName = &"") -> void:
	_zone_info[zone] = {
		"role": role,
		"index": index,
		"suit": suit
	}

func _collect_zone_policies() -> Array:
	var policies: Array = []
	for zone in _all_zones():
		var policy = ExampleSupport.get_zone_transfer_policy(zone)
		if policy != null and policy not in policies:
			policies.append(policy)
	return policies

func _all_zones() -> Array[Zone]:
	var zones: Array[Zone] = []
	zones.append_array(_free_cell_zones)
	zones.append_array(_foundation_zones)
	zones.append_array(_tableau_zones)
	return zones

func _clear_all_cards() -> void:
	_disconnect_card_bindings()
	for zone in _all_zones():
		zone.clear_selection()
		for item in zone.get_items():
			if zone.remove_item(item):
				item.queue_free()

func _disconnect_card_bindings() -> void:
	for item in _card_bindings.keys():
		if not is_instance_valid(item):
			continue
		var callable = _card_bindings[item]
		if item.gui_input.is_connected(callable):
			item.gui_input.disconnect(callable)
	_card_bindings.clear()

func _make_card_from_code(code: String) -> Control:
	var parsed = _parse_card_code(code)
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
	_bind_card(card)
	return card

func _bind_card(card: Control) -> void:
	if not is_instance_valid(card) or _card_bindings.has(card):
		return
	var callable = Callable(self, "_on_card_gui_input").bind(card)
	card.gui_input.connect(callable)
	_card_bindings[card] = callable

func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	var zone = _zone_for_item(card)
	if zone == null:
		return
	var role = _zone_info.get(zone, {}).get("role", &"")
	if role == &"tableau":
		_select_movable_tail(zone, card)
	else:
		_select_single_card(zone, card)

func _on_tableau_item_clicked(item: Control, zone: Zone) -> void:
	if zone == null or item == null:
		return
	_select_movable_tail(zone, item)

func _on_item_double_clicked(item: Control, _zone: Zone) -> void:
	if try_auto_foundation(item):
		return
	_set_status("%s cannot move to a foundation yet." % _card_label(item), REJECT_STATUS_COLOR)

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, _target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_refresh_summary()
	_update_victory_state()
	_set_status("%s moved from %s to %s." % [_card_label(item), source_zone.name, target_zone.name])

func _on_drop_rejected(items: Array, _source_zone: Zone, _target_zone: Zone, reason: String, _emitter_zone: Zone) -> void:
	if items.is_empty():
		_set_status(reason, REJECT_STATUS_COLOR)
		return
	_set_status("%s: %s" % [_card_label(items[0]), reason], REJECT_STATUS_COLOR)

func _on_drag_start_rejected(items: Array, _source_zone: Zone, reason: String, _emitter_zone: Zone) -> void:
	if items.is_empty():
		_set_status(reason, REJECT_STATUS_COLOR)
		return
	_set_status("%s: %s" % [_card_label(items[0]), reason], REJECT_STATUS_COLOR)

func _on_new_game_pressed() -> void:
	start_new_game()

func _on_replay_seed_pressed() -> void:
	start_new_game(_last_seed)

func _select_single_card(zone: Zone, card: Control) -> void:
	if zone == null or card == null:
		return
	_clear_selection_all()
	zone.select_item(card)

func _select_movable_tail(zone: Zone, card: Control) -> void:
	if zone == null or card == null:
		return
	var cards = _typed_cards(zone.get_items())
	var index = _find_card_index(cards, card)
	if index == -1:
		return
	var tail = cards.slice(index, cards.size())
	if tail.is_empty():
		return
	if tail.size() > 1 and not _is_descending_alternating_run(tail):
		_clear_selection_all()
		_set_status("Only exposed descending alternating runs can move together.", REJECT_STATUS_COLOR)
		return
	if tail.size() == 1 and index != cards.size() - 1:
		_clear_selection_all()
		_set_status("Only the exposed top card can move from this tableau.", REJECT_STATUS_COLOR)
		return
	_clear_selection_all()
	zone.select_item(tail[0], false)
	for tail_index in range(1, tail.size()):
		zone.select_item(tail[tail_index], true)

func _clear_selection_all() -> void:
	for zone in _all_zones():
		zone.clear_selection()

func _evaluate_transfer_to_free_cell(target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	if cards.size() != 1:
		return ZoneTransferDecision.new(false, "Free cells only hold one card at a time.", ZonePlacementTarget.invalid())
	if target_zone.get_item_count() > 0:
		return ZoneTransferDecision.new(false, "That free cell is already occupied.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(0))

func _evaluate_transfer_to_foundation(zone_index: int, target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	if cards.size() != 1:
		return ZoneTransferDecision.new(false, "Foundations only accept one card at a time.", ZonePlacementTarget.invalid())
	var card = cards[0] as FreeCellCardScript
	var required_suit = SUIT_ORDER[clampi(zone_index, 0, SUIT_ORDER.size() - 1)]
	if card.suit != required_suit:
		return ZoneTransferDecision.new(false, "Each foundation only accepts its own suit.", ZonePlacementTarget.invalid())
	var next_rank = target_zone.get_item_count() + 1
	if card.rank_value != next_rank:
		return ZoneTransferDecision.new(false, "Foundations build upward from Ace to King.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))

func _evaluate_transfer_to_tableau(source_zone: Zone, target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	var moving_head = cards[0] as FreeCellCardScript
	var target_cards = _typed_cards(target_zone.get_items())
	if target_cards.is_empty():
		var capacity = _tableau_stack_capacity(source_zone, target_zone)
		if cards.size() > capacity:
			return ZoneTransferDecision.new(false, "Not enough free cells and empty tableaus to move that whole run.", ZonePlacementTarget.invalid())
		return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))
	var target_top = target_cards[target_cards.size() - 1] as FreeCellCardScript
	if moving_head.is_red == target_top.is_red:
		return ZoneTransferDecision.new(false, "Tableau runs must alternate colors.", ZonePlacementTarget.invalid())
	if moving_head.rank_value + 1 != target_top.rank_value:
		return ZoneTransferDecision.new(false, "Tableau runs must descend by exactly one rank.", ZonePlacementTarget.invalid())
	var capacity = _tableau_stack_capacity(source_zone, target_zone)
	if cards.size() > capacity:
		return ZoneTransferDecision.new(false, "Not enough free cells and empty tableaus to move that whole run.", ZonePlacementTarget.invalid())
	return ZoneTransferDecision.new(true, "", ZonePlacementTarget.linear(target_zone.get_item_count()))

func _validate_source_cards(source_zone: Zone, source_role: StringName, cards: Array) -> Dictionary:
	match source_role:
		&"tableau":
			var tableau_cards = _typed_cards(source_zone.get_items())
			var start_index = _find_card_index(tableau_cards, cards[0])
			if start_index == -1:
				return {"allowed": false, "reason": "The selected cards are no longer in that tableau."}
			if start_index + cards.size() != tableau_cards.size():
				return {"allowed": false, "reason": "Only the exposed tail of a tableau can move."}
			for index in range(cards.size()):
				if tableau_cards[start_index + index] != cards[index]:
					return {"allowed": false, "reason": "FreeCell moves must keep the exposed tail together."}
			if cards.size() > 1 and not _is_descending_alternating_run(cards):
				return {"allowed": false, "reason": "Only descending alternating runs can move together."}
			if cards.size() == 1 and start_index != tableau_cards.size() - 1:
				return {"allowed": false, "reason": "Only the exposed top card can move from this tableau."}
			return {"allowed": true, "reason": ""}
		&"freecell", &"foundation":
			if cards.size() != 1:
				return {"allowed": false, "reason": "Only one card can move out of that lane."}
			var source_cards = _typed_cards(source_zone.get_items())
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
	return (empty_free_cells + 1) * (1 << empty_tableaus)

func _typed_cards(items: Array) -> Array:
	var cards: Array = []
	for item in items:
		if item is FreeCellCardScript and is_instance_valid(item):
			cards.append(item)
	return cards

func _is_descending_alternating_run(cards: Array) -> bool:
	if cards.is_empty():
		return false
	for index in range(cards.size() - 1):
		var upper = cards[index] as FreeCellCardScript
		var lower = cards[index + 1] as FreeCellCardScript
		if upper.is_red == lower.is_red:
			return false
		if upper.rank_value != lower.rank_value + 1:
			return false
	return true

func _find_card_index(cards: Array, target: Control) -> int:
	for index in range(cards.size()):
		if cards[index] == target:
			return index
	return -1

func _zone_for_item(item: Control) -> Zone:
	for zone in _all_zones():
		if zone.has_item(item):
			return zone
	return null

func _parse_card_code(code: String) -> Dictionary:
	if code.length() < 2:
		return {}
	var suit_code = code.right(1).to_upper()
	if not SUIT_CODE_TO_NAME.has(suit_code):
		return {}
	var rank_text = code.left(code.length() - 1).to_upper()
	var rank_value = _rank_value_from_text(rank_text)
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

func _rank_value_from_text(rank_text: String) -> int:
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

func _shuffled_deck_codes(seed: int) -> Array[String]:
	_rng.seed = seed
	var deck: Array[String] = []
	for suit_code in ["C", "D", "H", "S"]:
		for rank_value in range(1, 14):
			deck.append("%s%s" % [RANK_LABELS[rank_value], suit_code])
	for index in range(deck.size() - 1, 0, -1):
		var swap_index = _rng.randi_range(0, index)
		var card_code = deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = card_code
	return deck

func _refresh_summary() -> void:
	seed_label.text = "Seed %d  |  Foundations %d / 52  |  Free cells open %d" % [_last_seed, foundation_total(), _count_open_free_cells()]

func _count_open_free_cells() -> int:
	var open_cells := 0
	for zone in _free_cell_zones:
		if zone.get_item_count() == 0:
			open_cells += 1
	return open_cells

func _update_victory_state() -> void:
	_game_won = foundation_total() == 52
	victory_label.visible = _game_won
	if _game_won:
		victory_label.text = "All 52 cards reached the foundations. This deal is solved."
		_set_status("FreeCell solved. All foundations are complete.", WIN_STATUS_COLOR)

func _card_label(item: Control) -> String:
	if item is FreeCellCardScript:
		return (item as FreeCellCardScript).display_name()
	return item.name if item != null else "Card"

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "Latest: %s" % message
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var mode = DemoLayoutSupport.mode_for(self)
	var content_width = max(root_vbox.size.x, DemoLayoutSupport.resolved_width(self) - 40.0)
	var row_spacing = float(top_row.get_theme_constant("h_separation"))
	var compact_column_width = max(420.0, floor((content_width - row_spacing) * 0.5))
	var narrow_column_width = max(0.0, content_width)
	DemoLayoutSupport.set_minimum_width(free_cells_column, mode, 528.0, compact_column_width, narrow_column_width)
	DemoLayoutSupport.set_minimum_width(foundations_column, mode, 528.0, compact_column_width, narrow_column_width)
	var root_spacing = float(root_vbox.get_theme_constant("separation"))
	var reserved_height = _control_height(toolbar) + _control_height(status_label) + (_control_height(victory_label) if victory_label.visible else 0.0) + _control_height(top_row) + root_spacing * 4.0
	var available_scroll_height = clamp(root_vbox.size.y - reserved_height, 240.0, 440.0)
	tableau_scroll.custom_minimum_size = Vector2(0.0, available_scroll_height)
	tableau_row.custom_minimum_size = Vector2(_tableau_content_width(), 0.0)
	for zone in _all_zones():
		zone.refresh()

func _tableau_content_width() -> float:
	var total_width := 0.0
	var child_controls := 0
	for child in tableau_row.get_children():
		if child is not Control:
			continue
		child_controls += 1
		var control := child as Control
		total_width += max(control.custom_minimum_size.x, control.get_combined_minimum_size().x)
	if child_controls <= 1:
		return total_width
	var spacing = float(tableau_row.get_theme_constant("separation"))
	return total_width + spacing * float(child_controls - 1)

func _control_height(control: Control) -> float:
	if control == null:
		return 0.0
	return control.size.y if control.size.y > 0.0 else control.get_combined_minimum_size().y
