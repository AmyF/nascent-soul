class_name ZoneSelectionState extends RefCounted

var hovered_item: Control = null
var selected_items: Array[Control] = []
var anchor_item: Control = null

func clear() -> bool:
	var hover_changed = clear_hover()
	var selection_changed = clear_selection()
	return hover_changed or selection_changed

func clear_hover() -> bool:
	if hovered_item == null:
		return false
	hovered_item = null
	return true

func clear_selection() -> bool:
	var changed = anchor_item != null or not selected_items.is_empty()
	anchor_item = null
	selected_items.clear()
	return changed

func set_hovered(item: Control) -> bool:
	if hovered_item == item:
		return false
	hovered_item = item
	return true

func select_single(item: Control) -> bool:
	if is_instance_valid(item) and selected_items.size() == 1 and _find_item_index(item) == 0:
		anchor_item = item
		return false
	selected_items.clear()
	anchor_item = item if is_instance_valid(item) else null
	if is_instance_valid(item):
		selected_items.append(item)
	return true

func toggle_item(item: Control) -> bool:
	if not is_instance_valid(item):
		return false
	var existing_index = _find_item_index(item)
	if existing_index != -1:
		selected_items.remove_at(existing_index)
	else:
		selected_items.append(item)
	anchor_item = item
	return true

func select_range(items_in_order: Array[Control], to_item: Control, additive: bool = false) -> bool:
	if not is_instance_valid(to_item):
		return false
	var anchor = anchor_item if is_instance_valid(anchor_item) else to_item
	var start_index = _find_item_index_in_list(items_in_order, anchor)
	var end_index = _find_item_index_in_list(items_in_order, to_item)
	if start_index == -1 or end_index == -1:
		return select_single(to_item)
	var previous_selection = get_selected_items()
	var next_selection: Array[Control] = []
	if additive:
		next_selection = previous_selection.duplicate()
	var range_start = mini(start_index, end_index)
	var range_end = maxi(start_index, end_index)
	for index in range(range_start, range_end + 1):
		var item = items_in_order[index]
		if not is_instance_valid(item) or _find_item_index_in_array(next_selection, item) != -1:
			continue
		next_selection.append(item)
	selected_items = next_selection
	anchor_item = anchor
	return not _selection_matches(previous_selection, selected_items)

func prune(valid_items: Array[Control]) -> bool:
	var changed = false
	var valid_ids: Dictionary = {}
	for item in valid_items:
		if is_instance_valid(item):
			valid_ids[item.get_instance_id()] = true
	if hovered_item != null and (not is_instance_valid(hovered_item) or not valid_ids.has(hovered_item.get_instance_id())):
		hovered_item = null
		changed = true
	if anchor_item != null and (not is_instance_valid(anchor_item) or not valid_ids.has(anchor_item.get_instance_id())):
		anchor_item = null
		changed = true
	var remaining: Array[Control] = []
	for item in selected_items:
		if is_instance_valid(item) and valid_ids.has(item.get_instance_id()):
			remaining.append(item)
		else:
			changed = true
	selected_items = remaining
	return changed

func is_selected(item: Control) -> bool:
	return _find_item_index(item) != -1

func get_selected_items() -> Array[Control]:
	return selected_items.duplicate()

func _find_item_index(item: Control) -> int:
	if not is_instance_valid(item):
		return -1
	return _find_item_index_in_array(selected_items, item)

func _find_item_index_in_list(items: Array[Control], item: Control) -> int:
	return _find_item_index_in_array(items, item)

func _find_item_index_in_array(items: Array[Control], item: Control) -> int:
	if not is_instance_valid(item):
		return -1
	for index in range(items.size()):
		var selected_item = items[index]
		if is_instance_valid(selected_item) and selected_item == item:
			return index
	return -1

func _selection_matches(previous_selection: Array[Control], next_selection: Array[Control]) -> bool:
	if previous_selection.size() != next_selection.size():
		return false
	for index in range(previous_selection.size()):
		if previous_selection[index] != next_selection[index]:
			return false
	return true
