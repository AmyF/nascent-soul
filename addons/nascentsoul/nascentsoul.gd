@tool
extends EditorPlugin

const DEFAULT_ZONE_PRESET_PATH := "res://addons/nascentsoul/presets/hand_zone_preset.tres"
const DEFAULT_BATTLEFIELD_PRESET_PATH := "res://addons/nascentsoul/presets/battlefield_square_zone_preset.tres"
const DEFAULT_HEX_BATTLEFIELD_PRESET_PATH := "res://addons/nascentsoul/presets/battlefield_hex_zone_preset.tres"
const PLUGIN_ICON_PATH := "res://addons/nascentsoul/plugin_icon.png"
const CARD_ICON_PATH := "res://addons/nascentsoul/assets/card/card_front.png"
const ZONE_SCRIPT := preload("res://addons/nascentsoul/core/zone.gd")
const CARD_ZONE_SCRIPT := preload("res://addons/nascentsoul/core/card_zone.gd")
const BATTLEFIELD_ZONE_SCRIPT := preload("res://addons/nascentsoul/core/battlefield_zone.gd")
const ZONE_CARD_SCRIPT := preload("res://addons/nascentsoul/cards/zone_card.gd")
const CARD_DATA_SCRIPT := preload("res://addons/nascentsoul/cards/card_data.gd")
const ZONE_PIECE_SCRIPT := preload("res://addons/nascentsoul/pieces/zone_piece.gd")
const PIECE_DATA_SCRIPT := preload("res://addons/nascentsoul/pieces/piece_data.gd")
const ZONE_PRESET_SCRIPT := preload("res://addons/nascentsoul/resources/zone_preset.gd")
const DRAG_VISUAL_FACTORY_SCRIPT := preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
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
	add_custom_type("ZonePreset", "Resource", ZONE_PRESET_SCRIPT, _zone_icon)
	add_custom_type("ZoneConfigurableDragVisualFactory", "Resource", DRAG_VISUAL_FACTORY_SCRIPT, _zone_icon)

func _unregister_custom_types() -> void:
	remove_custom_type("ZoneConfigurableDragVisualFactory")
	remove_custom_type("ZonePreset")
	remove_custom_type("PieceData")
	remove_custom_type("ZonePiece")
	remove_custom_type("CardData")
	remove_custom_type("ZoneCard")
	remove_custom_type("BattlefieldZone")
	remove_custom_type("CardZone")
	remove_custom_type("Zone")

func _create_card_zone_from_preset() -> void:
	_create_zone_from_script(CARD_ZONE_SCRIPT, DEFAULT_ZONE_PRESET_PATH)

func _create_square_battlefield_zone() -> void:
	_create_zone_from_script(BATTLEFIELD_ZONE_SCRIPT, DEFAULT_BATTLEFIELD_PRESET_PATH)

func _create_hex_battlefield_zone() -> void:
	_create_zone_from_script(BATTLEFIELD_ZONE_SCRIPT, DEFAULT_HEX_BATTLEFIELD_PRESET_PATH)

func _create_zone_from_script(script: Script, preset_path: String) -> void:
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return
	var zone = script.new()
	zone.name = "Zone"
	zone.custom_minimum_size = Vector2(320, 220)
	zone.size = zone.custom_minimum_size
	zone.position = Vector2(64, 64)
	if ResourceLoader.exists(preset_path):
		zone.preset = load(preset_path)
	scene_root.add_child(zone)
	zone.owner = scene_root
	zone.refresh()
	get_editor_interface().edit_node(zone)

func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null
