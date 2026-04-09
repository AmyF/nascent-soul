class_name ZoneTransferService extends RefCounted

var context: ZoneContext
var zone: Zone
var store: ZoneStore

var input_service: ZoneInputService = null
var render_service: ZoneRenderService = null
var targeting_service: ZoneTargetingService = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone
	store = context.store

func bind_services(p_input_service: ZoneInputService, p_render_service: ZoneRenderService, p_targeting_service: ZoneTargetingService) -> void:
	input_service = p_input_service
	render_service = p_render_service
	targeting_service = p_targeting_service

func process(_delta: float) -> void:
	if zone.get_items_root() == null:
		return
	render_service.prune_display_state()
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		var should_refresh = false
		if context.get_space_model() is ZoneLinearSpaceModel and store.container_order_needs_sync(zone.get_items_root(), render_service.ghost_instance):
			store.sync_container_order(zone.get_items_root(), render_service.ghost_instance)
			should_refresh = true
			zone.layout_changed.emit()
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
	store.sync_container_order(items_root, render_service.ghost_instance)
	zone.item_added.emit(item, target_index)
	refresh()
	zone.layout_changed.emit()
	return true

func remove_item(item: ZoneItemControl) -> bool:
	if not store.has_item(item):
		return false
	var previous_index = store.find_item_index(item)
	var selection_changed = remove_item_from_state(item, false, true)
	var items_root = zone.get_items_root()
	if items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if previous_index >= 0:
		zone.item_removed.emit(item, previous_index)
	refresh()
	if selection_changed:
		zone.selection_changed.emit(context.selection_state.get_selected_items())
	zone.layout_changed.emit()
	return true

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
	var target_context = target_zone.get_context()
	var request = make_transfer_request(target_zone, zone, moving_items, target_context.transfer_service.resolve_transfer_target(moving_items, placement_target), request_position)
	var decision = target_zone.get_transfer_service().resolve_drop_decision(request)
	if not decision.allowed:
		target_zone.get_transfer_service().emit_drop_rejected_items(moving_items, zone, decision.reason)
		return false
	return _transfer_items_to(target_zone, moving_items, decision.resolved_target, request.global_position, zone, decision)

func clear_selection() -> void:
	input_service.clear_selection()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	input_service.select_item(item, additive)

func start_drag(items: Array[ZoneItemControl]) -> void:
	_start_drag_internal(items)

func start_drag_at(items: Array[ZoneItemControl], pointer_global_position: Vector2) -> void:
	_start_drag_internal(items, pointer_global_position)

func _start_drag_internal(items: Array[ZoneItemControl], pointer_global_position = null) -> void:
	if zone.get_items_root() == null or items.is_empty():
		return
	var valid_items: Array[ZoneItemControl] = []
	for item in store.items:
		if item in items and is_instance_valid(item):
			valid_items.append(item)
	if valid_items.is_empty():
		return
	input_service.clear_hover_for_items(valid_items, true)
	var primary_item = valid_items[0]
	var coordinator = zone.get_drag_coordinator()
	if coordinator == null:
		return
	var pointer_position = primary_item.get_global_mouse_position()
	if pointer_global_position is Vector2:
		pointer_position = pointer_global_position as Vector2
	var drag_offset = pointer_position - primary_item.global_position
	var cursor_proxy = render_service.create_cursor_proxy(primary_item)
	coordinator.start_drag(zone, valid_items, drag_offset, cursor_proxy)
	for item in valid_items:
		item.visible = false
	zone.drag_started.emit(valid_items, zone)
	refresh()

func finalize_drag_session(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = zone.get_drag_coordinator(false)
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
		success = source_zone.get_transfer_service()._transfer_items_to(zone, session.items, decision.resolved_target, request.global_position, source_zone, decision)
	if success:
		_cleanup_drag_session(session, true, false)
	else:
		_cleanup_drag_session(session, true, true)
	return success

func cancel_drag(session: ZoneDragSession = null) -> void:
	var active_session = session
	if active_session == null:
		var coordinator = zone.get_drag_coordinator(false)
		active_session = coordinator.get_session() if coordinator != null else null
	if active_session == null:
		return
	active_session.prune_invalid_items()
	_cleanup_drag_session(active_session, true, true)

func get_display_state(style: Resource) -> Dictionary:
	return render_service.get_display_state(style)

func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null) -> Dictionary:
	return store.build_transfer_snapshots(moving_items, drop_position)

func resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	return store.resolve_programmatic_transfer_global_position(moving_items)

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	store.set_transfer_handoff(item, snapshot)

func remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	var selection_changed = false
	var item_is_valid = is_instance_valid(item)
	if item_is_valid and context.selection_state.hovered_item == item and context.selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
	store.erase_item_reference(item)
	store.clear_item_target(item)
	store.clear_transfer_handoff(item)
	if item_is_valid:
		input_service.unregister_item(item)
	var items_root = zone.get_items_root()
	if item_is_valid and remove_from_container and items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if clear_visuals:
		_clear_item_visual_state(item, true)
	if context.selection_state.prune(store.items):
		selection_changed = true
	return selection_changed

func _clear_item_visual_state(item, reset_transform: bool) -> void:
	if not is_instance_valid(item):
		return
	if item is ZoneItemControl:
		(item as ZoneItemControl).apply_zone_visual_state(ZoneItemVisualState.new())
	if reset_transform:
		item.scale = Vector2.ONE
		item.rotation = 0.0
		item.z_index = 0

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
	var moving_items: Array[ZoneItemControl] = []
	var original_indices: Dictionary = {}
	for item in store.items:
		if item in items_to_move:
			original_indices[item] = store.find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var resolved_target = resolve_transfer_target(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(store.find_item_index(moving_items[0]), resolved_target)
	for item in moving_items:
		store.erase_item_reference(item)
	target_index = clampi(target_index, 0, store.items.size())
	for offset in range(moving_items.size()):
		store.items.insert(target_index + offset, moving_items[offset])
	for item in moving_items:
		store.set_item_target(item, _resolve_reordered_target(resolved_target, target_index + moving_items.find(item)))
		item.visible = true
	store.sync_container_order(zone.get_items_root(), render_service.ghost_instance)
	for item in moving_items:
		var to_index = store.find_item_index(item)
		var from_index = original_indices[item]
		if from_index != to_index:
			zone.item_reordered.emit(item, from_index, to_index)
	refresh()
	zone.layout_changed.emit()
	return true

func _transfer_items_to(target_zone: Zone, items_to_move: Array[ZoneItemControl], placement_target: ZonePlacementTarget, drop_position = null, source_zone_override: Zone = null, decision: ZoneTransferDecision = null) -> bool:
	if target_zone == null or target_zone.get_items_root() == null:
		return false
	var source_zone = source_zone_override if source_zone_override != null else zone
	var moving_items: Array[ZoneItemControl] = []
	var original_indices: Dictionary = {}
	var removed_indices: Dictionary = {}
	for item in store.items:
		if item in items_to_move:
			original_indices[item] = store.find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var transfer_snapshots = build_transfer_snapshots(moving_items, drop_position)
	var selection_changed = false
	var target_transfer = target_zone.get_transfer_service()
	var target_context = target_zone.get_context()
	var resolved_decision = decision if decision != null else ZoneTransferDecision.new(true, "", target_transfer.resolve_transfer_target(moving_items, placement_target))
	var final_target = target_transfer.resolve_transfer_target(moving_items, resolved_decision.resolved_target)
	if final_target == null or not final_target.is_valid():
		final_target = target_transfer.resolve_transfer_target(moving_items, null)
	if final_target == null or not final_target.is_valid():
		target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Invalid drop target.")
		return false
	var original_targets: Dictionary = {}
	for item in moving_items:
		original_targets[item] = store.get_item_target(context, item)
	for item in moving_items:
		selection_changed = remove_item_from_state(item, false, false) or selection_changed
		_clear_item_visual_state(item, false)
		var from_index = original_indices.get(item, -1)
		if from_index >= 0:
			removed_indices[item] = from_index
	if resolved_decision.transfer_mode == ZoneTransferDecision.TransferMode.SPAWN_PIECE:
		var spawned_items = _build_spawned_items(target_context, moving_items, resolved_decision, final_target)
		if spawned_items.is_empty():
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "No spawn item could be created.")
			for item in moving_items:
				if is_instance_valid(item):
					item.visible = true
			rebuild_items_from_root()
			input_service.sync_item_bindings()
			refresh()
			target_transfer.rebuild_items_from_root()
			target_zone.get_input_service().sync_item_bindings()
			target_zone.refresh()
			return false
		var spawned_snapshots: Dictionary = {}
		for index in range(min(spawned_items.size(), moving_items.size())):
			spawned_snapshots[spawned_items[index]] = transfer_snapshots.get(moving_items[index], {})
		var spawned_inserted = target_transfer._insert_transferred_items(spawned_items, final_target, spawned_snapshots)
		if not spawned_inserted:
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Failed to insert spawned items.")
			_restore_failed_transfer(moving_items, original_targets)
			return false
		for removed_item in moving_items:
			if removed_indices.has(removed_item):
				zone.item_removed.emit(removed_item, removed_indices[removed_item])
		for source_item in moving_items:
			if is_instance_valid(source_item):
				var items_root = zone.get_items_root()
				if items_root != null and source_item.get_parent() == items_root:
					items_root.remove_child(source_item)
				source_item.queue_free()
		_emit_item_transferred(source_zone, target_zone, spawned_items)
	else:
		var inserted = target_transfer._insert_transferred_items(moving_items, final_target, transfer_snapshots)
		if inserted:
			for item in moving_items:
				if not target_context.has_item(item):
					inserted = false
					break
		if not inserted:
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Failed to insert items.")
			_restore_failed_transfer(moving_items, original_targets)
			return false
		for removed_item in moving_items:
			if removed_indices.has(removed_item):
				zone.item_removed.emit(removed_item, removed_indices[removed_item])
		for item in moving_items:
			item.visible = true
		_emit_item_transferred(source_zone, target_zone, moving_items)
	store.sync_container_order(zone.get_items_root(), render_service.ghost_instance)
	refresh()
	if selection_changed:
		zone.selection_changed.emit(context.selection_state.get_selected_items())
	zone.layout_changed.emit()
	if source_zone != target_zone:
		target_zone.layout_changed.emit()
		target_zone.refresh()
	return true

func _build_spawned_items(target_context: ZoneContext, source_items: Array[ZoneItemControl], decision: ZoneTransferDecision, placement_target: ZonePlacementTarget) -> Array[ZoneItemControl]:
	var spawned_items: Array[ZoneItemControl] = []
	for source_item in source_items:
		var spawned = _instantiate_spawn_item(target_context, source_item, decision, placement_target)
		if spawned == null:
			continue
		spawned_items.append(spawned)
	return spawned_items

func _instantiate_spawn_item(target_context: ZoneContext, source_item: ZoneItemControl, decision: ZoneTransferDecision, placement_target: ZonePlacementTarget) -> ZoneItemControl:
	if decision.spawn_scene != null:
		var created = decision.spawn_scene.instantiate()
		if created is ZoneItemControl:
			source_item.configure_zone_spawned_item(created as ZoneItemControl, target_context, placement_target)
			return created as ZoneItemControl
	var from_item = source_item.create_zone_spawned_item(target_context, decision, placement_target)
	if from_item != null:
		source_item.configure_zone_spawned_item(from_item, target_context, placement_target)
		return from_item
	return null

func _insert_transferred_items(moving_items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, transfer_snapshots: Dictionary) -> bool:
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	var resolved_target = resolve_transfer_target(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(store.items.size(), resolved_target)
	for offset in range(moving_items.size()):
		var item = moving_items[offset]
		if store.contains_item_reference(item):
			store.erase_item_reference(item)
		if item.get_parent() != items_root:
			if item.get_parent() != null:
				item.reparent(items_root, true)
			else:
				items_root.add_child(item)
		set_transfer_handoff(item, transfer_snapshots.get(item, {}))
		item.visible = true
		input_service.register_item(item)
		store.items.insert(target_index + offset, item)
		store.set_item_target(item, _resolve_reordered_target(resolved_target, target_index + offset))
		zone.item_added.emit(item, target_index + offset)
	store.sync_container_order(items_root, render_service.ghost_instance)
	refresh()
	return true

func _restore_failed_transfer(moving_items: Array[ZoneItemControl], original_targets: Dictionary) -> void:
	var source_root = zone.get_items_root()
	for item in moving_items:
		if not is_instance_valid(item):
			continue
		item.visible = true
		if source_root != null and item.get_parent() != source_root:
			if item.get_parent() != null:
				item.reparent(source_root, true)
			else:
				source_root.add_child(item)
		var original_target = original_targets.get(item, ZonePlacementTarget.invalid())
		if original_target is ZonePlacementTarget and (original_target as ZonePlacementTarget).is_valid():
			store.set_item_target(item, original_target)
	rebuild_items_from_root()
	input_service.sync_item_bindings()
	refresh()

func _emit_item_transferred(source_zone: Zone, target_zone: Zone, moving_items: Array[ZoneItemControl]) -> void:
	for item in moving_items:
		var target = target_zone.get_item_target(item)
		target_zone.item_transferred.emit(item, source_zone, target_zone, target)
		if source_zone != target_zone:
			source_zone.item_transferred.emit(item, source_zone, target_zone, target)

func _emit_drop_rejected(session: ZoneDragSession, reason: String) -> void:
	var source_zone = session.source_zone as Zone
	zone.drop_rejected.emit(session.items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone.drop_rejected.emit(session.items, source_zone, zone, reason)

func emit_drop_rejected_items(items: Array[ZoneItemControl], source_zone: Zone, reason: String) -> void:
	zone.drop_rejected.emit(items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone.drop_rejected.emit(items, source_zone, zone, reason)

func _cleanup_drag_session(session: ZoneDragSession, refresh_involved: bool, emit_layout_changed: bool) -> void:
	session.prune_invalid_items()
	var involved_zones = _collect_involved_drag_zones(session)
	for involved_zone in involved_zones:
		involved_zone.get_render_service().clear_preview_for_session(session)
		involved_zone.get_input_service().clear_hover_for_items(session.items, false)
		involved_zone.get_input_service().reset_press_state_for_item()
	for item in session.items:
		if is_instance_valid(item):
			item.visible = true
	var coordinator = _resolve_drag_coordinator(involved_zones)
	if coordinator != null:
		coordinator.clear_session()
	if not refresh_involved:
		return
	for involved_zone in involved_zones:
		involved_zone.refresh()
		if emit_layout_changed:
			involved_zone.layout_changed.emit()

func _collect_involved_drag_zones(session: ZoneDragSession) -> Array[Zone]:
	var involved_zones: Array[Zone] = []
	_append_unique_zone(involved_zones, zone)
	if session.source_zone is Zone:
		_append_unique_zone(involved_zones, session.source_zone as Zone)
	if session.hover_zone is Zone:
		_append_unique_zone(involved_zones, session.hover_zone as Zone)
	return involved_zones

func _resolve_drag_coordinator(involved_zones: Array[Zone]) -> ZoneDragCoordinator:
	for involved_zone in involved_zones:
		var coordinator = involved_zone.get_drag_coordinator(false)
		if coordinator != null:
			return coordinator
	return zone.get_drag_coordinator(false)

func _append_unique_zone(zones: Array[Zone], candidate: Zone) -> void:
	if candidate == null or candidate in zones:
		return
	zones.append(candidate)

func _get_drop_global_position(session: ZoneDragSession) -> Vector2:
	if is_instance_valid(session.cursor_proxy):
		return session.cursor_proxy.global_position
	return Vector2.ZERO

func make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	return ZoneTransferRequest.new(target_zone, source_zone, items, placement_target, global_position)

func _evaluate_drop_request(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	var space_model = context.get_space_model()
	if space_model == null:
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	if not space_model.is_target_valid(context, target):
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	var decision = ZoneTransferDecision.new(true, "", target)
	var transfer_policy = context.get_transfer_policy()
	if transfer_policy != null:
		decision = transfer_policy.evaluate_transfer(context, request)
	if decision == null:
		return ZoneTransferDecision.new(true, "", target)
	return decision

func resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var decision = _evaluate_drop_request(request)
	if decision == null:
		decision = ZoneTransferDecision.new(true, "", request.placement_target)
	if (decision.resolved_target == null or not decision.resolved_target.is_valid()) and request.placement_target != null and request.placement_target.is_valid():
		return ZoneTransferDecision.new(decision.allowed, decision.reason, request.placement_target, decision.transfer_mode, decision.spawn_scene, decision.metadata)
	return decision
