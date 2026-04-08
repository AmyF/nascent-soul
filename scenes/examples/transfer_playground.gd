extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

var _deck_zone: Zone
var _hand_zone: Zone
var _board_zone: Zone
var _discard_zone: Zone

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var deck_panel: Panel = $RootMargin/RootVBox/TopRow/DeckColumn/DeckPanel
@onready var board_panel: Panel = $RootMargin/RootVBox/TopRow/BoardColumn/BoardPanel
@onready var discard_panel: Panel = $RootMargin/RootVBox/TopRow/DiscardColumn/DiscardPanel
@onready var hand_panel: Panel = $RootMargin/RootVBox/HandPanel

func _ready() -> void:
	_configure_panels()
	_build_zones()
	_populate_cards()
	_wire_demo_actions()
	_set_status("Playground: drag between zones, double-click deck to draw, double-click hand to play, right-click hand or board to discard.")

func _configure_panels() -> void:
	ExampleSupport.configure_panel(deck_panel, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_panel(board_panel, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_panel(discard_panel, Color(0.53, 0.26, 0.31))
	ExampleSupport.configure_panel(hand_panel, Color(0.33, 0.55, 0.42))

func _build_zones() -> void:
	var hand_layout := ZoneHandLayout.new()
	hand_layout.arch_angle_deg = 42.0
	hand_layout.arch_height = 34.0
	hand_layout.card_spacing_angle = 5.5
	hand_layout.center_offset_y = 0.0

	var board_layout := ZoneHBoxLayout.new()
	board_layout.item_spacing = 18.0
	board_layout.padding_left = 18.0

	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 18.0

	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 5
	board_capacity.reject_reason = "Board is full. Try discarding first."

	_deck_zone = ExampleSupport.make_zone(deck_panel, "DeckZone", pile_layout)
	_hand_zone = ExampleSupport.make_zone(hand_panel, "HandZone", hand_layout)
	_board_zone = ExampleSupport.make_zone(board_panel, "BoardZone", board_layout, null, board_capacity)
	_discard_zone = ExampleSupport.make_zone(discard_panel, "DiscardZone", pile_layout)

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
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Orbit", "cost": 2, "tags": ["attack"]}
	]:
		_hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"]))

	for spec in [
		{"title": "Sentinel", "cost": 3, "tags": ["power"]},
		{"title": "Pulse", "cost": 2, "tags": ["attack"]}
	]:
		_board_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true, true))

func _wire_demo_actions() -> void:
	_deck_zone.item_double_clicked.connect(_on_deck_card_double_clicked)
	_hand_zone.item_double_clicked.connect(_on_hand_card_double_clicked)
	_hand_zone.item_right_clicked.connect(_on_card_discard_requested)
	_board_zone.item_right_clicked.connect(_on_card_discard_requested)

	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.item_reordered.connect(_on_item_reordered.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))

func _on_deck_card_double_clicked(item: Control) -> void:
	if _deck_zone.has_item(item):
		_deck_zone.move_item_to(item, _hand_zone, _hand_zone.get_item_count())

func _on_hand_card_double_clicked(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _board_zone, _board_zone.get_item_count())

func _on_card_discard_requested(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _discard_zone, _discard_zone.get_item_count())
	elif _board_zone.has_item(item):
		_board_zone.move_item_to(item, _discard_zone, _discard_zone.get_item_count())

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, to_index: int, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_apply_zone_visual_state(item, target_zone)
	_set_status("%s moved from %s to %s at index %d." % [item.name, source_zone.name, target_zone.name, to_index])

func _on_item_reordered(item: Control, from_index: int, to_index: int, emitter_zone: Zone) -> void:
	_set_status("%s reordered inside %s from %d to %d." % [item.name, emitter_zone.name, from_index, to_index])

func _on_drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	_set_status("%s could not enter %s: %s" % [item_name, target_zone.name, reason])

func _apply_zone_visual_state(item: Control, target_zone: Zone) -> void:
	if item is not ZoneCard:
		return
	var card := item as ZoneCard
	card.highlighted = target_zone == _board_zone
	card.flip(target_zone != _deck_zone, false)

func _set_status(message: String) -> void:
	status_label.text = message
