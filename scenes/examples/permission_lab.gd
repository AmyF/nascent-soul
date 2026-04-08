extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const ZoneCompositePermissionScript = preload("res://addons/nascentsoul/impl/permissions/zone_composite_permission.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")
const DISCARD_PRESET = preload("res://addons/nascentsoul/presets/discard_zone_preset.tres")

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/Grid/DeckColumn/DeckZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/Grid/BoardColumn/BoardZone
@onready var _sanctum_zone: Zone = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/Grid/DiscardColumn/DiscardZone

func _ready() -> void:
	_configure_zones()
	_populate_cards()
	_wire_actions()
	_set_status("Permission lab: double-click deck to draw, right-click hand to send to Board, double-click hand to send to Sanctum. Board and Sanctum now both enforce their permission rules for drag-and-drop and direct move_item_to calls.")

func _configure_zones() -> void:
	_deck_zone.preset = PILE_PRESET
	_hand_zone.preset = HAND_PRESET
	_board_zone.preset = BOARD_PRESET
	_discard_zone.preset = DISCARD_PRESET

	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 16.0
	var sanctum_layout := ZoneVBoxLayout.new()
	sanctum_layout.item_spacing = 10.0
	sanctum_layout.padding_top = 14.0

	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 2
	board_capacity.reject_reason = "Board only allows two cards in this example."
	_board_zone.permission_policy = board_capacity

	var sanctum_source := ZoneSourcePermission.new()
	sanctum_source.allowed_source_zone_names = PackedStringArray(["HandZone"])
	sanctum_source.reject_reason = "Sanctum only accepts cards that come from HandZone."

	var sanctum_capacity := ZoneCapacityPermission.new()
	sanctum_capacity.max_items = 2
	sanctum_capacity.reject_reason = "Sanctum only allows two cards in this example."

	var sanctum_rules := ZoneCompositePermissionScript.new()
	sanctum_rules.combine_mode = ZoneCompositePermissionScript.CombineMode.ALL
	sanctum_rules.policies = [sanctum_source, sanctum_capacity]

	_deck_zone.layout_policy = pile_layout
	_sanctum_zone.layout_policy = sanctum_layout
	_sanctum_zone.permission_policy = sanctum_rules
	ExampleSupport.configure_zone(_deck_zone, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_zone(_hand_zone, Color(0.33, 0.55, 0.42))
	ExampleSupport.configure_zone(_board_zone, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_zone(_sanctum_zone, Color(0.63, 0.41, 0.68))
	ExampleSupport.configure_zone(_discard_zone, Color(0.53, 0.26, 0.31))

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
