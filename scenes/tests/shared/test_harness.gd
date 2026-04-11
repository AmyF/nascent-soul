extends Control
class_name ZoneTestHarness

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

var _checks_run: int = 0
var _failures: Array[String] = []
var _suite_name: String = "Unnamed Suite"

func run_suite() -> Dictionary:
	custom_minimum_size = Vector2(1400, 900)
	_checks_run = 0
	_failures.clear()
	await _run_suite()
	await _reset_root()
	await _cleanup_viewport_helpers()
	ExampleSupport.clear_card_texture_cache()
	return {
		"name": _suite_name,
		"checks": _checks_run,
		"failures": _failures.duplicate()
	}

func _run_suite() -> void:
	pass

func _make_panel(name: String, position_value: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = name
	panel.position = position_value
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	add_child(panel)
	return panel

func _mount_scene_in_host(scene: Control, host_size: Vector2, host_position: Vector2 = Vector2.ZERO) -> Panel:
	var host := Panel.new()
	host.name = "%sHost" % scene.name
	host.position = host_position
	host.custom_minimum_size = host_size
	host.size = host_size
	host.clip_contents = true
	add_child(host)
	host.add_child(scene)
	await _settle_frames(3)
	return host

func _zone_item_names(zone: Zone) -> Array[String]:
	var names: Array[String] = []
	for item in zone.get_items():
		names.append(item.name)
	return names

func _move_item(source_zone: Zone, item: Control, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleSupport.move_item(source_zone, item, target_zone, placement_target)

func _transfer_items(source_zone: Zone, items: Array, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleSupport.transfer_items(source_zone, items, target_zone, placement_target)

func _reorder_items(zone: Zone, items: Array, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleSupport.reorder_items(zone, items, placement_target)

func _begin_item_targeting(zone: Zone, item: Control, intent: ZoneTargetingIntent = null, pointer_global_position: Vector2 = Vector2.ZERO) -> bool:
	return ExampleSupport.begin_item_targeting(zone, item, intent, pointer_global_position)

func _first_open_target(zone: Zone, item: Control) -> ZonePlacementTarget:
	return ExampleSupport.get_first_open_target(zone, item)

func _drag_session(zone: Zone) -> ZoneDragSession:
	return zone.get_drag_session() if zone != null else null

func _preview_transfer(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2, preview_source: ZoneItemControl = null) -> ZoneTransferDecision:
	if target_zone == null:
		return ZoneTransferDecision.new()
	return target_zone._runtime_preview_transfer(items, source_zone, placement_target, global_position, preview_source)

func _capture_transfer_snapshots(zone: Zone, moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	return zone._runtime_capture_transfer_snapshots(moving_items, drop_position, anchor_item) if zone != null else {}

func _resolve_transfer_origin(zone: Zone, moving_items: Array[ZoneItemControl]):
	return zone._runtime_resolve_transfer_origin(moving_items) if zone != null else Vector2.ZERO

func _managed_control_names(container: Control) -> Array[String]:
	var names: Array[String] = []
	var resolved_container = _resolve_managed_container(container)
	for child in resolved_container.get_children():
		if child is Control:
			names.append((child as Control).name)
	return names

func _unmanaged_control_names(zone: Zone) -> Array[String]:
	var unmanaged: Array[String] = []
	var managed_items = zone.get_items()
	var items_root = zone.get_items_root()
	for child in items_root.get_children():
		if child is Control and child not in managed_items:
			unmanaged.append((child as Control).name if (child as Control).name != "" else child.get_class())
	var preview_root = zone.get_preview_root()
	for child in preview_root.get_children():
		if child is Control:
			unmanaged.append((child as Control).name if (child as Control).name != "" else child.get_class())
	return unmanaged

func _check(condition: bool, message: String) -> void:
	_checks_run += 1
	if condition:
		return
	_failures.append(message)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _reset_root() -> void:
	var children := get_children().duplicate()
	for child in children:
		if is_instance_valid(child):
			child.free()
	await _settle_frames(1)

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
	await _settle_frames(1)

func _emit_left_click(item: Control, ctrl_pressed: bool = false, shift_pressed: bool = false) -> void:
	_emit_mouse_button(item, MOUSE_BUTTON_LEFT, true, false, ctrl_pressed, shift_pressed)
	_emit_mouse_button(item, MOUSE_BUTTON_LEFT, false, false, ctrl_pressed, shift_pressed)

func _emit_mouse_button(item: Control, button_index: MouseButton, pressed: bool, double_click: bool = false, ctrl_pressed: bool = false, shift_pressed: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	event.double_click = double_click
	event.ctrl_pressed = ctrl_pressed
	event.shift_pressed = shift_pressed
	event.position = item.size * 0.5
	event.global_position = item.global_position + event.position
	item.gui_input.emit(event)

func _emit_mouse_motion(item: Control, global_position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = global_position - item.global_position
	event.global_position = global_position
	item.gui_input.emit(event)

func _emit_background_left_click(container: Control, global_position: Vector2 = Vector2(-1, -1)) -> void:
	var target = _resolve_interaction_target(container)
	var click_position = global_position
	if click_position.x < 0.0 and click_position.y < 0.0:
		click_position = target.global_position + target.size * 0.5
	var local_position = click_position - target.global_position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = local_position
	press.global_position = click_position
	target.gui_input.emit(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = local_position
	release.global_position = click_position
	target.gui_input.emit(release)

func _emit_mouse_entered(item: Control) -> void:
	item.mouse_entered.emit()

func _emit_mouse_exited(item: Control) -> void:
	item.mouse_exited.emit()

func _emit_action_input(control: Control, action_name: StringName) -> void:
	var target = _resolve_interaction_target(control)
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	target.gui_input.emit(event)

func _overlay_visible(card: ZoneCard) -> bool:
	var overlay = card.get_node_or_null("VisualRoot/HighlightOverlay")
	return overlay is CanvasItem and (overlay as CanvasItem).visible

func _rect_inside(outer: Rect2, inner: Rect2, tolerance: float = 1.0) -> bool:
	return inner.position.x >= outer.position.x - tolerance \
		and inner.position.y >= outer.position.y - tolerance \
		and inner.end.x <= outer.end.x + tolerance \
		and inner.end.y <= outer.end.y + tolerance

func _all_items_within(zone: Zone, container: Control, tolerance: float = 1.0) -> bool:
	var container_rect = container.get_global_rect()
	for item in zone.get_items():
		if not is_instance_valid(item):
			continue
		if not _rect_inside(container_rect, item.get_global_rect(), tolerance):
			return false
	return true

func _find_unmanaged_control(zone: Zone) -> Control:
	var managed_items = zone.get_items()
	for child in zone.get_preview_root().get_children():
		if child is Control:
			return child as Control
	for child in zone.get_items_root().get_children():
		if child is Control and child not in managed_items:
			return child as Control
	return null

func _resolve_managed_container(control: Control) -> Control:
	if control is Zone:
		return (control as Zone).get_items_root()
	var child_zone = _resolve_child_zone(control)
	if child_zone != null:
		return child_zone.get_items_root()
	return control

func _resolve_interaction_target(control: Control) -> Control:
	if control is Zone:
		return control
	var child_zone = _resolve_child_zone(control)
	return child_zone if child_zone != null else control

func _resolve_child_zone(control: Control) -> Zone:
	for child in control.get_children():
		if child is Zone:
			return child as Zone
	return null
