extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_STATUS_COLOR := Color(0.96, 0.60, 0.56)

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var spell_style_option: OptionButton = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellToolbar/SpellStyleOption
@onready var spell_hand_panel: Panel = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel
@onready var spell_target_panel: Panel = $RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel
@onready var ability_style_option: OptionButton = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AbilityStyleOption
@onready var ability_button: Button = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AimAbilityButton
@onready var cancel_button: Button = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/CancelTargetingButton
@onready var ability_panel: Panel = $RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel

var _spell_source_zone: Zone
var _spell_target_zone: BattlefieldZone
var _ability_zone: BattlefieldZone
var _ability_piece: ZonePiece
var _spell_style_id: StringName = &"classic"
var _ability_style_id: StringName = &"tactical"

func _ready() -> void:
	_populate_style_options(spell_style_option, _spell_style_id)
	_populate_style_options(ability_style_option, _ability_style_id)
	_build_spell_targeting_demo()
	_build_piece_targeting_demo()
	spell_style_option.item_selected.connect(_on_spell_style_selected)
	ability_style_option.item_selected.connect(_on_ability_style_selected)
	ability_button.pressed.connect(_start_piece_targeting)
	cancel_button.pressed.connect(_cancel_targeting)
	_set_status(ExampleSupport.compact_bilingual("拖拽 Meteor 指向敌方棋子，或切换风格后点击 Aim Ability 体验 style override", "Drag Meteor onto an enemy piece, or switch presets and click Aim Ability to preview style overrides"))

func _build_spell_targeting_demo() -> void:
	var hand_layout := ZoneHBoxLayout.new()
	hand_layout.item_spacing = 16.0
	_spell_source_zone = ExampleSupport.make_zone(spell_hand_panel, "SpellSourceZone", hand_layout)
	ExampleSupport.set_zone_targeting_style(_spell_source_zone, TargetingSupport.builtin_targeting_style(_spell_style_id))
	_spell_source_zone.targeting_started.connect(_on_targeting_started.bind("spell"))
	_spell_source_zone.target_hover_state_changed.connect(_on_target_hover_state_changed.bind("spell"))
	_spell_source_zone.targeting_resolved.connect(_on_targeting_resolved.bind("spell"))
	_spell_source_zone.targeting_cancelled.connect(_on_targeting_cancelled.bind("spell"))
	_spell_source_zone.add_item(TargetingSupport.make_spell_card("Meteor"))

	var spell_space := ZoneSquareGridSpaceModel.new()
	spell_space.columns = 4
	spell_space.rows = 2
	_spell_target_zone = ExampleSupport.make_battlefield_zone(spell_target_panel, "SpellTargetZone", spell_space, ZoneOccupancyTransferPolicy.new())
	_spell_target_zone.add_item(TargetingSupport.make_target_piece("Bulwark", "ally", 1, 4), ZonePlacementTarget.square(0, 0))
	_spell_target_zone.add_item(TargetingSupport.make_target_piece("Enemy Scout", "enemy", 2, 1), ZonePlacementTarget.square(2, 0))
	_spell_target_zone.add_item(TargetingSupport.make_target_piece("Enemy Sentinel", "enemy", 3, 3), ZonePlacementTarget.square(3, 1))

func _build_piece_targeting_demo() -> void:
	var ability_space := ZoneSquareGridSpaceModel.new()
	ability_space.columns = 4
	ability_space.rows = 3
	_ability_zone = ExampleSupport.make_battlefield_zone(ability_panel, "AbilityBattlefieldZone", ability_space, ZoneOccupancyTransferPolicy.new())
	ExampleSupport.set_zone_targeting_style(_ability_zone, TargetingSupport.builtin_targeting_style(&"classic"))
	_ability_zone.targeting_started.connect(_on_targeting_started.bind("ability"))
	_ability_zone.target_hover_state_changed.connect(_on_target_hover_state_changed.bind("ability"))
	_ability_zone.targeting_resolved.connect(_on_targeting_resolved.bind("ability"))
	_ability_zone.targeting_cancelled.connect(_on_targeting_cancelled.bind("ability"))
	_ability_piece = ExampleSupport.make_piece("Guardian", "blue", 3, 5)
	_ability_zone.add_item(_ability_piece, ZonePlacementTarget.square(1, 1))
	_ability_zone.add_item(TargetingSupport.make_target_piece("Beacon", "ally", 0, 2), ZonePlacementTarget.square(2, 1))

func _start_piece_targeting() -> void:
	if _ability_piece == null or not is_instance_valid(_ability_piece) or not _ability_zone.has_item(_ability_piece):
		return
	var intent = TargetingSupport.make_square_placement_intent("Guardian Dash")
	intent.style_override = TargetingSupport.builtin_targeting_style(_ability_style_id)
	if ExampleSupport.begin_item_targeting(_ability_zone, _ability_piece, intent):
		_set_status(ExampleSupport.compact_bilingual("Guardian 已进入选目标状态，请选择一个格子", "Guardian is now targeting. Choose a board cell."))

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

func _populate_style_options(option: OptionButton, selected_style_id: StringName) -> void:
	option.clear()
	var ids = TargetingSupport.builtin_targeting_style_ids()
	for index in range(ids.size()):
		var style_id = ids[index]
		option.add_item(TargetingSupport.builtin_targeting_style_label(style_id), index)
		if style_id == selected_style_id:
			option.select(index)

func _on_spell_style_selected(index: int) -> void:
	_spell_style_id = TargetingSupport.builtin_targeting_style_ids()[index]
	if _spell_source_zone != null:
		ExampleSupport.set_zone_targeting_style(_spell_source_zone, TargetingSupport.builtin_targeting_style(_spell_style_id))
	_set_status(ExampleSupport.compact_bilingual("Spell 风格已切换为", "Spell preset switched to") + " " + TargetingSupport.builtin_targeting_style_label(_spell_style_id))

func _on_ability_style_selected(index: int) -> void:
	_ability_style_id = TargetingSupport.builtin_targeting_style_ids()[index]
	_set_status(ExampleSupport.compact_bilingual("Ability override 已切换为", "Ability override switched to") + " " + TargetingSupport.builtin_targeting_style_label(_ability_style_id))

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = "%s: %s" % [ExampleSupport.compact_bilingual("最近", "Latest"), message]
	status_label.add_theme_color_override("font_color", font_color)
