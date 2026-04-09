class_name ZoneRuntime extends RefCounted

var zone: Zone
var item_state: ZoneItemState
var display_runtime: ZoneDisplayRuntime
var interaction_runtime: ZoneInteractionRuntime
var targeting_runtime: ZoneTargetingRuntime

var selection_state: ZoneSelectionState:
	get:
		return interaction_runtime.selection_state
	set(value):
		interaction_runtime.selection_state = value

func _init(p_zone: Zone) -> void:
	zone = p_zone
	item_state = ZoneItemState.new(self)
	display_runtime = ZoneDisplayRuntime.new(self)
	interaction_runtime = ZoneInteractionRuntime.new(self)
	targeting_runtime = ZoneTargetingRuntime.new(self)

func bind() -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		_disconnect_items_root(item_state.bound_items_root)
		_disconnect_zone_input()
		item_state.bound_items_root = null
		item_state.clear_runtime_items(false)
		display_runtime.clear_preview_internal()
		item_state.clear_transfer_handoffs()
		display_runtime.reset_hover_feedback_tracking()
		targeting_runtime.clear_targeting_feedback(false)
		return
	if item_state.bound_items_root != null and item_state.bound_items_root != items_root:
		_disconnect_items_root(item_state.bound_items_root)
	display_runtime.clear_preview_internal()
	display_runtime.reset_hover_feedback_tracking()
	targeting_runtime.clear_targeting_feedback(false)
	interaction_runtime.ensure_long_press_timer()
	if item_state.bound_items_root != items_root:
		var entered_callable = Callable(self, "_on_items_root_child_entered")
		if not items_root.child_entered_tree.is_connected(entered_callable):
			items_root.child_entered_tree.connect(entered_callable)
		var exiting_callable = Callable(self, "_on_items_root_child_exiting")
		if not items_root.child_exiting_tree.is_connected(exiting_callable):
			items_root.child_exiting_tree.connect(exiting_callable)
		item_state.bound_items_root = items_root
	var gui_input_callable = Callable(self, "_on_zone_gui_input")
	if not zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.connect(gui_input_callable)
	item_state.rebuild_items_from_root()

func unbind() -> void:
	_disconnect_items_root(item_state.bound_items_root)
	_disconnect_zone_input()
	item_state.bound_items_root = null
	item_state.clear_runtime_items(false)
	clear_display_state()
	display_runtime.clear_preview_internal()
	item_state.clear_transfer_handoffs()
	display_runtime.reset_hover_feedback_tracking()
	targeting_runtime.clear_targeting_feedback(false)
	interaction_runtime.cleanup()

func process(_delta: float) -> void:
	if item_state.bound_items_root != zone.get_items_root():
		bind()
	if zone.get_items_root() == null:
		return
	display_runtime.prune_display_state()
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		var should_refresh = false
		if item_state.container_order_needs_sync():
			item_state.sync_container_order()
			should_refresh = true
			zone.layout_changed.emit()
		if display_runtime.clear_hover_feedback([]):
			should_refresh = true
		if should_refresh:
			refresh()
		return
	if session.prune_invalid_items() and session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return
	display_runtime.update_hover_preview(session)

func refresh() -> void:
	display_runtime.refresh()

func get_items() -> Array[Control]:
	return item_state.get_items()

func get_item_count() -> int:
	return item_state.get_item_count()

func has_item(item: Control) -> bool:
	return item_state.has_item(item)

func get_item_target(item: Control) -> ZonePlacementTarget:
	return item_state.get_item_target(item)

func get_items_at_target(target: ZonePlacementTarget) -> Array[Control]:
	return item_state.get_items_at_target(target)

func get_item_at_global_position(global_position: Vector2) -> Control:
	return item_state.get_item_at_global_position(global_position)

func resolve_target_position(target: ZonePlacementTarget, container_size: Vector2, item_size: Vector2) -> Vector2:
	var space_model = zone.get_space_model_resource()
	if space_model == null:
		return Vector2.ZERO
	return space_model.resolve_item_position(zone, self, target, container_size, item_size)

func resolve_target_size(target: ZonePlacementTarget) -> Vector2:
	var space_model = zone.get_space_model_resource()
	if space_model == null:
		return Vector2.ZERO
	return space_model.resolve_target_size(zone, self, target)

func resolve_target_anchor(target: ZonePlacementTarget) -> Vector2:
	var space_model = zone.get_space_model_resource()
	if space_model == null:
		return zone.global_position + zone.size * 0.5
	return space_model.resolve_target_anchor(zone, self, target)

func begin_targeting(item: Control, intent: ZoneTargetingIntent = null) -> bool:
	return targeting_runtime.begin_targeting(item, intent)

func cancel_targeting() -> void:
	targeting_runtime.cancel_targeting()

func _set_item_target(item: Control, target: ZonePlacementTarget) -> void:
	item_state.set_item_target(item, target)

func _clear_item_target(item) -> void:
	item_state.clear_item_target(item)

func _targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	return item_state.targets_match(a, b)

func _resolve_transfer_target_for_api(items: Array[Control], placement_target: ZonePlacementTarget) -> ZonePlacementTarget:
	var space_model = zone.get_space_model_resource()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	if placement_target != null and placement_target.is_valid():
		return space_model.normalize_target(zone, self, placement_target, items)
	var reference_item = items[0] if not items.is_empty() else null
	return space_model.resolve_add_target(zone, self, reference_item, null)

func _resolve_insert_target(item: Control, placement_target: ZonePlacementTarget, index_hint: int) -> ZonePlacementTarget:
	var space_model = zone.get_space_model_resource()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	var single_item: Array[Control] = []
	if is_instance_valid(item):
		single_item.append(item)
	if placement_target != null and placement_target.is_valid():
		return space_model.normalize_target(zone, self, placement_target, single_item)
	return space_model.resolve_add_target(zone, self, item, index_hint)

func _resolve_linear_insert_index(index_hint: int, target: ZonePlacementTarget) -> int:
	if zone.get_space_model_resource() is ZoneLinearSpaceModel:
		if target != null and target.is_linear():
			return clampi(target.slot, 0, item_state.items.size())
		return clampi(index_hint, 0, item_state.items.size())
	return clampi(index_hint, 0, item_state.items.size())

func _resolve_reordered_target(base_target: ZonePlacementTarget, linear_index: int) -> ZonePlacementTarget:
	if zone.get_space_model_resource() is ZoneLinearSpaceModel:
		return ZonePlacementTarget.linear(linear_index)
	return base_target.duplicate_target() if base_target != null else ZonePlacementTarget.invalid()

func _build_spawned_items(source_items: Array[Control], decision: ZoneTransferDecision, placement_target: ZonePlacementTarget, source_zone: Zone) -> Array[Control]:
	var spawned_items: Array[Control] = []
	for source_item in source_items:
		var spawned = _instantiate_spawn_item(source_item, decision)
		if spawned == null:
			continue
		if spawned.has_method("apply_transfer_source"):
			spawned.call("apply_transfer_source", source_item, source_zone, zone, placement_target)
		if source_item.has_method("configure_spawned_piece"):
			source_item.call("configure_spawned_piece", spawned, placement_target)
		spawned_items.append(spawned)
	return spawned_items

func _instantiate_spawn_item(source_item: Control, decision: ZoneTransferDecision) -> Control:
	if decision.spawn_scene != null:
		var created = decision.spawn_scene.instantiate()
		if created is Control:
			return created as Control
	if source_item.has_method("create_zone_piece"):
		var from_item = source_item.call("create_zone_piece")
		if from_item is Control:
			return from_item as Control
	if source_item.has_meta("zone_piece_scene"):
		var piece_scene = source_item.get_meta("zone_piece_scene")
		if piece_scene is PackedScene:
			var instance = piece_scene.instantiate()
			if instance is Control:
				return instance as Control
	return null

func add_item(item: Control, placement_target: ZonePlacementTarget = null) -> bool:
	return insert_item(item, item_state.items.size(), placement_target)

func insert_item(item: Control, index: int, placement_target: ZonePlacementTarget = null) -> bool:
	var items_root = zone.get_items_root()
	if not is_instance_valid(item) or items_root == null:
		return false
	var resolved_target = _resolve_insert_target(item, placement_target, index)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	if _contains_item_reference(item):
		return reorder_item(item, resolved_target)
	if item.get_parent() != items_root:
		if item.get_parent() != null:
			item.reparent(items_root, true)
		else:
			items_root.add_child(item)
	_register_item(item)
	var target_index = _resolve_linear_insert_index(index, resolved_target)
	if _contains_item_reference(item):
		_erase_item_reference(item)
		target_index = clampi(target_index, 0, item_state.items.size())
	item_state.items.insert(target_index, item)
	_set_item_target(item, resolved_target)
	item.visible = true
	_sync_container_order()
	zone.item_added.emit(item, target_index)
	refresh()
	zone.layout_changed.emit()
	return true

func remove_item(item: Control) -> bool:
	if not has_item(item):
		return false
	var previous_index = _find_item_index(item)
	var selection_changed = _remove_item_from_state(item, false, true)
	var items_root = zone.get_items_root()
	if items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if previous_index >= 0:
		zone.item_removed.emit(item, previous_index)
	refresh()
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	zone.layout_changed.emit()
	return true

func move_item_to(item: Control, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	if target_zone == null or not has_item(item):
		return false
	if target_zone == zone:
		return reorder_item(item, placement_target)
	var moving_items: Array[Control] = [item]
	var requested_target = target_zone.get_runtime()._resolve_transfer_target_for_api(moving_items, placement_target)
	var request_position = _resolve_programmatic_transfer_global_position(moving_items)
	var request = _make_transfer_request(target_zone, zone, moving_items, requested_target, request_position)
	var decision = target_zone.get_runtime()._resolve_drop_decision(request)
	if not decision.allowed:
		target_zone.get_runtime()._emit_drop_rejected_items(moving_items, zone, decision.reason)
		return false
	return _transfer_items_to(target_zone, moving_items, decision.resolved_target, request.global_position, zone, decision)

func transfer_items(items: Array[Control], target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	if target_zone == null or items.is_empty():
		return false
	var moving_items: Array[Control] = []
	for item in item_state.items:
		if _array_contains_valid_control(items, item):
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	if target_zone == zone:
		return _reorder_items(moving_items, _resolve_transfer_target_for_api(moving_items, placement_target))
	var request_position = _resolve_programmatic_transfer_global_position(moving_items)
	var request = _make_transfer_request(target_zone, zone, moving_items, target_zone.get_runtime()._resolve_transfer_target_for_api(moving_items, placement_target), request_position)
	var decision = target_zone.get_runtime()._resolve_drop_decision(request)
	if not decision.allowed:
		target_zone.get_runtime()._emit_drop_rejected_items(moving_items, zone, decision.reason)
		return false
	return _transfer_items_to(target_zone, moving_items, decision.resolved_target, request.global_position, zone, decision)

func reorder_item(item: Control, placement_target: ZonePlacementTarget = null) -> bool:
	if not has_item(item):
		return false
	var moving_items: Array[Control] = [item]
	return _reorder_items(moving_items, _resolve_transfer_target_for_api(moving_items, placement_target))

func clear_selection() -> void:
	interaction_runtime.clear_selection()

func select_item(item: Control, additive: bool = false) -> void:
	interaction_runtime.select_item(item, additive)

func start_drag(items: Array[Control]) -> void:
	_start_drag_internal(items)

func _start_drag_internal(items: Array[Control], pointer_global_position = null) -> void:
	if zone.get_items_root() == null or items.is_empty():
		return
	var valid_items: Array[Control] = []
	for item in item_state.items:
		if item in items and is_instance_valid(item):
			valid_items.append(item)
	if valid_items.is_empty():
		return
	_clear_hover_for_items(valid_items, true)
	var primary_item = valid_items[0]
	var coordinator = zone.get_drag_coordinator()
	if coordinator == null:
		return
	var pointer_position = primary_item.get_global_mouse_position()
	if pointer_global_position is Vector2:
		pointer_position = pointer_global_position as Vector2
	var drag_offset = pointer_position - primary_item.global_position
	var cursor_proxy = _create_cursor_proxy(primary_item)
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
		target_zone.get_runtime().perform_drop(active_session)
	else:
		cancel_drag(active_session)

func perform_drop(session: ZoneDragSession) -> bool:
	session.prune_invalid_items()
	if session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return false
	var requested_target = session.requested_target if session.requested_target != null and session.requested_target.is_valid() else session.preview_target
	var request = _make_transfer_request(zone, session.source_zone, session.items, requested_target, _get_drop_global_position(session))
	var decision = _resolve_drop_decision(request)
	if not decision.allowed:
		_emit_drop_rejected(session, decision.reason)
		_cleanup_drag_session(session, true, true)
		return false
	var source_zone = session.source_zone as Zone
	var success = false
	if source_zone == zone:
		success = _reorder_items(session.items, decision.resolved_target)
	elif source_zone != null:
		success = source_zone.get_runtime()._transfer_items_to(zone, session.items, decision.resolved_target, request.global_position, source_zone, decision)
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

func clear_preview() -> void:
	display_runtime.clear_preview()

func clear_display_state() -> void:
	display_runtime.clear_display_state()

func get_display_state(style: Resource) -> Dictionary:
	return display_runtime.get_display_state(style)

func consume_transfer_handoff(item: Control) -> Dictionary:
	return item_state.consume_transfer_handoff(item)

func resolve_item_size(item: Control) -> Vector2:
	return display_runtime.resolve_item_size(item)

func _prune_display_state() -> void:
	display_runtime.prune_display_state()

func _ensure_long_press_timer() -> void:
	interaction_runtime.ensure_long_press_timer()

func _rebuild_items_from_root() -> void:
	item_state.rebuild_items_from_root()

func _register_item(item: Control) -> void:
	item_state.register_item(item)

func _unregister_item(item) -> void:
	item_state.unregister_item(item)

func _on_items_root_child_entered(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _on_items_root_child_exiting(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _on_item_gui_input(event: InputEvent, item: Control) -> void:
	interaction_runtime.on_item_gui_input(event, item)

func _on_zone_gui_input(event: InputEvent) -> void:
	interaction_runtime.on_zone_gui_input(event)

func _on_item_mouse_entered(item: Control) -> void:
	interaction_runtime.on_item_mouse_entered(item)

func _on_item_mouse_exited(item: Control) -> void:
	interaction_runtime.on_item_mouse_exited(item)

func _handle_mouse_button(event: InputEventMouseButton, item: Control) -> void:
	interaction_runtime.handle_mouse_button(event, item)

func _handle_mouse_motion(event: InputEventMouseMotion, item: Control) -> void:
	interaction_runtime.handle_mouse_motion(event, item)

func _apply_click_selection(item: Control, event: InputEventMouseButton) -> void:
	interaction_runtime.apply_click_selection(item, event)

func _handle_keyboard_navigation(event: InputEvent, interaction: ZoneInteraction) -> bool:
	return interaction_runtime.handle_keyboard_navigation(event, interaction)

func _matches_action(event: InputEvent, action_name: StringName) -> bool:
	return interaction_runtime.matches_action(event, action_name)

func _move_keyboard_selection(direction: int, wrap_navigation: bool) -> void:
	interaction_runtime.move_keyboard_selection(direction, wrap_navigation)

func _get_keyboard_active_item() -> Control:
	return interaction_runtime.get_keyboard_active_item()

func _resolve_drag_items(item: Control) -> Array[Control]:
	return interaction_runtime.resolve_drag_items(item)

func _stop_long_press_timer() -> void:
	interaction_runtime.stop_long_press_timer()

func _on_long_press_timeout() -> void:
	interaction_runtime.on_long_press_timeout()

func _handle_targeting_input(event: InputEvent) -> bool:
	return targeting_runtime.handle_targeting_input(event)

func update_targeting_session(session: ZoneTargetingSession, global_position: Vector2) -> void:
	targeting_runtime.update_targeting_session(session, global_position)

func finalize_targeting_session(session: ZoneTargetingSession) -> void:
	targeting_runtime.finalize_targeting_session(session)

func cancel_targeting_session(session: ZoneTargetingSession, emit_signal: bool) -> void:
	targeting_runtime.cancel_targeting_session(session, emit_signal)

func _start_targeting_internal(item: Control, intent: ZoneTargetingIntent, entry_mode: StringName, pointer_global_position: Vector2) -> bool:
	return targeting_runtime.start_targeting_internal(item, intent, entry_mode, pointer_global_position)

func _resolve_targeting_intent(item: Control, entry_mode: StringName) -> ZoneTargetingIntent:
	return targeting_runtime.resolve_targeting_intent(item, entry_mode)

func _resolve_item_target_anchor_global(item: Control) -> Vector2:
	return targeting_runtime.resolve_item_target_anchor_global(item)

func _resolve_target_candidate(intent: ZoneTargetingIntent, global_position: Vector2) -> ZoneTargetCandidate:
	return targeting_runtime.resolve_target_candidate(intent, global_position)

func _resolve_target_decision(source_item: Control, intent: ZoneTargetingIntent, candidate: ZoneTargetCandidate, global_position: Vector2) -> ZoneTargetDecision:
	return targeting_runtime.resolve_target_decision(source_item, intent, candidate, global_position)

func _resolve_target_candidate_from_decision(decision: ZoneTargetDecision, fallback: ZoneTargetCandidate) -> ZoneTargetCandidate:
	return targeting_runtime.resolve_target_candidate_from_decision(decision, fallback)

func _collect_targeting_zones() -> Array[Zone]:
	return targeting_runtime.collect_targeting_zones()

func _build_item_candidate(target_zone: Zone, item: Control, global_position: Vector2) -> ZoneTargetCandidate:
	return targeting_runtime.build_item_candidate(target_zone, item, global_position)

func _build_placement_candidate(target_zone: Zone, placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTargetCandidate:
	return targeting_runtime.build_placement_candidate(target_zone, placement_target, global_position)

func _build_candidate_metadata(item: Control, placement_target: ZonePlacementTarget) -> Dictionary:
	return targeting_runtime.build_candidate_metadata(item, placement_target)

func _extract_node_metadata(node: Object) -> Dictionary:
	return targeting_runtime.extract_node_metadata(node)

func _apply_targeting_feedback(session: ZoneTargetingSession, candidate: ZoneTargetCandidate, decision: ZoneTargetDecision) -> void:
	targeting_runtime.apply_targeting_feedback(session, candidate, decision)

func _clear_targeting_feedback(emit_clear_signals: bool, source_item: Control = null) -> void:
	targeting_runtime.clear_targeting_feedback(emit_clear_signals, source_item)

func _set_target_candidate_visual(item: Control, active: bool, allowed: bool) -> void:
	targeting_runtime.set_target_candidate_visual(item, active, allowed)

func _target_candidates_match(a: ZoneTargetCandidate, b: ZoneTargetCandidate) -> bool:
	return targeting_runtime.target_candidates_match(a, b)

func _target_decisions_match(a: ZoneTargetDecision, b: ZoneTargetDecision) -> bool:
	return targeting_runtime.target_decisions_match(a, b)

func _update_hover_preview(session: ZoneDragSession) -> void:
	display_runtime.update_hover_preview(session)

func _get_layout_items(session: ZoneDragSession) -> Array[Control]:
	return display_runtime.get_layout_items(session)

func _should_render_ghost_for_session(session: ZoneDragSession) -> bool:
	return display_runtime.should_render_ghost_for_session(session)

func _create_ghost(source_item: Control) -> void:
	display_runtime.create_ghost(source_item)

func _create_cursor_proxy(source_item: Control) -> Control:
	return display_runtime.create_cursor_proxy(source_item)

func _create_factory_ghost(source_item: Control) -> Control:
	var factory = zone.get_drag_visual_factory_resource()
	if factory == null:
		return null
	var created = factory.create_ghost(zone, self, source_item)
	if created is Control and created != source_item and is_instance_valid(created):
		return created as Control
	return null

func _create_factory_proxy(source_item: Control) -> Control:
	var factory = zone.get_drag_visual_factory_resource()
	if factory == null:
		return null
	var created = factory.create_drag_proxy(zone, self, source_item)
	if created is Control and created != source_item and is_instance_valid(created):
		return created as Control
	return null

func _clear_preview_internal() -> void:
	display_runtime.clear_preview_internal()

func _reorder_items(items_to_move: Array[Control], placement_target: ZonePlacementTarget) -> bool:
	var moving_items: Array[Control] = []
	var original_indices: Dictionary = {}
	var removed_indices: Dictionary = {}
	for item in item_state.items:
		if _array_contains_valid_control(items_to_move, item):
			original_indices[item] = _find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var resolved_target = _resolve_transfer_target_for_api(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(_find_item_index(moving_items[0]), resolved_target)
	for item in moving_items:
		_erase_item_reference(item)
	target_index = clampi(target_index, 0, item_state.items.size())
	for offset in range(moving_items.size()):
		item_state.items.insert(target_index + offset, moving_items[offset])
	for item in moving_items:
		_set_item_target(item, _resolve_reordered_target(resolved_target, target_index + moving_items.find(item)))
		item.visible = true
	_sync_container_order()
	for item in moving_items:
		var to_index = _find_item_index(item)
		var from_index = original_indices[item]
		if from_index != to_index:
			zone.item_reordered.emit(item, from_index, to_index)
	refresh()
	zone.layout_changed.emit()
	return true

func _transfer_items_to(target_zone: Zone, items_to_move: Array[Control], placement_target: ZonePlacementTarget, drop_position = null, source_zone_override: Zone = null, decision: ZoneTransferDecision = null) -> bool:
	if target_zone == null or target_zone.get_items_root() == null:
		return false
	var source_zone = source_zone_override if source_zone_override != null else zone
	var moving_items: Array[Control] = []
	var original_indices: Dictionary = {}
	var removed_indices: Dictionary = {}
	for item in item_state.items:
		if _array_contains_valid_control(items_to_move, item):
			original_indices[item] = _find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var transfer_snapshots = _build_transfer_snapshots(moving_items, drop_position)
	var selection_changed = false
	var target_runtime = target_zone.get_runtime()
	var resolved_decision = decision if decision != null else ZoneTransferDecision.new(true, "", target_runtime._resolve_transfer_target_for_api(moving_items, placement_target))
	var final_target = target_runtime._resolve_transfer_target_for_api(moving_items, resolved_decision.resolved_target)
	if final_target == null or not final_target.is_valid():
		final_target = target_runtime._resolve_transfer_target_for_api(moving_items, null)
	if final_target == null or not final_target.is_valid():
		target_zone.get_runtime()._emit_drop_rejected_items(moving_items, source_zone, "Invalid drop target.")
		return false
	var original_targets: Dictionary = {}
	for item in moving_items:
		original_targets[item] = item_state.get_item_target(item)
	for item in moving_items:
		selection_changed = _remove_item_from_state(item, false, false) or selection_changed
		_clear_item_visual_state(item, false)
		var from_index = original_indices.get(item, -1)
		if from_index >= 0:
			removed_indices[item] = from_index
	if resolved_decision.transfer_mode == ZoneTransferDecision.TransferMode.SPAWN_PIECE:
		var spawned_items = _build_spawned_items(moving_items, resolved_decision, final_target, source_zone)
		if spawned_items.is_empty():
			target_zone.get_runtime()._emit_drop_rejected_items(moving_items, source_zone, "No spawn item could be created.")
			for item in moving_items:
				if is_instance_valid(item):
					item.visible = true
			item_state.rebuild_items_from_root()
			refresh()
			target_runtime.item_state.rebuild_items_from_root()
			target_zone.refresh()
			return false
		var spawned_snapshots: Dictionary = {}
		for index in range(min(spawned_items.size(), moving_items.size())):
			spawned_snapshots[spawned_items[index]] = transfer_snapshots.get(moving_items[index], {})
		var spawned_inserted = target_runtime._insert_transferred_items(spawned_items, final_target, spawned_snapshots)
		if not spawned_inserted:
			target_zone.get_runtime()._emit_drop_rejected_items(moving_items, source_zone, "Failed to insert spawned items.")
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
		var inserted = target_runtime._insert_transferred_items(moving_items, final_target, transfer_snapshots)
		if inserted:
			for item in moving_items:
				if not target_runtime.item_state.contains_item_reference(item):
					inserted = false
					break
		if not inserted:
			target_zone.get_runtime()._emit_drop_rejected_items(moving_items, source_zone, "Failed to insert items.")
			_restore_failed_transfer(moving_items, original_targets)
			return false
		for removed_item in moving_items:
			if removed_indices.has(removed_item):
				zone.item_removed.emit(removed_item, removed_indices[removed_item])
		for item in moving_items:
			item.visible = true
		_emit_item_transferred(source_zone, target_zone, moving_items)
	_sync_container_order()
	refresh()
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	zone.layout_changed.emit()
	if source_zone != target_zone:
		target_zone.layout_changed.emit()
		target_zone.refresh()
	return true

func _insert_transferred_items(moving_items: Array[Control], placement_target: ZonePlacementTarget, transfer_snapshots: Dictionary) -> bool:
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	var resolved_target = _resolve_transfer_target_for_api(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(item_state.items.size(), resolved_target)
	for offset in range(moving_items.size()):
		var item = moving_items[offset]
		if _contains_item_reference(item):
			_erase_item_reference(item)
		if item.get_parent() != items_root:
			if item.get_parent() != null:
				item.reparent(items_root, true)
			else:
				items_root.add_child(item)
		_set_transfer_handoff(item, transfer_snapshots.get(item, {}))
		item.visible = true
		_register_item(item)
		item_state.items.insert(target_index + offset, item)
		_set_item_target(item, _resolve_reordered_target(resolved_target, target_index + offset))
		zone.item_added.emit(item, target_index + offset)
	_sync_container_order()
	refresh()
	return true

func _restore_failed_transfer(moving_items: Array[Control], original_targets: Dictionary) -> void:
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
			_set_item_target(item, original_target)
	item_state.rebuild_items_from_root()
	refresh()

func _sync_container_order() -> void:
	item_state.sync_container_order()

func _emit_item_transferred(source_zone: Zone, target_zone: Zone, moving_items: Array[Control]) -> void:
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

func _emit_drop_rejected_items(items: Array[Control], source_zone: Zone, reason: String) -> void:
	zone.drop_rejected.emit(items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone.drop_rejected.emit(items, source_zone, zone, reason)

func _cleanup_drag_session(session: ZoneDragSession, refresh_involved: bool, emit_layout_changed: bool) -> void:
	session.prune_invalid_items()
	var involved_zones = _collect_involved_drag_zones(session)
	for involved_zone in involved_zones:
		involved_zone.get_runtime()._clear_preview_for_session(session)
		involved_zone.get_runtime()._clear_hover_for_items(session.items, false)
		involved_zone.get_runtime()._reset_press_state_for_item()
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

func _clear_runtime_items(emit_selection_changed: bool) -> void:
	item_state.clear_runtime_items(emit_selection_changed)

func _remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	var selection_changed = false
	var item_is_valid = is_instance_valid(item)
	if item_is_valid and selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
	_erase_item_reference(item)
	_clear_item_target(item)
	_clear_transfer_handoff(item)
	if item in item_state.item_bindings:
		_unregister_item(item)
	var items_root = zone.get_items_root()
	if item_is_valid and remove_from_container and items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if clear_visuals:
		_clear_item_visual_state(item, true)
	if selection_state.prune(item_state.items):
		selection_changed = true
	return selection_changed

func _clear_item_visual_state(item, reset_transform: bool) -> void:
	if not is_instance_valid(item):
		return
	if item.has_method("set_hovered_visual"):
		item.call("set_hovered_visual", false)
	if item.has_method("set_selected_visual"):
		item.call("set_selected_visual", false)
	if reset_transform:
		item.scale = Vector2.ONE
		item.rotation = 0.0
		item.z_index = 0

func _build_transfer_snapshots(moving_items: Array[Control], drop_position = null) -> Dictionary:
	return item_state.build_transfer_snapshots(moving_items, drop_position)

func _resolve_programmatic_transfer_global_position(moving_items: Array[Control]):
	return item_state.resolve_programmatic_transfer_global_position(moving_items)

func _snapshot_item_visual_state(item: Control) -> Dictionary:
	return item_state.snapshot_item_visual_state(item)

func _set_transfer_handoff(item: Control, snapshot: Dictionary) -> void:
	item_state.set_transfer_handoff(item, snapshot)

func _clear_transfer_handoff(item) -> void:
	item_state.clear_transfer_handoff(item)

func _clear_transfer_handoffs() -> void:
	item_state.clear_transfer_handoffs()

func _clear_hover_for_items(items: Array[Control], emit_signal: bool) -> void:
	interaction_runtime.clear_hover_for_items(items, emit_signal)

func _reset_press_state_for_item(item = null) -> void:
	interaction_runtime.reset_press_state_for_item(item)

func _get_drop_global_position(session: ZoneDragSession) -> Vector2:
	if is_instance_valid(session.cursor_proxy):
		return session.cursor_proxy.global_position
	return Vector2.ZERO

func _disconnect_items_root(items_root: Control) -> void:
	if items_root == null:
		return
	var entered_callable = Callable(self, "_on_items_root_child_entered")
	if items_root.child_entered_tree.is_connected(entered_callable):
		items_root.child_entered_tree.disconnect(entered_callable)
	var exiting_callable = Callable(self, "_on_items_root_child_exiting")
	if items_root.child_exiting_tree.is_connected(exiting_callable):
		items_root.child_exiting_tree.disconnect(exiting_callable)

func _disconnect_zone_input() -> void:
	var gui_input_callable = Callable(self, "_on_zone_gui_input")
	if zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.disconnect(gui_input_callable)

func _handle_items_root_structure_changed() -> void:
	if zone == null or not is_instance_valid(zone):
		return
	_rebuild_items_from_root()
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator == null or coordinator.get_session() == null:
		refresh()
		zone.layout_changed.emit()

func _container_order_needs_sync() -> bool:
	return item_state.container_order_needs_sync()

func _erase_item_reference(item) -> void:
	item_state.erase_item_reference(item)

func _contains_item_reference(item: Control) -> bool:
	return item_state.contains_item_reference(item)

func _find_item_index(item: Control) -> int:
	return item_state.find_item_index(item)

func _array_contains_valid_control(items: Array[Control], candidate: Control) -> bool:
	return item_state.array_contains_valid_control(items, candidate)

func _clear_background_interaction() -> void:
	interaction_runtime.clear_background_interaction()

func _find_item_at_global_position(global_position: Vector2) -> Control:
	return item_state.get_item_at_global_position(global_position)

func _clear_preview_for_session(session: ZoneDragSession) -> void:
	display_runtime.clear_preview_for_session(session)

func _evaluate_drop_request(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	if not zone.get_space_model_resource().is_target_valid(zone, self, target):
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	var decision = ZoneTransferDecision.new(true, "", target)
	var transfer_policy = zone.get_transfer_policy_resource()
	if transfer_policy != null:
		decision = transfer_policy.evaluate_transfer(request)
	if decision == null:
		return ZoneTransferDecision.new(true, "", target)
	return decision

func _make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[Control], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	return ZoneTransferRequest.new(target_zone, source_zone, items, placement_target, global_position)

func _resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var decision = _evaluate_drop_request(request)
	if decision == null:
		decision = ZoneTransferDecision.new(true, "", request.placement_target)
	if (decision.resolved_target == null or not decision.resolved_target.is_valid()) and request.placement_target != null and request.placement_target.is_valid():
		return ZoneTransferDecision.new(decision.allowed, decision.reason, request.placement_target, decision.transfer_mode, decision.spawn_scene, decision.metadata)
	return decision

func _apply_hover_feedback(items: Array[Control], decision: ZoneTransferDecision, preview_target, preview_source: Control) -> bool:
	return display_runtime.apply_hover_feedback(items, decision, preview_target, preview_source)

func _clear_hover_feedback(items: Array[Control]) -> bool:
	return display_runtime.clear_hover_feedback(items)

func _has_hover_state_changed(active: bool, decision: ZoneTransferDecision) -> bool:
	return display_runtime.has_hover_state_changed(active, decision)

func _make_clear_hover_decision() -> ZoneTransferDecision:
	return display_runtime.make_clear_hover_decision()

func _reset_hover_feedback_tracking() -> void:
	display_runtime.reset_hover_feedback_tracking()
