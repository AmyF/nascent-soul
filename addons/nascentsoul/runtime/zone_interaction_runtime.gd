class_name ZoneInteractionRuntime extends RefCounted

var runtime
var zone: Zone
var selection_state := ZoneSelectionState.new()

var pressed_item: Control = null
var pressed_position: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var has_dragged: bool = false
var long_press_item: Control = null
var long_press_timer: Timer = null

func _init(p_runtime) -> void:
	runtime = p_runtime
	zone = runtime.zone

func ensure_long_press_timer() -> void:
	if is_instance_valid(long_press_timer):
		return
	long_press_timer = Timer.new()
	long_press_timer.name = "__NascentSoulLongPressTimer"
	long_press_timer.one_shot = true
	zone.add_child(long_press_timer)
	var timeout_callable = Callable(runtime, "_on_long_press_timeout")
	if not long_press_timer.timeout.is_connected(timeout_callable):
		long_press_timer.timeout.connect(timeout_callable)

func cleanup() -> void:
	if is_instance_valid(long_press_timer):
		long_press_timer.queue_free()
	long_press_timer = null

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
		runtime.refresh()

func select_item(item: Control, additive: bool = false) -> void:
	if not runtime.has_item(item):
		return
	var changed = selection_state.toggle_item(item) if additive else selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		runtime.refresh()

func on_item_gui_input(event: InputEvent, item: Control) -> void:
	if zone.get_interaction_config() == null:
		return
	if event is InputEventMouseButton:
		handle_mouse_button(event as InputEventMouseButton, item)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event as InputEventMouseMotion, item)

func on_zone_gui_input(event: InputEvent) -> void:
	var interaction = zone.get_interaction_config()
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
	if runtime.get_item_at_global_position(mouse_event.global_position) != null:
		return
	clear_background_interaction()

func on_item_mouse_entered(item: Control) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.set_hovered(item):
		zone.item_hover_entered.emit(item)
		runtime.refresh()

func on_item_mouse_exited(item: Control) -> void:
	var coordinator = zone.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone.item_hover_exited.emit(item)
		runtime.refresh()

func handle_mouse_button(event: InputEventMouseButton, item: Control) -> void:
	var interaction = zone.get_interaction_config()
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

func handle_mouse_motion(event: InputEventMouseMotion, item: Control) -> void:
	if not is_pressed or has_dragged or not is_instance_valid(pressed_item) or pressed_item != item:
		return
	var interaction = zone.get_interaction_config()
	if interaction == null or not interaction.drag_enabled:
		return
	if event.global_position.distance_to(pressed_position) <= interaction.drag_threshold:
		return
	has_dragged = true
	is_pressed = false
	stop_long_press_timer()
	var targeting_intent = runtime.targeting_runtime.resolve_targeting_intent(item, &"drag")
	if targeting_intent != null and runtime.targeting_runtime.start_targeting_internal(item, targeting_intent, &"drag", event.global_position):
		return
	var drag_items = resolve_drag_items(item)
	runtime.start_drag_at(drag_items, event.global_position)

func apply_click_selection(item: Control, event: InputEventMouseButton) -> void:
	var interaction = zone.get_interaction_config()
	if interaction == null or not interaction.select_on_click:
		return
	var additive = interaction.multi_select_enabled and interaction.ctrl_toggles_selection and event.ctrl_pressed
	var changed = false
	if interaction.multi_select_enabled and interaction.shift_range_select_enabled and event.shift_pressed:
		changed = selection_state.select_range(runtime.item_state.items, item, additive)
	else:
		if additive:
			changed = selection_state.toggle_item(item)
		else:
			changed = selection_state.select_single(item)
	if changed:
		zone.selection_changed.emit(selection_state.get_selected_items())
		runtime.refresh()

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
	if runtime.item_state.items.is_empty():
		return
	var current_item = get_keyboard_active_item()
	var current_index = runtime.item_state.find_item_index(current_item) if current_item != null else -1
	if current_index == -1:
		current_index = 0 if direction >= 0 else runtime.item_state.items.size() - 1
	else:
		current_index += direction
		if wrap_navigation:
			current_index = wrapi(current_index, 0, runtime.item_state.items.size())
		else:
			current_index = clampi(current_index, 0, runtime.item_state.items.size() - 1)
	var next_item = runtime.item_state.items[current_index]
	if not is_instance_valid(next_item):
		return
	if selection_state.select_single(next_item):
		zone.selection_changed.emit(selection_state.get_selected_items())
		runtime.refresh()

func get_keyboard_active_item() -> Control:
	if is_instance_valid(selection_state.anchor_item):
		return selection_state.anchor_item
	var selected = selection_state.get_selected_items()
	if not selected.is_empty():
		var last_item = selected[selected.size() - 1]
		if is_instance_valid(last_item):
			return last_item
	return selection_state.hovered_item if is_instance_valid(selection_state.hovered_item) else null

func resolve_drag_items(item: Control) -> Array[Control]:
	if selection_state.is_selected(item) and selection_state.get_selected_items().size() > 1:
		var ordered_selection: Array[Control] = []
		for candidate in runtime.item_state.items:
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

func clear_hover_for_items(items_to_clear: Array[Control], emit_signal: bool) -> void:
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
		runtime.refresh()
