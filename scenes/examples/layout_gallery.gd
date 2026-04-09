extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

@export_group("Sample Cards")
@export var gallery_cards: Array[ExampleCardSpec] = []

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var sort_button: Button = $RootMargin/RootVBox/Toolbar/SortButton
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var sort_mode_label: Label = $RootMargin/RootVBox/Toolbar/SortModeLabel
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone as Zone
@onready var _row_zone: Zone = $RootMargin/RootVBox/Grid/RowColumn/RowZone as Zone
@onready var _list_zone: Zone = $RootMargin/RootVBox/Grid/ListColumn/ListZone as Zone
@onready var _pile_zone: Zone = $RootMargin/RootVBox/Grid/PileColumn/PileZone as Zone

func _ready() -> void:
	_populate_cards()
	sort_button.pressed.connect(_toggle_row_sort)
	reset_button.pressed.connect(_reset_gallery)
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual("布局对照已就绪", "Layout gallery is ready"))
	_schedule_headless_quit_if_root()

func _populate_cards() -> void:
	ExampleSupport.add_cards_from_specs(_hand_zone, gallery_cards, true)
	ExampleSupport.add_cards_from_specs(_row_zone, gallery_cards, true)
	ExampleSupport.add_cards_from_specs(_list_zone, gallery_cards, true)
	ExampleSupport.add_cards_from_specs(_pile_zone, gallery_cards, false)

func _toggle_row_sort() -> void:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	if _row_sort == null:
		return
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
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	_row_sort.descending = false
	_row_zone.refresh()
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"布局画廊已重置，Row 回到费用升序",
		"The gallery has been reset and Row is back to ascending cost"
	))

func _refresh_guidance() -> void:
	sort_mode_label.text = ExampleSupport.compact_bilingual(
		"Row 费用%s" % [_current_sort_name()],
		"Row cost %s" % [_current_sort_name_en()]
	)

func _set_status(message: String) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]

func _current_sort_name() -> String:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	return "降序" if _row_sort != null and _row_sort.descending else "升序"

func _current_sort_name_en() -> String:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	return "descending" if _row_sort != null and _row_sort.descending else "ascending"

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
