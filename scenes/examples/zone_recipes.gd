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
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_COLOR := Color(0.96, 0.60, 0.56)

var _board_capacity: ZoneCapacityPermission

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var toolbar: HBoxContainer = $RootMargin/RootVBox/Toolbar
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var deck_label: Label = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckLabel
@onready var hand_label: Label = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandLabel
@onready var board_label: Label = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardLabel
@onready var discard_label: Label = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardLabel
@onready var deck_details: Label = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckDetails
@onready var hand_details: Label = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandDetails
@onready var board_details: Label = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails
@onready var discard_details: Label = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardDetails
@onready var _deck_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone
@onready var _board_zone: Zone = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardZone

func _ready() -> void:
	root_vbox.add_theme_constant_override("separation", 10)
	_apply_scene_copy()
	_describe_recipes()
	_configure_zones()
	_populate_cards()
	_wire_actions()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("Starter recipe 已就绪", "Starter recipe is ready"))
	_schedule_headless_quit_if_root()

func _apply_scene_copy() -> void:
	deck_label.text = ExampleSupport.compact_bilingual("牌库模板", "Deck Recipe")
	hand_label.text = ExampleSupport.compact_bilingual("手牌模板", "Hand Recipe")
	board_label.text = ExampleSupport.compact_bilingual("战场模板", "Board Recipe")
	discard_label.text = ExampleSupport.compact_bilingual("弃牌堆模板", "Discard Recipe")
	ExampleSupport.style_heading_label(deck_label, Color(0.96, 0.92, 0.74))
	ExampleSupport.style_heading_label(hand_label, Color(0.84, 0.96, 0.88))
	ExampleSupport.style_heading_label(board_label, Color(0.83, 0.91, 0.99))
	ExampleSupport.style_heading_label(discard_label, Color(0.97, 0.85, 0.88))
	ExampleSupport.style_action_button(reset_button, BOARD_ACCENT)
	reset_button.text = ExampleSupport.compact_bilingual("重置模板", "Reset recipe")
	for label in [deck_details, hand_details, board_details, discard_details]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", ExampleSupport.MUTED_TEXT_COLOR)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_constant_override("line_spacing", 2)
	ExampleSupport.style_status_label(status_label, BOARD_ACCENT)
	root_vbox.move_child(status_label, root_vbox.get_child_count() - 1)

func _describe_recipes() -> void:
	deck_details.text = ExampleSupport.compact_bilingual(
		"PileZonePreset，适合抽牌堆与隐藏堆叠",
		"PileZonePreset for draw piles and hidden stacks"
	)
	hand_details.text = ExampleSupport.compact_bilingual(
		"HandZonePreset，适合手牌与奖励选择",
		"HandZonePreset for player hands and reward picks"
	)
	board_details.text = ExampleSupport.compact_bilingual(
		"BoardZonePreset，容量限制的主动位",
		"BoardZonePreset for capacity-limited active rows"
	)
	discard_details.text = ExampleSupport.compact_bilingual(
		"DiscardZonePreset，适合弃牌堆与回收区",
		"DiscardZonePreset for discard piles and recovery zones"
	)

func _configure_zones() -> void:
	_deck_zone.preset = PILE_PRESET
	_hand_zone.preset = HAND_PRESET
	_board_zone.preset = BOARD_PRESET
	_discard_zone.preset = DISCARD_PRESET
	_board_capacity = ZoneCapacityPermission.new()
	_board_capacity.max_items = 4
	_board_capacity.reject_reason = ExampleSupport.bilingual(
		"Board recipe 已满。提高 max_items 或先弃掉一张牌。",
		"Board recipe is full. Raise max_items or discard a card first."
	)
	_board_zone.permission_policy = _board_capacity
	ExampleSupport.configure_zone(_deck_zone, DECK_ACCENT)
	ExampleSupport.configure_zone(_hand_zone, HAND_ACCENT)
	ExampleSupport.configure_zone(_board_zone, BOARD_ACCENT)
	ExampleSupport.configure_zone(_discard_zone, DISCARD_ACCENT)

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
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"模板已重置，可以继续试玩或直接复制这四列",
		"The recipe board has been reset and is ready to copy"
	))

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
	board_details.text = ExampleSupport.compact_bilingual(
		"BoardZonePreset，当前 %d / %d 容量" % [board_count, _board_capacity.max_items],
		"BoardZonePreset, currently %d / %d capacity" % [board_count, _board_capacity.max_items]
	)

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
