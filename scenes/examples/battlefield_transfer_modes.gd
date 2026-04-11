extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const REJECT_COLOR := Color(0.96, 0.60, 0.56)
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

@export_group("Status Copy")
@export_multiline var ready_status: String = ""

@export_group("Layout")
@export var source_widths: Vector3 = Vector3(240.0, 212.0, 180.0)
@export var battlefield_widths: Vector3 = Vector3(340.0, 292.0, 280.0)
@export var source_panel_heights: Vector3 = Vector3(220.0, 196.0, 180.0)
@export var battlefield_panel_heights: Vector3 = Vector3(320.0, 296.0, 280.0)
@export var battlefield_min_cell_size: float = 88.0

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var content_row: HFlowContainer = $RootMargin/RootVBox/ContentRow
@onready var source_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/SourceColumn
@onready var direct_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/DirectColumn
@onready var summon_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/SummonColumn
@onready var source_panel: Panel = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel
@onready var direct_panel: Panel = $RootMargin/RootVBox/ContentRow/DirectColumn/DirectPanel
@onready var summon_panel: Panel = $RootMargin/RootVBox/ContentRow/SummonColumn/SummonPanel
@onready var _source_zone: Zone = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel/ModeSourceZone as Zone
@onready var _direct_zone: BattlefieldZone = $RootMargin/RootVBox/ContentRow/DirectColumn/DirectPanel/DirectBattlefieldZone as BattlefieldZone
@onready var _summon_zone: BattlefieldZone = $RootMargin/RootVBox/ContentRow/SummonColumn/SummonPanel/SummonBattlefieldZone as BattlefieldZone

var _direct_space: ZoneSquareGridSpaceModel
var _summon_space: ZoneSquareGridSpaceModel
var _direct_base_cell_size := Vector2.ZERO
var _direct_padding := Vector2.ZERO
var _summon_base_cell_size := Vector2.ZERO
var _summon_padding := Vector2.ZERO

func _ready() -> void:
	_direct_space = ExampleSupport.get_zone_space_model(_direct_zone) as ZoneSquareGridSpaceModel
	_summon_space = ExampleSupport.get_zone_space_model(_summon_zone) as ZoneSquareGridSpaceModel
	if _direct_space != null:
		_direct_base_cell_size = _direct_space.cell_size
		_direct_padding = _direct_space.padding
	if _summon_space != null:
		_summon_base_cell_size = _summon_space.cell_size
		_summon_padding = _summon_space.padding
	_source_zone.item_double_clicked.connect(_send_to_direct)
	_source_zone.item_right_clicked.connect(_send_to_summon)
	for zone in [_source_zone, _direct_zone, _summon_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	if ready_status != "":
		_set_status(ready_status)
	_schedule_headless_quit_if_root()

func _send_to_direct(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = ExampleSupport.get_first_open_target(_direct_zone, item)
	if target.is_valid():
		ExampleSupport.move_item(_source_zone, item, _direct_zone, target)

func _send_to_summon(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = ExampleSupport.get_first_open_target(_summon_zone, item)
	if target.is_valid():
		ExampleSupport.move_item(_source_zone, item, _summon_zone, target)

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	var target_text = ExampleSupport.describe_target(target)
	_set_status("%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text])

func _on_drop_rejected(items: Array, _source_zone_ref: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	_set_status("%s: %s" % [item_name, reason], REJECT_COLOR)

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var mode: StringName = DemoLayoutSupport.mode_for(self)
	var source_width: float = _pick_mode_value(mode, source_widths)
	var battlefield_width: float = _pick_mode_value(mode, battlefield_widths)
	DemoLayoutSupport.ensure_child_order(content_row, [source_column, direct_column, summon_column])
	DemoLayoutSupport.set_minimum_size(source_column, source_width, 0.0)
	DemoLayoutSupport.set_minimum_size(direct_column, battlefield_width, 0.0)
	DemoLayoutSupport.set_minimum_size(summon_column, battlefield_width, 0.0)
	DemoLayoutSupport.set_minimum_size(source_panel, source_width, _pick_mode_value(mode, source_panel_heights))
	DemoLayoutSupport.set_minimum_size(direct_panel, battlefield_width, _pick_mode_value(mode, battlefield_panel_heights))
	DemoLayoutSupport.set_minimum_size(summon_panel, battlefield_width, _pick_mode_value(mode, battlefield_panel_heights))
	_apply_square_grid_layout(
		_direct_space,
		direct_panel.custom_minimum_size,
		_direct_base_cell_size,
		_direct_padding,
		battlefield_min_cell_size
	)
	_apply_square_grid_layout(
		_summon_space,
		summon_panel.custom_minimum_size,
		_summon_base_cell_size,
		_summon_padding,
		battlefield_min_cell_size
	)
	for zone in [_source_zone, _direct_zone, _summon_zone]:
		if zone != null:
			zone.refresh()

func _pick_mode_value(mode: StringName, values: Vector3) -> float:
	return DemoLayoutSupport.pick_float(mode, values.x, values.y, values.z)

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)

func _apply_square_grid_layout(space_model: ZoneSquareGridSpaceModel, panel_size: Vector2, base_cell_size: Vector2, padding: Vector2, min_cell: float) -> void:
	if space_model == null:
		return
	var columns: int = max(space_model.columns, 1)
	var rows: int = max(space_model.rows, 1)
	var inner_width: float = max(1.0, panel_size.x - padding.x * 2.0)
	var inner_height: float = max(1.0, panel_size.y - padding.y * 2.0)
	var max_cell_extent: float = max(min(base_cell_size.x, base_cell_size.y), min_cell)
	var cell_extent: float = clamp(floor(min(inner_width / float(columns), inner_height / float(rows))), min_cell, max_cell_extent)
	space_model.cell_size = Vector2(cell_extent, cell_extent)
	space_model.padding = padding
