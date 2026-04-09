class_name ZoneRuntime extends RefCounted

var zone: Zone
var selection_state := ZoneSelectionState.new()

var _items: Array[Control] = []
var _item_targets: Dictionary = {}
var _ghost_instance: Control = null
var _item_bindings: Dictionary = {}
var _display_state: Dictionary = {}
var _transfer_handoffs: Dictionary = {}
var _pressed_item: Control = null
var _pressed_position: Vector2 = Vector2.ZERO
var _is_pressed: bool = false
var _has_dragged: bool = false
var _long_press_item: Control = null
var _long_press_timer: Timer = null
var _bound_items_root: Control = null
var _hover_active: bool = false
var _hover_allowed: bool = false
var _hover_reason: String = ""
var _hover_target: ZonePlacementTarget = null
var _hover_preview_target: ZonePlacementTarget = null

func _init(p_zone: Zone) -> void:
	zone = p_zone

func bind() -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		_disconnect_items_root(_bound_items_root)
		_disconnect_zone_input()
		_bound_items_root = null
		_clear_runtime_items(false)
		_clear_preview_internal()
		_clear_transfer_handoffs()
		_reset_hover_feedback_tracking()
		return
	if _bound_items_root != null and _bound_items_root != items_root:
		_disconnect_items_root(_bound_items_root)
	_clear_preview_internal()
	_reset_hover_feedback_tracking()
	_ensure_long_press_timer()
	if _bound_items_root != items_root:
		var entered_callable = Callable(self, "_on_items_root_child_entered")
		if not items_root.child_entered_tree.is_connected(entered_callable):
			items_root.child_entered_tree.connect(entered_callable)
		var exiting_callable = Callable(self, "_on_items_root_child_exiting")
		if not items_root.child_exiting_tree.is_connected(exiting_callable):
			items_root.child_exiting_tree.connect(exiting_callable)
		_bound_items_root = items_root
	var gui_input_callable = Callable(self, "_on_zone_gui_input")
	if not zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.connect(gui_input_callable)
	_rebuild_items_from_root()

func unbind() -> void:
	_disconnect_items_root(_bound_items_root)
	_disconnect_zone_input()
	_bound_items_root = null
	_clear_runtime_items(false)
	clear_display_state()
	_clear_preview_internal()
	_clear_transfer_handoffs()
	_reset_hover_feedback_tracking()
	if is_instance_valid(_long_press_timer):
		_long_press_timer.queue_free()
	_long_press_timer = null

func process(_delta: float) -> void:
	if _bound_items_root != zone.get_items_root():
		bind()
	if zone.get_items_root() == null:
		return
	_prune_display_state()
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		var should_refresh = false
		if _container_order_needs_sync():
			_sync_container_order()
			should_refresh = true
			zone.layout_changed.emit()
		if _clear_hover_feedback([]):
			should_refresh = true
		if should_refresh:
			refresh()
		return
	if session.prune_invalid_items() and session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return
	_update_hover_preview(session)

func refresh() -> void:
	var layout_policy = zone.get_layout_policy_resource()
	var display_style = zone.get_display_style_resource()
	if zone.get_items_root() == null or layout_policy == null or display_style == null:
		return
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	var layout_items := _get_layout_items(session)
	var sort_policy = zone.get_sort_policy_resource()
	if sort_policy != null and session == null and zone.get_space_model_resource() is ZoneLinearSpaceModel:
		layout_items = sort_policy.sort_items(layout_items)
	var ghost_hint = null
	if _should_render_ghost_for_session(session):
		ghost_hint = zone.get_space_model_resource().resolve_layout_hint(session.preview_target)
	var placements = layout_policy.calculate(layout_items, zone.size, _ghost_instance, ghost_hint, self)
	display_style.apply(zone, self, placements)

func get_items() -> Array[Control]:
	return _items.duplicate()

func get_item_count() -> int:
	return _items.size()

func has_item(item: Control) -> bool:
	return _contains_item_reference(item)

func get_item_target(item: Control) -> ZonePlacementTarget:
	if not is_instance_valid(item):
		return ZonePlacementTarget.invalid()
	if _item_targets.has(item):
		var existing = _item_targets[item]
		if existing is ZonePlacementTarget:
			return (existing as ZonePlacementTarget).duplicate_target()
	var fallback_index = _find_item_index(item)
	return zone.get_space_model_resource().resolve_render_target(zone, self, item, fallback_index)

func get_items_at_target(target: ZonePlacementTarget) -> Array[Control]:
	var matched: Array[Control] = []
	if target == null or not target.is_valid():
		return matched
	for item in _items:
		if not is_instance_valid(item):
			continue
		var item_target = get_item_target(item)
		if item_target.matches(target):
			matched.append(item)
	return matched

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

func _set_item_target(item: Control, target: ZonePlacementTarget) -> void:
	if not is_instance_valid(item) or target == null:
		return
	_item_targets[item] = target.duplicate_target()
	item.set_meta("zone_placement_target", target.duplicate_target())

func _clear_item_target(item) -> void:
	if item == null:
		return
	_item_targets.erase(item)
	if is_instance_valid(item) and item.has_meta("zone_placement_target"):
		item.remove_meta("zone_placement_target")

func _targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.matches(b)

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
			return clampi(target.slot, 0, _items.size())
		return clampi(index_hint, 0, _items.size())
	return clampi(index_hint, 0, _items.size())

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
	return insert_item(item, _items.size(), placement_target)

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
		target_index = clampi(target_index, 0, _items.size())
	_items.insert(target_index, item)
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
	for item in _items:
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
	if selection_state.clear_selection():
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func select_item(item: Control, additive: bool = false) -> void:
	if not has_item(item):
		return
	var changed = false
	var interaction = zone.get_interaction_config()
	if additive and interaction != null and interaction.multi_select_enabled:
		changed = selection_state.toggle_item(item)
	else:
		changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func start_drag(items: Array[Control]) -> void:
	_start_drag_internal(items)

func _start_drag_internal(items: Array[Control], pointer_global_position = null) -> void:
	if zone.get_items_root() == null or items.is_empty():
		return
	var valid_items: Array[Control] = []
	for item in _items:
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
	if _clear_hover_feedback([]):
		refresh()

func clear_display_state() -> void:
	for state in _display_state.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		for item in active_tweens.keys():
			if active_tweens[item] != null:
				active_tweens[item].kill()
	_display_state.clear()
	_clear_transfer_handoffs()

func get_display_state(style: Resource) -> Dictionary:
	var key = style.get_instance_id()
	if not _display_state.has(key):
		_display_state[key] = {
			"active_tweens": {},
			"target_cache": {}
		}
	return _display_state[key]

func consume_transfer_handoff(item: Control) -> Dictionary:
	if not is_instance_valid(item) or not _transfer_handoffs.has(item):
		return {}
	var handoff: Dictionary = _transfer_handoffs[item]
	_transfer_handoffs.erase(item)
	return handoff.duplicate(true)

func resolve_item_size(item: Control) -> Vector2:
	var layout_policy = zone.get_layout_policy_resource()
	if layout_policy != null:
		return layout_policy.resolve_item_size(item)
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)

func _prune_display_state() -> void:
	for state in _display_state.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		var target_cache: Dictionary = state.get("target_cache", {})
		var stale_items: Array = []
		for item in active_tweens.keys():
			var tween = active_tweens[item]
			if not is_instance_valid(item) or tween == null or not tween.is_valid() or not tween.is_running():
				stale_items.append(item)
		for item in target_cache.keys():
			if not is_instance_valid(item) and item not in stale_items:
				stale_items.append(item)
		for item in stale_items:
			active_tweens.erase(item)
			if not is_instance_valid(item):
				target_cache.erase(item)

func _ensure_long_press_timer() -> void:
	if is_instance_valid(_long_press_timer):
		return
	_long_press_timer = Timer.new()
	_long_press_timer.name = "__NascentSoulLongPressTimer"
	_long_press_timer.one_shot = true
	zone.add_child(_long_press_timer)
	var timeout_callable = Callable(self, "_on_long_press_timeout")
	if not _long_press_timer.timeout.is_connected(timeout_callable):
		_long_press_timer.timeout.connect(timeout_callable)

func _rebuild_items_from_root() -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		_clear_runtime_items(true)
		return
	var container_items: Array[Control] = []
	for child in items_root.get_children():
		if child is Control and child != _ghost_instance:
			container_items.append(child as Control)
	var selection_changed = false
	var existing_items := _items.duplicate()
	for item in existing_items:
		if not is_instance_valid(item) or item.get_parent() != items_root or item not in container_items:
			selection_changed = _remove_item_from_state(item, false, true) or selection_changed
	for i in range(container_items.size()):
		var item = container_items[i]
		_register_item(item)
		var restored_target = item.get_meta("zone_placement_target") if item.has_meta("zone_placement_target") else null
		if restored_target != null and restored_target is ZonePlacementTarget:
			_set_item_target(item, zone.get_space_model_resource().normalize_target(zone, self, restored_target as ZonePlacementTarget, [item]))
		elif not _item_targets.has(item):
			_set_item_target(item, zone.get_space_model_resource().resolve_add_target(zone, self, item, i))
		if _contains_item_reference(item):
			continue
		var insert_at = min(i, _items.size())
		_items.insert(insert_at, item)
	for item in _item_bindings.keys():
		if item not in _items:
			_unregister_item(item)
	if selection_state.prune(_items):
		selection_changed = true
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	_sync_container_order()

func _register_item(item: Control) -> void:
	if _item_bindings.has(item):
		return
	if item.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	var gui_input_callable = Callable(self, "_on_item_gui_input").bind(item)
	var mouse_entered_callable = Callable(self, "_on_item_mouse_entered").bind(item)
	var mouse_exited_callable = Callable(self, "_on_item_mouse_exited").bind(item)
	if not item.gui_input.is_connected(gui_input_callable):
		item.gui_input.connect(gui_input_callable)
	if not item.mouse_entered.is_connected(mouse_entered_callable):
		item.mouse_entered.connect(mouse_entered_callable)
	if not item.mouse_exited.is_connected(mouse_exited_callable):
		item.mouse_exited.connect(mouse_exited_callable)
	_item_bindings[item] = {
		"gui_input": gui_input_callable,
		"mouse_entered": mouse_entered_callable,
		"mouse_exited": mouse_exited_callable
	}

func _unregister_item(item) -> void:
	if not _item_bindings.has(item):
		return
	var bindings: Dictionary = _item_bindings[item]
	_reset_press_state_for_item(item)
	if is_instance_valid(item):
		if item.gui_input.is_connected(bindings["gui_input"]):
			item.gui_input.disconnect(bindings["gui_input"])
		if item.mouse_entered.is_connected(bindings["mouse_entered"]):
			item.mouse_entered.disconnect(bindings["mouse_entered"])
		if item.mouse_exited.is_connected(bindings["mouse_exited"]):
			item.mouse_exited.disconnect(bindings["mouse_exited"])
	_item_bindings.erase(item)

func _on_items_root_child_entered(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _on_items_root_child_exiting(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _on_item_gui_input(event: InputEvent, item: Control) -> void:
	if zone.get_interaction_config() == null:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton, item)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion, item)

func _on_zone_gui_input(event: InputEvent) -> void:
	var interaction = zone.get_interaction_config()
	if interaction == null:
		return
	if _handle_keyboard_navigation(event, interaction):
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
		return
	if not interaction.clear_selection_on_background_click:
		return
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	if _find_item_at_global_position(mouse_event.global_position) != null:
		return
	_clear_background_interaction()

func _on_item_mouse_entered(item: Control) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	if selection_state.set_hovered(item):
		zone.item_hover_entered.emit(item)
		refresh()

func _on_item_mouse_exited(item: Control) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	if selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
		refresh()

func _handle_mouse_button(event: InputEventMouseButton, item: Control) -> void:
	var interaction = zone.get_interaction_config()
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			zone.grab_focus()
			_is_pressed = true
			_has_dragged = false
			_pressed_item = item
			_pressed_position = event.global_position
			_long_press_item = item
			if interaction != null and interaction.long_press_enabled and is_instance_valid(_long_press_timer):
				_long_press_timer.wait_time = interaction.long_press_time
				_long_press_timer.start()
		else:
			_stop_long_press_timer()
			var should_activate = _is_pressed and is_instance_valid(_pressed_item) and _pressed_item == item and not _has_dragged
			_is_pressed = false
			_pressed_item = null
			if should_activate:
				_apply_click_selection(item, event)
				if event.double_click:
					zone.item_double_clicked.emit(item)
				else:
					zone.item_clicked.emit(item)
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		zone.item_right_clicked.emit(item)

func _handle_mouse_motion(event: InputEventMouseMotion, item: Control) -> void:
	if not _is_pressed or _has_dragged or not is_instance_valid(_pressed_item) or _pressed_item != item:
		return
	var interaction = zone.get_interaction_config()
	if interaction == null or not interaction.drag_enabled:
		return
	if event.global_position.distance_to(_pressed_position) <= interaction.drag_threshold:
		return
	_has_dragged = true
	_is_pressed = false
	_stop_long_press_timer()
	var drag_items = _resolve_drag_items(item)
	_start_drag_internal(drag_items, event.global_position)

func _apply_click_selection(item: Control, event: InputEventMouseButton) -> void:
	var interaction = zone.get_interaction_config()
	if interaction == null or not interaction.select_on_click:
		return
	var additive = interaction.multi_select_enabled and interaction.ctrl_toggles_selection and event.ctrl_pressed
	var changed = false
	if interaction.multi_select_enabled and interaction.shift_range_select_enabled and event.shift_pressed:
		changed = selection_state.select_range(_items, item, additive)
	else:
		if additive:
			changed = selection_state.toggle_item(item)
		else:
			changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func _handle_keyboard_navigation(event: InputEvent, interaction: ZoneInteraction) -> bool:
	if not interaction.keyboard_navigation_enabled or not zone.has_focus():
		return false
	if _matches_action(event, interaction.next_item_action):
		_move_keyboard_selection(1, interaction.wrap_navigation)
		return true
	if _matches_action(event, interaction.previous_item_action):
		_move_keyboard_selection(-1, interaction.wrap_navigation)
		return true
	if _matches_action(event, interaction.activate_item_action):
		var active_item = _get_keyboard_active_item()
		if active_item != null:
			zone.item_clicked.emit(active_item)
		return true
	if _matches_action(event, interaction.clear_selection_action):
		_clear_background_interaction()
		return true
	return false

func _matches_action(event: InputEvent, action_name: StringName) -> bool:
	if action_name == StringName():
		return false
	if event is InputEventAction:
		var action_event := event as InputEventAction
		return action_event.action == action_name and action_event.pressed
	if not InputMap.has_action(action_name):
		return false
	return event.is_action_pressed(action_name, false, true)

func _move_keyboard_selection(direction: int, wrap_navigation: bool) -> void:
	if _items.is_empty():
		return
	var current_item = _get_keyboard_active_item()
	var current_index = _find_item_index(current_item) if current_item != null else -1
	if current_index == -1:
		current_index = 0 if direction >= 0 else _items.size() - 1
	else:
		current_index += direction
		if wrap_navigation:
			current_index = wrapi(current_index, 0, _items.size())
		else:
			current_index = clampi(current_index, 0, _items.size() - 1)
	var next_item = _items[current_index]
	if not is_instance_valid(next_item):
		return
	if selection_state.select_single(next_item):
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func _get_keyboard_active_item() -> Control:
	if is_instance_valid(selection_state.anchor_item):
		return selection_state.anchor_item
	var selected = selection_state.get_selected_items()
	if not selected.is_empty():
		var last_item = selected[selected.size() - 1]
		if is_instance_valid(last_item):
			return last_item
	return selection_state.hovered_item if is_instance_valid(selection_state.hovered_item) else null

func _resolve_drag_items(item: Control) -> Array[Control]:
	if selection_state.is_selected(item) and selection_state.get_selected_items().size() > 1:
		var ordered_selection: Array[Control] = []
		for candidate in _items:
			if selection_state.is_selected(candidate):
				ordered_selection.append(candidate)
		return ordered_selection
	return [item]

func _stop_long_press_timer() -> void:
	if is_instance_valid(_long_press_timer):
		_long_press_timer.stop()
	_long_press_item = null

func _on_long_press_timeout() -> void:
	if not _is_pressed or _has_dragged or not is_instance_valid(_long_press_item):
		return
	var item = _long_press_item
	_is_pressed = false
	_pressed_item = null
	_long_press_item = null
	zone.item_long_pressed.emit(item)

func _update_hover_preview(session: ZoneDragSession) -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	var global_mouse = zone.get_viewport().get_mouse_position()
	var is_hovering = zone.get_global_rect().has_point(global_mouse)
	if not is_hovering:
		if session.hover_zone == zone:
			session.hover_zone = null
			session.requested_target = ZonePlacementTarget.invalid()
			session.preview_target = ZonePlacementTarget.invalid()
		if _clear_hover_feedback(session.items):
			refresh()
		return
	var visible_items = _get_layout_items(session)
	var requested_target = zone.get_space_model_resource().resolve_hover_target(zone, self, visible_items, global_mouse, zone.get_local_mouse_position())
	requested_target = zone.get_space_model_resource().normalize_target(zone, self, requested_target, session.items)
	var request = _make_transfer_request(zone, session.source_zone, session.items, requested_target, global_mouse)
	var decision = _resolve_drop_decision(request)
	var preview_target = decision.resolved_target if decision.allowed else ZonePlacementTarget.invalid()
	session.hover_zone = zone
	session.requested_target = requested_target
	session.preview_target = preview_target
	if _apply_hover_feedback(session.items, decision, preview_target, session.items[0] if not session.items.is_empty() else null):
		refresh()

func _get_layout_items(session: ZoneDragSession) -> Array[Control]:
	var layout_items: Array[Control] = []
	for item in _items:
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			continue
		if session != null and item in session.items and not item.visible:
			continue
		if item.visible:
			layout_items.append(item)
	return layout_items

func _should_render_ghost_for_session(session: ZoneDragSession) -> bool:
	if session == null or session.hover_zone != zone or session.preview_target == null or not session.preview_target.is_valid() or not is_instance_valid(_ghost_instance):
		return false
	var items_root = zone.get_items_root()
	for item in session.items:
		if not is_instance_valid(item):
			continue
		if item.visible and item.get_parent() == items_root:
			return false
	return true

func _create_ghost(source_item: Control) -> void:
	var preview_root = zone.get_preview_root()
	if preview_root == null or not is_instance_valid(source_item):
		return
	var ghost = _create_factory_ghost(source_item)
	if ghost == null and source_item.has_method("create_zone_ghost"):
		var created = source_item.call("create_zone_ghost")
		if created is Control:
			ghost = created as Control
	elif ghost == null and source_item.has_meta("zone_ghost_scene"):
		var ghost_scene = source_item.get_meta("zone_ghost_scene")
		if ghost_scene is PackedScene:
			ghost = ghost_scene.instantiate() as Control
	if ghost == null:
		var fallback := ColorRect.new()
		fallback.color = Color(1, 1, 1, 0.18)
		fallback.custom_minimum_size = resolve_item_size(source_item)
		fallback.size = resolve_item_size(source_item)
		ghost = fallback
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ghost.get_parent() != preview_root:
		if ghost.get_parent() != null:
			ghost.reparent(preview_root, false)
		else:
			preview_root.add_child(ghost)
	_ghost_instance = ghost

func _create_cursor_proxy(source_item: Control) -> Control:
	var factory_proxy = _create_factory_proxy(source_item)
	if factory_proxy != null:
		return factory_proxy
	if source_item.has_method("create_drag_proxy"):
		var created = source_item.call("create_drag_proxy")
		if created is Control:
			return created as Control
	var proxy = source_item.duplicate(0)
	if proxy is Control:
		var control_proxy := proxy as Control
		control_proxy.modulate.a = 0.9
		control_proxy.global_position = source_item.global_position
		return control_proxy
	var fallback := ColorRect.new()
	fallback.color = Color(1, 1, 1, 0.7)
	fallback.custom_minimum_size = resolve_item_size(source_item)
	fallback.size = resolve_item_size(source_item)
	fallback.global_position = source_item.global_position
	return fallback

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
	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
	_ghost_instance = null

func _reorder_items(items_to_move: Array[Control], placement_target: ZonePlacementTarget) -> bool:
	var moving_items: Array[Control] = []
	var original_indices: Dictionary = {}
	for item in _items:
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
	target_index = clampi(target_index, 0, _items.size())
	for offset in range(moving_items.size()):
		_items.insert(target_index + offset, moving_items[offset])
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
	for item in _items:
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
		return false
	for item in moving_items:
		selection_changed = _remove_item_from_state(item, false, false) or selection_changed
		_clear_item_visual_state(item, false)
		var from_index = original_indices.get(item, -1)
		if from_index >= 0:
			zone.item_removed.emit(item, from_index)
	if resolved_decision.transfer_mode == ZoneTransferDecision.TransferMode.SPAWN_PIECE:
		var spawned_items = _build_spawned_items(moving_items, resolved_decision, final_target, source_zone)
		var spawned_snapshots: Dictionary = {}
		for index in range(min(spawned_items.size(), moving_items.size())):
			spawned_snapshots[spawned_items[index]] = transfer_snapshots.get(moving_items[index], {})
		target_runtime._insert_transferred_items(spawned_items, final_target, spawned_snapshots)
		for source_item in moving_items:
			if is_instance_valid(source_item):
				var items_root = zone.get_items_root()
				if items_root != null and source_item.get_parent() == items_root:
					items_root.remove_child(source_item)
				source_item.queue_free()
		_emit_item_transferred(source_zone, target_zone, spawned_items)
	else:
		target_runtime._insert_transferred_items(moving_items, final_target, transfer_snapshots)
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

func _insert_transferred_items(moving_items: Array[Control], placement_target: ZonePlacementTarget, transfer_snapshots: Dictionary) -> void:
	var items_root = zone.get_items_root()
	var resolved_target = _resolve_transfer_target_for_api(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return
	var target_index = _resolve_linear_insert_index(_items.size(), resolved_target)
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
		_items.insert(target_index + offset, item)
		_set_item_target(item, _resolve_reordered_target(resolved_target, target_index + offset))
		zone.item_added.emit(item, target_index + offset)
	_sync_container_order()
	refresh()

func _sync_container_order() -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	for index in range(_items.size()):
		var item = _items[index]
		if is_instance_valid(item) and item.get_parent() == items_root:
			items_root.move_child(item, index)

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
	var selection_changed = selection_state.clear()
	var existing_items := _items.duplicate()
	for item in existing_items:
		_remove_item_from_state(item, false, true)
	_items.clear()
	_item_targets.clear()
	_clear_transfer_handoffs()
	if emit_selection_changed and selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())

func _remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	var selection_changed = false
	var item_is_valid = is_instance_valid(item)
	if item_is_valid and selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
	_erase_item_reference(item)
	_clear_item_target(item)
	_clear_transfer_handoff(item)
	if item in _item_bindings:
		_unregister_item(item)
	var items_root = zone.get_items_root()
	if item_is_valid and remove_from_container and items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if clear_visuals:
		_clear_item_visual_state(item, true)
	if selection_state.prune(_items):
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
	var snapshots: Dictionary = {}
	if moving_items.is_empty():
		return snapshots
	for item in moving_items:
		if is_instance_valid(item):
			snapshots[item] = _snapshot_item_visual_state(item)
	if drop_position is not Vector2:
		return snapshots
	var resolved_drop_position: Vector2 = drop_position
	var primary_item = moving_items[0]
	var primary_snapshot: Dictionary = snapshots.get(primary_item, {})
	var primary_global: Vector2 = primary_snapshot.get("global_position", resolved_drop_position)
	for item in moving_items:
		var snapshot: Dictionary = snapshots.get(item, {}).duplicate(true)
		var source_global: Vector2 = snapshot.get("global_position", resolved_drop_position)
		snapshot["global_position"] = resolved_drop_position + (source_global - primary_global)
		snapshots[item] = snapshot
	return snapshots

func _resolve_programmatic_transfer_global_position(moving_items: Array[Control]):
	for item in moving_items:
		if is_instance_valid(item):
			return item.global_position
	return null

func _snapshot_item_visual_state(item: Control) -> Dictionary:
	if not is_instance_valid(item):
		return {}
	return {
		"global_position": item.global_position,
		"rotation": item.rotation,
		"scale": item.scale
	}

func _set_transfer_handoff(item: Control, snapshot: Dictionary) -> void:
	if not is_instance_valid(item):
		return
	if snapshot.is_empty():
		_transfer_handoffs.erase(item)
		return
	_transfer_handoffs[item] = snapshot.duplicate(true)

func _clear_transfer_handoff(item) -> void:
	if item == null:
		return
	_transfer_handoffs.erase(item)

func _clear_transfer_handoffs() -> void:
	_transfer_handoffs.clear()

func _clear_hover_for_items(items: Array[Control], emit_signal: bool) -> void:
	var hovered_item = selection_state.hovered_item
	if hovered_item == null or not is_instance_valid(hovered_item):
		if hovered_item != null:
			selection_state.set_hovered(null)
		return
	var found = false
	for item in items:
		if is_instance_valid(item) and item == hovered_item:
			found = true
			break
	if not found:
		return
	if selection_state.set_hovered(null) and emit_signal:
		zone.item_hover_exited.emit(hovered_item)

func _reset_press_state_for_item(item = null) -> void:
	if item == null:
		_is_pressed = false
		_has_dragged = false
		_pressed_item = null
		_stop_long_press_timer()
		return
	if is_instance_valid(_pressed_item) and is_instance_valid(item) and _pressed_item == item:
		_is_pressed = false
		_has_dragged = false
		_pressed_item = null
	if _long_press_item == item or (item != null and not is_instance_valid(item) and not is_instance_valid(_long_press_item)):
		_stop_long_press_timer()

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
	_rebuild_items_from_root()
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator == null or coordinator.get_session() == null:
		refresh()
		zone.layout_changed.emit()

func _container_order_needs_sync() -> bool:
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	if zone.get_space_model_resource() is not ZoneLinearSpaceModel:
		return false
	var control_index = 0
	for child in items_root.get_children():
		if child is not Control or child == _ghost_instance:
			continue
		if control_index >= _items.size():
			return true
		if child != _items[control_index]:
			return true
		control_index += 1
	return control_index != _items.size()

func _erase_item_reference(item) -> void:
	if is_instance_valid(item):
		for index in range(_items.size() - 1, -1, -1):
			var existing_item = _items[index]
			if is_instance_valid(existing_item) and existing_item == item:
				_items.remove_at(index)
				_item_targets.erase(item)
				return
	else:
		for index in range(_items.size() - 1, -1, -1):
			if not is_instance_valid(_items[index]):
				_item_targets.erase(_items[index])
				_items.remove_at(index)

func _contains_item_reference(item: Control) -> bool:
	return _find_item_index(item) != -1

func _find_item_index(item: Control) -> int:
	if not is_instance_valid(item):
		return -1
	for index in range(_items.size()):
		var existing_item = _items[index]
		if is_instance_valid(existing_item) and existing_item == item:
			return index
	return -1

func _array_contains_valid_control(items: Array[Control], candidate: Control) -> bool:
	if not is_instance_valid(candidate):
		return false
	for item in items:
		if is_instance_valid(item) and item == candidate:
			return true
	return false

func _clear_background_interaction() -> void:
	var hovered_item = selection_state.hovered_item
	var hover_changed = selection_state.clear_hover()
	var selection_changed = selection_state.clear_selection()
	if hover_changed and is_instance_valid(hovered_item):
		zone.item_hover_exited.emit(hovered_item)
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	if hover_changed or selection_changed:
		refresh()

func _find_item_at_global_position(global_position: Vector2) -> Control:
	for index in range(_items.size() - 1, -1, -1):
		var item = _items[index]
		if not is_instance_valid(item) or not item.visible:
			continue
		if item.get_global_rect().has_point(global_position):
			return item
	return null

func _clear_preview_for_session(session: ZoneDragSession) -> void:
	var items = session.items if session != null else []
	var invalid_target = ZonePlacementTarget.invalid()
	var should_emit_preview_clear = _hover_preview_target != null and _hover_preview_target.is_valid()
	if session != null and session.hover_zone == zone and session.preview_target != null and session.preview_target.is_valid():
		should_emit_preview_clear = true
	if should_emit_preview_clear and (_hover_preview_target == null or not _hover_preview_target.is_valid()):
		zone.drop_preview_changed.emit(items, zone, invalid_target)
	if is_instance_valid(_ghost_instance):
		_clear_preview_internal()
	if _hover_active:
		zone.drop_hover_state_changed.emit(items, zone, _make_clear_hover_decision())
	_reset_hover_feedback_tracking()

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

func _make_drop_request(target_zone: Zone, source_zone: Node, items: Array[Control], requested_index: int, global_position: Vector2) -> ZoneTransferRequest:
	var target = ZonePlacementTarget.linear(requested_index, global_position) if requested_index >= 0 else ZonePlacementTarget.invalid()
	return _make_transfer_request(target_zone, source_zone, items, target, global_position)

func _resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var decision = _evaluate_drop_request(request)
	if decision == null:
		decision = ZoneTransferDecision.new(true, "", request.placement_target)
	if (decision.resolved_target == null or not decision.resolved_target.is_valid()) and request.placement_target != null and request.placement_target.is_valid():
		return ZoneTransferDecision.new(decision.allowed, decision.reason, request.placement_target, decision.transfer_mode, decision.spawn_scene, decision.metadata)
	return decision

func _apply_hover_feedback(items: Array[Control], decision: ZoneTransferDecision, preview_target, preview_source: Control) -> bool:
	var resolved_preview_target = preview_target
	if preview_target is int:
		resolved_preview_target = ZonePlacementTarget.linear(preview_target as int) if preview_target >= 0 else ZonePlacementTarget.invalid()
	var refresh_needed = false
	var has_preview = resolved_preview_target != null and resolved_preview_target.is_valid()
	if has_preview:
		if not is_instance_valid(_ghost_instance) and is_instance_valid(preview_source):
			_create_ghost(preview_source)
			refresh_needed = true
	elif is_instance_valid(_ghost_instance):
		_clear_preview_internal()
		refresh_needed = true
	if not _targets_match(_hover_preview_target, resolved_preview_target):
		zone.drop_preview_changed.emit(items, zone, resolved_preview_target if resolved_preview_target != null else ZonePlacementTarget.invalid())
		refresh_needed = true
	if _has_hover_state_changed(true, decision):
		zone.drop_hover_state_changed.emit(items, zone, decision)
	_hover_active = true
	_hover_allowed = decision.allowed
	_hover_reason = decision.reason
	_hover_target = decision.resolved_target.duplicate_target() if decision.resolved_target != null else ZonePlacementTarget.invalid()
	_hover_preview_target = resolved_preview_target.duplicate_target() if resolved_preview_target != null else ZonePlacementTarget.invalid()
	return refresh_needed

func _clear_hover_feedback(items: Array[Control]) -> bool:
	var refresh_needed = false
	if _hover_preview_target != null and _hover_preview_target.is_valid():
		zone.drop_preview_changed.emit(items, zone, ZonePlacementTarget.invalid())
		refresh_needed = true
	if is_instance_valid(_ghost_instance):
		_clear_preview_internal()
		refresh_needed = true
	if _hover_active:
		zone.drop_hover_state_changed.emit(items, zone, _make_clear_hover_decision())
	_reset_hover_feedback_tracking()
	return refresh_needed

func _has_hover_state_changed(active: bool, decision: ZoneTransferDecision) -> bool:
	if _hover_active != active:
		return true
	if not active:
		return false
	return _hover_allowed != decision.allowed \
		or _hover_reason != decision.reason \
		or not _targets_match(_hover_target, decision.resolved_target)

func _make_clear_hover_decision() -> ZoneTransferDecision:
	return ZoneTransferDecision.new(false, "", ZonePlacementTarget.invalid())

func _reset_hover_feedback_tracking() -> void:
	_hover_active = false
	_hover_allowed = false
	_hover_reason = ""
	_hover_target = ZonePlacementTarget.invalid()
	_hover_preview_target = ZonePlacementTarget.invalid()
