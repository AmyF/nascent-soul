extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

@export_group("Status Copy")
@export var ready_status := "布局对照已就绪 / Layout gallery is ready"
@export var row_sort_status_format := "Row 费用%s / Row cost %s"
@export var toggle_status_format := "Row 费用%s，List 仍按 primary tag 分组 / Row is now cost-%s, List still groups by primary tag"
@export var reset_status := "布局画廊已重置，Row 回到费用升序 / The gallery has been reset and Row is back to ascending cost"
@export var status_prefix := "最近 / Latest"

@export_group("Layout Presets")
@export var grid_columns := Vector3i(4, 2, 2)
@export var column_widths := Vector3(260.0, 212.0, 176.0)
@export var hand_zone_heights := Vector3(220.0, 196.0, 184.0)
@export var stack_zone_heights := Vector3(240.0, 212.0, 192.0)

@export_group("Sort Labels")
@export var ascending_sort_name := "升序"
@export var descending_sort_name := "降序"
@export var ascending_sort_name_en := "ascending"
@export var descending_sort_name_en := "descending"

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var sort_button: Button = $RootMargin/RootVBox/Toolbar/SortButton
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var sort_mode_label: Label = $RootMargin/RootVBox/Toolbar/SortModeLabel
@onready var grid: GridContainer = $RootMargin/RootVBox/Grid
@onready var hand_column: VBoxContainer = $RootMargin/RootVBox/Grid/HandColumn
@onready var row_column: VBoxContainer = $RootMargin/RootVBox/Grid/RowColumn
@onready var list_column: VBoxContainer = $RootMargin/RootVBox/Grid/ListColumn
@onready var pile_column: VBoxContainer = $RootMargin/RootVBox/Grid/PileColumn
@onready var _hand_zone: Zone = $RootMargin/RootVBox/Grid/HandColumn/HandZone as Zone
@onready var _row_zone: Zone = $RootMargin/RootVBox/Grid/RowColumn/RowZone as Zone
@onready var _list_zone: Zone = $RootMargin/RootVBox/Grid/ListColumn/ListZone as Zone
@onready var _pile_zone: Zone = $RootMargin/RootVBox/Grid/PileColumn/PileZone as Zone

var _initial_zone_items: Dictionary = {}

func _ready() -> void:
	_capture_initial_zone_items()
	sort_button.pressed.connect(_toggle_row_sort)
	reset_button.pressed.connect(_reset_gallery)
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	_refresh_guidance()
	_set_status(ready_status)
	_schedule_headless_quit_if_root()

func _toggle_row_sort() -> void:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	if _row_sort == null:
		return
	_row_sort.descending = not _row_sort.descending
	_row_zone.refresh()
	_refresh_guidance()
	_set_status(toggle_status_format % [_current_sort_name(), _current_sort_name_en()])

func _reset_gallery() -> void:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	if _row_sort != null:
		_row_sort.descending = false
	_restore_zone_items([_hand_zone, _row_zone, _list_zone, _pile_zone])
	_row_zone.refresh()
	_refresh_guidance()
	_set_status(reset_status)

func _refresh_guidance() -> void:
	sort_mode_label.text = row_sort_status_format % [_current_sort_name(), _current_sort_name_en()]

func _set_status(message: String) -> void:
	status_label.text = "%s: %s" % [status_prefix, message]

func _current_sort_name() -> String:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	return descending_sort_name if _row_sort != null and _row_sort.descending else ascending_sort_name

func _current_sort_name_en() -> String:
	var _row_sort: ZonePropertySort = ExampleSupport.get_zone_sort_policy(_row_zone) as ZonePropertySort
	return descending_sort_name_en if _row_sort != null and _row_sort.descending else ascending_sort_name_en

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)

func _capture_initial_zone_items() -> void:
	_initial_zone_items = _snapshot_zone_items([_hand_zone, _row_zone, _list_zone, _pile_zone])

func _snapshot_zone_items(zones: Array[Zone]) -> Dictionary:
	var snapshots := {}
	for zone in zones:
		var templates: Array[ZoneItemControl] = []
		for item in zone.get_items():
			var duplicated = item.duplicate() as ZoneItemControl
			if duplicated != null:
				templates.append(duplicated)
		snapshots[zone.name] = templates
	return snapshots

func _restore_zone_items(zones: Array[Zone]) -> void:
	for zone in zones:
		for item in zone.get_items():
			zone.remove_item(item)
			item.queue_free()
		var templates = _initial_zone_items.get(zone.name, [])
		for template in templates:
			if template is not ZoneItemControl:
				continue
			var duplicated = (template as ZoneItemControl).duplicate() as ZoneItemControl
			if duplicated != null:
				zone.add_item(duplicated)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _pick_layout_value(mode: StringName, preset: Vector3) -> float:
	return DemoLayoutSupport.pick_float(mode, preset.x, preset.y, preset.z)

func _apply_responsive_layout() -> void:
	var mode := DemoLayoutSupport.mode_for(self)
	DemoLayoutSupport.set_grid_columns(grid, mode, grid_columns.x, grid_columns.y, grid_columns.z)
	for column in [hand_column, row_column, list_column, pile_column]:
		DemoLayoutSupport.set_minimum_width(column, mode, column_widths.x, column_widths.y, column_widths.z)
	var zone_width := _pick_layout_value(mode, column_widths)
	DemoLayoutSupport.set_minimum_size(_hand_zone, zone_width, _pick_layout_value(mode, hand_zone_heights))
	DemoLayoutSupport.set_minimum_size(_row_zone, zone_width, _pick_layout_value(mode, hand_zone_heights))
	DemoLayoutSupport.set_minimum_size(_list_zone, zone_width, _pick_layout_value(mode, stack_zone_heights))
	DemoLayoutSupport.set_minimum_size(_pile_zone, zone_width, _pick_layout_value(mode, stack_zone_heights))
	for zone in [_hand_zone, _row_zone, _list_zone, _pile_zone]:
		zone.refresh()
