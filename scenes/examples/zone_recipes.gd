extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

var _deck_zone: Zone
var _hand_zone: Zone
var _board_zone: Zone
var _discard_zone: Zone

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var deck_details: Label = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckDetails
@onready var hand_details: Label = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandDetails
@onready var board_details: Label = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails
@onready var discard_details: Label = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardDetails
@onready var deck_panel: Panel = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckPanel
@onready var hand_panel: Panel = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandPanel
@onready var board_panel: Panel = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardPanel
@onready var discard_panel: Panel = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardPanel

func _ready() -> void:
	_configure_panels()
	_describe_recipes()
	_build_zones()
	_populate_cards()
	_wire_actions()
	_set_status("Recipe board: start from Deck / Hand / Board / Discard, then replace the policies or visuals that are unique to your game.")

func _configure_panels() -> void:
	ExampleSupport.configure_panel(deck_panel, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_panel(hand_panel, Color(0.33, 0.55, 0.42))
	ExampleSupport.configure_panel(board_panel, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_panel(discard_panel, Color(0.53, 0.26, 0.31))

func _describe_recipes() -> void:
	deck_details.text = "Pile layout + ZoneCardDisplay\nBest for draw piles and hidden stacks."
	hand_details.text = "Hand layout + multi-select\nUse for player hands and reveal zones."
	board_details.text = "HBox layout + capacity permission\nUse for battlefield rows or active slots."
	discard_details.text = "Pile layout + allow-all permission\nUse for discard, graveyard, or exhaust piles."

func _build_zones() -> void:
	var deck_layout := ZonePileLayout.new()
	deck_layout.overlap_x = 16.0
	var hand_layout := ZoneHandLayout.new()
	hand_layout.arch_angle_deg = 38.0
	hand_layout.arch_height = 26.0
	hand_layout.card_spacing_angle = 5.5
	var board_layout := ZoneHBoxLayout.new()
	board_layout.item_spacing = 16.0
	board_layout.padding_left = 14.0
	board_layout.padding_top = 12.0
	var discard_layout := ZonePileLayout.new()
	discard_layout.overlap_x = 18.0
	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 4
	board_capacity.reject_reason = "Board recipe is full. Raise max_items or discard a card."
	_deck_zone = ExampleSupport.make_zone(deck_panel, "DeckZone", deck_layout)
	_hand_zone = ExampleSupport.make_zone(hand_panel, "HandZone", hand_layout)
	_board_zone = ExampleSupport.make_zone(board_panel, "BoardZone", board_layout, null, board_capacity)
	_discard_zone = ExampleSupport.make_zone(discard_panel, "DiscardZone", discard_layout)

func _populate_cards() -> void:
	for spec in [
		{"title": "Spark", "cost": 1, "tags": ["attack"]},
		{"title": "Shell", "cost": 1, "tags": ["skill"]},
		{"title": "Focus", "cost": 2, "tags": ["power"]},
		{"title": "Gale", "cost": 1, "tags": ["attack"]},
		{"title": "Echo", "cost": 2, "tags": ["skill"]},
		{"title": "Nova", "cost": 3, "tags": ["attack"]}
	]:
		_deck_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], false))
	for spec in [
		{"title": "Tether", "cost": 1, "tags": ["skill"]},
		{"title": "Bloom", "cost": 2, "tags": ["power"]},
		{"title": "Strike", "cost": 1, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]}
	]:
		_hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
	for spec in [
		{"title": "Sentinel", "cost": 3, "tags": ["power"]},
		{"title": "Pulse", "cost": 2, "tags": ["attack"]}
	]:
		_board_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true, true))

func _wire_actions() -> void:
	reset_button.pressed.connect(_reset_recipe)
	_deck_zone.item_double_clicked.connect(_draw_to_hand)
	_hand_zone.item_double_clicked.connect(_play_to_board)
	_hand_zone.item_right_clicked.connect(_discard_from_hand)
	_board_zone.item_right_clicked.connect(_discard_from_board)
	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))

func _reset_recipe() -> void:
	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		for item in zone.get_items():
			zone.remove_item(item)
			item.queue_free()
	_populate_cards()
	_set_status("Recipe board reset. This scene is meant to be copied into a new project and then customized.")

func _draw_to_hand(item: Control) -> void:
	if _deck_zone.has_item(item):
		_deck_zone.move_item_to(item, _hand_zone, _hand_zone.get_item_count())

func _play_to_board(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _board_zone, _board_zone.get_item_count())

func _discard_from_hand(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _discard_zone, _discard_zone.get_item_count())

func _discard_from_board(item: Control) -> void:
	if _board_zone.has_item(item):
		_board_zone.move_item_to(item, _discard_zone, _discard_zone.get_item_count())

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, to_index: int, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	if item is ZoneCard:
		var card := item as ZoneCard
		card.highlighted = target_zone == _board_zone
		card.flip(target_zone != _deck_zone, false)
	_set_status("%s moved from %s to %s at index %d." % [item.name, source_zone.name, target_zone.name, to_index])

func _on_drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	var source_name = source_zone.name if source_zone != null else "Unknown"
	_set_status("%s from %s was rejected by %s: %s" % [item_name, source_name, target_zone.name, reason])

func _set_status(message: String) -> void:
	status_label.text = message
