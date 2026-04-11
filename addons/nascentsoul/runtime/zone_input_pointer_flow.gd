class_name ZoneInputPointerFlow extends RefCounted

var input_service = null
var context: ZoneContext = null
var zone = null

var pressed_item: ZoneItemControl = null
var pressed_position: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var has_dragged: bool = false
var long_press_item: ZoneItemControl = null
var long_press_timer: Timer = null

func _init(p_input_service, p_context: ZoneContext) -> void:
	input_service = p_input_service
	context = p_context
	zone = context.zone

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
	if is_instance_valid(long_press_timer):
		var timeout_callable = Callable(self, "on_long_press_timeout")
		if long_press_timer.timeout.is_connected(timeout_callable):
			long_press_timer.timeout.disconnect(timeout_callable)
		long_press_timer.stop()
		long_press_timer.queue_free()
	reset_press_state_for_item()
	long_press_timer = null
	long_press_item = null
	zone = null
	context = null
	input_service = null

func handle_zone_gui_input(event: InputEvent) -> void:
	var interaction = context.get_interaction()
	if interaction == null:
		return
	var targeting_coordinator = input_service.get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if input_service.handle_keyboard_navigation(event, interaction):
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
		return
	if not interaction.clear_selection_on_background_click:
		return
	var coordinator = input_service.get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	if context.get_item_at_global_position(mouse_event.global_position) != null:
		return
	input_service.clear_background_interaction()

func handle_mouse_button(event: InputEventMouseButton, item: ZoneItemControl) -> void:
	var interaction = context.get_interaction()
	var targeting_coordinator = input_service.get_targeting_coordinator(false)
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
				input_service.apply_click_selection(item, event)
				if event.double_click:
					input_service.emit_item_double_clicked(item)
				else:
					input_service.emit_item_clicked(item)
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		input_service.emit_item_right_clicked(item)

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
	if input_service.targeting_service != null and input_service.targeting_service.try_start_drag_targeting(item, event.global_position):
		return
	var drag_items = input_service.resolve_drag_items(item)
	if input_service.transfer_service != null:
		input_service.transfer_service.start_drag_at(drag_items, event.global_position, item)

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
	input_service.emit_item_long_pressed(item)

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
