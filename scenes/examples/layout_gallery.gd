extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

var _hand_zone: Zone
var _row_zone: Zone
var _list_zone: Zone
var _pile_zone: Zone
var _row_sort: ZonePropertySort

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var sort_button: Button = $RootMargin/RootVBox/Toolbar/SortButton
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var hand_panel: Panel = $RootMargin/RootVBox/Grid/HandColumn/HandPanel
@onready var row_panel: Panel = $RootMargin/RootVBox/Grid/RowColumn/RowPanel
@onready var list_panel: Panel = $RootMargin/RootVBox/Grid/ListColumn/ListPanel
@onready var pile_panel: Panel = $RootMargin/RootVBox/Grid/PileColumn/PilePanel

func _ready() -> void:
	_configure_panels()
	_build_zones()
	_populate_cards()
	sort_button.pressed.connect(_toggle_row_sort)
	reset_button.pressed.connect(_reset_gallery)
	_set_status("Layout gallery: compare hand, row, list, and pile layouts. Use the toolbar to toggle row sorting.")

func _configure_panels() -> void:
	ExampleSupport.configure_panel(hand_panel, Color(0.28, 0.55, 0.42))
	ExampleSupport.configure_panel(row_panel, Color(0.31, 0.45, 0.70))
	ExampleSupport.configure_panel(list_panel, Color(0.54, 0.44, 0.23), true)
	ExampleSupport.configure_panel(pile_panel, Color(0.56, 0.29, 0.36))

func _build_zones() -> void:
	var hand_layout := ZoneHandLayout.new()
	hand_layout.arch_angle_deg = 36.0
	hand_layout.arch_height = 26.0
	hand_layout.card_spacing_angle = 6.0
	hand_layout.center_offset_y = 0.0

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

	_hand_zone = ExampleSupport.make_zone(hand_panel, "HandGallery", hand_layout)
	_row_zone = ExampleSupport.make_zone(row_panel, "RowGallery", row_layout, null, null, _row_sort)
	_list_zone = ExampleSupport.make_zone(list_panel, "ListGallery", list_layout)
	_pile_zone = ExampleSupport.make_zone(pile_panel, "PileGallery", pile_layout)

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
	_set_status("Row zone now sorts by example_cost in %s order." % ["descending" if _row_sort.descending else "ascending"])

func _reset_gallery() -> void:
	for zone in [_hand_zone, _row_zone, _list_zone, _pile_zone]:
		for item in zone.get_items():
			zone.remove_item(item)
	_populate_cards()
	_row_sort.descending = false
	_row_zone.refresh()
	sort_button.text = "Row Sort: Cost Asc"
	_set_status("Gallery reset to its initial card set.")

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
