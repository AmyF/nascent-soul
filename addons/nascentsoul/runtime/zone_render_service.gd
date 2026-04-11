class_name ZoneRenderService extends RefCounted

# Internal runtime helper for layout application, preview ghosts, and hover state.

const ZoneDragPreviewFeedbackScript = preload("res://addons/nascentsoul/runtime/zone_drag_preview_feedback.gd")

var context: ZoneContext
var zone: Zone
var runtime_port = null

var _preview_feedback = null

func _init(p_context: ZoneContext, p_runtime_port) -> void:
	context = p_context
	zone = context.zone
	runtime_port = p_runtime_port
	_preview_feedback = ZoneDragPreviewFeedbackScript.new(self, context)

func refresh() -> void:
	var layout_policy = context.get_layout_policy()
	var display_style = context.get_display_style()
	if zone.get_items_root() == null or layout_policy == null or display_style == null:
		return
	var coordinator = get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	var layout_items := get_layout_items(session)
	var sort_policy = context.get_sort_policy()
	if sort_policy != null and session == null and context.get_space_model() is ZoneLinearSpaceModel:
		layout_items = sort_policy.sort_items(context, layout_items)
	var ghost_hint = null
	if should_render_ghost_for_session(session):
		ghost_hint = context.get_space_model().resolve_layout_hint(session.preview_target)
	var placements = layout_policy.calculate(context, layout_items, zone.size, _preview_feedback.ghost_instance, ghost_hint)
	display_style.apply(context, placements)

func clear_preview() -> void:
	_preview_feedback.clear_preview()

func clear_display_state() -> void:
	if context == null:
		return
	context.clear_display_state()
	context.clear_transfer_handoffs()

func cleanup() -> void:
	if _preview_feedback != null:
		_preview_feedback.cleanup()
	clear_display_state()
	_preview_feedback = null
	runtime_port = null
	context = null
	zone = null

func get_display_state(style: Resource) -> Dictionary:
	return context.get_display_state(style) if context != null else {}

func prune_display_state() -> void:
	if context != null:
		context.prune_display_state()

func resolve_item_size(item: ZoneItemControl) -> Vector2:
	var layout_policy = context.get_layout_policy()
	if layout_policy != null:
		return layout_policy.resolve_item_size(item)
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)

func get_layout_items(session: ZoneDragSession) -> Array[ZoneItemControl]:
	var layout_items: Array[ZoneItemControl] = []
	var ordered_items = context.get_items_ordered()
	for item in ordered_items:
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			continue
		if session != null and item in session.items and not item.visible:
			continue
		if item.visible:
			layout_items.append(item)
	return layout_items

func should_render_ghost_for_session(session: ZoneDragSession) -> bool:
	return _preview_feedback.should_render_ghost_for_session(session)

func create_cursor_proxy(source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	return _preview_feedback.create_cursor_proxy(source_items, anchor_item)

func get_preview_ghost() -> Control:
	return _preview_feedback.ghost_instance if _preview_feedback != null else null

func sync_container_order() -> void:
	if zone == null or context == null:
		return
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	var ghost_instance = get_preview_ghost()
	var control_index = 0
	for item in context.get_items_ordered():
		if not is_instance_valid(item) or item.get_parent() != items_root:
			continue
		var target_index = control_index
		if is_instance_valid(ghost_instance) and ghost_instance.get_parent() == items_root and ghost_instance.get_index() <= target_index:
			target_index += 1
		if item.get_index() != target_index:
			items_root.move_child(item, target_index)
		control_index += 1

func container_order_needs_sync() -> bool:
	if zone == null or context == null:
		return false
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	var ghost_instance = get_preview_ghost()
	var ordered_items = context.get_items_ordered()
	var control_index = 0
	for child in items_root.get_children():
		if child is not ZoneItemControl or child == ghost_instance:
			continue
		if control_index >= ordered_items.size():
			return true
		if child != ordered_items[control_index]:
			return true
		control_index += 1
	return control_index != ordered_items.size()

func clear_preview_for_session(session: ZoneDragSession) -> void:
	_preview_feedback.clear_preview_for_session(session)

func apply_hover_feedback(items: Array[ZoneItemControl], decision: ZoneTransferDecision, preview_target, preview_source: ZoneItemControl) -> bool:
	return _preview_feedback.apply_hover_feedback(items, decision, preview_target, preview_source)

func clear_hover_feedback(items: Array[ZoneItemControl]) -> bool:
	return _preview_feedback.clear_hover_feedback(items)

func emit_drop_preview_changed(items: Array, target_zone: Zone, target) -> void:
	if runtime_port != null:
		runtime_port.emit_drop_preview_changed(items, target_zone, target)

func emit_drop_hover_state_changed(items: Array, target_zone: Zone, decision) -> void:
	if runtime_port != null:
		runtime_port.emit_drop_hover_state_changed(items, target_zone, decision)

func get_drag_coordinator(create_if_missing: bool = true):
	return runtime_port.get_drag_coordinator(create_if_missing) if runtime_port != null else null
