class_name ZoneTransferService extends RefCounted

# Internal runtime helper for transfer evaluation and execution.

const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")
const ZoneTransferEvaluatorScript = preload("res://addons/nascentsoul/runtime/zone_transfer_evaluator.gd")
const ZoneTransferExecutionScript = preload("res://addons/nascentsoul/runtime/zone_transfer_execution.gd")
const ZoneDragSessionCleanupScript = preload("res://addons/nascentsoul/runtime/zone_drag_session_cleanup.gd")

var context: ZoneContext
var zone: Zone
var store: ZoneStore

var input_service: ZoneInputService = null
var render_service: ZoneRenderService = null

var _evaluator = null
var _execution = null
var _drag_session_cleanup = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone
	store = context.store
	_evaluator = ZoneTransferEvaluatorScript.new(context)
	_execution = ZoneTransferExecutionScript.new(context, store, _evaluator)
	_drag_session_cleanup = ZoneDragSessionCleanupScript.new(zone)

func bind_services(p_input_service: ZoneInputService, p_render_service: ZoneRenderService) -> void:
	input_service = p_input_service
	render_service = p_render_service
	_execution.bind_services(input_service, render_service)

func cleanup() -> void:
	if _drag_session_cleanup != null:
		_drag_session_cleanup.cleanup()
	if _execution != null:
		_execution.cleanup()
	if _evaluator != null:
		_evaluator.cleanup()
	input_service = null
	render_service = null
	_drag_session_cleanup = null
	_execution = null
	_evaluator = null
	store = null
	zone = null
	context = null

func process(_delta: float) -> void:
	if zone.get_items_root() == null:
		return
	render_service.prune_display_state()
	var coordinator = zone._get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		var should_refresh = false
		if context.get_space_model() is ZoneLinearSpaceModel and store.container_order_needs_sync(zone.get_items_root(), render_service.get_preview_ghost()):
			store.sync_container_order(zone.get_items_root(), render_service.get_preview_ghost())
			should_refresh = true
			zone._emit_layout_changed()
		if render_service.clear_hover_feedback([]):
			should_refresh = true
		if should_refresh:
			zone.refresh()
		return
	if session.prune_invalid_items() and session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return
	render_service.update_hover_preview(session)

func refresh() -> void:
	render_service.refresh()

func rebuild_items_from_root() -> bool:
	return store.rebuild_items_from_root(context, zone.get_items_root())

func resolve_transfer_target(items: Array[ZoneItemControl], placement_target: ZonePlacementTarget) -> ZonePlacementTarget:
	return _evaluator.resolve_transfer_target(items, placement_target)

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
	store.sync_container_order(items_root, render_service.get_preview_ghost())
	zone._emit_item_added(item, target_index)
	refresh()
	zone._emit_layout_changed()
	return true

func remove_item(item: ZoneItemControl) -> bool:
	return _execution.remove_item(item)

func perform_transfer(command: ZoneTransferCommand) -> bool:
	if command == null:
		return false
	match command.kind:
		ZoneTransferCommand.CommandKind.INSERT:
			if command.target_zone != null and command.target_zone != zone:
				return command.target_zone.perform_transfer(command)
			var item = command.primary_item()
			return add_item(item, command.placement_target)
		ZoneTransferCommand.CommandKind.REORDER:
			var owning_zone = command.source_zone if command.source_zone != null else zone
			if owning_zone != zone:
				return owning_zone.perform_transfer(command)
			return _reorder_items(command.items, resolve_transfer_target(command.items, command.placement_target))
		_:
			var source_zone = command.source_zone if command.source_zone != null else zone
			if source_zone != zone:
				return source_zone.perform_transfer(command)
			var target_zone = command.target_zone if command.target_zone != null else zone
			if target_zone == zone:
				return _reorder_items(command.items, resolve_transfer_target(command.items, command.placement_target))
			return _transfer_command_items(target_zone, command.items, command.placement_target, command.global_position)

func _transfer_command_items(target_zone: Zone, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position = null) -> bool:
	if target_zone == null or items.is_empty():
		return false
	var moving_items: Array[ZoneItemControl] = []
	for item in store.items:
		if item in items and is_instance_valid(item):
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var request_position = global_position if global_position != null else store.resolve_programmatic_transfer_global_position(moving_items)
	var target_context = target_zone._get_context()
	var request = make_transfer_request(target_zone, zone, moving_items, target_context.transfer_service.resolve_transfer_target(moving_items, placement_target), request_position)
	var decision = target_zone._get_transfer_service().resolve_drop_decision(request)
	if not decision.allowed:
		target_zone._get_transfer_service().emit_drop_rejected_items(moving_items, zone, decision.reason)
		return false
	return _transfer_items_to(target_zone, moving_items, decision.resolved_target, request.global_position, zone, decision)

func clear_selection() -> void:
	input_service.clear_selection()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	input_service.select_item(item, additive)

func start_drag(items: Array[ZoneItemControl], anchor_item: ZoneItemControl = null) -> void:
	_start_drag_internal(items, null, anchor_item)

func start_drag_at(items: Array[ZoneItemControl], pointer_global_position: Vector2, anchor_item: ZoneItemControl = null) -> void:
	_start_drag_internal(items, pointer_global_position, anchor_item)

func _start_drag_internal(items: Array[ZoneItemControl], pointer_global_position = null, requested_anchor_item: ZoneItemControl = null) -> void:
	if zone.get_items_root() == null or items.is_empty():
		return
	var candidate_items = _sanitize_drag_items(items)
	var anchor_item = _resolve_drag_anchor(requested_anchor_item, candidate_items)
	if not is_instance_valid(anchor_item):
		return
	var drag_start = _evaluate_drag_start(anchor_item, candidate_items)
	if not drag_start.allowed:
		zone._emit_drag_start_rejected(drag_start.items, zone, drag_start.reason)
		return
	var valid_items = _sanitize_drag_items(drag_start.items, anchor_item)
	if valid_items.is_empty():
		zone._emit_drag_start_rejected([anchor_item], zone, "No draggable items remain.")
		return
	anchor_item = _resolve_drag_anchor(anchor_item, valid_items)
	if not is_instance_valid(anchor_item):
		zone._emit_drag_start_rejected(valid_items, zone, "The drag anchor is no longer available.")
		return
	var coordinator = zone._get_drag_coordinator()
	if coordinator == null:
		return
	input_service.clear_hover_for_items(valid_items, true)
	var pointer_position = anchor_item.global_position + anchor_item.size * 0.5
	if anchor_item.get_viewport() != null:
		pointer_position = anchor_item.get_global_mouse_position()
	if pointer_global_position is Vector2:
		pointer_position = pointer_global_position as Vector2
	var drag_offset = pointer_position - anchor_item.global_position
	var cursor_proxy = render_service.create_cursor_proxy(valid_items, anchor_item)
	coordinator.start_drag(zone, valid_items, anchor_item, drag_offset, cursor_proxy)
	for item in valid_items:
		item.visible = false
	zone._emit_drag_started(valid_items, zone)
	refresh()

func _sanitize_drag_items(items: Array[ZoneItemControl], anchor_item: ZoneItemControl = null) -> Array[ZoneItemControl]:
	var valid_items: Array[ZoneItemControl] = []
	var requested: Dictionary = {}
	for item in items:
		if is_instance_valid(item):
			requested[item.get_instance_id()] = item
	if is_instance_valid(anchor_item):
		requested[anchor_item.get_instance_id()] = anchor_item
	if requested.is_empty():
		return valid_items
	for item in store.items:
		if is_instance_valid(item) and requested.has(item.get_instance_id()):
			valid_items.append(item)
	return valid_items

func _resolve_drag_anchor(requested_anchor_item: ZoneItemControl, items: Array[ZoneItemControl]) -> ZoneItemControl:
	if is_instance_valid(requested_anchor_item) and requested_anchor_item in items:
		return requested_anchor_item
	for item in items:
		if is_instance_valid(item):
			return item
	return null

func _evaluate_drag_start(anchor_item: ZoneItemControl, candidate_items: Array[ZoneItemControl]):
	var policy = context.get_transfer_policy()
	var selected_items = candidate_items.duplicate()
	var decision = policy.evaluate_drag_start(context, anchor_item, selected_items) if policy != null else ZoneDragStartDecisionScript.new(true, "", selected_items)
	if decision == null:
		decision = ZoneDragStartDecisionScript.new(true, "", selected_items)
	var resolved_items = _sanitize_drag_items(decision.items, anchor_item)
	if decision.allowed and resolved_items.is_empty():
		return ZoneDragStartDecisionScript.new(false, "No draggable items remain.", [anchor_item])
	var reported_items = resolved_items
	if not decision.allowed and reported_items.is_empty():
		reported_items = [anchor_item]
	return ZoneDragStartDecisionScript.new(decision.allowed, decision.reason, reported_items)

func finalize_drag_session(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = zone._get_drag_coordinator(false)
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
		success = source_zone._get_transfer_service()._transfer_items_to(zone, session.items, decision.resolved_target, request.global_position, source_zone, decision, session.anchor_item)
	if success:
		_cleanup_drag_session(session, true, false)
	else:
		_cleanup_drag_session(session, true, true)
	return success

func cancel_drag(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = zone._get_drag_coordinator(false)
		active_session = coordinator.get_session() if coordinator != null else null
	if active_session == null:
		return
	active_session.prune_invalid_items()
	_cleanup_drag_session(active_session, true, true)

func get_display_state(style: Resource) -> Dictionary:
	return render_service.get_display_state(style)

func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	return store.build_transfer_snapshots(moving_items, drop_position, anchor_item)

func resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	return store.resolve_programmatic_transfer_global_position(moving_items)

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	store.set_transfer_handoff(item, snapshot)

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
			return clampi(target.slot, 0, store.items.size())
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
	zone._emit_drop_rejected(session.items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone._emit_drop_rejected(session.items, source_zone, zone, reason)

func emit_drop_rejected_items(items: Array[ZoneItemControl], source_zone: Zone, reason: String) -> void:
	zone._emit_drop_rejected(items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone._emit_drop_rejected(items, source_zone, zone, reason)

func _cleanup_drag_session(session: ZoneDragSession, refresh_involved: bool, emit_layout_changed: bool) -> void:
	_drag_session_cleanup.cleanup_drag_session(session, refresh_involved, emit_layout_changed)

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
	return _evaluator.make_transfer_request(target_zone, source_zone, items, placement_target, global_position)

func _evaluate_drop_request(request: ZoneTransferRequest) -> ZoneTransferDecision:
	return _evaluator.evaluate_drop_request(request)

func resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	return _evaluator.resolve_drop_decision(request)
