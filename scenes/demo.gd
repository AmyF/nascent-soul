extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

func _ready() -> void:
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
