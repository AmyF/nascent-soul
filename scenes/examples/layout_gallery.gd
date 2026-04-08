extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const ZoneGroupSortScript = preload("res://addons/nascentsoul/impl/sorts/zone_group_sort.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")

const HAND_ACCENT := Color(0.28, 0.55, 0.42)
const ROW_ACCENT := Color(0.31, 0.45, 0.70)
const LIST_ACCENT := Color(0.54, 0.44, 0.23)
const PILE_ACCENT := Color(0.56, 0.29, 0.36)

var _row_sort: ZonePropertySort
var _list_group_sort
var _hand_caption_label: Label
var _row_caption_label: Label
var _list_caption_label: Label
var _pile_caption_label: Label
var _sort_mode_label: Label

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var toolbar: HBoxContainer = $RootMargin/RootVBox/Toolbar
@onready var sort_button: Button = $RootMargin/RootVBox/Toolbar/SortButton
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var hand_column: VBoxContainer = $RootMargin/RootVBox/Grid/HandColumn
@onready var hand_label: Label = $RootMargin/RootVBox/Grid/HandColumn/HandLabel
@onready var row_column: VBoxContainer = $RootMargin/RootVBox/Grid/RowColumn
@onready var row_label: Label = $RootMargin/RootVBox/Grid/RowColumn/RowLabel
@onready var list_column: VBoxContainer = $RootMargin/RootVBox/Grid/ListColumn
@onready var list_label: Label = $RootMargin/RootVBox/Grid/ListColumn/ListLabel
@onready var pile_column: VBoxContainer = $RootMargin/RootVBox/Grid/PileColumn
@onready var pile_label: Label = $RootMargin/RootVBox/Grid/PileColumn/PileLabel
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone
@onready var _row_zone: Zone = $RootMargin/RootVBox/Grid/RowColumn/RowZone
@onready var _list_zone: Zone = $RootMargin/RootVBox/Grid/ListColumn/ListZone
@onready var _pile_zone: Zone = $RootMargin/RootVBox/Grid/PileColumn/PileZone

func _ready() -> void:
	root_vbox.add_theme_constant_override("separation", 10)
	_apply_scene_copy()
	_configure_zones()
	_populate_cards()
	sort_button.pressed.connect(_toggle_row_sort)
	reset_button.pressed.connect(_reset_gallery)
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("布局对照已就绪", "Layout gallery is ready"))
	_schedule_headless_quit_if_root()

func _apply_scene_copy() -> void:
	hand_label.text = ExampleSupport.compact_bilingual("手牌弧线", "Hand")
	row_label.text = ExampleSupport.compact_bilingual("横向排布", "HBox")
	list_label.text = ExampleSupport.compact_bilingual("分组列表", "Grouped List")
	pile_label.text = ExampleSupport.compact_bilingual("叠堆排布", "Pile")
	ExampleSupport.style_heading_label(hand_label, Color(0.84, 0.96, 0.88))
	ExampleSupport.style_heading_label(row_label, Color(0.83, 0.91, 0.99))
	ExampleSupport.style_heading_label(list_label, Color(0.97, 0.92, 0.78))
	ExampleSupport.style_heading_label(pile_label, Color(0.97, 0.85, 0.88))
	sort_button.text = ExampleSupport.compact_bilingual("切换横排序", "Toggle row sort")
	reset_button.text = ExampleSupport.compact_bilingual("重置卡牌", "Reset cards")
	ExampleSupport.style_action_button(sort_button, ROW_ACCENT)
	ExampleSupport.style_action_button(reset_button, PILE_ACCENT)
	_hand_caption_label = _ensure_detail_label(hand_column, "HandCaptionLabel", 1)
	_row_caption_label = _ensure_detail_label(row_column, "RowCaptionLabel", 1)
	_list_caption_label = _ensure_detail_label(list_column, "ListCaptionLabel", 1)
	_pile_caption_label = _ensure_detail_label(pile_column, "PileCaptionLabel", 1)
	_sort_mode_label = toolbar.get_node_or_null("SortModeLabel") as Label
	if _sort_mode_label == null:
		_sort_mode_label = ExampleSupport.make_detail_label("SortModeLabel")
		_sort_mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toolbar.add_child(_sort_mode_label)
	ExampleSupport.style_status_label(status_label, ROW_ACCENT)
	root_vbox.move_child(status_label, root_vbox.get_child_count() - 1)

func _configure_zones() -> void:
	var row_layout := ZoneHBoxLayout.new()
	row_layout.item_spacing = 14.0
	row_layout.padding_left = 16.0
	row_layout.padding_top = 12.0

	var list_layout := ZoneVBoxLayout.new()
	list_layout.item_spacing = 10.0
	list_layout.padding_top = 12.0

	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 22.0
	pile_layout.padding_left = 16.0
	pile_layout.padding_top = 20.0

	_row_sort = ZonePropertySort.new()
	_row_sort.metadata_key = "example_cost"
	_list_group_sort = ZoneGroupSortScript.new()
	_list_group_sort.group_metadata_key = "example_primary_tag"
	_list_group_sort.group_order = PackedStringArray(["attack", "skill", "power"])
	_list_group_sort.item_metadata_key = "example_cost"

	_hand_zone.preset = HAND_PRESET
	_row_zone.layout_policy = row_layout
	_row_zone.sort_policy = _row_sort
	_list_zone.layout_policy = list_layout
	_list_zone.sort_policy = _list_group_sort
	_pile_zone.preset = PILE_PRESET
	_pile_zone.layout_policy = pile_layout
	ExampleSupport.configure_zone(_hand_zone, HAND_ACCENT)
	ExampleSupport.configure_zone(_row_zone, ROW_ACCENT)
	ExampleSupport.configure_zone(_list_zone, LIST_ACCENT, true)
	ExampleSupport.configure_zone(_pile_zone, PILE_ACCENT)

func _populate_cards() -> void:
	for spec in _card_specs():
		_hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_row_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_list_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_pile_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], false))

func _toggle_row_sort() -> void:
	_row_sort.descending = not _row_sort.descending
	_row_zone.refresh()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"Row 费用%s，List 仍按 primary tag 分组" % [_current_sort_name()],
		"Row is now cost-%s, List still groups by primary tag" % [_current_sort_name_en()]
	))

func _reset_gallery() -> void:
	for zone in [_hand_zone, _row_zone, _list_zone, _pile_zone]:
		for item in zone.get_items():
			zone.remove_item(item)
			item.queue_free()
	_populate_cards()
	_row_sort.descending = false
	_row_zone.refresh()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"布局画廊已重置，Row 回到费用升序",
		"The gallery has been reset and Row is back to ascending cost"
	))

func _card_specs() -> Array[Dictionary]:
	return [
		{"title": "Pulse", "cost": 2, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Anchor", "cost": 3, "tags": ["power"]},
		{"title": "Burst", "cost": 1, "tags": ["attack"]},
		{"title": "Loom", "cost": 2, "tags": ["skill"]}
	]

func _refresh_guidance() -> void:
	_hand_caption_label.text = ExampleSupport.compact_bilingual(
		"适合手牌与奖励选择",
		"Best for player hands and reward picks"
	)
	_row_caption_label.text = ExampleSupport.compact_bilingual(
		"稳定左到右阅读，当前 %s" % [_current_sort_name()],
		"Stable left-to-right reading, currently %s" % [_current_sort_name_en()]
	)
	_list_caption_label.text = ExampleSupport.compact_bilingual(
		"先按 primary tag 分组，再按费用",
		"Groups by primary tag before cost"
	)
	_pile_caption_label.text = ExampleSupport.compact_bilingual(
		"适合牌库、弃牌堆与累计感区域",
		"Best for decks, discards, and accumulated stacks"
	)
	_sort_mode_label.text = ExampleSupport.compact_bilingual(
		"Row 费用%s" % [_current_sort_name()],
		"Row cost %s" % [_current_sort_name_en()]
	)

func _set_status(message: String) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]

func _ensure_detail_label(parent: Node, label_name: String, insert_index: int) -> Label:
	var label = parent.get_node_or_null(label_name) as Label
	if label == null:
		label = ExampleSupport.make_detail_label(label_name)
		ExampleSupport.insert_child(parent, label, insert_index)
	return label

func _current_sort_name() -> String:
	return "降序" if _row_sort != null and _row_sort.descending else "升序"

func _current_sort_name_en() -> String:
	return "descending" if _row_sort != null and _row_sort.descending else "ascending"

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
