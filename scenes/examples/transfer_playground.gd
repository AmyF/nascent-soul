extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")
const DISCARD_PRESET = preload("res://addons/nascentsoul/presets/discard_zone_preset.tres")

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/TopRow/DeckColumn/DeckZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/TopRow/BoardColumn/BoardZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/TopRow/DiscardColumn/DiscardZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/HandZone

func _ready() -> void:
	_configure_zones()
	_populate_cards()
	_wire_demo_actions()
	_set_status("Playground: drag between zones, double-click deck to draw, double-click hand to play, right-click hand or board to discard.")

func _configure_zones() -> void:
	_deck_zone.preset = PILE_PRESET
	_hand_zone.preset = HAND_PRESET
	_board_zone.preset = BOARD_PRESET
	_discard_zone.preset = DISCARD_PRESET
	var board_capacity := ZoneCapacityPermission.new()
	board_capacity.max_items = 5
	board_capacity.reject_reason = "Board is full. Try discarding first."
	_board_zone.permission_policy = board_capacity

	var drag_visual_factory := ZoneConfigurableDragVisualFactory.new()
	drag_visual_factory.ghost_mode = ZoneConfigurableDragVisualFactory.GhostMode.OUTLINE_PANEL
	drag_visual_factory.ghost_fill_color = Color(0.96, 0.93, 0.84, 0.08)
	drag_visual_factory.ghost_border_color = Color(0.96, 0.80, 0.30, 0.72)
	drag_visual_factory.proxy_mode = ZoneConfigurableDragVisualFactory.ProxyMode.DUPLICATE
	drag_visual_factory.proxy_modulate = Color(1, 1, 1, 0.88)
	drag_visual_factory.proxy_scale = Vector2(1.04, 1.04)
	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		zone.drag_visual_factory = drag_visual_factory
		zone.refresh()
	ExampleSupport.configure_zone(_deck_zone, Color(0.59, 0.53, 0.26))
	ExampleSupport.configure_zone(_board_zone, Color(0.27, 0.48, 0.70))
	ExampleSupport.configure_zone(_discard_zone, Color(0.53, 0.26, 0.31))
	ExampleSupport.configure_zone(_hand_zone, Color(0.33, 0.55, 0.42))

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
