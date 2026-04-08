extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")
const DISCARD_PRESET = preload("res://addons/nascentsoul/presets/discard_zone_preset.tres")

const DECK_ACCENT := Color(0.59, 0.53, 0.26)
const HAND_ACCENT := Color(0.33, 0.55, 0.42)
const BOARD_ACCENT := Color(0.27, 0.48, 0.70)
const DISCARD_ACCENT := Color(0.53, 0.26, 0.31)
const REJECT_COLOR := Color(0.96, 0.60, 0.56)
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

var _board_capacity: ZoneCapacityPermission
var _board_rule_label: Label

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var deck_column: VBoxContainer = $RootMargin/RootVBox/TopRow/DeckColumn
@onready var deck_label: Label = $RootMargin/RootVBox/TopRow/DeckColumn/DeckLabel
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/TopRow/BoardColumn
@onready var board_label: Label = $RootMargin/RootVBox/TopRow/BoardColumn/BoardLabel
@onready var discard_column: VBoxContainer = $RootMargin/RootVBox/TopRow/DiscardColumn
@onready var discard_label: Label = $RootMargin/RootVBox/TopRow/DiscardColumn/DiscardLabel
@onready var hand_label: Label = $RootMargin/RootVBox/HandLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/TopRow/DeckColumn/DeckZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/TopRow/BoardColumn/BoardZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/TopRow/DiscardColumn/DiscardZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/HandZone

func _ready() -> void:
	root_vbox.add_theme_constant_override("separation", 10)
	_apply_scene_copy()
	_configure_zones()
	_populate_cards()
	_wire_demo_actions()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("主线流程已就绪", "The main flow is ready"))
	_schedule_headless_quit_if_root()

func _apply_scene_copy() -> void:
	deck_label.text = ExampleSupport.compact_bilingual("牌库", "Deck")
	hand_label.text = ExampleSupport.compact_bilingual("手牌", "Hand")
	board_label.text = ExampleSupport.compact_bilingual("战场", "Board")
	discard_label.text = ExampleSupport.compact_bilingual("弃牌堆", "Discard")
	ExampleSupport.style_heading_label(deck_label, Color(0.96, 0.92, 0.74))
	ExampleSupport.style_heading_label(hand_label, Color(0.84, 0.96, 0.88))
	ExampleSupport.style_heading_label(board_label, Color(0.83, 0.91, 0.99))
	ExampleSupport.style_heading_label(discard_label, Color(0.97, 0.85, 0.88))
	_board_rule_label = _ensure_detail_label(board_column, "BoardRuleLabel", 1)
	ExampleSupport.style_status_label(status_label, HAND_ACCENT)
	root_vbox.move_child(status_label, root_vbox.get_child_count() - 1)

func _configure_zones() -> void:
	_deck_zone.preset = PILE_PRESET
	_hand_zone.preset = HAND_PRESET
	_board_zone.preset = BOARD_PRESET
	_discard_zone.preset = DISCARD_PRESET
	_board_capacity = ZoneCapacityPermission.new()
	_board_capacity.max_items = 5
	_board_capacity.reject_reason = ExampleSupport.bilingual(
		"Board 已满。先把一张牌丢进 Discard 再试。",
		"Board is full. Discard a card first, then try again."
	)
	_board_zone.permission_policy = _board_capacity

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
	ExampleSupport.configure_zone(_deck_zone, DECK_ACCENT)
	ExampleSupport.configure_zone(_board_zone, BOARD_ACCENT)
	ExampleSupport.configure_zone(_discard_zone, DISCARD_ACCENT)
	ExampleSupport.configure_zone(_hand_zone, HAND_ACCENT)

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
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"%s: %s -> %s @ %d" % [item.name, source_zone.name, target_zone.name, to_index],
		"%s: %s -> %s @ %d" % [item.name, source_zone.name, target_zone.name, to_index]
	))

func _on_item_reordered(item: Control, from_index: int, to_index: int, emitter_zone: Zone) -> void:
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"%s 在 %s 中 %d -> %d" % [item.name, emitter_zone.name, from_index, to_index],
		"%s in %s %d -> %d" % [item.name, emitter_zone.name, from_index, to_index]
	))

func _on_drop_rejected(items: Array, _source_zone: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_refresh_guidance()
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	_set_status(ExampleSupport.compact_bilingual(
		"%s 无法进入 %s：%s" % [item_name, target_zone.name, reason],
		"%s could not enter %s: %s" % [item_name, target_zone.name, reason]
	), REJECT_COLOR)

func _apply_zone_visual_state(item: Control, target_zone: Zone) -> void:
	if item is not ZoneCard:
		return
	var card := item as ZoneCard
	card.highlighted = target_zone == _board_zone
	card.flip(target_zone != _deck_zone, false)

func _refresh_guidance() -> void:
	var board_count = _board_zone.get_item_count()
	var board_limit = _board_capacity.max_items if _board_capacity != null else 0
	_board_rule_label.text = ExampleSupport.compact_bilingual(
		"战场 %d / %d，满员时直接拒绝放置" % [board_count, board_limit],
		"Board %d / %d, full state rejects drops" % [board_count, board_limit]
	)

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _ensure_detail_label(parent: Node, label_name: String, insert_index: int) -> Label:
	var label = parent.get_node_or_null(label_name) as Label
	if label == null:
		label = ExampleSupport.make_detail_label(label_name)
		ExampleSupport.insert_child(parent, label, insert_index)
	return label

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
