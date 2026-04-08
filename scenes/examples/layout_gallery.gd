extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const ZoneGroupSortScript = preload("res://addons/nascentsoul/impl/sorts/zone_group_sort.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const PILE_PRESET = preload("res://addons/nascentsoul/presets/pile_zone_preset.tres")

var _row_sort: ZonePropertySort
var _list_group_sort

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var sort_button: Button = $RootMargin/RootVBox/Toolbar/SortButton
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone
@onready var _row_zone: Zone = $RootMargin/RootVBox/Grid/RowColumn/RowZone
@onready var _list_zone: Zone = $RootMargin/RootVBox/Grid/ListColumn/ListZone
@onready var _pile_zone: Zone = $RootMargin/RootVBox/Grid/PileColumn/PileZone

func _ready() -> void:
	_configure_zones()
	_populate_cards()
	sort_button.pressed.connect(_toggle_row_sort)
	reset_button.pressed.connect(_reset_gallery)
	_set_status("Layout gallery: compare hand, row, grouped list, and pile layouts. The row toggles cost sort; the list auto-groups by primary tag.")

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
	ExampleSupport.configure_zone(_hand_zone, Color(0.28, 0.55, 0.42))
	ExampleSupport.configure_zone(_row_zone, Color(0.31, 0.45, 0.70))
	ExampleSupport.configure_zone(_list_zone, Color(0.54, 0.44, 0.23), true)
	ExampleSupport.configure_zone(_pile_zone, Color(0.56, 0.29, 0.36))

func _populate_cards() -> void:
	for spec in _card_specs():
		_hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_row_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_list_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		_pile_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], false))

func _toggle_row_sort() -> void:
	_row_sort.descending = not _row_sort.descending
	_row_zone.refresh()
	sort_button.text = "Row Sort: Cost Desc" if _row_sort.descending else "Row Sort: Cost Asc"
	_set_status("Row zone now sorts by example_cost in %s order. The list remains grouped by primary tag." % ["descending" if _row_sort.descending else "ascending"])

func _reset_gallery() -> void:
	for zone in [_hand_zone, _row_zone, _list_zone, _pile_zone]:
		for item in zone.get_items():
			zone.remove_item(item)
	_populate_cards()
	_row_sort.descending = false
	_row_zone.refresh()
	sort_button.text = "Row Sort: Cost Asc"
	_set_status("Gallery reset. Row sorting uses cost, and the list stays grouped by primary tag.")

func _card_specs() -> Array[Dictionary]:
	return [
		{"title": "Pulse", "cost": 2, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Anchor", "cost": 3, "tags": ["power"]},
		{"title": "Burst", "cost": 1, "tags": ["attack"]},
		{"title": "Loom", "cost": 2, "tags": ["skill"]}
	]

func _set_status(message: String) -> void:
	status_label.text = message
