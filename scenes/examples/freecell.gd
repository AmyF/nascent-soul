extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const FreeCellCardScript = preload("res://scenes/examples/freecell/freecell_card.gd")
const FreeCellCardDisplayScript = preload("res://scenes/examples/freecell/freecell_card_display.gd")
const FreeCellRulesScript = preload("res://scenes/examples/freecell/freecell_rules.gd")
const FreeCellSlotLayoutScript = preload("res://scenes/examples/freecell/freecell_slot_layout.gd")
const FreeCellTableauLayoutScript = preload("res://scenes/examples/freecell/freecell_tableau_layout.gd")
const FreeCellZonePolicyScript = preload("res://scenes/examples/freecell/freecell_zone_policy.gd")
const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

const GAME_MENU_NEW := 1
const GAME_MENU_SELECT := 2
const GAME_MENU_RESTART := 3
const HELP_MENU_RULES := 11
const HELP_MENU_ABOUT := 12

const NORMAL_STATUS_COLOR := Color(0.10, 0.10, 0.10, 1.0)
const REJECT_STATUS_COLOR := Color(0.72, 0.09, 0.12, 1.0)
const WIN_STATUS_COLOR := Color(0.20, 0.42, 0.12, 1.0)
const SUIT_ORDER := FreeCellRulesScript.SUIT_ORDER
const DEAL_MAX := FreeCellRulesScript.DEAL_MAX
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
const RANK_LABELS := FreeCellRulesScript.RANK_LABELS

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var title_bar: PanelContainer = $RootMargin/RootVBox/TitleBar
@onready var window_title_label: Label = $RootMargin/RootVBox/TitleBar/TitleBarRow/WindowTitleLabel
@onready var toolbar: PanelContainer = $RootMargin/RootVBox/Toolbar
@onready var game_menu_button: MenuButton = $RootMargin/RootVBox/Toolbar/ToolbarRow/GameMenuButton
@onready var help_menu_button: MenuButton = $RootMargin/RootVBox/Toolbar/ToolbarRow/HelpMenuButton
@onready var deal_label: Label = $RootMargin/RootVBox/Toolbar/ToolbarRow/SeedLabel
@onready var top_row: HBoxContainer = $RootMargin/RootVBox/TopRow
@onready var free_cells_slots_row: HBoxContainer = $RootMargin/RootVBox/TopRow/FreeCellsSlotsRow
@onready var foundations_slots_row: HBoxContainer = $RootMargin/RootVBox/TopRow/FoundationsSlotsRow
@onready var tableau_scroll: ScrollContainer = $RootMargin/RootVBox/TableauScroll
@onready var tableau_row: HBoxContainer = $RootMargin/RootVBox/TableauScroll/TableauRow
@onready var victory_label: Label = $RootMargin/RootVBox/VictoryLabel
@onready var status_bar: PanelContainer = $RootMargin/RootVBox/StatusBar
@onready var status_label: Label = $RootMargin/RootVBox/StatusBar/StatusLabel
@onready var select_game_overlay: Control = $SelectGameOverlay
@onready var select_game_spin_box: SpinBox = $SelectGameOverlay/DialogPanel/DialogVBox/SelectGameSpinBox
@onready var select_game_ok_button: Button = $SelectGameOverlay/DialogPanel/DialogVBox/ButtonRow/SelectGameOkButton
@onready var select_game_cancel_button: Button = $SelectGameOverlay/DialogPanel/DialogVBox/ButtonRow/SelectGameCancelButton

var _tableau_zones: Array[Zone] = []
var _free_cell_zones: Array[Zone] = []
var _foundation_zones: Array[Zone] = []
var _zone_info: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _last_deal_number: int = 1
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

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if select_game_overlay.visible:
		if key_event.keycode == KEY_ESCAPE:
			_hide_select_game_overlay()
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
			_on_select_game_confirmed()
			get_viewport().set_input_as_handled()
			return
	if key_event.keycode == KEY_F2:
		start_new_game()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F5:
		start_new_game(_last_deal_number)
		get_viewport().set_input_as_handled()
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_G:
		_show_select_game_overlay()
		get_viewport().set_input_as_handled()

func start_new_game(deal_number: int = -1) -> void:
	_last_deal_number = deal_number if deal_number > 0 else _random_deal_number()
	_game_won = false
	victory_label.visible = false
	_hide_select_game_overlay()
	_clear_all_cards()
	var deck_codes = FreeCellRulesScript.deal_codes(_last_deal_number)
	for index in range(deck_codes.size()):
		var zone = _tableau_zones[index % _tableau_zones.size()]
		zone.add_item(_make_card_from_code(deck_codes[index]))
	_refresh_chrome()
	_set_status("Classic FreeCell ready. Drag cards or double-click to send exposed cards home.")

func load_debug_state(state: Dictionary) -> void:
	_game_won = false
	victory_label.visible = false
	_hide_select_game_overlay()
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
		var zone = _preferred_foundation_zone_for_suit(suit)
		if zone == null:
			continue
		for code in foundations[suit_name]:
			zone.add_item(_make_card_from_code(str(code)))
	_refresh_chrome()
	_update_victory_state()
	if not _game_won:
		_set_status("Loaded a FreeCell position for debugging.")

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
	var source_role = StringName(_zone_info.get(source_zone, {}).get("role", &""))
	if source_role == &"foundation":
		return false
	if not _is_exposed_card(freecell_card):
		return false
	if not _is_foundation_move_legal(freecell_card):
		return false
	return _move_card_to_foundation(freecell_card)

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
	var source_role = StringName(source_info.get("role", &""))
	var source_validation = _validate_source_cards(source_zone, source_role, cards)
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
	var drag_factory := ZoneConfigurableDragVisualFactory.new()
	drag_factory.ghost_fill_color = Color(1.0, 1.0, 1.0, 0.10)
	drag_factory.ghost_border_color = Color(0.08, 0.09, 0.11, 0.75)
	drag_factory.proxy_modulate = Color(1.0, 1.0, 1.0, 0.96)
	for index in range(free_cells_slots_row.get_child_count()):
		var host = free_cells_slots_row.get_child(index).get_node("ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"freecell"
		policy.zone_index = index
		var layout := FreeCellSlotLayoutScript.new()
		var zone = ExampleSupport.make_zone(host, "FreeCell%d" % (index + 1), layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"freecell", index)
		_bind_zone_events(zone)
		_free_cell_zones.append(zone)
	for index in range(foundations_slots_row.get_child_count()):
		var host = foundations_slots_row.get_child(index).get_node("ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"foundation"
		policy.zone_index = index
		var layout := FreeCellSlotLayoutScript.new()
		var zone = ExampleSupport.make_zone(host, "Foundation%d" % (index + 1), layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"foundation", index)
		_bind_zone_events(zone)
		_foundation_zones.append(zone)
	for index in range(tableau_row.get_child_count()):
		var host = tableau_row.get_child(index).get_node("ZoneHost") as Control
		var policy = FreeCellZonePolicyScript.new()
		policy.controller = self
		policy.zone_role = &"tableau"
		policy.zone_index = index
		var layout = FreeCellTableauLayoutScript.new()
		var zone = ExampleSupport.make_zone(host, "Tableau%d" % (index + 1), layout, display_style, policy, ZoneManualSort.new(), interaction, drag_factory)
		_register_zone(zone, &"tableau", index)
		_bind_zone_events(zone)
		_tableau_zones.append(zone)

func _wire_controls() -> void:
	select_game_overlay.visible = false
	select_game_spin_box.min_value = 1
	select_game_spin_box.max_value = DEAL_MAX
	select_game_spin_box.step = 1
	select_game_ok_button.pressed.connect(_on_select_game_confirmed)
	select_game_cancel_button.pressed.connect(_hide_select_game_overlay)

	var game_popup = game_menu_button.get_popup()
	game_popup.clear()
	game_popup.add_item("New Game\tF2", GAME_MENU_NEW)
	game_popup.add_item("Select Game...\tCtrl+G", GAME_MENU_SELECT)
	game_popup.add_item("Restart This Game\tF5", GAME_MENU_RESTART)
	game_popup.id_pressed.connect(_on_game_menu_id_pressed)

	var help_popup = help_menu_button.get_popup()
	help_popup.clear()
	help_popup.add_item("How to Play", HELP_MENU_RULES)
	help_popup.add_item("About This Showcase", HELP_MENU_ABOUT)
	help_popup.id_pressed.connect(_on_help_menu_id_pressed)

func _bind_zone_events(zone: Zone) -> void:
	zone.item_transferred.connect(_on_item_transferred.bind(zone))
	zone.drop_rejected.connect(_on_drop_rejected.bind(zone))
	zone.drag_start_rejected.connect(_on_drag_start_rejected.bind(zone))
	zone.item_double_clicked.connect(_on_item_double_clicked.bind(zone))
	zone.item_right_clicked.connect(_on_item_right_clicked.bind(zone))
	zone.item_clicked.connect(_on_zone_item_clicked.bind(zone))

func _register_zone(zone: Zone, role: StringName, index: int) -> void:
	_zone_info[zone] = {
		"role": role,
		"index": index
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
	for zone in _all_zones():
		zone.clear_selection()
		for item in zone.get_items():
			if zone.remove_item(item):
				item.queue_free()

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
	return card

func _on_zone_item_clicked(item: Control, zone: Zone) -> void:
	if zone == null or item == null:
		return
	var role = StringName(_zone_info.get(zone, {}).get("role", &""))
	if role == &"tableau":
		_select_movable_tail(zone, item)
		return
	_select_single_card(zone, item)

func _on_item_double_clicked(item: Control, _zone: Zone) -> void:
	if try_auto_foundation(item):
		return
	_set_status("%s cannot move to the foundations yet." % _card_label(item), REJECT_STATUS_COLOR)

func _on_item_right_clicked(item: Control, _zone: Zone) -> void:
	if try_auto_foundation(item):
		return
	_set_status("%s stays where it is." % _card_label(item), REJECT_STATUS_COLOR)

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, _target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_refresh_chrome()
	_update_victory_state()
	if _game_won:
		return
	_set_status("%s moved from %s to %s." % [_card_label(item), _zone_display_name(source_zone), _zone_display_name(target_zone)])

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

func _on_game_menu_id_pressed(id: int) -> void:
	match id:
		GAME_MENU_NEW:
			start_new_game()
		GAME_MENU_SELECT:
			_show_select_game_overlay()
		GAME_MENU_RESTART:
			start_new_game(_last_deal_number)

func _on_help_menu_id_pressed(id: int) -> void:
	match id:
		HELP_MENU_RULES:
			_set_status("Build down by alternating color. Build the foundations up from Ace to King in suit.")
		HELP_MENU_ABOUT:
			_set_status("Windows XP style FreeCell showcase built on NascentSoul card zones.")

func _on_select_game_confirmed() -> void:
	var next_deal = int(select_game_spin_box.value)
	_hide_select_game_overlay()
	start_new_game(next_deal)

func _show_select_game_overlay() -> void:
	select_game_spin_box.value = _last_deal_number
	select_game_overlay.visible = true
	select_game_spin_box.grab_focus()

func _hide_select_game_overlay() -> void:
	select_game_overlay.visible = false

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

func _evaluate_transfer_to_foundation(_zone_index: int, target_zone: Zone, cards: Array) -> ZoneTransferDecision:
	if cards.size() != 1:
		return ZoneTransferDecision.new(false, "Foundations only accept one card at a time.", ZonePlacementTarget.invalid())
	var card = cards[0] as FreeCellCardScript
	var foundation_cards = _typed_cards(target_zone.get_items())
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
	var target_cards = _typed_cards(target_zone.get_items())
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
	return FreeCellRulesScript.movable_run_capacity(empty_free_cells, empty_tableaus)

func _typed_cards(items: Array) -> Array:
	var cards: Array = []
	for item in items:
		if item is FreeCellCardScript and is_instance_valid(item):
			cards.append(item)
	return cards

func _is_descending_alternating_run(cards: Array) -> bool:
	return FreeCellRulesScript.is_descending_alternating_run(cards)

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

func _refresh_chrome() -> void:
	window_title_label.text = "FreeCell Game #%d" % _last_deal_number
	deal_label.text = "Game #%d" % _last_deal_number

func _random_deal_number() -> int:
	_rng.seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	return _rng.randi_range(1, DEAL_MAX)

func _move_card_to_foundation(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var source_zone = _zone_for_item(card)
	if source_zone == null:
		return false
	var target_zone = _foundation_zone_for_card(card)
	if target_zone == null:
		return false
	return ExampleSupport.move_item(source_zone, card, target_zone, ZonePlacementTarget.linear(target_zone.get_item_count()))

func _is_exposed_card(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var source_zone = _zone_for_item(card)
	if source_zone == null:
		return false
	var source_cards = _typed_cards(source_zone.get_items())
	return not source_cards.is_empty() and source_cards[source_cards.size() - 1] == card

func _is_foundation_move_legal(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var target_zone = _foundation_zone_for_card(card)
	if target_zone == null:
		return false
	return FreeCellRulesScript.foundation_accepts_card(_typed_cards(target_zone.get_items()), card)

func _foundation_zone_for_card(card: FreeCellCardScript) -> Zone:
	if not is_instance_valid(card):
		return null
	var started_zone = _foundation_zone_for_suit(card.suit)
	if started_zone != null:
		return started_zone
	if card.rank_value != 1:
		return null
	return _first_empty_foundation_zone()

func _foundation_zone_for_suit(suit: StringName) -> Zone:
	for zone in _foundation_zones:
		var cards = _typed_cards(zone.get_items())
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

func _preferred_foundation_zone_for_suit(suit: StringName) -> Zone:
	var suit_index = SUIT_ORDER.find(suit)
	if suit_index < 0 or suit_index >= _foundation_zones.size():
		return null
	return _foundation_zones[suit_index]

func _update_victory_state() -> void:
	_game_won = foundation_total() == 52
	victory_label.visible = _game_won
	if _game_won:
		victory_label.text = "You won."
		_set_status("Every card reached the foundations. Press F2 for a new game.", WIN_STATUS_COLOR)

func _card_label(item: Control) -> String:
	if item is FreeCellCardScript:
		return (item as FreeCellCardScript).display_name()
	return item.name if item != null else "Card"

func _zone_display_name(zone: Zone) -> String:
	if zone == null:
		return "Unknown"
	var info = _zone_info.get(zone, {})
	var role = StringName(info.get("role", &""))
	var index = int(info.get("index", 0)) + 1
	match role:
		&"freecell":
			return "Free Cell %d" % index
		&"foundation":
			return "Foundation %d" % index
		&"tableau":
			return "Tableau %d" % index
		_:
			return zone.name

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	tableau_row.custom_minimum_size = Vector2(_tableau_content_width(), 0.0)
	var reserved_height = _control_height(title_bar) + _control_height(toolbar) + _control_height(top_row) + _control_height(status_bar) + (_control_height(victory_label) if victory_label.visible else 0.0) + 28.0
	var available_height = clamp(size.y - reserved_height, 260.0, 520.0)
	tableau_scroll.custom_minimum_size = Vector2(0.0, available_height)
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
