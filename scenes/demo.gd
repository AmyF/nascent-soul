extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const TRANSFER_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const LAYOUT_SCENE = preload("res://scenes/examples/layout_gallery.tscn")
const PERMISSION_SCENE = preload("res://scenes/examples/permission_lab.tscn")
const RECIPES_SCENE = preload("res://scenes/examples/zone_recipes.tscn")

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var title_label: Label = $RootMargin/RootVBox/TitleLabel
@onready var tab_container: TabContainer = $RootMargin/RootVBox/TabContainer
@onready var transfer_tab: Control = $RootMargin/RootVBox/TabContainer/TransferTab
@onready var layout_tab: Control = $RootMargin/RootVBox/TabContainer/LayoutTab
@onready var permission_tab: Control = $RootMargin/RootVBox/TabContainer/PermissionTab
@onready var recipes_tab: Control = $RootMargin/RootVBox/TabContainer/RecipesTab

func _ready() -> void:
	_mount_tab_scenes()
	_apply_text_styles()
	_schedule_headless_quit_if_root()

func _mount_tab_scenes() -> void:
	var hosts: Array[Control] = [transfer_tab, layout_tab, permission_tab, recipes_tab]
	var scenes: Array[PackedScene] = [TRANSFER_SCENE, LAYOUT_SCENE, PERMISSION_SCENE, RECIPES_SCENE]
	for index in range(hosts.size()):
		_mount_tab_scene(hosts[index], scenes[index])

func _mount_tab_scene(host: Control, scene_resource: PackedScene) -> void:
	if host == null or scene_resource == null or host.get_child_count() > 0:
		return
	var scene = scene_resource.instantiate()
	scene.name = "Content"
	host.add_child(scene)
	if scene is Control:
		var control := scene as Control
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0

func _apply_text_styles() -> void:
	title_label.text = ExampleSupport.compact_bilingual("NascentSoul 示例总览", "NascentSoul Example Hub")
	ExampleSupport.style_title_label(title_label)
	var summaries = _tab_summaries()
	for index in range(summaries.size()):
		tab_container.set_tab_title(index, summaries[index]["tab_title"])

func _tab_summaries() -> Array[Dictionary]:
	return [
		{
			"tab_title": ExampleSupport.compact_bilingual("转移", "Transfer")
		},
		{
			"tab_title": ExampleSupport.compact_bilingual("布局", "Layouts")
		},
		{
			"tab_title": ExampleSupport.compact_bilingual("规则", "Rules")
		},
		{
			"tab_title": ExampleSupport.compact_bilingual("模板", "Recipes")
		}
	]

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	if get_tree().current_scene != self:
		return
	get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
