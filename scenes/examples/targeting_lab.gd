extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_STATUS_COLOR := Color(0.96, 0.60, 0.56)
const SCENE_SQUARE_META_KEY := &"demo_square"

@export var spell_style_ids: PackedStringArray = PackedStringArray(["classic", "arcane", "strike", "tactical"])
@export var ability_style_ids: PackedStringArray = PackedStringArray(["classic", "arcane", "strike", "tactical"])
@export var spell_initial_style_id: StringName = &"classic"
@export var ability_initial_style_id: StringName = &"tactical"
@export_multiline var initial_status_message: String = "拖拽 Meteor 指向敌方棋子，或切换风格后点击 Aim Ability 体验 style override / Drag Meteor onto an enemy piece, or switch presets and click Aim Ability to preview style overrides"
@export_range(1.0, 240.0, 1.0) var grid_min_cell_size: float = 72.0
@export_range(1.0, 240.0, 1.0) var grid_max_cell_size: float = 120.0

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var content_row: HFlowContainer = $RootMargin/RootVBox/ContentRow
@onready var spell_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/SpellColumn
@onready var spell_style_option: OptionButton = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellToolbar/SpellStyleOption
@onready var spell_hand_panel: Panel = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel
@onready var spell_target_panel: Panel = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel
@onready var ability_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/AbilityColumn
@onready var ability_style_option: OptionButton = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AbilityStyleOption
@onready var ability_button: Button = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AimAbilityButton
@onready var cancel_button: Button = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/CancelTargetingButton
@onready var ability_panel: Panel = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel
@onready var _spell_source_zone: Zone = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel/SpellSourceZone as Zone
@onready var _spell_target_zone: BattlefieldZone = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel/SpellTargetZone as BattlefieldZone
@onready var _ability_zone: BattlefieldZone = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel/AbilityBattlefieldZone as BattlefieldZone

var _spell_space_model: ZoneSquareGridSpaceModel
var _ability_space_model: ZoneSquareGridSpaceModel
var _ability_piece: ZonePiece = null
var _spell_style_id: StringName
var _ability_style_id: StringName

func _ready() -> void:
	_spell_space_model = ExampleSupport.get_zone_space_model(_spell_target_zone) as ZoneSquareGridSpaceModel
	_ability_space_model = ExampleSupport.get_zone_space_model(_ability_zone) as ZoneSquareGridSpaceModel
	_spell_style_id = _populate_style_options(spell_style_option, spell_style_ids, spell_initial_style_id)
	_ability_style_id = _populate_style_options(ability_style_option, ability_style_ids, ability_initial_style_id)
	if _spell_source_zone != null:
		ExampleSupport.set_zone_targeting_style(_spell_source_zone, TargetingSupport.builtin_targeting_style(_spell_style_id))
	_apply_scene_targets(_spell_target_zone)
	_apply_scene_targets(_ability_zone)
	_ability_piece = _find_ability_piece(_ability_zone)
	_spell_source_zone.targeting_started.connect(_on_targeting_started.bind("spell"))
	_spell_source_zone.target_hover_state_changed.connect(_on_target_hover_state_changed.bind("spell"))
	_spell_source_zone.targeting_resolved.connect(_on_targeting_resolved.bind("spell"))
	_spell_source_zone.targeting_cancelled.connect(_on_targeting_cancelled.bind("spell"))
	_ability_zone.targeting_started.connect(_on_targeting_started.bind("ability"))
	_ability_zone.target_hover_state_changed.connect(_on_target_hover_state_changed.bind("ability"))
	_ability_zone.targeting_resolved.connect(_on_targeting_resolved.bind("ability"))
	_ability_zone.targeting_cancelled.connect(_on_targeting_cancelled.bind("ability"))
	spell_style_option.item_selected.connect(_on_spell_style_selected)
	ability_style_option.item_selected.connect(_on_ability_style_selected)
	ability_button.pressed.connect(_start_piece_targeting)
	cancel_button.pressed.connect(_cancel_targeting)
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	if initial_status_message != "":
		_set_status(initial_status_message)

func _apply_scene_targets(zone: Zone) -> void:
	if zone == null:
		return
	for item in zone.get_items():
		if item is not ZoneItemControl:
			continue
		var placement_target := _scene_square_target(item as ZoneItemControl)
		if placement_target == null:
			continue
		ExampleSupport.reorder_items(zone, [item], placement_target)

func _scene_square_target(item: ZoneItemControl) -> ZonePlacementTarget:
	if item == null:
		return null
	var square = item.get_zone_item_metadata().get(SCENE_SQUARE_META_KEY, null)
	if square is Vector2i:
		return ZonePlacementTarget.square(square.x, square.y)
	if square is Vector2:
		return ZonePlacementTarget.square(int(square.x), int(square.y))
	return null

func _find_ability_piece(zone: Zone) -> ZonePiece:
	if zone == null:
		return null
	for item in zone.get_items():
		if item is ZonePiece and item is ZoneItemControl and (item as ZoneItemControl).zone_targeting_intent_override != null:
			return item as ZonePiece
	return null

func _start_piece_targeting() -> void:
	if _ability_piece == null or not is_instance_valid(_ability_piece) or not _ability_zone.has_item(_ability_piece):
		return
	var intent := _resolve_ability_intent()
	if intent == null:
		return
	intent.style_override = TargetingSupport.builtin_targeting_style(_ability_style_id)
	if ExampleSupport.begin_item_targeting(_ability_zone, _ability_piece, intent):
		_set_status(ExampleSupport.compact_bilingual("Guardian 已进入选目标状态，请选择一个格子", "Guardian is now targeting. Choose a board cell."))

func _resolve_ability_intent() -> ZoneTargetingIntent:
	if _ability_piece == null:
		return null
	return _ability_piece.create_zone_targeting_intent(null, &"explicit")

func _cancel_targeting() -> void:
	if _spell_source_zone != null and _spell_source_zone.is_targeting():
		_spell_source_zone.cancel_targeting()
		return
	if _ability_zone != null and _ability_zone.is_targeting():
		_ability_zone.cancel_targeting()

func _on_targeting_started(source_item: Control, _source_zone: Zone, intent: ZoneTargetingIntent, context: String) -> void:
	var ability_name = str(intent.metadata.get("ability_name", intent.metadata.get("spell_name", source_item.name))) if intent != null else source_item.name
	if context == "spell":
		_set_status("%s: %s (%s)" % [ability_name, ExampleSupport.compact_bilingual("拖拽到敌方棋子上", "drag onto an enemy piece"), TargetingSupport.builtin_targeting_style_label(_spell_style_id)])
	else:
		_set_status("%s: %s (%s)" % [ability_name, ExampleSupport.compact_bilingual("请选择一个格子", "choose a cell"), TargetingSupport.builtin_targeting_style_label(_ability_style_id)])

func _on_target_hover_state_changed(source_item: Control, _target_zone: Zone, decision: ZoneTargetDecision, _context: String) -> void:
	if decision == null:
		return
	var candidate = decision.resolved_candidate if decision.resolved_candidate != null and decision.resolved_candidate.is_valid() else null
	if candidate == null:
		return
	if decision.allowed:
		_set_status(_format_resolution_message(source_item, candidate))
		return
	if decision.reason != "":
		_set_status("%s: %s" % [source_item.name, decision.reason], REJECT_STATUS_COLOR)

func _on_targeting_resolved(source_item: Control, _source_zone: Zone, candidate: ZoneTargetCandidate, _decision: ZoneTargetDecision, _context: String) -> void:
	_set_status(ExampleSupport.compact_bilingual("已锁定目标", "Locked target") + ": " + _format_resolution_message(source_item, candidate))

func _on_targeting_cancelled(source_item: Control, _source_zone: Zone, _context: String) -> void:
	_set_status("%s: %s" % [source_item.name, ExampleSupport.compact_bilingual("已取消选目标", "targeting cancelled")], REJECT_STATUS_COLOR)

func _format_resolution_message(source_item: Control, candidate: ZoneTargetCandidate) -> String:
	if candidate == null or not candidate.is_valid():
		return "%s -> none" % source_item.name
	if candidate.is_item():
		return "%s -> %s" % [source_item.name, candidate.target_item.name]
	if candidate.is_placement():
		return "%s -> %s" % [source_item.name, candidate.placement_target.describe()]
	return "%s -> invalid" % source_item.name

func _populate_style_options(option: OptionButton, style_ids: PackedStringArray, selected_style_id: StringName) -> StringName:
	option.clear()
	var resolved_index := -1
	for index in range(style_ids.size()):
		var style_id := StringName(style_ids[index])
		option.add_item(TargetingSupport.builtin_targeting_style_label(style_id), index)
		if style_id == selected_style_id:
			resolved_index = index
	if resolved_index == -1 and not style_ids.is_empty():
		resolved_index = 0
	if resolved_index >= 0:
		option.select(resolved_index)
		return StringName(style_ids[resolved_index])
	return selected_style_id

func _style_id_at(style_ids: PackedStringArray, index: int, fallback: StringName) -> StringName:
	if index >= 0 and index < style_ids.size():
		return StringName(style_ids[index])
	return fallback

func _on_spell_style_selected(index: int) -> void:
	_spell_style_id = _style_id_at(spell_style_ids, index, _spell_style_id)
	if _spell_source_zone != null:
		ExampleSupport.set_zone_targeting_style(_spell_source_zone, TargetingSupport.builtin_targeting_style(_spell_style_id))
	_set_status(ExampleSupport.compact_bilingual("Spell 风格已切换为", "Spell preset switched to") + " " + TargetingSupport.builtin_targeting_style_label(_spell_style_id))

func _on_ability_style_selected(index: int) -> void:
	_ability_style_id = _style_id_at(ability_style_ids, index, _ability_style_id)
	_set_status(ExampleSupport.compact_bilingual("Ability override 已切换为", "Ability override switched to") + " " + TargetingSupport.builtin_targeting_style_label(_ability_style_id))

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var mode := DemoLayoutSupport.mode_for(self)
	var column_width := DemoLayoutSupport.pick_float(mode, 360.0, 312.0, 288.0)
	DemoLayoutSupport.ensure_child_order(content_row, [spell_column, ability_column])
	DemoLayoutSupport.set_minimum_size(spell_column, column_width, 0.0)
	DemoLayoutSupport.set_minimum_size(ability_column, column_width, 0.0)
	DemoLayoutSupport.set_minimum_size(spell_hand_panel, column_width, DemoLayoutSupport.pick_float(mode, 220.0, 196.0, 176.0))
	DemoLayoutSupport.set_minimum_size(spell_target_panel, column_width, DemoLayoutSupport.pick_float(mode, 340.0, 300.0, 264.0))
	DemoLayoutSupport.set_minimum_size(ability_panel, column_width, DemoLayoutSupport.pick_float(mode, 400.0, 340.0, 292.0))
	_apply_square_grid_layout(_spell_space_model, spell_target_panel.custom_minimum_size)
	_apply_square_grid_layout(_ability_space_model, ability_panel.custom_minimum_size)
	for zone in [_spell_source_zone, _spell_target_zone, _ability_zone]:
		if zone != null:
			zone.refresh()

func _apply_square_grid_layout(space_model: ZoneSquareGridSpaceModel, panel_size: Vector2) -> void:
	if space_model == null:
		return
	var columns: int = maxi(1, space_model.columns)
	var rows: int = maxi(1, space_model.rows)
	var padding := space_model.padding
	var inner_width = max(1.0, panel_size.x - padding.x * 2.0)
	var inner_height = max(1.0, panel_size.y - padding.y * 2.0)
	var spacing_width = space_model.cell_spacing.x * float(max(0, columns - 1))
	var spacing_height = space_model.cell_spacing.y * float(max(0, rows - 1))
	var available_width = max(1.0, inner_width - spacing_width)
	var available_height = max(1.0, inner_height - spacing_height)
	var cell_extent = clampf(floor(min(available_width / float(columns), available_height / float(rows))), grid_min_cell_size, grid_max_cell_size)
	space_model.cell_size = Vector2(cell_extent, cell_extent)
	space_model.padding = padding
