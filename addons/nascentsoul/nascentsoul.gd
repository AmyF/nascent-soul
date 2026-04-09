@tool
extends EditorPlugin

const DEFAULT_ZONE_CONFIG_PATH := "res://addons/nascentsoul/presets/hand_zone_config.tres"
const DEFAULT_BATTLEFIELD_CONFIG_PATH := "res://addons/nascentsoul/presets/battlefield_square_zone_config.tres"
const DEFAULT_HEX_BATTLEFIELD_CONFIG_PATH := "res://addons/nascentsoul/presets/battlefield_hex_zone_config.tres"
const PLUGIN_ICON_PATH := "res://addons/nascentsoul/plugin_icon.png"
const CARD_ICON_PATH := "res://addons/nascentsoul/assets/card/card_front.png"
const ZONE_SCRIPT := preload("res://addons/nascentsoul/core/zone.gd")
const CARD_ZONE_SCRIPT := preload("res://addons/nascentsoul/core/card_zone.gd")
const BATTLEFIELD_ZONE_SCRIPT := preload("res://addons/nascentsoul/core/battlefield_zone.gd")
const ZONE_CARD_SCRIPT := preload("res://addons/nascentsoul/cards/zone_card.gd")
const CARD_DATA_SCRIPT := preload("res://addons/nascentsoul/cards/card_data.gd")
const ZONE_PIECE_SCRIPT := preload("res://addons/nascentsoul/pieces/zone_piece.gd")
const PIECE_DATA_SCRIPT := preload("res://addons/nascentsoul/pieces/piece_data.gd")
const ZONE_CONFIG_SCRIPT := preload("res://addons/nascentsoul/resources/zone_config.gd")
const DRAG_VISUAL_FACTORY_SCRIPT := preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
const TARGETING_STYLE_SCRIPT := preload("res://addons/nascentsoul/resources/zone_targeting_style.gd")
const LAYERED_TARGETING_STYLE_SCRIPT := preload("res://addons/nascentsoul/resources/zone_layered_targeting_style.gd")
const TARGETING_VISUAL_LAYER_SCRIPT := preload("res://addons/nascentsoul/resources/zone_targeting_visual_layer.gd")
const ARROW_TARGETING_STYLE_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_arrow_targeting_style.gd")
const TARGET_PATH_LAYER_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_path_layer.gd")
const TARGET_HEAD_LAYER_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_head_layer.gd")
const TARGET_ENDPOINT_LAYER_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_endpoint_layer.gd")
const TARGET_TRAIL_LAYER_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_trail_layer.gd")
const TARGETING_POLICY_SCRIPT := preload("res://addons/nascentsoul/resources/zone_targeting_policy.gd")
const TARGET_ALLOW_ALL_POLICY_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_allow_all_policy.gd")
const TARGET_COMPOSITE_POLICY_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_composite_policy.gd")
const TARGET_RULE_TABLE_POLICY_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_rule_table_policy.gd")
const TARGET_RULE_SCRIPT := preload("res://addons/nascentsoul/impl/targeting/zone_target_rule.gd")
const TARGETING_INTENT_SCRIPT := preload("res://addons/nascentsoul/model/zone_targeting_intent.gd")
const CREATE_CARD_ZONE_MENU := "Create Card Zone"
const CREATE_SQUARE_BATTLEFIELD_MENU := "Create Square Battlefield Zone"
const CREATE_HEX_BATTLEFIELD_MENU := "Create Hex Battlefield Zone"

var _zone_icon: Texture2D
var _card_icon: Texture2D

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	_zone_icon = _load_optional_texture(PLUGIN_ICON_PATH)
	_card_icon = _load_optional_texture(CARD_ICON_PATH)
	_register_custom_types()
	add_tool_menu_item(CREATE_CARD_ZONE_MENU, _create_card_zone_from_preset)
	add_tool_menu_item(CREATE_SQUARE_BATTLEFIELD_MENU, _create_square_battlefield_zone)
	add_tool_menu_item(CREATE_HEX_BATTLEFIELD_MENU, _create_hex_battlefield_zone)


func _exit_tree() -> void:
	remove_tool_menu_item(CREATE_HEX_BATTLEFIELD_MENU)
	remove_tool_menu_item(CREATE_SQUARE_BATTLEFIELD_MENU)
	remove_tool_menu_item(CREATE_CARD_ZONE_MENU)
	_unregister_custom_types()

func _register_custom_types() -> void:
	if _zone_icon == null:
		_zone_icon = _load_optional_texture(PLUGIN_ICON_PATH)
	if _card_icon == null:
		_card_icon = _load_optional_texture(CARD_ICON_PATH)
	add_custom_type("Zone", "Control", ZONE_SCRIPT, _zone_icon)
	add_custom_type("CardZone", "Zone", CARD_ZONE_SCRIPT, _zone_icon)
	add_custom_type("BattlefieldZone", "Zone", BATTLEFIELD_ZONE_SCRIPT, _zone_icon)
	add_custom_type("ZoneCard", "Control", ZONE_CARD_SCRIPT, _card_icon)
	add_custom_type("CardData", "Resource", CARD_DATA_SCRIPT, _card_icon)
	add_custom_type("ZonePiece", "Control", ZONE_PIECE_SCRIPT, _zone_icon)
	add_custom_type("PieceData", "Resource", PIECE_DATA_SCRIPT, _zone_icon)
	add_custom_type("ZoneConfig", "Resource", ZONE_CONFIG_SCRIPT, _zone_icon)
	add_custom_type("ZoneConfigurableDragVisualFactory", "Resource", DRAG_VISUAL_FACTORY_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetingStyle", "Resource", TARGETING_STYLE_SCRIPT, _zone_icon)
	add_custom_type("ZoneLayeredTargetingStyle", "ZoneTargetingStyle", LAYERED_TARGETING_STYLE_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetingVisualLayer", "Resource", TARGETING_VISUAL_LAYER_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetPathLayer", "ZoneTargetingVisualLayer", TARGET_PATH_LAYER_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetHeadLayer", "ZoneTargetingVisualLayer", TARGET_HEAD_LAYER_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetEndpointLayer", "ZoneTargetingVisualLayer", TARGET_ENDPOINT_LAYER_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetTrailLayer", "ZoneTargetingVisualLayer", TARGET_TRAIL_LAYER_SCRIPT, _zone_icon)
	add_custom_type("ZoneArrowTargetingStyle", "ZoneTargetingStyle", ARROW_TARGETING_STYLE_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetingPolicy", "Resource", TARGETING_POLICY_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetAllowAllPolicy", "ZoneTargetingPolicy", TARGET_ALLOW_ALL_POLICY_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetCompositePolicy", "ZoneTargetingPolicy", TARGET_COMPOSITE_POLICY_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetRuleTablePolicy", "ZoneTargetingPolicy", TARGET_RULE_TABLE_POLICY_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetRule", "Resource", TARGET_RULE_SCRIPT, _zone_icon)
	add_custom_type("ZoneTargetingIntent", "Resource", TARGETING_INTENT_SCRIPT, _zone_icon)

func _unregister_custom_types() -> void:
	remove_custom_type("ZoneTargetingIntent")
	remove_custom_type("ZoneTargetRule")
	remove_custom_type("ZoneTargetRuleTablePolicy")
	remove_custom_type("ZoneTargetCompositePolicy")
	remove_custom_type("ZoneTargetAllowAllPolicy")
	remove_custom_type("ZoneTargetingPolicy")
	remove_custom_type("ZoneArrowTargetingStyle")
	remove_custom_type("ZoneTargetTrailLayer")
	remove_custom_type("ZoneTargetEndpointLayer")
	remove_custom_type("ZoneTargetHeadLayer")
	remove_custom_type("ZoneTargetPathLayer")
	remove_custom_type("ZoneTargetingVisualLayer")
	remove_custom_type("ZoneLayeredTargetingStyle")
	remove_custom_type("ZoneTargetingStyle")
	remove_custom_type("ZoneConfigurableDragVisualFactory")
	remove_custom_type("ZoneConfig")
	remove_custom_type("PieceData")
	remove_custom_type("ZonePiece")
	remove_custom_type("CardData")
	remove_custom_type("ZoneCard")
	remove_custom_type("BattlefieldZone")
	remove_custom_type("CardZone")
	remove_custom_type("Zone")

func _create_card_zone_from_preset() -> void:
	_create_zone_from_script(CARD_ZONE_SCRIPT, DEFAULT_ZONE_CONFIG_PATH)

func _create_square_battlefield_zone() -> void:
	_create_zone_from_script(BATTLEFIELD_ZONE_SCRIPT, DEFAULT_BATTLEFIELD_CONFIG_PATH)

func _create_hex_battlefield_zone() -> void:
	_create_zone_from_script(BATTLEFIELD_ZONE_SCRIPT, DEFAULT_HEX_BATTLEFIELD_CONFIG_PATH)

func _create_zone_from_script(script: Script, config_path: String) -> void:
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return
	var zone = script.new()
	zone.name = "Zone"
	zone.custom_minimum_size = Vector2(320, 220)
	zone.size = zone.custom_minimum_size
	zone.position = Vector2(64, 64)
	if ResourceLoader.exists(config_path):
		zone.config = load(config_path)
	scene_root.add_child(zone)
	zone.owner = scene_root
	zone.refresh()
	get_editor_interface().edit_node(zone)

func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null
