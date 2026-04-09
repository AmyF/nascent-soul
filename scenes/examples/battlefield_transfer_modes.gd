extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const ZoneRuleTableTransferPolicyScript = preload("res://addons/nascentsoul/impl/permissions/zone_rule_table_transfer_policy.gd")
const ZoneTransferRuleScript = preload("res://addons/nascentsoul/impl/permissions/zone_transfer_rule.gd")
const ZoneCardScript = preload("res://addons/nascentsoul/cards/zone_card.gd")
const ZonePieceScript = preload("res://addons/nascentsoul/pieces/zone_piece.gd")

const REJECT_COLOR := Color(0.96, 0.60, 0.56)
const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var source_panel: Panel = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel
@onready var direct_panel: Panel = $RootMargin/RootVBox/ContentRow/DirectColumn/DirectPanel
@onready var summon_panel: Panel = $RootMargin/RootVBox/ContentRow/SummonColumn/SummonPanel

var _source_zone: Zone
var _direct_zone: BattlefieldZone
var _summon_zone: BattlefieldZone
var _direct_space: ZoneSquareGridSpaceModel
var _summon_space: ZoneSquareGridSpaceModel

func _ready() -> void:
	_source_zone = ExampleSupport.make_zone(source_panel, "ModeSourceZone", ZoneHBoxLayout.new())
	_source_zone.transfer_policy = _make_cards_only_rule_table(ExampleSupport.compact_bilingual("Cards 只接受卡牌，不能接收已生成的棋子", "Cards only accept cards, not spawned pieces"))
	_direct_space = ZoneSquareGridSpaceModel.new()
	_direct_space.columns = 3
	_direct_space.rows = 2
	_summon_space = ZoneSquareGridSpaceModel.new()
	_summon_space.columns = 3
	_summon_space.rows = 2
	var direct_composite = ZoneCompositeTransferPolicy.new()
	var direct_rules = _make_cards_only_rule_table(ExampleSupport.compact_bilingual("Direct Place 保持卡牌形态，棋子不能进入", "Direct Place keeps card form, so pieces cannot enter"))
	var direct_policies: Array[ZoneTransferPolicy] = [ZoneOccupancyTransferPolicy.new(), direct_rules]
	direct_composite.policies = direct_policies
	_direct_zone = ExampleSupport.make_battlefield_zone(direct_panel, "DirectBattlefieldZone", _direct_space, direct_composite)
	var rule_table = ZoneRuleTableTransferPolicyScript.new()
	var rule = ZoneTransferRuleScript.new()
	rule.source_item_script = ZoneCardScript
	rule.target_kind = ZonePlacementTarget.TargetKind.SQUARE
	rule.transfer_mode = ZoneTransferDecision.TransferMode.SPAWN_PIECE
	var piece_scene := PackedScene.new()
	var prototype := ZonePiece.new()
	piece_scene.pack(prototype)
	prototype.free()
	rule.spawn_scene = piece_scene
	var typed_rules: Array[ZoneTransferRule] = [rule]
	rule_table.rules = typed_rules
	var summon_composite = ZoneCompositeTransferPolicy.new()
	var typed_policies: Array[ZoneTransferPolicy] = [ZoneOccupancyTransferPolicy.new(), rule_table]
	summon_composite.policies = typed_policies
	_summon_zone = ExampleSupport.make_battlefield_zone(summon_panel, "SummonBattlefieldZone", _summon_space, summon_composite)
	for spec in [
		{"title": "Aegis", "cost": 1, "tags": ["unit"]},
		{"title": "Bloom", "cost": 2, "tags": ["summon"]},
		{"title": "Beacon", "cost": 3, "tags": ["spell"]}
	]:
		_source_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
	_source_zone.item_double_clicked.connect(_send_to_direct)
	_source_zone.item_right_clicked.connect(_send_to_summon)
	for zone in [_source_zone, _direct_zone, _summon_zone]:
		zone.item_transferred.connect(_on_item_transferred.bind(zone))
		zone.drop_rejected.connect(_on_drop_rejected.bind(zone))
	_set_status(ExampleSupport.compact_bilingual("源区双击进入 Direct Place 并保持卡牌；源区右键进入 Spawn Piece 并生成棋子；生成的棋子默认不能回到 Cards 或 Direct Place", "Double-click in source to enter Direct Place as a card; right-click in source to enter Spawn Piece and become a piece; spawned pieces do not return to Cards or Direct Place by default"))

func _send_to_direct(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = _direct_space.get_first_open_target(_direct_zone, _direct_zone.get_runtime(), item)
	if target.is_valid():
		_source_zone.move_item_to(item, _direct_zone, target)

func _send_to_summon(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = _summon_space.get_first_open_target(_summon_zone, _summon_zone.get_runtime(), item)
	if target.is_valid():
		_source_zone.move_item_to(item, _summon_zone, target)

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

func _make_cards_only_rule_table(reject_reason: String) -> ZoneRuleTableTransferPolicy:
	var rule_table = ZoneRuleTableTransferPolicyScript.new()
	var rule = ZoneTransferRuleScript.new()
	rule.source_item_script = ZonePieceScript
	rule.allowed = false
	rule.reject_reason = reject_reason
	var typed_rules: Array[ZoneTransferRule] = [rule]
	rule_table.rules = typed_rules
	return rule_table
