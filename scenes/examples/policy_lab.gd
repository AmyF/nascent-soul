extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_COLOR := Color(0.96, 0.60, 0.56)

@export_group("Sample Cards")
@export var deck_cards: Array[ExampleCardSpec] = []
@export var hand_cards: Array[ExampleCardSpec] = []

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var board_capacity_label: Label = $RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel
@onready var sanctum_capacity_label: Label = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/Grid/DeckColumn/DeckZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/Grid/BoardColumn/BoardZone
@onready var _sanctum_zone: Zone = $RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/Grid/DiscardColumn/DiscardZone
@onready var _board_capacity: ZoneCapacityPermission = _board_zone.transfer_policy as ZoneCapacityPermission
@onready var _sanctum_rules: ZoneCompositePermission = _sanctum_zone.transfer_policy as ZoneCompositePermission

func _ready() -> void:
	_populate_cards()
	_wire_actions()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("规则实验室已就绪", "Policy lab is ready"))
	_schedule_headless_quit_if_root()

func _populate_cards() -> void:
	ExampleSupport.add_cards_from_specs(_deck_zone, deck_cards, false)
	ExampleSupport.add_cards_from_specs(_hand_zone, hand_cards, true)

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
		_deck_zone.move_item_to(item, _hand_zone, ZonePlacementTarget.linear(_hand_zone.get_item_count()))

func _send_hand_to_sanctum(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _sanctum_zone, ZonePlacementTarget.linear(_sanctum_zone.get_item_count()))

func _send_hand_to_board(item: Control) -> void:
	if _hand_zone.has_item(item):
		_hand_zone.move_item_to(item, _board_zone, ZonePlacementTarget.linear(_board_zone.get_item_count()))

func _discard_card(item: Control) -> void:
	for zone in [_board_zone, _sanctum_zone]:
		if zone.has_item(item):
			zone.move_item_to(item, _discard_zone, ZonePlacementTarget.linear(_discard_zone.get_item_count()))
			return

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	if item is ZoneCard:
		var card := item as ZoneCard
		card.highlighted = target_zone == _sanctum_zone
		card.flip(target_zone != _deck_zone, false)
	_refresh_guidance()
	var target_text = ExampleSupport.describe_target(target)
	_set_status(ExampleSupport.compact_bilingual(
		"%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text],
		"%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text]
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
	var board_limit = _board_capacity.max_items if _board_capacity != null else 0
	board_capacity_label.text = "容量 %d / %d / Capacity %d / %d" % [board_count, board_limit, board_count, board_limit]
	var sanctum_capacity = _resolve_capacity_policy(_sanctum_rules)
	var sanctum_count = _sanctum_zone.get_item_count()
	var sanctum_limit = sanctum_capacity.max_items if sanctum_capacity != null else 0
	sanctum_capacity_label.text = "容量 %d / %d / Capacity %d / %d" % [sanctum_count, sanctum_limit, sanctum_count, sanctum_limit]

func _resolve_capacity_policy(policy: ZoneCompositePermission) -> ZoneCapacityPermission:
	if policy == null:
		return null
	for child_policy in policy.policies:
		if child_policy is ZoneCapacityPermission:
			return child_policy as ZoneCapacityPermission
	return null

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
