extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const REJECT_COLOR := Color(0.96, 0.60, 0.56)
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

@export_group("Status Copy")
@export var ready_status := "主线流程已就绪 / The main flow is ready"
@export var status_prefix := "最近 / Latest"
@export var board_capacity_format := "容量 %d / %d / Capacity %d / %d"

@export_group("Layout Presets")
@export var deck_column_widths := Vector3(200.0, 176.0, 160.0)
@export var discard_column_widths := Vector3(200.0, 176.0, 160.0)
@export var deck_zone_heights := Vector3(240.0, 220.0, 200.0)
@export var board_zone_heights := Vector3(240.0, 220.0, 210.0)
@export var hand_zone_heights := Vector3(150.0, 144.0, 136.0)
@export var board_width_desktop_range := Vector2(420.0, 620.0)
@export var board_width_compact_range := Vector2(400.0, 520.0)
@export var board_width_narrow_range := Vector2(360.0, 460.0)
@export var desktop_board_gutter := 92.0
@export var compact_board_gutter := 72.0
@export var narrow_board_gutter := 56.0

@onready var top_row: HFlowContainer = $RootMargin/RootVBox/TopRow
@onready var deck_column: VBoxContainer = $RootMargin/RootVBox/TopRow/DeckColumn
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/TopRow/BoardColumn
@onready var discard_column: VBoxContainer = $RootMargin/RootVBox/TopRow/DiscardColumn
@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var board_capacity_label: Label = $RootMargin/RootVBox/TopRow/BoardColumn/BoardCapacityLabel
@onready var _deck_zone: Zone = $RootMargin/RootVBox/TopRow/DeckColumn/DeckZone as Zone
@onready var _board_zone: Zone = $RootMargin/RootVBox/TopRow/BoardColumn/BoardZone as Zone
@onready var _discard_zone: Zone = $RootMargin/RootVBox/TopRow/DiscardColumn/DiscardZone as Zone
@onready var _hand_zone: Zone = $RootMargin/RootVBox/HandZone as Zone

func _ready() -> void:
	_wire_demo_actions()
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	_refresh_guidance()
	_set_status(ready_status)
	_schedule_headless_quit_if_root()

func _wire_demo_actions() -> void:
	_deck_zone.item_double_clicked.connect(_on_deck_card_double_clicked)
	_hand_zone.item_double_clicked.connect(_on_hand_card_double_clicked)
	_hand_zone.item_right_clicked.connect(_on_card_discard_requested)
	_board_zone.item_right_clicked.connect(_on_card_discard_requested)

	for zone in [_deck_zone, _hand_zone, _board_zone, _discard_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.item_reordered.connect(_on_item_reordered.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))

func _on_deck_card_double_clicked(item: Control) -> void:
	if _deck_zone.has_item(item):
		ExampleSupport.move_item(_deck_zone, item, _hand_zone, ZonePlacementTarget.linear(_hand_zone.get_item_count()))

func _on_hand_card_double_clicked(item: Control) -> void:
	if _hand_zone.has_item(item):
		ExampleSupport.move_item(_hand_zone, item, _board_zone, ZonePlacementTarget.linear(_board_zone.get_item_count()))

func _on_card_discard_requested(item: Control) -> void:
	if _hand_zone.has_item(item):
		ExampleSupport.move_item(_hand_zone, item, _discard_zone, ZonePlacementTarget.linear(_discard_zone.get_item_count()))
	elif _board_zone.has_item(item):
		ExampleSupport.move_item(_board_zone, item, _discard_zone, ZonePlacementTarget.linear(_discard_zone.get_item_count()))

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_apply_zone_visual_state(item, target_zone)
	_refresh_guidance()
	var target_text = ExampleSupport.describe_target(target)
	_set_status(ExampleSupport.compact_bilingual(
		"%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text],
		"%s: %s -> %s @ %s" % [item.name, source_zone.name, target_zone.name, target_text]
	))

func _on_item_reordered(item: Control, from_index: int, to_index: int, emitter_zone: Zone) -> void:
	_refresh_guidance()
	_set_status(ExampleSupport.compact_bilingual(
		"%s 在 %s 中 %d -> %d" % [item.name, emitter_zone.name, from_index, to_index],
		"%s in %s %d -> %d" % [item.name, emitter_zone.name, from_index, to_index]
	))

func _on_drop_rejected(items: Array, _source_zone: Zone, target_zone: Zone, reason: String, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_refresh_guidance()
	var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
	_set_status(ExampleSupport.compact_bilingual(
		"%s 无法进入 %s：%s" % [item_name, target_zone.name, reason],
		"%s could not enter %s: %s" % [item_name, target_zone.name, reason]
	), REJECT_COLOR)

func _apply_zone_visual_state(item: Control, target_zone: Zone) -> void:
	if item is not ZoneCard:
		return
	var card := item as ZoneCard
	card.highlighted = target_zone == _board_zone
	card.flip(target_zone != _deck_zone, false)

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

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _pick_layout_value(mode: StringName, preset: Vector3) -> float:
	return DemoLayoutSupport.pick_float(mode, preset.x, preset.y, preset.z)

func _apply_responsive_layout() -> void:
	var mode := DemoLayoutSupport.mode_for(self)
	var available_width := DemoLayoutSupport.resolved_width(self)
	var deck_width := _pick_layout_value(mode, deck_column_widths)
	var discard_width := _pick_layout_value(mode, discard_column_widths)
	var board_width := 0.0
	match mode:
		DemoLayoutSupport.DESKTOP:
			board_width = clamp(
				available_width - deck_width - discard_width - desktop_board_gutter,
				board_width_desktop_range.x,
				board_width_desktop_range.y
			)
		DemoLayoutSupport.COMPACT:
			board_width = clamp(
				available_width - compact_board_gutter,
				board_width_compact_range.x,
				board_width_compact_range.y
			)
		_:
			board_width = clamp(
				available_width - narrow_board_gutter,
				board_width_narrow_range.x,
				board_width_narrow_range.y
			)
	DemoLayoutSupport.ensure_child_order(
		top_row,
		[deck_column, board_column, discard_column] if mode == DemoLayoutSupport.DESKTOP else [board_column, deck_column, discard_column]
	)
	DemoLayoutSupport.set_minimum_size(deck_column, deck_width, 0.0)
	DemoLayoutSupport.set_minimum_size(board_column, board_width, 0.0)
	DemoLayoutSupport.set_minimum_size(discard_column, discard_width, 0.0)
	DemoLayoutSupport.set_minimum_size(_deck_zone, deck_width, _pick_layout_value(mode, deck_zone_heights))
	DemoLayoutSupport.set_minimum_size(_board_zone, board_width, _pick_layout_value(mode, board_zone_heights))
	DemoLayoutSupport.set_minimum_size(_discard_zone, discard_width, _pick_layout_value(mode, deck_zone_heights))
	DemoLayoutSupport.set_minimum_height(_hand_zone, mode, hand_zone_heights.x, hand_zone_heights.y, hand_zone_heights.z)
	for zone in [_deck_zone, _board_zone, _discard_zone, _hand_zone]:
		zone.refresh()
