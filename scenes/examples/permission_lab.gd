extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const ZoneCompositePermissionScript = preload("res://addons/nascentsoul/impl/permissions/zone_composite_permission.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")
const DISCARD_PRESET = preload("res://addons/nascentsoul/presets/discard_zone_preset.tres")

const DECK_ACCENT := Color(0.59, 0.53, 0.26)
const HAND_ACCENT := Color(0.33, 0.55, 0.42)
const BOARD_ACCENT := Color(0.27, 0.48, 0.70)
const SANCTUM_ACCENT := Color(0.63, 0.41, 0.68)
const DISCARD_ACCENT := Color(0.53, 0.26, 0.31)
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_COLOR := Color(0.96, 0.60, 0.56)

var _board_capacity: ZoneCapacityPermission
var _sanctum_source: ZoneSourcePermission
var _sanctum_capacity: ZoneCapacityPermission
var _board_rule_label: Label
var _sanctum_rule_label: Label

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var deck_label: Label = $RootMargin/RootVBox/Grid/DeckColumn/DeckLabel
@onready var hand_label: Label = $RootMargin/RootVBox/Grid/HandColumn/HandLabel
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/Grid/BoardColumn
@onready var board_label: Label = $RootMargin/RootVBox/Grid/BoardColumn/BoardLabel
@onready var sanctum_column: VBoxContainer = $RootMargin/RootVBox/Grid/SanctumColumn
@onready var sanctum_label: Label = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumLabel
@onready var discard_label: Label = $RootMargin/RootVBox/Grid/DiscardColumn/DiscardLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/Grid/DeckColumn/DeckZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/Grid/BoardColumn/BoardZone
@onready var _sanctum_zone: Zone = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/Grid/DiscardColumn/DiscardZone

func _ready() -> void:
	root_vbox.add_theme_constant_override("separation", 10)
	_apply_scene_copy()
	_configure_zones()
	_populate_cards()
	_wire_actions()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("权限实验室已就绪", "Permission lab is ready"))
	_schedule_headless_quit_if_root()

func _apply_scene_copy() -> void:
	deck_label.text = ExampleSupport.compact_bilingual("牌库", "Deck")
	hand_label.text = ExampleSupport.compact_bilingual("手牌", "Hand")
	board_label.text = ExampleSupport.compact_bilingual("战场", "Board")
	sanctum_label.text = ExampleSupport.compact_bilingual("圣所", "Sanctum")
	discard_label.text = ExampleSupport.compact_bilingual("弃牌堆", "Discard")
	ExampleSupport.style_heading_label(deck_label, Color(0.96, 0.92, 0.74))
	ExampleSupport.style_heading_label(hand_label, Color(0.84, 0.96, 0.88))
	ExampleSupport.style_heading_label(board_label, Color(0.83, 0.91, 0.99))
	ExampleSupport.style_heading_label(sanctum_label, Color(0.94, 0.85, 0.99))
	ExampleSupport.style_heading_label(discard_label, Color(0.97, 0.85, 0.88))
	_board_rule_label = _ensure_detail_label(board_column, "BoardRuleLabel", 1)
	_sanctum_rule_label = _ensure_detail_label(sanctum_column, "SanctumRuleLabel", 1)
	ExampleSupport.style_status_label(status_label, SANCTUM_ACCENT)
	root_vbox.move_child(status_label, root_vbox.get_child_count() - 1)

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

	_board_capacity = ZoneCapacityPermission.new()
	_board_capacity.max_items = 2
	_board_capacity.reject_reason = ExampleSupport.bilingual(
		"Board 在这个实验里只允许 2 张牌。",
		"Board only allows two cards in this lab."
	)
	_board_zone.permission_policy = _board_capacity

	_sanctum_source = ZoneSourcePermission.new()
	_sanctum_source.allowed_source_zone_names = PackedStringArray(["HandZone"])
	_sanctum_source.reject_reason = ExampleSupport.bilingual(
		"Sanctum 只接收来自 HandZone 的卡牌。",
		"Sanctum only accepts cards that come from HandZone."
	)

	_sanctum_capacity = ZoneCapacityPermission.new()
	_sanctum_capacity.max_items = 2
	_sanctum_capacity.reject_reason = ExampleSupport.bilingual(
		"Sanctum 在这个实验里也只允许 2 张牌。",
		"Sanctum also allows only two cards in this lab."
	)

	var sanctum_rules := ZoneCompositePermissionScript.new()
	sanctum_rules.combine_mode = ZoneCompositePermissionScript.CombineMode.ALL
	sanctum_rules.policies = [_sanctum_source, _sanctum_capacity]

	_deck_zone.layout_policy = pile_layout
	_sanctum_zone.layout_policy = sanctum_layout
	_sanctum_zone.permission_policy = sanctum_rules
	ExampleSupport.configure_zone(_deck_zone, DECK_ACCENT)
	ExampleSupport.configure_zone(_hand_zone, HAND_ACCENT)
	ExampleSupport.configure_zone(_board_zone, BOARD_ACCENT)
	ExampleSupport.configure_zone(_sanctum_zone, SANCTUM_ACCENT)
	ExampleSupport.configure_zone(_discard_zone, DISCARD_ACCENT)

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
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"%s: %s -> %s @ %d" % [item.name, source_zone.name, target_zone.name, to_index],
		"%s: %s -> %s @ %d" % [item.name, source_zone.name, target_zone.name, to_index]
	))

func _on_drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_refresh_guidance()
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	var source_name = source_zone.name if source_zone != null else "Unknown"
	_set_status(ExampleSupport.compact_bilingual(
		"%s 从 %s 进入 %s 被拒绝：%s" % [item_name, source_name, target_zone.name, reason],
		"%s from %s into %s was rejected: %s" % [item_name, source_name, target_zone.name, reason]
	), REJECT_COLOR)

func _refresh_guidance() -> void:
	var board_count = _board_zone.get_item_count()
	var sanctum_count = _sanctum_zone.get_item_count()
	_board_rule_label.text = ExampleSupport.compact_bilingual(
		"任意来源，%d / %d 容量" % [board_count, _board_capacity.max_items],
		"Any source, %d / %d capacity" % [board_count, _board_capacity.max_items]
	)
	_sanctum_rule_label.text = ExampleSupport.compact_bilingual(
		"仅 HandZone，%d / %d 容量" % [sanctum_count, _sanctum_capacity.max_items],
		"HandZone only, %d / %d capacity" % [sanctum_count, _sanctum_capacity.max_items]
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
