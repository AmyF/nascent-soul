class_name ZoneStore extends RefCounted

var items: Array[ZoneItemControl] = []
var item_targets: Dictionary = {}
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
	# item_targets stores explicit placement chosen by transfer/layout flows. When
	# no cached target exists, derive one from the current logical order instead.
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
		if context != null:
			context.clear_transfer_handoffs()
		return false
	# The scene tree becomes authoritative after editor edits, restore flows, and
	# failed-transfer rollback. Reconcile logical state back to that container.
	var selection_changed = false
	var container_items: Array[ZoneItemControl] = []
	for child in items_root.get_children():
		if child is ZoneItemControl:
			container_items.append(child as ZoneItemControl)
	var existing_items := items.duplicate()
	for item in existing_items:
		if not is_instance_valid(item) or item.get_parent() != items_root or item not in container_items:
			if context != null:
				context.clear_transfer_handoff(item)
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
	if selection_state != null:
		selection_state.clear()
