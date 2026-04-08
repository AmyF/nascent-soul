@tool
extends EditorPlugin

const EXAMPLE_HUB_PATH := "res://scenes/demo.tscn"
const RECIPE_SCENE_PATH := "res://scenes/examples/zone_recipes.tscn"
const README_PATH := "res://README.md"
const ZONE_SCRIPT := preload("res://addons/nascentsoul/core/zone.gd")
const ZONE_CARD_SCRIPT := preload("res://addons/nascentsoul/cards/zone_card.gd")
const CARD_DATA_SCRIPT := preload("res://addons/nascentsoul/cards/card_data.gd")
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
	add_tool_menu_item(MENU_OPEN_EXAMPLES, _open_example_hub)
	add_tool_menu_item(MENU_OPEN_RECIPES, _open_recipe_scene)
	add_tool_menu_item(MENU_OPEN_README, _open_readme)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_OPEN_EXAMPLES)
	remove_tool_menu_item(MENU_OPEN_RECIPES)
	remove_tool_menu_item(MENU_OPEN_README)
	_unregister_custom_types()

func _register_custom_types() -> void:
	if _zone_icon == null:
		_zone_icon = load("res://icon.png")
	if _card_icon == null:
		_card_icon = load("res://assets/card/card_front.png")
	add_custom_type("Zone", "Node", ZONE_SCRIPT, _zone_icon)
	add_custom_type("ZoneCard", "Control", ZONE_CARD_SCRIPT, _card_icon)
	add_custom_type("CardData", "Resource", CARD_DATA_SCRIPT, _card_icon)

func _unregister_custom_types() -> void:
	remove_custom_type("CardData")
	remove_custom_type("ZoneCard")
	remove_custom_type("Zone")

func _open_example_hub() -> void:
	if ResourceLoader.exists(EXAMPLE_HUB_PATH):
		get_editor_interface().open_scene_from_path(EXAMPLE_HUB_PATH)

func _open_recipe_scene() -> void:
	if ResourceLoader.exists(RECIPE_SCENE_PATH):
		get_editor_interface().open_scene_from_path(RECIPE_SCENE_PATH)

func _open_readme() -> void:
	if ResourceLoader.exists(README_PATH):
		OS.shell_open(ProjectSettings.globalize_path(README_PATH))
