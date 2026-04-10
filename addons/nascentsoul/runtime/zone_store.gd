class_name ZoneStore extends RefCounted

var items: Array[ZoneItemControl] = []
var item_targets: Dictionary = {}
var transfer_handoffs: Dictionary = {}
var selection_state: ZoneSelectionState = ZoneSelectionState.new()

func cleanup() -> void:
	clear_runtime_items()
	selection_state = null

func get_items() -> Array[ZoneItemControl]:
	return items.duplicate()

func get_item_count() -> int:
	return items.size()

func has_item(item) -> bool:
	return find_item_index(item) != -1

func get_item_target(context: ZoneContext, item: ZoneItemControl) -> ZonePlacementTarget:
	if not is_instance_valid(item):
		return ZonePlacementTarget.invalid()
	if item_targets.has(item):
		var existing = item_targets[item]
		if existing is ZonePlacementTarget:
			return (existing as ZonePlacementTarget).duplicate_target()
	var space_model = context.get_space_model()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	var fallback_index = find_item_index(item)
	return space_model.resolve_render_target(context, item, fallback_index)

func get_items_at_target(context: ZoneContext, target: ZonePlacementTarget) -> Array[ZoneItemControl]:
	var matched: Array[ZoneItemControl] = []
	if target == null or not target.is_valid():
		return matched
	for item in items:
		if not is_instance_valid(item):
			continue
		var item_target = get_item_target(context, item)
		if item_target.matches(target):
			matched.append(item)
	return matched

func get_item_at_global_position(global_position: Vector2) -> ZoneItemControl:
	for index in range(items.size() - 1, -1, -1):
		var item = items[index]
		if not is_instance_valid(item) or not item.visible:
			continue
		if item.get_global_rect().has_point(global_position):
			return item
	return null

func set_item_target(item: ZoneItemControl, target: ZonePlacementTarget) -> void:
	if not is_instance_valid(item) or target == null:
		return
	item_targets[item] = target.duplicate_target()

func clear_item_target(item) -> void:
	if item == null:
		return
	item_targets.erase(item)

func targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.matches(b)

func rebuild_items_from_root(context: ZoneContext, items_root: Control) -> bool:
	if items_root == null:
		clear_runtime_items()
		return false
	var selection_changed = false
	var container_items: Array[ZoneItemControl] = []
	for child in items_root.get_children():
		if child is ZoneItemControl:
			container_items.append(child as ZoneItemControl)
	var existing_items := items.duplicate()
	for item in existing_items:
		if not is_instance_valid(item) or item.get_parent() != items_root or item not in container_items:
			remove_item_reference(item)
			selection_changed = selection_state.prune(items) or selection_changed
	var space_model = context.get_space_model()
	for index in range(container_items.size()):
		var item = container_items[index]
		if contains_item_reference(item):
			continue
		var target = space_model.resolve_add_target(context, item, index) if space_model != null else ZonePlacementTarget.linear(index)
		insert_item_reference(item, min(index, items.size()), target)
	if selection_state.prune(items):
		selection_changed = true
	return selection_changed

func insert_item_reference(item: ZoneItemControl, index: int, target: ZonePlacementTarget) -> void:
	if not is_instance_valid(item):
		return
	if contains_item_reference(item):
		erase_item_reference(item)
	index = clampi(index, 0, items.size())
	items.insert(index, item)
	set_item_target(item, target)

func remove_item_reference(item) -> void:
	erase_item_reference(item)
	clear_transfer_handoff(item)

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

func contains_item_reference(item) -> bool:
	return find_item_index(item) != -1

func find_item_index(item) -> int:
	if not is_instance_valid(item):
		return -1
	for index in range(items.size()):
		var existing_item = items[index]
		if is_instance_valid(existing_item) and existing_item == item:
			return index
	return -1

func clear_runtime_items() -> void:
	items.clear()
	item_targets.clear()
	clear_transfer_handoffs()
	if selection_state != null:
		selection_state.clear()

func sync_container_order(items_root: Control, ghost_instance: Control = null) -> void:
	if items_root == null:
		return
	var control_index = 0
	for item in items:
		if not is_instance_valid(item) or item.get_parent() != items_root:
			continue
		var target_index = control_index
		if is_instance_valid(ghost_instance) and ghost_instance.get_parent() == items_root and ghost_instance.get_index() <= target_index:
			target_index += 1
		if item.get_index() != target_index:
			items_root.move_child(item, target_index)
		control_index += 1

func container_order_needs_sync(items_root: Control, ghost_instance: Control = null) -> bool:
	if items_root == null:
		return false
	var control_index = 0
	for child in items_root.get_children():
		if child is not ZoneItemControl or child == ghost_instance:
			continue
		if control_index >= items.size():
			return true
		if child != items[control_index]:
			return true
		control_index += 1
	return control_index != items.size()

func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null) -> Dictionary:
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

func resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	for item in moving_items:
		if is_instance_valid(item):
			return item.global_position
	return null

func snapshot_item_visual_state(item: ZoneItemControl) -> Dictionary:
	if not is_instance_valid(item):
		return {}
	return {
		"global_position": item.global_position,
		"rotation": item.rotation,
		"scale": item.scale
	}

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
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

func get_transfer_handoff_count() -> int:
	return transfer_handoffs.size()

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	if not is_instance_valid(item):
		return false
	return transfer_handoffs.has(item)

func consume_transfer_handoff(item: ZoneItemControl) -> Dictionary:
	if not is_instance_valid(item) or not transfer_handoffs.has(item):
		return {}
	var handoff: Dictionary = transfer_handoffs[item]
	transfer_handoffs.erase(item)
	return handoff.duplicate(true)

func array_contains_valid_item(items_to_check: Array[ZoneItemControl], candidate: ZoneItemControl) -> bool:
	if not is_instance_valid(candidate):
		return false
	for item in items_to_check:
		if is_instance_valid(item) and item == candidate:
			return true
	return false
