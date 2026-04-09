class_name ZoneInputService extends RefCounted

var context: ZoneContext
var zone: Zone
var selection_state: ZoneSelectionState

var item_bindings: Dictionary = {}
var pressed_item: ZoneItemControl = null
var pressed_position: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var has_dragged: bool = false
var long_press_item: ZoneItemControl = null
var long_press_timer: Timer = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone
	selection_state = context.selection_state

func bind() -> void:
	var gui_input_callable = Callable(self, "on_zone_gui_input")
	if not zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.connect(gui_input_callable)
	ensure_long_press_timer()
	sync_item_bindings()

func sync_item_bindings() -> void:
	var valid_items = context.get_items()
	var valid_ids: Dictionary = {}
	for item in valid_items:
		if is_instance_valid(item):
			valid_ids[item.get_instance_id()] = true
	for item in item_bindings.keys().duplicate():
		if not is_instance_valid(item) or not valid_ids.has(item.get_instance_id()):
			unregister_item(item)
	for item in valid_items:
		if is_instance_valid(item):
			register_item(item)

func ensure_long_press_timer() -> void:
	if is_instance_valid(long_press_timer):
		return
	long_press_timer = Timer.new()
	long_press_timer.name = "__NascentSoulLongPressTimer"
	long_press_timer.one_shot = true
	zone.add_child(long_press_timer)
	var timeout_callable = Callable(self, "on_long_press_timeout")
	if not long_press_timer.timeout.is_connected(timeout_callable):
		long_press_timer.timeout.connect(timeout_callable)

func cleanup() -> void:
	for item in item_bindings.keys().duplicate():
		unregister_item(item)
	var gui_input_callable = Callable(self, "on_zone_gui_input")
	if zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.disconnect(gui_input_callable)
	if is_instance_valid(long_press_timer):
		long_press_timer.queue_free()
	long_press_timer = null

func register_item(item: ZoneItemControl) -> void:
	if not is_instance_valid(item) or item_bindings.has(item):
		return
	if item.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	var gui_input_callable = Callable(self, "on_item_gui_input").bind(item)
	var mouse_entered_callable = Callable(self, "on_item_mouse_entered").bind(item)
	var mouse_exited_callable = Callable(self, "on_item_mouse_exited").bind(item)
	if not item.gui_input.is_connected(gui_input_callable):
		item.gui_input.connect(gui_input_callable)
	if not item.mouse_entered.is_connected(mouse_entered_callable):
		item.mouse_entered.connect(mouse_entered_callable)
	if not item.mouse_exited.is_connected(mouse_exited_callable):
		item.mouse_exited.connect(mouse_exited_callable)
	item_bindings[item] = {
		"gui_input": gui_input_callable,
		"mouse_entered": mouse_entered_callable,
		"mouse_exited": mouse_exited_callable
	}

func unregister_item(item) -> void:
	if not item_bindings.has(item):
		return
	var bindings: Dictionary = item_bindings[item]
	reset_press_state_for_item(item)
	if is_instance_valid(item):
		if item.gui_input.is_connected(bindings["gui_input"]):
			item.gui_input.disconnect(bindings["gui_input"])
		if item.mouse_entered.is_connected(bindings["mouse_entered"]):
			item.mouse_entered.disconnect(bindings["mouse_entered"])
		if item.mouse_exited.is_connected(bindings["mouse_exited"]):
			item.mouse_exited.disconnect(bindings["mouse_exited"])
	item_bindings.erase(item)

func clear_selection() -> void:
	var hover_changed = false
	var selection_changed = false
	var hovered = selection_state.hovered_item
	if hovered != null and selection_state.set_hovered(null):
		hover_changed = true
		zone.item_hover_exited.emit(hovered)
	selection_changed = selection_state.clear_selection()
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	if hover_changed or selection_changed:
		zone.refresh()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	if not context.has_item(item):
		return
	var changed = selection_state.toggle_item(item) if additive else selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		zone.refresh()

func on_item_gui_input(event: InputEvent, item: ZoneItemControl) -> void:
	if context.get_interaction() == null:
		return
	if event is InputEventMouseButton:
		handle_mouse_button(event as InputEventMouseButton, item)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event as InputEventMouseMotion, item)

func on_zone_gui_input(event: InputEvent) -> void:
	var interaction = context.get_interaction()
	if interaction == null:
		return
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if handle_keyboard_navigation(event, interaction):
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
	if context.get_item_at_global_position(mouse_event.global_position) != null:
		return
	clear_background_interaction()

func on_item_mouse_entered(item: ZoneItemControl) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.set_hovered(item):
		zone.item_hover_entered.emit(item)
		zone.refresh()

func on_item_mouse_exited(item: ZoneItemControl) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
		zone.refresh()

func handle_mouse_button(event: InputEventMouseButton, item: ZoneItemControl) -> void:
	var interaction = context.get_interaction()
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null and event.button_index == MOUSE_BUTTON_RIGHT:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			zone.grab_focus()
			is_pressed = true
			has_dragged = false
			pressed_item = item
			pressed_position = event.global_position
			long_press_item = item
			if interaction != null and interaction.long_press_enabled and is_instance_valid(long_press_timer):
				long_press_timer.wait_time = interaction.long_press_time
				long_press_timer.start()
		else:
			stop_long_press_timer()
			var should_activate = is_pressed and is_instance_valid(pressed_item) and pressed_item == item and not has_dragged
			is_pressed = false
			pressed_item = null
			if should_activate:
				apply_click_selection(item, event)
				if event.double_click:
					zone.item_double_clicked.emit(item)
				else:
					zone.item_clicked.emit(item)
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		zone.item_right_clicked.emit(item)

func handle_mouse_motion(event: InputEventMouseMotion, item: ZoneItemControl) -> void:
	if not is_pressed or has_dragged or not is_instance_valid(pressed_item) or pressed_item != item:
		return
	var interaction = context.get_interaction()
	if interaction == null or not interaction.drag_enabled:
		return
	if event.global_position.distance_to(pressed_position) <= interaction.drag_threshold:
		return
	has_dragged = true
	is_pressed = false
	stop_long_press_timer()
	if context.targeting_service.try_start_drag_targeting(item, event.global_position):
		return
	var drag_items = resolve_drag_items(item)
	context.transfer_service.start_drag_at(drag_items, event.global_position)

func apply_click_selection(item: ZoneItemControl, event: InputEventMouseButton) -> void:
	var interaction = context.get_interaction()
	if interaction == null or not interaction.select_on_click:
		return
	var additive = interaction.multi_select_enabled and interaction.ctrl_toggles_selection and event.ctrl_pressed
	var changed = false
	if interaction.multi_select_enabled and interaction.shift_range_select_enabled and event.shift_pressed:
		changed = selection_state.select_range(context.get_items_ordered(), item, additive)
	else:
		if additive:
			changed = selection_state.toggle_item(item)
		else:
			changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		zone.refresh()

func handle_keyboard_navigation(event: InputEvent, interaction: ZoneInteraction) -> bool:
	if not interaction.keyboard_navigation_enabled or not zone.has_focus():
		return false
	if matches_action(event, interaction.next_item_action):
		move_keyboard_selection(1, interaction.wrap_navigation)
		return true
	if matches_action(event, interaction.previous_item_action):
		move_keyboard_selection(-1, interaction.wrap_navigation)
		return true
	if matches_action(event, interaction.activate_item_action):
		var active_item = get_keyboard_active_item()
		if active_item != null:
			zone.item_clicked.emit(active_item)
		return true
	if matches_action(event, interaction.clear_selection_action):
		clear_background_interaction()
		return true
	return false

func matches_action(event: InputEvent, action_name: StringName) -> bool:
	if action_name == StringName():
		return false
	if event is InputEventAction:
		var action_event := event as InputEventAction
		return action_event.action == action_name and action_event.pressed
	if not InputMap.has_action(action_name):
		return false
	return event.is_action_pressed(action_name, false, true)

func move_keyboard_selection(direction: int, wrap_navigation: bool) -> void:
	if context.get_item_count() == 0:
		return
	var current_item = get_keyboard_active_item()
	var current_index = context.find_item_index(current_item) if current_item != null else -1
	if current_index == -1:
		current_index = 0 if direction >= 0 else context.get_item_count() - 1
	else:
		current_index += direction
		if wrap_navigation:
			current_index = wrapi(current_index, 0, context.get_item_count())
		else:
			current_index = clampi(current_index, 0, context.get_item_count() - 1)
	var next_item = context.get_items_ordered()[current_index]
	if not is_instance_valid(next_item):
		return
	if selection_state.select_single(next_item):
		zone.selection_changed.emit(selection_state.get_selected_items())
		zone.refresh()

func get_keyboard_active_item() -> ZoneItemControl:
	if is_instance_valid(selection_state.anchor_item):
		return selection_state.anchor_item
	var selected = selection_state.get_selected_items()
	if not selected.is_empty():
		var last_item = selected[selected.size() - 1]
		if is_instance_valid(last_item):
			return last_item
	return selection_state.hovered_item if is_instance_valid(selection_state.hovered_item) else null

func resolve_drag_items(item: ZoneItemControl) -> Array[ZoneItemControl]:
	if selection_state.is_selected(item) and selection_state.get_selected_items().size() > 1:
		var ordered_selection: Array[ZoneItemControl] = []
		for candidate in context.get_items_ordered():
			if selection_state.is_selected(candidate):
				ordered_selection.append(candidate)
		return ordered_selection
	return [item]

func stop_long_press_timer() -> void:
	if is_instance_valid(long_press_timer):
		long_press_timer.stop()
	long_press_item = null

func on_long_press_timeout() -> void:
	if not is_pressed or has_dragged or not is_instance_valid(long_press_item):
		return
	var item = long_press_item
	is_pressed = false
	pressed_item = null
	long_press_item = null
	zone.item_long_pressed.emit(item)

func clear_hover_for_items(items_to_clear: Array[ZoneItemControl], emit_signal: bool) -> void:
	var hovered_item = selection_state.hovered_item
	if hovered_item == null or not is_instance_valid(hovered_item):
		if hovered_item != null:
			selection_state.set_hovered(null)
		return
	var found = false
	for item in items_to_clear:
		if is_instance_valid(item) and item == hovered_item:
			found = true
			break
	if not found:
		return
	if selection_state.set_hovered(null) and emit_signal:
		zone.item_hover_exited.emit(hovered_item)

func reset_press_state_for_item(item = null) -> void:
	if item == null:
		is_pressed = false
		has_dragged = false
		pressed_item = null
		stop_long_press_timer()
		return
	if is_instance_valid(pressed_item) and is_instance_valid(item) and pressed_item == item:
		is_pressed = false
		has_dragged = false
		pressed_item = null
	if long_press_item == item or (item != null and not is_instance_valid(item) and not is_instance_valid(long_press_item)):
		stop_long_press_timer()

func clear_background_interaction() -> void:
	var hovered_item = selection_state.hovered_item
	var hover_changed = selection_state.clear_hover()
	var selection_changed = selection_state.clear_selection()
	if hover_changed and is_instance_valid(hovered_item):
		zone.item_hover_exited.emit(hovered_item)
	if selection_changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
	if hover_changed or selection_changed:
		zone.refresh()
