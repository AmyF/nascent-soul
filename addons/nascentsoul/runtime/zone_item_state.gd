class_name ZoneItemState extends RefCounted

var runtime
var zone: Zone

var items: Array[Control] = []
var item_targets: Dictionary = {}
var item_bindings: Dictionary = {}
var transfer_handoffs: Dictionary = {}
var bound_items_root: Control = null

func _init(p_runtime) -> void:
	runtime = p_runtime
	zone = runtime.zone

func get_items() -> Array[Control]:
	return items.duplicate()

func get_item_count() -> int:
	return items.size()

func has_item(item: Control) -> bool:
	return contains_item_reference(item)

func get_item_target(item: Control) -> ZonePlacementTarget:
	if not is_instance_valid(item):
		return ZonePlacementTarget.invalid()
	if item_targets.has(item):
		var existing = item_targets[item]
		if existing is ZonePlacementTarget:
			return (existing as ZonePlacementTarget).duplicate_target()
	var fallback_index = find_item_index(item)
	return zone.get_space_model_resource().resolve_render_target(zone, runtime, item, fallback_index)

func get_items_at_target(target: ZonePlacementTarget) -> Array[Control]:
	var matched: Array[Control] = []
	if target == null or not target.is_valid():
		return matched
	for item in items:
		if not is_instance_valid(item):
			continue
		var item_target = get_item_target(item)
		if item_target.matches(target):
			matched.append(item)
	return matched

func get_item_at_global_position(global_position: Vector2) -> Control:
	for index in range(items.size() - 1, -1, -1):
		var item = items[index]
		if not is_instance_valid(item) or not item.visible:
			continue
		if item.get_global_rect().has_point(global_position):
			return item
	return null

func set_item_target(item: Control, target: ZonePlacementTarget) -> void:
	if not is_instance_valid(item) or target == null:
		return
	item_targets[item] = target.duplicate_target()
	item.set_meta("zone_placement_target", target.duplicate_target())

func clear_item_target(item) -> void:
	if item == null:
		return
	item_targets.erase(item)
	if is_instance_valid(item) and item.has_meta("zone_placement_target"):
		item.remove_meta("zone_placement_target")

func targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.matches(b)

func rebuild_items_from_root() -> void:
	if zone == null or not is_instance_valid(zone):
		return
	var items_root = zone.get_items_root()
	if items_root == null:
		clear_runtime_items(true)
		return
	var container_items: Array[Control] = []
	for child in items_root.get_children():
		if child is Control and child != runtime.display_runtime.ghost_instance:
			container_items.append(child as Control)
	var selection_changed = false
	var existing_items := items.duplicate()
	for item in existing_items:
		if not is_instance_valid(item) or item.get_parent() != items_root or item not in container_items:
			selection_changed = runtime._remove_item_from_state(item, false, true) or selection_changed
	for i in range(container_items.size()):
		var item = container_items[i]
		register_item(item)
		var restored_target = item.get_meta("zone_placement_target") if item.has_meta("zone_placement_target") else null
		if restored_target != null and restored_target is ZonePlacementTarget:
			set_item_target(item, zone.get_space_model_resource().normalize_target(zone, runtime, restored_target as ZonePlacementTarget, [item]))
		elif not item_targets.has(item):
			set_item_target(item, zone.get_space_model_resource().resolve_add_target(zone, runtime, item, i))
		if contains_item_reference(item):
			continue
		var insert_at = min(i, items.size())
		items.insert(insert_at, item)
	for item in item_bindings.keys():
		if item not in items:
			unregister_item(item)
	if runtime.selection_state.prune(items):
		selection_changed = true
	if selection_changed:
		zone.selection_changed.emit(runtime.selection_state.get_selected_items())
	sync_container_order()

func register_item(item: Control) -> void:
	if item_bindings.has(item):
		return
	if item.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	var gui_input_callable = Callable(runtime, "_on_item_gui_input").bind(item)
	var mouse_entered_callable = Callable(runtime, "_on_item_mouse_entered").bind(item)
	var mouse_exited_callable = Callable(runtime, "_on_item_mouse_exited").bind(item)
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
	runtime._reset_press_state_for_item(item)
	if is_instance_valid(item):
		if item.gui_input.is_connected(bindings["gui_input"]):
			item.gui_input.disconnect(bindings["gui_input"])
		if item.mouse_entered.is_connected(bindings["mouse_entered"]):
			item.mouse_entered.disconnect(bindings["mouse_entered"])
		if item.mouse_exited.is_connected(bindings["mouse_exited"]):
			item.mouse_exited.disconnect(bindings["mouse_exited"])
	item_bindings.erase(item)

func clear_runtime_items(emit_selection_changed: bool) -> void:
	var selection_changed = runtime.selection_state.clear()
	var existing_items := items.duplicate()
	for item in existing_items:
		runtime._remove_item_from_state(item, false, true)
	items.clear()
	item_targets.clear()
	clear_transfer_handoffs()
	if emit_selection_changed and selection_changed:
		zone.selection_changed.emit(runtime.selection_state.get_selected_items())

func sync_container_order() -> void:
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	var control_index = 0
	for item in items:
		if not is_instance_valid(item) or item.get_parent() != items_root:
			continue
		var current_index = item.get_index()
		var target_index = control_index
		if runtime.display_runtime.ghost_instance != null and is_instance_valid(runtime.display_runtime.ghost_instance) and runtime.display_runtime.ghost_instance.get_parent() == items_root and runtime.display_runtime.ghost_instance.get_index() <= target_index:
			target_index += 1
		if current_index != target_index:
			items_root.move_child(item, target_index)
		control_index += 1

func container_order_needs_sync() -> bool:
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	if zone.get_space_model_resource() is not ZoneLinearSpaceModel:
		return false
	var control_index = 0
	for child in items_root.get_children():
		if child is not Control or child == runtime.display_runtime.ghost_instance:
			continue
		if control_index >= items.size():
			return true
		if child != items[control_index]:
			return true
		control_index += 1
	return control_index != items.size()

func erase_item_reference(item) -> void:
	if is_instance_valid(item):
		for index in range(items.size() - 1, -1, -1):
			var existing_item = items[index]
			if is_instance_valid(existing_item) and existing_item == item:
				items.remove_at(index)
				item_targets.erase(item)
				return
	else:
		for index in range(items.size() - 1, -1, -1):
			if not is_instance_valid(items[index]):
				item_targets.erase(items[index])
				items.remove_at(index)

func contains_item_reference(item: Control) -> bool:
	return find_item_index(item) != -1

func find_item_index(item: Control) -> int:
	if not is_instance_valid(item):
		return -1
	for index in range(items.size()):
		var existing_item = items[index]
		if is_instance_valid(existing_item) and existing_item == item:
			return index
	return -1

func array_contains_valid_control(items_to_check: Array[Control], candidate: Control) -> bool:
	if not is_instance_valid(candidate):
		return false
	for item in items_to_check:
		if is_instance_valid(item) and item == candidate:
			return true
	return false

func build_transfer_snapshots(moving_items: Array[Control], drop_position = null) -> Dictionary:
	var snapshots: Dictionary = {}
	if moving_items.is_empty():
		return snapshots
	for item in moving_items:
		if is_instance_valid(item):
			snapshots[item] = snapshot_item_visual_state(item)
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

func resolve_programmatic_transfer_global_position(moving_items: Array[Control]):
	for item in moving_items:
		if is_instance_valid(item):
			return item.global_position
	return null

func snapshot_item_visual_state(item: Control) -> Dictionary:
	if not is_instance_valid(item):
		return {}
	return {
		"global_position": item.global_position,
		"rotation": item.rotation,
		"scale": item.scale
	}

func set_transfer_handoff(item: Control, snapshot: Dictionary) -> void:
	if not is_instance_valid(item):
		return
	if snapshot.is_empty():
		transfer_handoffs.erase(item)
		return
	transfer_handoffs[item] = snapshot.duplicate(true)

func clear_transfer_handoff(item) -> void:
	if item == null:
		return
	transfer_handoffs.erase(item)

func clear_transfer_handoffs() -> void:
	transfer_handoffs.clear()

func consume_transfer_handoff(item: Control) -> Dictionary:
	if not is_instance_valid(item) or not transfer_handoffs.has(item):
		return {}
	var handoff: Dictionary = transfer_handoffs[item]
	transfer_handoffs.erase(item)
	return handoff.duplicate(true)
