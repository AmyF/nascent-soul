class_name ZoneRuntime extends RefCounted

var zone: Zone
var selection_state := ZoneSelectionState.new()

var _items: Array[Control] = []
var _ghost_instance: Control = null
var _item_bindings: Dictionary = {}
var _display_state: Dictionary = {}
var _pressed_item: Control = null
var _pressed_position: Vector2 = Vector2.ZERO
var _is_pressed: bool = false
var _has_dragged: bool = false
var _long_press_item: Control = null
var _long_press_timer: Timer = null
var _bound_container: Control = null

func _init(p_zone: Zone) -> void:
	zone = p_zone

func bind() -> void:
	if zone.container == null:
		_disconnect_container(_bound_container)
		_bound_container = null
		_clear_runtime_items(false)
		_clear_preview_internal()
		return
	if _bound_container != null and _bound_container != zone.container:
		_disconnect_container(_bound_container)
	_clear_preview_internal()
	_ensure_long_press_timer()
	if _bound_container != zone.container:
		var entered_callable = Callable(self, "_on_container_child_entered")
		if not zone.container.child_entered_tree.is_connected(entered_callable):
			zone.container.child_entered_tree.connect(entered_callable)
		var exiting_callable = Callable(self, "_on_container_child_exiting")
		if not zone.container.child_exiting_tree.is_connected(exiting_callable):
			zone.container.child_exiting_tree.connect(exiting_callable)
		var gui_input_callable = Callable(self, "_on_container_gui_input")
		if not zone.container.gui_input.is_connected(gui_input_callable):
			zone.container.gui_input.connect(gui_input_callable)
		_bound_container = zone.container
	_rebuild_items_from_container()

func unbind() -> void:
	_disconnect_container(_bound_container)
	_bound_container = null
	_clear_runtime_items(false)
	clear_display_state()
	_clear_preview_internal()
	if is_instance_valid(_long_press_timer):
		_long_press_timer.queue_free()
	_long_press_timer = null

func process(_delta: float) -> void:
	if _bound_container != zone.container:
		bind()
	if zone.container == null:
		return
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	if session == null:
		if _container_order_needs_sync():
			_sync_container_order()
			refresh()
			zone.layout_changed.emit()
		if is_instance_valid(_ghost_instance):
			_clear_preview_internal()
			refresh()
		return
	if session.prune_invalid_items() and session.items.is_empty():
		_cleanup_drag_session(session, true, true)
		return
	_update_hover_preview(session)

func refresh() -> void:
	if zone.container == null or zone.layout_policy == null or zone.display_style == null:
		return
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	var layout_items := _get_layout_items(session)
	if zone.sort_policy != null and session == null:
		layout_items = zone.sort_policy.sort_items(layout_items)
	var ghost_index := -1
	if session != null and session.hover_zone == zone and is_instance_valid(_ghost_instance):
		ghost_index = clampi(session.preview_index, 0, layout_items.size())
	var placements = zone.layout_policy.calculate(layout_items, zone.container.size, _ghost_instance, ghost_index)
	zone.display_style.apply(zone, self, placements)

func get_items() -> Array[Control]:
	return _items.duplicate()

func get_item_count() -> int:
	return _items.size()

func has_item(item: Control) -> bool:
	return _contains_item_reference(item)

func add_item(item: Control) -> bool:
	return insert_item(item, _items.size())

func insert_item(item: Control, index: int) -> bool:
	if not is_instance_valid(item) or zone.container == null:
		return false
	if _contains_item_reference(item):
		return reorder_item(item, index)
	if item.get_parent() != zone.container:
		if item.get_parent() != null:
			item.reparent(zone.container, false)
		else:
			zone.container.add_child(item)
	_register_item(item)
	var target_index = clampi(index, 0, _items.size())
	if _contains_item_reference(item):
		_erase_item_reference(item)
		target_index = clampi(target_index, 0, _items.size())
	_items.insert(target_index, item)
	item.visible = true
	_sync_container_order()
	refresh()
	zone.layout_changed.emit()
	return true

func remove_item(item: Control) -> bool:
	if not has_item(item):
		return false
	var selection_changed = _remove_item_from_state(item, false, true)
	if item.get_parent() == zone.container:
		zone.container.remove_child(item)
	refresh()
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	zone.layout_changed.emit()
	return true

func move_item_to(item: Control, target_zone: Zone, index: int = -1) -> bool:
	if target_zone == null or not has_item(item):
		return false
	if target_zone == zone:
		return reorder_item(item, index)
	var moving_items: Array[Control] = [item]
	return _transfer_items_to(target_zone, moving_items, index, Vector2.ZERO)

func reorder_item(item: Control, index: int) -> bool:
	if not has_item(item):
		return false
	var moving_items: Array[Control] = [item]
	return _reorder_items(moving_items, index)

func clear_selection() -> void:
	if selection_state.clear_selection():
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func select_item(item: Control, additive: bool = false) -> void:
	if not has_item(item):
		return
	var changed = false
	if additive and zone.interaction != null and zone.interaction.multi_select_enabled:
		changed = selection_state.toggle_item(item)
	else:
		changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

func start_drag(items: Array[Control]) -> void:
	if zone.container == null or items.is_empty():
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
	var drag_offset = primary_item.get_global_mouse_position() - primary_item.global_position
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
	var request = ZoneDropRequest.new(zone, session.source_zone, session.items, session.preview_index, _get_drop_global_position(session))
	var decision = ZoneDropDecision.new(true, "", request.requested_index)
	if zone.permission_policy != null:
		decision = zone.permission_policy.evaluate_drop(request)
	if decision == null:
		decision = ZoneDropDecision.new(true, "", request.requested_index)
	if not decision.allowed:
		_emit_drop_rejected(session, decision.reason)
		_cleanup_drag_session(session, true, true)
		return false
	var source_zone = session.source_zone as Zone
	var target_index = decision.target_index
	if target_index < 0:
		target_index = request.requested_index
	if target_index < 0:
		target_index = _items.size()
	var success = false
	if source_zone == zone:
		success = _reorder_items(session.items, target_index)
	elif source_zone != null:
		success = source_zone.get_runtime()._transfer_items_to(zone, session.items, target_index, request.global_position, source_zone)
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
	if is_instance_valid(_ghost_instance):
		_clear_preview_internal()
		refresh()

func clear_display_state() -> void:
	for state in _display_state.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		for item in active_tweens.keys():
			if active_tweens[item] != null:
				active_tweens[item].kill()
	_display_state.clear()

func get_display_state(style: Resource) -> Dictionary:
	var key = style.get_instance_id()
	if not _display_state.has(key):
		_display_state[key] = {
			"active_tweens": {},
			"target_cache": {}
		}
	return _display_state[key]

func resolve_item_size(item: Control) -> Vector2:
	if zone.layout_policy != null:
		return zone.layout_policy.resolve_item_size(item)
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)

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

func _rebuild_items_from_container() -> void:
	if zone.container == null:
		_clear_runtime_items(true)
		return
	var container_items: Array[Control] = []
	for child in zone.container.get_children():
		if child is Control and child != _ghost_instance:
			container_items.append(child as Control)
	var selection_changed = false
	var existing_items := _items.duplicate()
	for item in existing_items:
		if not is_instance_valid(item) or item.get_parent() != zone.container or item not in container_items:
			selection_changed = _remove_item_from_state(item, false, true) or selection_changed
	for i in range(container_items.size()):
		var item = container_items[i]
		_register_item(item)
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

func _on_container_child_entered(_node: Node) -> void:
	call_deferred("_handle_container_structure_changed")

func _on_container_child_exiting(_node: Node) -> void:
	call_deferred("_handle_container_structure_changed")

func _on_item_gui_input(event: InputEvent, item: Control) -> void:
	if zone.interaction == null:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton, item)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion, item)

func _on_container_gui_input(event: InputEvent) -> void:
	if zone.interaction == null or not zone.interaction.clear_selection_on_background_click:
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
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
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_has_dragged = false
			_pressed_item = item
			_pressed_position = event.global_position
			_long_press_item = item
			if zone.interaction.long_press_enabled and is_instance_valid(_long_press_timer):
				_long_press_timer.wait_time = zone.interaction.long_press_time
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
	if zone.interaction == null or not zone.interaction.drag_enabled:
		return
	if event.global_position.distance_to(_pressed_position) <= zone.interaction.drag_threshold:
		return
	_has_dragged = true
	_is_pressed = false
	_stop_long_press_timer()
	var drag_items = _resolve_drag_items(item)
	start_drag(drag_items)

func _apply_click_selection(item: Control, event: InputEventMouseButton) -> void:
	if zone.interaction == null or not zone.interaction.select_on_click:
		return
	var additive = zone.interaction.multi_select_enabled and zone.interaction.ctrl_toggles_selection and event.ctrl_pressed
	var changed = false
	if zone.interaction.multi_select_enabled and zone.interaction.shift_range_select_enabled and event.shift_pressed:
		changed = selection_state.select_range(_items, item, additive)
	else:
		if additive:
			changed = selection_state.toggle_item(item)
		else:
			changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		refresh()

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
	if zone.container == null:
		return
	var global_mouse = zone.get_viewport().get_mouse_position()
	var is_hovering = zone.container.get_global_rect().has_point(global_mouse)
	if not is_hovering:
		if session.hover_zone == zone:
			session.hover_zone = null
			session.preview_index = -1
			zone.drop_preview_changed.emit(session.items, zone, -1)
			clear_preview()
		return
	if not is_instance_valid(_ghost_instance):
		_create_ghost(session.items[0])
	var visible_items = _get_layout_items(session)
	var target_index = visible_items.size()
	if zone.layout_policy != null:
		target_index = zone.layout_policy.get_insertion_index(visible_items, zone.container.size, zone.container.get_local_mouse_position())
	target_index = clampi(target_index, 0, visible_items.size())
	var changed = session.hover_zone != zone or session.preview_index != target_index
	session.hover_zone = zone
	session.preview_index = target_index
	if changed:
		zone.drop_preview_changed.emit(session.items, zone, target_index)
		refresh()

func _get_layout_items(session: ZoneDragSession) -> Array[Control]:
	var layout_items: Array[Control] = []
	for item in _items:
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			continue
		if session != null and item in session.items:
			continue
		if item.visible:
			layout_items.append(item)
	return layout_items

func _create_ghost(source_item: Control) -> void:
	if zone.container == null or not is_instance_valid(source_item):
		return
	var ghost: Control = null
	if source_item.has_method("create_zone_ghost"):
		var created = source_item.call("create_zone_ghost")
		if created is Control:
			ghost = created as Control
	elif source_item.has_meta("zone_ghost_scene"):
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
	zone.container.add_child(ghost)
	_ghost_instance = ghost

func _create_cursor_proxy(source_item: Control) -> Control:
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

func _clear_preview_internal() -> void:
	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
	_ghost_instance = null

func _reorder_items(items_to_move: Array[Control], target_index: int) -> bool:
	var moving_items: Array[Control] = []
	var original_indices: Dictionary = {}
	for item in _items:
		if _array_contains_valid_control(items_to_move, item):
			original_indices[item] = _find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	for item in moving_items:
		_erase_item_reference(item)
	target_index = clampi(target_index, 0, _items.size())
	for offset in range(moving_items.size()):
		_items.insert(target_index + offset, moving_items[offset])
	for item in moving_items:
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

func _transfer_items_to(target_zone: Zone, items_to_move: Array[Control], target_index: int, drop_position: Vector2, source_zone_override: Zone = null) -> bool:
	if target_zone == null or target_zone.container == null:
		return false
	var source_zone = source_zone_override if source_zone_override != null else zone
	var moving_items: Array[Control] = []
	for item in _items:
		if _array_contains_valid_control(items_to_move, item):
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var selection_changed = false
	for item in moving_items:
		selection_changed = _remove_item_from_state(item, false, true) or selection_changed
	var target_runtime = target_zone.get_runtime()
	target_runtime._insert_transferred_items(moving_items, target_index, drop_position)
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

func _insert_transferred_items(moving_items: Array[Control], target_index: int, drop_position: Vector2) -> void:
	target_index = clampi(target_index, 0, _items.size())
	for offset in range(moving_items.size()):
		var item = moving_items[offset]
		if _contains_item_reference(item):
			_erase_item_reference(item)
		if item.get_parent() != zone.container:
			if item.get_parent() != null:
				item.reparent(zone.container, false)
			else:
				zone.container.add_child(item)
		item.visible = true
		if drop_position != Vector2.ZERO:
			item.global_position = drop_position
		_register_item(item)
		_items.insert(target_index + offset, item)
	_sync_container_order()
	refresh()

func _sync_container_order() -> void:
	if zone.container == null:
		return
	for index in range(_items.size()):
		var item = _items[index]
		if is_instance_valid(item) and item.get_parent() == zone.container:
			zone.container.move_child(item, index)

func _emit_item_transferred(source_zone: Zone, target_zone: Zone, moving_items: Array[Control]) -> void:
	for item in moving_items:
		var target_index = target_zone.get_items().find(item)
		target_zone.item_transferred.emit(item, source_zone, target_zone, target_index)
		if source_zone != target_zone:
			source_zone.item_transferred.emit(item, source_zone, target_zone, target_index)

func _emit_drop_rejected(session: ZoneDragSession, reason: String) -> void:
	var source_zone = session.source_zone as Zone
	zone.drop_rejected.emit(session.items, source_zone, zone, reason)
	if source_zone != null and source_zone != zone:
		source_zone.drop_rejected.emit(session.items, source_zone, zone, reason)

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
	if emit_selection_changed and selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())

func _remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	var selection_changed = false
	var item_is_valid = is_instance_valid(item)
	if item_is_valid and selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
	_erase_item_reference(item)
	if item in _item_bindings:
		_unregister_item(item)
	if item_is_valid and remove_from_container and item.get_parent() == zone.container:
		zone.container.remove_child(item)
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

func _disconnect_container(container: Control) -> void:
	if container == null:
		return
	var entered_callable = Callable(self, "_on_container_child_entered")
	if container.child_entered_tree.is_connected(entered_callable):
		container.child_entered_tree.disconnect(entered_callable)
	var exiting_callable = Callable(self, "_on_container_child_exiting")
	if container.child_exiting_tree.is_connected(exiting_callable):
		container.child_exiting_tree.disconnect(exiting_callable)
	var gui_input_callable = Callable(self, "_on_container_gui_input")
	if container.gui_input.is_connected(gui_input_callable):
		container.gui_input.disconnect(gui_input_callable)

func _handle_container_structure_changed() -> void:
	_rebuild_items_from_container()
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator == null or coordinator.get_session() == null:
		refresh()
		zone.layout_changed.emit()

func _container_order_needs_sync() -> bool:
	if zone.container == null:
		return false
	var control_index = 0
	for child in zone.container.get_children():
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
				return
	else:
		for index in range(_items.size() - 1, -1, -1):
			if not is_instance_valid(_items[index]):
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
	var should_emit = is_instance_valid(_ghost_instance)
	if session != null and session.hover_zone == zone and session.preview_index != -1:
		should_emit = true
	if should_emit:
		zone.drop_preview_changed.emit(session.items if session != null else [], zone, -1)
	_clear_preview_internal()
