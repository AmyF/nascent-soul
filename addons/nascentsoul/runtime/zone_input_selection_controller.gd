extends RefCounted

# Internal helper for selection, hover, and keyboard-navigation behavior.

var context: ZoneContext = null
var zone = null
var selection_state: ZoneSelectionState = null

func _init(p_context: ZoneContext, p_selection_state: ZoneSelectionState) -> void:
	context = p_context
	zone = context.zone
	selection_state = p_selection_state

func cleanup() -> void:
	selection_state = null
	zone = null
	context = null

func clear_selection() -> void:
	var hover_changed = false
	var selection_changed = false
	var hovered = selection_state.hovered_item
	if hovered != null and selection_state.set_hovered(null):
		hover_changed = true
		zone._emit_item_hover_exited(hovered)
	selection_changed = selection_state.clear_selection()
	if selection_changed:
		zone._emit_selection_changed()
	if hover_changed or selection_changed:
		zone.refresh()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	if not context.has_item(item):
		return
	var changed = selection_state.toggle_item(item) if additive else selection_state.select_single(item)
	if changed:
		zone._emit_selection_changed()
		zone.refresh()

func handle_item_mouse_entered(item: ZoneItemControl) -> void:
	var coordinator = zone._get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone._get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.set_hovered(item):
		zone._emit_item_hover_entered(item)
		zone.refresh()

func handle_item_mouse_exited(item: ZoneItemControl) -> void:
	var coordinator = zone._get_drag_coordinator(false)
	if coordinator != null and coordinator.get_session() != null:
		return
	var targeting_coordinator = zone._get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		return
	if selection_state.hovered_item == item and selection_state.set_hovered(null):
		zone._emit_item_hover_exited(item)
		zone.refresh()

func handle_keyboard_navigation(event: InputEvent, interaction: ZoneInteraction) -> bool:
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
			zone._emit_item_clicked(active_item)
		return true
	if _matches_action(event, interaction.clear_selection_action):
		clear_background_interaction()
		return true
	return false

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
		zone._emit_selection_changed()
		zone.refresh()

func resolve_drag_items(item: ZoneItemControl) -> Array[ZoneItemControl]:
	if selection_state.is_selected(item) and selection_state.get_selected_items().size() > 1:
		var ordered_selection: Array[ZoneItemControl] = []
		for candidate in context.get_items_ordered():
			if selection_state.is_selected(candidate):
				ordered_selection.append(candidate)
		return ordered_selection
	return [item]

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
		zone._emit_item_hover_exited(hovered_item)

func clear_background_interaction() -> void:
	var hovered_item = selection_state.hovered_item
	var hover_changed = selection_state.clear_hover()
	var selection_changed = selection_state.clear_selection()
	if hover_changed and is_instance_valid(hovered_item):
		zone._emit_item_hover_exited(hovered_item)
	if selection_changed:
		zone._emit_selection_changed()
	if hover_changed or selection_changed:
		zone.refresh()

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
	if context.get_item_count() == 0:
		return
	var current_item = _get_keyboard_active_item()
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
		zone._emit_selection_changed()
		zone.refresh()

func _get_keyboard_active_item() -> ZoneItemControl:
	if is_instance_valid(selection_state.anchor_item):
		return selection_state.anchor_item
	var selected = selection_state.get_selected_items()
	if not selected.is_empty():
		var last_item = selected[selected.size() - 1]
		if is_instance_valid(last_item):
			return last_item
	return selection_state.hovered_item if is_instance_valid(selection_state.hovered_item) else null
