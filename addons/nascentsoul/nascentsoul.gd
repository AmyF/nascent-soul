@tool
extends EditorPlugin

const EXAMPLE_HUB_PATH := "res://scenes/demo.tscn"
const RECIPE_SCENE_PATH := "res://scenes/examples/zone_recipes.tscn"
const README_PATH := "res://README.md"
const DEFAULT_ZONE_PRESET_PATH := "res://addons/nascentsoul/presets/hand_zone_preset.tres"
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

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	_zone_icon = load("res://icon.png")
	_card_icon = load("res://assets/card/card_front.png")
	_register_custom_types()
	add_tool_menu_item(CREATE_ZONE_PRESET_MENU, _create_zone_from_preset)
	add_tool_menu_item(MENU_OPEN_EXAMPLES, _open_example_hub)
	add_tool_menu_item(MENU_OPEN_RECIPES, _open_recipe_scene)
	add_tool_menu_item(MENU_OPEN_README, _open_readme)


func _exit_tree() -> void:
	remove_tool_menu_item(CREATE_ZONE_PRESET_MENU)
	remove_tool_menu_item(MENU_OPEN_EXAMPLES)
	remove_tool_menu_item(MENU_OPEN_RECIPES)
	remove_tool_menu_item(MENU_OPEN_README)
	_unregister_custom_types()

func _register_custom_types() -> void:
	if _zone_icon == null:
		_zone_icon = load("res://icon.png")
	if _card_icon == null:
		_card_icon = load("res://assets/card/card_front.png")
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
	if ResourceLoader.exists(README_PATH):
		OS.shell_open(ProjectSettings.globalize_path(README_PATH))
