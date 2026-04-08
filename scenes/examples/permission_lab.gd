extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

var _deck_zone: Zone
var _hand_zone: Zone
var _board_zone: Zone
var _sanctum_zone: Zone
var _discard_zone: Zone

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var deck_panel: Panel = $RootMargin/RootVBox/Grid/DeckColumn/DeckPanel
@onready var hand_panel: Panel = $RootMargin/RootVBox/Grid/HandColumn/HandPanel
@onready var board_panel: Panel = $RootMargin/RootVBox/Grid/BoardColumn/BoardPanel
@onready var sanctum_panel: Panel = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumPanel
@onready var discard_panel: Panel = $RootMargin/RootVBox/Grid/DiscardColumn/DiscardPanel

func _ready() -> void:
	_configure_panels()
	_build_zones()
	_populate_cards()
	_wire_actions()
	_set_status("Permission lab: double-click deck to draw, right-click hand to send to Board, double-click hand to send to Sanctum. Dragging from the wrong source or exceeding capacity will be rejected.")

func _configure_panels() -> void:
	ExampleSupport.configure_panel(deck_panel, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_panel(hand_panel, Color(0.33, 0.55, 0.42))
	ExampleSupport.configure_panel(board_panel, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_panel(sanctum_panel, Color(0.63, 0.41, 0.68))
	ExampleSupport.configure_panel(discard_panel, Color(0.53, 0.26, 0.31))

func _build_zones() -> void:
	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 16.0
	var hand_layout := ZoneHBoxLayout.new()
	hand_layout.item_spacing = 14.0
	hand_layout.padding_left = 14.0
	var board_layout := ZoneHBoxLayout.new()
	board_layout.item_spacing = 16.0
	board_layout.padding_left = 14.0
	var sanctum_layout := ZoneVBoxLayout.new()
	sanctum_layout.item_spacing = 10.0
	sanctum_layout.padding_top = 14.0

	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 2
	board_capacity.reject_reason = "Board only allows two cards in this example."

	var sanctum_source := ZoneSourcePermission.new()
	sanctum_source.allowed_source_zone_names = PackedStringArray(["HandZone"])
	sanctum_source.reject_reason = "Sanctum only accepts cards that come from HandZone."

	_deck_zone = ExampleSupport.make_zone(deck_panel, "DeckZone", pile_layout)
	_hand_zone = ExampleSupport.make_zone(hand_panel, "HandZone", hand_layout)
	_board_zone = ExampleSupport.make_zone(board_panel, "BoardZone", board_layout, null, board_capacity)
	_sanctum_zone = ExampleSupport.make_zone(sanctum_panel, "SanctumZone", sanctum_layout, null, sanctum_source)
	_discard_zone = ExampleSupport.make_zone(discard_panel, "DiscardZone", pile_layout)

func _populate_cards() -> void:
	for spec in [
		{"title": "Rune", "cost": 1, "tags": ["skill"]},
		{"title": "Shard", "cost": 1, "tags": ["attack"]},
		{"title": "Beacon", "cost": 2, "tags": ["power"]},
		{"title": "Mirror", "cost": 2, "tags": ["skill"]}
	]:
		_deck_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], false))

	for spec in [
		{"title": "Bloom", "cost": 2, "tags": ["power"]},
		{"title": "Trace", "cost": 1, "tags": ["skill"]},
		{"title": "Arc", "cost": 1, "tags": ["attack"]}
	]:
		_hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))

func _wire_actions() -> void:
	_deck_zone.item_double_clicked.connect(_draw_to_hand)
	_hand_zone.item_double_clicked.connect(_send_hand_to_sanctum)
	_hand_zone.item_right_clicked.connect(_send_hand_to_board)
	_board_zone.item_right_clicked.connect(_discard_card)
	_sanctum_zone.item_right_clicked.connect(_discard_card)

	for zone in [_deck_zone, _hand_zone, _board_zone, _sanctum_zone, _discard_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))

func _draw_to_hand(item: Control) -> void:
	if _deck_zone.has_item(item):
		_deck_zone.move_item_to(item, _hand_zone, _hand_zone.get_item_count())

func _send_hand_to_sanctum(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _sanctum_zone, _sanctum_zone.get_item_count())

func _send_hand_to_board(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _board_zone, _board_zone.get_item_count())

func _discard_card(item: Control) -> void:
	for zone in [_board_zone, _sanctum_zone]:
		if zone.has_item(item):
			zone.move_item_to(item, _discard_zone, _discard_zone.get_item_count())
			return

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, to_index: int, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	if item is ZoneCard:
		var card := item as ZoneCard
		card.highlighted = target_zone == _sanctum_zone
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
