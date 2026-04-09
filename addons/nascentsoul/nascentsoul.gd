@tool
extends EditorPlugin

const DEFAULT_ZONE_PRESET_PATH := "res://addons/nascentsoul/presets/hand_zone_preset.tres"
const PLUGIN_ICON_PATH := "res://addons/nascentsoul/plugin_icon.png"
const CARD_ICON_PATH := "res://addons/nascentsoul/assets/card/card_front.png"
const ZONE_SCRIPT := preload("res://addons/nascentsoul/core/zone.gd")
const ZONE_CARD_SCRIPT := preload("res://addons/nascentsoul/cards/zone_card.gd")
const CARD_DATA_SCRIPT := preload("res://addons/nascentsoul/cards/card_data.gd")
const ZONE_PRESET_SCRIPT := preload("res://addons/nascentsoul/resources/zone_preset.gd")
const DRAG_VISUAL_FACTORY_SCRIPT := preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
const CREATE_ZONE_PRESET_MENU := "Create Zone From Preset"

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
	add_tool_menu_item(CREATE_ZONE_PRESET_MENU, _create_zone_from_preset)


func _exit_tree() -> void:
	remove_tool_menu_item(CREATE_ZONE_PRESET_MENU)
	_unregister_custom_types()

func _register_custom_types() -> void:
	if _zone_icon == null:
		_zone_icon = _load_optional_texture(PLUGIN_ICON_PATH)
	if _card_icon == null:
		_card_icon = _load_optional_texture(CARD_ICON_PATH)
	add_custom_type("Zone", "Control", ZONE_SCRIPT, _zone_icon)
	add_custom_type("ZoneCard", "Control", ZONE_CARD_SCRIPT, _card_icon)
	add_custom_type("CardData", "Resource", CARD_DATA_SCRIPT, _card_icon)
	add_custom_type("ZonePreset", "Resource", ZONE_PRESET_SCRIPT, _zone_icon)
	add_custom_type("ZoneConfigurableDragVisualFactory", "Resource", DRAG_VISUAL_FACTORY_SCRIPT, _zone_icon)

func _unregister_custom_types() -> void:
	remove_custom_type("ZoneConfigurableDragVisualFactory")
	remove_custom_type("ZonePreset")
	remove_custom_type("CardData")
	remove_custom_type("ZoneCard")
	remove_custom_type("Zone")

func _create_zone_from_preset() -> void:
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return
	var zone := ZONE_SCRIPT.new()
	zone.name = "Zone"
	zone.custom_minimum_size = Vector2(320, 220)
	zone.size = zone.custom_minimum_size
	zone.position = Vector2(64, 64)
	if ResourceLoader.exists(DEFAULT_ZONE_PRESET_PATH):
		zone.preset = load(DEFAULT_ZONE_PRESET_PATH)
	scene_root.add_child(zone)
	zone.owner = scene_root
	zone.refresh()
	get_editor_interface().edit_node(zone)

func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null
