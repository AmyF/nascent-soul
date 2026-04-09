extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)

@onready var status_label: Label = $RootMargin/RootVBox/StatusLabel
@onready var source_panel: Panel = $RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel
@onready var battlefield_panel: Panel = $RootMargin/RootVBox/ContentRow/BattlefieldColumn/BattlefieldPanel

var _source_zone: Zone
var _battlefield_zone: BattlefieldZone
var _space_model: ZoneSquareGridSpaceModel

func _ready() -> void:
	_space_model = ZoneSquareGridSpaceModel.new()
	_space_model.columns = 4
	_space_model.rows = 3
	_source_zone = ExampleSupport.make_zone(source_panel, "SquareSourceZone", ZoneHBoxLayout.new())
	var occupancy = ZoneOccupancyTransferPolicy.new()
	_battlefield_zone = ExampleSupport.make_battlefield_zone(battlefield_panel, "SquareBattlefieldZone", _space_model, occupancy)
	for spec in [
		{"title": "Spark", "cost": 1, "tags": ["spell"]},
		{"title": "Ward", "cost": 2, "tags": ["guard"]},
		{"title": "Anchor", "cost": 3, "tags": ["summon"]}
	]:
		_source_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
	_source_zone.item_double_clicked.connect(_on_source_card_double_clicked)
	_battlefield_zone.item_right_clicked.connect(_on_battlefield_item_right_clicked)
	_battlefield_zone.item_transferred.connect(_on_item_transferred.bind(_battlefield_zone))
	_source_zone.item_transferred.connect(_on_item_transferred.bind(_source_zone))
	_set_status(ExampleSupport.compact_bilingual("双击卡牌进入方格战场，右键战场牌回手牌", "Double-click cards into the square battlefield, right-click them to return"))

func _on_source_card_double_clicked(item: Control) -> void:
	if not _source_zone.has_item(item):
		return
	var target = _space_model.get_first_open_target(_battlefield_zone.get_context(), item)
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
