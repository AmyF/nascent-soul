extends Control

const ExampleItemSupport = preload("res://scenes/showcases/shared/example_item_support.gd")

@export var freecell_scene: PackedScene
@export var xiangqi_scene: PackedScene

@onready var freecell_button: Button = $RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton
@onready var xiangqi_button: Button = $RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton
@onready var content_title_label: Label = $RootMargin/RootHBox/ContentColumn/ContentTitleLabel
@onready var content_summary_label: Label = $RootMargin/RootHBox/ContentColumn/ContentSummaryLabel
@onready var content_host: Control = $RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost

var _current_content: Control = null
var _demo_scene_by_key: Dictionary = {}

func _ready() -> void:
	_demo_scene_by_key = {
		&"freecell": freecell_scene,
		&"xiangqi": xiangqi_scene
	}
	for button in _demo_buttons():
		button.pressed.connect(_on_demo_button_pressed.bind(button))
	_show_demo_from_button(freecell_button)
	_schedule_headless_quit_if_root()

func _schedule_headless_quit_if_root() -> void:
	if DisplayServer.get_name() != "headless":
		return
	get_tree().process_frame.connect(_maybe_shutdown_headless_if_root, CONNECT_ONE_SHOT)

func _maybe_shutdown_headless_if_root() -> void:
	var tree = get_tree()
	if tree == null:
		return
	if tree.current_scene != null and tree.current_scene != self:
		return
	call_deferred("_shutdown_headless")

func _shutdown_headless() -> void:
	for _i in range(12):
		await get_tree().process_frame
	await _cleanup_before_quit()

func _cleanup_before_quit() -> void:
	_cleanup_current_content()
	_cleanup_viewport_helpers()
	ExampleItemSupport.clear_card_texture_cache()
	var tree = get_tree()
	if tree == null:
		return
	if tree.current_scene == self:
		tree.current_scene = null
	queue_free()
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	tree.quit()

func _demo_buttons() -> Array[Button]:
	return [
		freecell_button,
		xiangqi_button
	]

func _on_demo_button_pressed(button: Button) -> void:
	_show_demo_from_button(button)

func _show_demo_from_button(button: Button) -> void:
	if button == null:
		push_error("Demo shell requires a valid button to mount content.")
		return
	var scene_key := StringName(str(button.get_meta("demo_scene_key", "")))
	var title := str(button.get_meta("demo_title", button.text))
	var summary := str(button.get_meta("demo_summary", ""))
	var scene_resource = _demo_scene_by_key.get(scene_key)
	var content = _instantiate_control_scene(scene_resource, title)
	if content == null:
		return
	_mount_content(content, title, summary)
	_set_button_states(button)

func _instantiate_control_scene(scene_resource: PackedScene, title: String) -> Control:
	if scene_resource == null:
		push_error("Demo shell scene for %s is not assigned." % title)
		return null
	var instance := scene_resource.instantiate()
	if instance is not Control:
		push_error("Demo shell scene for %s must inherit Control." % title)
		if instance is Node:
			(instance as Node).free()
		return null
	return instance as Control

func _mount_content(content: Control, title: String, summary: String) -> void:
	_cleanup_current_content()
	_current_content = content
	content_title_label.text = title
	content_summary_label.text = summary
	content_host.add_child(content)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 0.0
	content.offset_top = 0.0
	content.offset_right = 0.0
	content.offset_bottom = 0.0

func _set_button_states(active_button: Button) -> void:
	for button in _demo_buttons():
		button.disabled = button == active_button

func _cleanup_current_content() -> void:
	if _current_content == null or not is_instance_valid(_current_content):
		return
	_cleanup_viewport_helpers()
	_current_content.queue_free()
	_current_content = null

func _cleanup_viewport_helpers() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var helpers := viewport.find_children("__NascentSoul*", "", true, false)
	for helper in helpers:
		if not is_instance_valid(helper):
			continue
		if helper.has_method("clear_session"):
			helper.call("clear_session")
		helper.free()
