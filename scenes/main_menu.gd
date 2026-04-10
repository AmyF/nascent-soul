extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const DEMO_SCENE = preload("res://scenes/demo.tscn")
const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")

@onready var title_label: Label = $RootMargin/RootHBox/Sidebar/SidebarVBox/TitleLabel
@onready var summary_label: Label = $RootMargin/RootHBox/Sidebar/SidebarVBox/SummaryLabel
@onready var demo_button: Button = $RootMargin/RootHBox/Sidebar/SidebarVBox/DemoHubButton
@onready var freecell_button: Button = $RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton
@onready var content_title_label: Label = $RootMargin/RootHBox/ContentColumn/ContentTitleLabel
@onready var content_summary_label: Label = $RootMargin/RootHBox/ContentColumn/ContentSummaryLabel
@onready var content_host: Control = $RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost

var _current_content: Control = null

func _ready() -> void:
	demo_button.pressed.connect(_show_demo_hub)
	freecell_button.pressed.connect(_show_freecell)
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
	ExampleSupport.clear_card_texture_cache()
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

func _show_demo_hub() -> void:
	_mount_content(DEMO_SCENE.instantiate(), "Demo Menu", "Open the full NascentSoul example hub and browse the rest of the playable samples.")

func _show_freecell() -> void:
	_mount_content(FREECELL_SCENE.instantiate(), "FreeCell", "Launch the classic Windows XP style FreeCell implementation directly from the main menu.")

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

func _cleanup_current_content() -> void:
	if _current_content == null or not is_instance_valid(_current_content):
		return
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
