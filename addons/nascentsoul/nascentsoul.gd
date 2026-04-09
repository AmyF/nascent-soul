@tool
extends EditorPlugin

const EXAMPLE_HUB_PATH := "res://scenes/demo.tscn"
const RECIPE_SCENE_PATH := "res://scenes/examples/zone_recipes.tscn"
const README_PATH := "res://README.md"
const DEFAULT_ZONE_PRESET_PATH := "res://addons/nascentsoul/presets/hand_zone_preset.tres"
const PLUGIN_ICON_PATH := "res://addons/nascentsoul/plugin_icon.png"
const CARD_ICON_PATH := "res://addons/nascentsoul/assets/card/card_front.png"
const ZONE_SCRIPT := preload("res://addons/nascentsoul/core/zone.gd")
const ZONE_CARD_SCRIPT := preload("res://addons/nascentsoul/cards/zone_card.gd")
const CARD_DATA_SCRIPT := preload("res://addons/nascentsoul/cards/card_data.gd")
const ZONE_PRESET_SCRIPT := preload("res://addons/nascentsoul/resources/zone_preset.gd")
const DRAG_VISUAL_FACTORY_SCRIPT := preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
const CREATE_ZONE_PRESET_MENU := "Create Zone From Preset"
const MENU_OPEN_EXAMPLES := "Open NascentSoul Example Hub"
const MENU_OPEN_RECIPES := "Open NascentSoul Zone Recipes"
const MENU_OPEN_README := "Open NascentSoul README"

var _zone_icon: Texture2D
var _card_icon: Texture2D
var _added_examples_menu: bool = false
var _added_recipes_menu: bool = false
var _added_readme_menu: bool = false

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	_zone_icon = _load_optional_texture(PLUGIN_ICON_PATH)
	_card_icon = _load_optional_texture(CARD_ICON_PATH)
	_register_custom_types()
	add_tool_menu_item(CREATE_ZONE_PRESET_MENU, _create_zone_from_preset)
	if ResourceLoader.exists(EXAMPLE_HUB_PATH):
		add_tool_menu_item(MENU_OPEN_EXAMPLES, _open_example_hub)
		_added_examples_menu = true
	if ResourceLoader.exists(RECIPE_SCENE_PATH):
		add_tool_menu_item(MENU_OPEN_RECIPES, _open_recipe_scene)
		_added_recipes_menu = true
	if FileAccess.file_exists(README_PATH):
		add_tool_menu_item(MENU_OPEN_README, _open_readme)
		_added_readme_menu = true


func _exit_tree() -> void:
	remove_tool_menu_item(CREATE_ZONE_PRESET_MENU)
	if _added_examples_menu:
		remove_tool_menu_item(MENU_OPEN_EXAMPLES)
	if _added_recipes_menu:
		remove_tool_menu_item(MENU_OPEN_RECIPES)
	if _added_readme_menu:
		remove_tool_menu_item(MENU_OPEN_README)
	_added_examples_menu = false
	_added_recipes_menu = false
	_added_readme_menu = false
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

func _open_example_hub() -> void:
	if ResourceLoader.exists(EXAMPLE_HUB_PATH):
		get_editor_interface().open_scene_from_path(EXAMPLE_HUB_PATH)

func _open_recipe_scene() -> void:
	if ResourceLoader.exists(RECIPE_SCENE_PATH):
		get_editor_interface().open_scene_from_path(RECIPE_SCENE_PATH)

func _open_readme() -> void:
	if FileAccess.file_exists(README_PATH):
		OS.shell_open(ProjectSettings.globalize_path(README_PATH))

func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null
