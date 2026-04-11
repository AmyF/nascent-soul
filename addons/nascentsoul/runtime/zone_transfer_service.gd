class_name ZoneTransferService extends RefCounted

# Internal runtime helper for transfer decision flow, drag orchestration, and
# execution collaboration.

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")
const ZoneTransferCommandRouterScript = preload("res://addons/nascentsoul/runtime/zone_transfer_command_router.gd")
const ZoneDragStartFlowScript = preload("res://addons/nascentsoul/runtime/zone_drag_start_flow.gd")
const ZoneTransferDecisionResolverScript = preload("res://addons/nascentsoul/runtime/zone_transfer_decision_resolver.gd")
const ZoneTransferExecutionScript = preload("res://addons/nascentsoul/runtime/zone_transfer_execution.gd")
const ZoneDragSessionCleanupScript = preload("res://addons/nascentsoul/runtime/zone_drag_session_cleanup.gd")

var context: ZoneContext
var zone: Zone
var store: ZoneStore
var runtime_port = null

var input_service: ZoneInputService = null
var render_service: ZoneRenderService = null

var _command_router = null
var _drag_start_flow = null
var _decision_resolver = null
var _execution = null
var _drag_session_cleanup = null

func _init(p_context: ZoneContext, p_runtime_port) -> void:
	context = p_context
	zone = context.zone
	store = context.get_store()
	runtime_port = p_runtime_port
	_command_router = ZoneTransferCommandRouterScript.new(self, context, store)
	_drag_start_flow = ZoneDragStartFlowScript.new(self, context, store, runtime_port)
	_decision_resolver = ZoneTransferDecisionResolverScript.new(context)
	_execution = ZoneTransferExecutionScript.new(self, context, store)
	_drag_session_cleanup = ZoneDragSessionCleanupScript.new(self)

# Lifecycle and zone-facing API.
func bind_services(p_input_service: ZoneInputService, p_render_service: ZoneRenderService) -> void:
	input_service = p_input_service
	render_service = p_render_service
	_execution.bind_services(input_service, render_service)

func cleanup() -> void:
	if _drag_session_cleanup != null:
		_drag_session_cleanup.cleanup()
	if _decision_resolver != null:
		_decision_resolver.cleanup()
	if _drag_start_flow != null:
		_drag_start_flow.cleanup()
	if _command_router != null:
		_command_router.cleanup()
	if _execution != null:
		_execution.cleanup()
	input_service = null
	render_service = null
	_drag_session_cleanup = null
	_decision_resolver = null
	_drag_start_flow = null
	_command_router = null
	_execution = null
	store = null
	runtime_port = null
	zone = null
	context = null

func process(_delta: float) -> void:
	if zone.get_items_root() == null:
		return
	render_service.prune_display_state()
	var coordinator = get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		var should_refresh = false
		if context.get_space_model() is ZoneLinearSpaceModel and render_service.container_order_needs_sync():
			render_service.sync_container_order()
			should_refresh = true
			runtime_port.emit_layout_changed()
		if render_service.clear_hover_feedback([]):
			should_refresh = true
		if should_refresh:
			runtime_port.request_refresh()
		return
	if session.prune_invalid_items() and session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return
	_update_hover_preview(session)

func refresh() -> void:
	render_service.refresh()

func rebuild_items_from_root() -> bool:
	return store.rebuild_items_from_root(context, zone.get_items_root())

func resolve_transfer_target(items: Array[ZoneItemControl], placement_target: ZonePlacementTarget) -> ZonePlacementTarget:
	var space_model = context.get_space_model()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	if placement_target != null and placement_target.is_valid():
		return space_model.normalize_target(context, placement_target, items)
	var reference_item = items[0] if not items.is_empty() else null
	return space_model.resolve_add_target(context, reference_item, null)

func add_item(item: ZoneItemControl, placement_target: ZonePlacementTarget = null) -> bool:
	return insert_item(item, store.items.size(), placement_target)

func insert_item(item: ZoneItemControl, index: int, placement_target: ZonePlacementTarget = null) -> bool:
	var items_root = zone.get_items_root()
	if not is_instance_valid(item) or items_root == null:
		return false
	var resolved_target = _resolve_insert_target(item, placement_target, index)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	if store.contains_item_reference(item):
		return _reorder_items([item], resolved_target)
	if item.get_parent() != items_root:
		if item.get_parent() != null:
			item.reparent(items_root, true)
		else:
			items_root.add_child(item)
	input_service.register_item(item)
	var target_index = _resolve_linear_insert_index(index, resolved_target)
	store.insert_item_reference(item, target_index, resolved_target)
	item.visible = true
	render_service.sync_container_order()
	runtime_port.emit_item_added(item, target_index)
	refresh()
	runtime_port.emit_layout_changed()
	return true

func remove_item(item: ZoneItemControl) -> bool:
	return _execution.remove_item(item)

func perform_transfer(command: ZoneTransferCommand) -> bool:
	return _command_router.perform_transfer(command) if _command_router != null else false

func _transfer_command_items(target_zone: Zone, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position = null) -> bool:
	return _command_router.transfer_command_items(target_zone, items, placement_target, global_position) if _command_router != null else false

func clear_selection() -> void:
	input_service.clear_selection()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	input_service.select_item(item, additive)

# Drag session lifecycle.
func start_drag(items: Array[ZoneItemControl], anchor_item: ZoneItemControl = null) -> void:
	if _drag_start_flow != null:
		_drag_start_flow.start_drag(items, null, anchor_item)

func start_drag_at(items: Array[ZoneItemControl], pointer_global_position: Vector2, anchor_item: ZoneItemControl = null) -> void:
	if _drag_start_flow != null:
		_drag_start_flow.start_drag(items, pointer_global_position, anchor_item)

func finalize_drag_session(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = get_drag_coordinator(false)
		active_session = coordinator.get_session() if coordinator != null else null
	if active_session == null or active_session.source_zone != zone:
		return
	if active_session.prune_invalid_items() and active_session.items.is_empty():
		_cleanup_drag_session(active_session, true, true)
		return
	if active_session.hover_zone != null and active_session.hover_zone is Zone:
		var target_zone := active_session.hover_zone as Zone
		target_zone.perform_drop(active_session)
	else:
		cancel_drag(active_session)

func perform_drop(session: ZoneDragSession) -> bool:
	session.prune_invalid_items()
	if session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return false
	var requested_target = session.requested_target if session.requested_target != null and session.requested_target.is_valid() else session.preview_target
	var request = make_transfer_request(zone, session.source_zone, session.items, requested_target, _get_drop_global_position(session))
	var decision = resolve_drop_decision(request)
	if not decision.allowed:
		_emit_drop_rejected(session, decision.reason)
		_cleanup_drag_session(session, true, true)
		return false
	var source_zone = session.source_zone as Zone
	var success = false
	if source_zone == zone:
		success = _reorder_items(session.items, decision.resolved_target)
	elif source_zone != null:
		var source_transfer = ZoneRuntimePortScript.resolve_transfer_service(source_zone)
		if source_transfer != null:
			success = source_transfer._transfer_items_to(zone, session.items, decision.resolved_target, request.global_position, source_zone, decision, session.anchor_item)
	if success:
		_cleanup_drag_session(session, true, false)
	else:
		_cleanup_drag_session(session, true, true)
	return success

func cancel_drag(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = get_drag_coordinator(false)
		active_session = coordinator.get_session() if coordinator != null else null
	if active_session == null:
		return
	active_session.prune_invalid_items()
	_cleanup_drag_session(active_session, true, true)

func get_display_state(style: Resource) -> Dictionary:
	return render_service.get_display_state(style)

# Execution helpers shared with transfer collaborators.
func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	return context.build_transfer_snapshots(moving_items, drop_position, anchor_item) if context != null else {}

func resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	return context.resolve_programmatic_transfer_global_position(moving_items) if context != null else null

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	if context != null:
		context.set_transfer_handoff(item, snapshot)

func remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	return _execution.remove_item_from_state(item, remove_from_container, clear_visuals)

func _clear_item_visual_state(item, reset_transform: bool) -> void:
	_execution.clear_item_visual_state(item, reset_transform)

func _resolve_insert_target(item: ZoneItemControl, placement_target: ZonePlacementTarget, index_hint: int) -> ZonePlacementTarget:
	var space_model = context.get_space_model()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	var single_item: Array[ZoneItemControl] = []
	if is_instance_valid(item):
		single_item.append(item)
	if placement_target != null and placement_target.is_valid():
		return space_model.normalize_target(context, placement_target, single_item)
	return space_model.resolve_add_target(context, item, index_hint)

func _resolve_linear_insert_index(index_hint: int, target: ZonePlacementTarget) -> int:
	if context.get_space_model() is ZoneLinearSpaceModel:
		if target != null and target.is_linear():
			return clampi(target.linear_index, 0, store.items.size())
		return clampi(index_hint, 0, store.items.size())
	return clampi(index_hint, 0, store.items.size())

func _resolve_reordered_target(base_target: ZonePlacementTarget, linear_index: int) -> ZonePlacementTarget:
	if context.get_space_model() is ZoneLinearSpaceModel:
		return ZonePlacementTarget.linear(linear_index)
	return base_target.duplicate_target() if base_target != null else ZonePlacementTarget.invalid()

func _reorder_items(items_to_move: Array[ZoneItemControl], placement_target: ZonePlacementTarget) -> bool:
	return _execution.reorder_items(items_to_move, placement_target)

func _transfer_items_to(target_zone: Zone, items_to_move: Array[ZoneItemControl], placement_target: ZonePlacementTarget, drop_position = null, source_zone_override: Zone = null, decision: ZoneTransferDecision = null, anchor_item: ZoneItemControl = null) -> bool:
	return _execution.transfer_items_to(target_zone, items_to_move, placement_target, drop_position, source_zone_override, decision, anchor_item)

func _insert_transferred_items(moving_items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, transfer_snapshots: Dictionary) -> bool:
	return _execution.insert_transferred_items(moving_items, placement_target, transfer_snapshots)

func _restore_failed_transfer(moving_items: Array[ZoneItemControl], original_targets: Dictionary) -> void:
	_execution.restore_failed_transfer(moving_items, original_targets)

func _emit_item_transferred(source_zone: Zone, target_zone: Zone, moving_items: Array[ZoneItemControl]) -> void:
	_execution.emit_item_transferred(source_zone, target_zone, moving_items)

func _emit_drop_rejected(session: ZoneDragSession, reason: String) -> void:
	var source_zone = session.source_zone as Zone
	ZoneRuntimePortScript.emit_drop_rejected_for(zone, session.items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		ZoneRuntimePortScript.emit_drop_rejected_for(source_zone, session.items, source_zone, zone, reason)

func emit_drop_rejected_items(items: Array[ZoneItemControl], source_zone: Zone, reason: String) -> void:
	ZoneRuntimePortScript.emit_drop_rejected_for(zone, items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		ZoneRuntimePortScript.emit_drop_rejected_for(source_zone, items, source_zone, zone, reason)

func get_drag_coordinator(create_if_missing: bool = true):
	return runtime_port.get_drag_coordinator(create_if_missing) if runtime_port != null else null

func _cleanup_drag_session(session: ZoneDragSession, refresh_involved: bool, emit_layout_changed: bool) -> void:
	_drag_session_cleanup.cleanup_drag_session(session, refresh_involved, emit_layout_changed)

# Drop-preview evaluation.
func _update_hover_preview(session: ZoneDragSession) -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	var viewport = zone.get_viewport()
	if viewport == null:
		return
	var global_mouse = viewport.get_mouse_position()
	if not zone.get_global_rect().has_point(global_mouse):
		if session.hover_zone == zone:
			session.hover_zone = null
			session.requested_target = ZonePlacementTarget.invalid()
			session.preview_target = ZonePlacementTarget.invalid()
		if render_service.clear_hover_feedback(session.items):
			runtime_port.request_refresh()
		return
	var decision = update_hover_preview_session(zone, session, render_service.get_layout_items(session), global_mouse, zone.get_local_mouse_position())
	if decision == null:
		if render_service.clear_hover_feedback(session.items):
			runtime_port.request_refresh()
		return
	var preview_anchor = session.anchor_item if is_instance_valid(session.anchor_item) else session.items[0] if not session.items.is_empty() and session.items[0] is ZoneItemControl else null
	if render_service.apply_hover_feedback(session.items, decision, session.preview_target, preview_anchor):
		runtime_port.request_refresh()

func _get_drop_global_position(session: ZoneDragSession) -> Vector2:
	if session == null:
		return Vector2.ZERO
	var viewport = zone.get_viewport()
	if viewport != null:
		return viewport.get_mouse_position() - session.drag_offset
	if is_instance_valid(session.anchor_item):
		return session.anchor_item.global_position
	return Vector2.ZERO

func make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	return _decision_resolver.make_transfer_request(target_zone, source_zone, items, placement_target, global_position) if _decision_resolver != null else null

func resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	if _decision_resolver == null:
		return ZoneTransferDecision.new(true, "", request.placement_target)
	return _decision_resolver.resolve_drop_decision(request)

func update_hover_preview_session(target_zone: Zone, session: ZoneDragSession, visible_items: Array[ZoneItemControl], global_position: Vector2, local_position: Vector2) -> ZoneTransferDecision:
	return _decision_resolver.update_hover_preview_session(target_zone, session, visible_items, global_position, local_position) if _decision_resolver != null else null
