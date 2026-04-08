extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")
const DISCARD_PRESET = preload("res://addons/nascentsoul/presets/discard_zone_preset.tres")

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var deck_details: Label = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckDetails
@onready var hand_details: Label = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandDetails
@onready var board_details: Label = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails
@onready var discard_details: Label = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardDetails
@onready var _deck_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardZone

func _ready() -> void:
	_describe_recipes()
	_configure_zones()
	_populate_cards()
	_wire_actions()
	_set_status("Recipe board: start from Deck / Hand / Board / Discard, then replace the policies or visuals that are unique to your game.")

func _describe_recipes() -> void:
	deck_details.text = "Pile layout + ZoneCardDisplay\nBest for draw piles and hidden stacks."
	hand_details.text = "Hand layout + multi-select\nUse for player hands and reveal zones."
	board_details.text = "HBox layout + capacity permission\nUse for battlefield rows or active slots."
	discard_details.text = "Pile layout + allow-all permission\nUse for discard, graveyard, or exhaust piles."

func _configure_zones() -> void:
	_deck_zone.preset = PILE_PRESET
	_hand_zone.preset = HAND_PRESET
	_board_zone.preset = BOARD_PRESET
	_discard_zone.preset = DISCARD_PRESET
	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 4
	board_capacity.reject_reason = "Board recipe is full. Raise max_items or discard a card."
	_board_zone.permission_policy = board_capacity
	ExampleSupport.configure_zone(_deck_zone, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_zone(_hand_zone, Color(0.33, 0.55, 0.42))
	ExampleSupport.configure_zone(_board_zone, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_zone(_discard_zone, Color(0.53, 0.26, 0.31))

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
