extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

@export_group("Status Copy")
@export_multiline var ready_status: String = ""

@export_group("Layout")
@export var source_widths: Vector3 = Vector3(320.0, 232.0, 216.0)
@export var battlefield_gap_widths: Vector3 = Vector3(96.0, 72.0, 56.0)
@export var battlefield_width_limits_desktop: Vector2 = Vector2(460.0, 520.0)
@export var battlefield_width_limits_compact: Vector2 = Vector2(440.0, 500.0)
@export var battlefield_width_limits_mobile: Vector2 = Vector2(440.0, 480.0)
@export var source_panel_heights: Vector3 = Vector3(220.0, 200.0, 184.0)
@export var battlefield_panel_heights: Vector3 = Vector3(420.0, 400.0, 380.0)
@export var battlefield_min_cell_size: float = 92.0

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var content_row: HFlowContainer = $RootMargin/RootVBox/ContentRow
@onready var source_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/SourceColumn
@onready var battlefield_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/BattlefieldColumn
@onready var source_panel: Panel = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel
@onready var battlefield_panel: Panel = $RootMargin/RootVBox/ContentRow/BattlefieldColumn/BattlefieldPanel
@onready var _source_zone: Zone = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel/SquareSourceZone as Zone
@onready var _battlefield_zone: BattlefieldZone = $RootMargin/RootVBox/ContentRow/BattlefieldColumn/BattlefieldPanel/SquareBattlefieldZone as BattlefieldZone

var _space_model: ZoneSquareGridSpaceModel
var _battlefield_base_cell_size := Vector2.ZERO
var _battlefield_padding := Vector2.ZERO

func _ready() -> void:
	_space_model = ExampleSupport.get_zone_space_model(_battlefield_zone) as ZoneSquareGridSpaceModel
	if _space_model != null:
		_battlefield_base_cell_size = _space_model.cell_size
		_battlefield_padding = _space_model.padding
	_source_zone.item_double_clicked.connect(_on_source_card_double_clicked)
	_battlefield_zone.item_right_clicked.connect(_on_battlefield_item_right_clicked)
	_battlefield_zone.item_transferred.connect(_on_item_transferred.bind(_battlefield_zone))
	_source_zone.item_transferred.connect(_on_item_transferred.bind(_source_zone))
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	if ready_status != "":
		_set_status(ready_status)
	_schedule_headless_quit_if_root()

func _on_source_card_double_clicked(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = ExampleSupport.get_first_open_target(_battlefield_zone, item)
	if target.is_valid():
		ExampleSupport.move_item(_source_zone, item, _battlefield_zone, target)

func _on_battlefield_item_right_clicked(item: Control) -> void:
	if _battlefield_zone.has_item(item):
		ExampleSupport.move_item(_battlefield_zone, item, _source_zone, ZonePlacementTarget.linear(_source_zone.get_item_count()))

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	var target_text = ExampleSupport.describe_target(target)
	_set_status("%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text])

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var mode: StringName = DemoLayoutSupport.mode_for(self)
	var available_width: float = DemoLayoutSupport.resolved_width(self)
	var source_width: float = _pick_mode_value(mode, source_widths)
	var battlefield_width_limits: Vector2 = _battlefield_width_limits(mode)
	var field_width: float = clamp(
		available_width - source_width - _pick_mode_value(mode, battlefield_gap_widths),
		battlefield_width_limits.x,
		battlefield_width_limits.y
	)
	DemoLayoutSupport.ensure_child_order(
		content_row,
		[source_column, battlefield_column] if mode == DemoLayoutSupport.DESKTOP else [battlefield_column, source_column]
	)
	DemoLayoutSupport.set_minimum_size(source_column, source_width, 0.0)
	DemoLayoutSupport.set_minimum_size(battlefield_column, field_width, 0.0)
	DemoLayoutSupport.set_minimum_size(source_panel, source_width, _pick_mode_value(mode, source_panel_heights))
	DemoLayoutSupport.set_minimum_size(battlefield_panel, field_width, _pick_mode_value(mode, battlefield_panel_heights))
	_apply_square_grid_layout(
		_space_model,
		battlefield_panel.custom_minimum_size,
		_battlefield_base_cell_size,
		_battlefield_padding,
		battlefield_min_cell_size
	)
	if _source_zone != null:
		_source_zone.refresh()
	if _battlefield_zone != null:
		_battlefield_zone.refresh()

func _pick_mode_value(mode: StringName, values: Vector3) -> float:
	return DemoLayoutSupport.pick_float(mode, values.x, values.y, values.z)

func _battlefield_width_limits(mode: StringName) -> Vector2:
	match mode:
		DemoLayoutSupport.DESKTOP:
			return battlefield_width_limits_desktop
		DemoLayoutSupport.COMPACT:
			return battlefield_width_limits_compact
		_:
			return battlefield_width_limits_mobile

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
