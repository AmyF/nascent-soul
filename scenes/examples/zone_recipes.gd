extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_COLOR := Color(0.96, 0.60, 0.56)

@export_group("Status Copy")
@export var ready_status := "Starter recipe 已就绪 / Starter recipe is ready"
@export var reset_status := "模板已重置，可以继续试玩或直接复制这四列 / The recipe board has been reset and is ready to copy"
@export var status_prefix := "最近 / Latest"
@export var board_capacity_format := "容量 %d / %d / Capacity %d / %d"

@export_group("Layout Presets")
@export var grid_columns := Vector3i(4, 2, 2)
@export var edge_column_widths := Vector3(200.0, 176.0, 164.0)
@export var middle_column_widths := Vector3(260.0, 212.0, 188.0)
@export var zone_heights := Vector3(240.0, 210.0, 184.0)

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var reset_button: Button = $RootMargin/RootVBox/Toolbar/ResetButton
@onready var recipes_grid: GridContainer = $RootMargin/RootVBox/RecipesGrid
@onready var deck_column: VBoxContainer = $RootMargin/RootVBox/RecipesGrid/DeckColumn
@onready var hand_column: VBoxContainer = $RootMargin/RootVBox/RecipesGrid/HandColumn
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/RecipesGrid/BoardColumn
@onready var discard_column: VBoxContainer = $RootMargin/RootVBox/RecipesGrid/DiscardColumn
@onready var board_capacity_label: Label = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone as Zone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone as Zone
@onready var _board_zone: Zone = $RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone as Zone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardZone as Zone

var _initial_zone_items: Dictionary = {}

func _ready() -> void:
	_capture_initial_zone_items()
	_wire_actions()
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	_refresh_guidance()
	_set_status(ready_status)
	_schedule_headless_quit_if_root()

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
	_restore_zone_items([_deck_zone, _hand_zone, _board_zone, _discard_zone])
	_refresh_guidance()
	_set_status(reset_status)

func _draw_to_hand(item: Control) -> void:
	if _deck_zone.has_item(item):
		ExampleSupport.move_item(_deck_zone, item, _hand_zone, ZonePlacementTarget.linear(_hand_zone.get_item_count()))

func _play_to_board(item: Control) -> void:
	if _hand_zone.has_item(item):
		ExampleSupport.move_item(_hand_zone, item, _board_zone, ZonePlacementTarget.linear(_board_zone.get_item_count()))

func _discard_from_hand(item: Control) -> void:
	if _hand_zone.has_item(item):
		ExampleSupport.move_item(_hand_zone, item, _discard_zone, ZonePlacementTarget.linear(_discard_zone.get_item_count()))

func _discard_from_board(item: Control) -> void:
	if _board_zone.has_item(item):
		ExampleSupport.move_item(_board_zone, item, _discard_zone, ZonePlacementTarget.linear(_discard_zone.get_item_count()))

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	if item is ZoneCard:
		var card := item as ZoneCard
		card.highlighted = target_zone == _board_zone
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
	var _board_capacity: ZoneCapacityTransferPolicy = ExampleSupport.get_zone_transfer_policy(_board_zone) as ZoneCapacityTransferPolicy
	var board_limit = _board_capacity.max_items if _board_capacity != null else 0
	board_capacity_label.text = board_capacity_format % [board_count, board_limit, board_count, board_limit]

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [status_prefix, message]
	status_label.add_theme_color_override("font_color", font_color)

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)

func _capture_initial_zone_items() -> void:
	_initial_zone_items = _snapshot_zone_items([_deck_zone, _hand_zone, _board_zone, _discard_zone])

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
	DemoLayoutSupport.set_grid_columns(recipes_grid, mode, grid_columns.x, grid_columns.y, grid_columns.z)
	DemoLayoutSupport.set_minimum_width(deck_column, mode, edge_column_widths.x, edge_column_widths.y, edge_column_widths.z)
	DemoLayoutSupport.set_minimum_width(discard_column, mode, edge_column_widths.x, edge_column_widths.y, edge_column_widths.z)
	DemoLayoutSupport.set_minimum_width(hand_column, mode, middle_column_widths.x, middle_column_widths.y, middle_column_widths.z)
	DemoLayoutSupport.set_minimum_width(board_column, mode, middle_column_widths.x, middle_column_widths.y, middle_column_widths.z)
	DemoLayoutSupport.set_minimum_size(_deck_zone, _pick_layout_value(mode, edge_column_widths), _pick_layout_value(mode, zone_heights))
	DemoLayoutSupport.set_minimum_size(_hand_zone, _pick_layout_value(mode, middle_column_widths), _pick_layout_value(mode, zone_heights))
	DemoLayoutSupport.set_minimum_size(_board_zone, _pick_layout_value(mode, middle_column_widths), _pick_layout_value(mode, zone_heights))
	DemoLayoutSupport.set_minimum_size(_discard_zone, _pick_layout_value(mode, edge_column_widths), _pick_layout_value(mode, zone_heights))
	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		zone.refresh()
