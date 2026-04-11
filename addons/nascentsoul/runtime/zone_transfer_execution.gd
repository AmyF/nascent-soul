extends RefCounted

# Internal helper for reorders, cross-zone transfers, spawns, and rollback.

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")

var context: ZoneContext = null
var zone = null
var store: ZoneStore = null
var transfer_service = null

var input_service: ZoneInputService = null
var render_service: ZoneRenderService = null

func _init(p_transfer_service, p_context: ZoneContext, p_store: ZoneStore) -> void:
	transfer_service = p_transfer_service
	context = p_context
	zone = context.zone
	store = p_store

func bind_services(p_input_service: ZoneInputService, p_render_service: ZoneRenderService) -> void:
	input_service = p_input_service
	render_service = p_render_service

func cleanup() -> void:
	input_service = null
	render_service = null
	transfer_service = null
	store = null
	zone = null
	context = null

func remove_item(item: ZoneItemControl) -> bool:
	if not store.has_item(item):
		return false
	var previous_index = store.find_item_index(item)
	var selection_changed = remove_item_from_state(item, false, true)
	var items_root = zone.get_items_root()
	if items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if previous_index >= 0:
		transfer_service.runtime_port.emit_item_removed(item, previous_index)
	transfer_service.runtime_port.request_refresh()
	if selection_changed:
		transfer_service.runtime_port.emit_selection_changed()
	transfer_service.runtime_port.emit_layout_changed()
	return true

func remove_item_from_state(item, remove_from_container: bool, clear_visuals: bool) -> bool:
	var selection_changed = false
	var item_is_valid = is_instance_valid(item)
	if item_is_valid and context.selection_state.hovered_item == item and context.selection_state.set_hovered(null):
		transfer_service.runtime_port.emit_item_hover_exited(item)
	store.erase_item_reference(item)
	store.clear_item_target(item)
	context.clear_transfer_handoff(item)
	if item_is_valid:
		input_service.unregister_item(item)
	var items_root = zone.get_items_root()
	if item_is_valid and remove_from_container and items_root != null and item.get_parent() == items_root:
		items_root.remove_child(item)
	if clear_visuals:
		clear_item_visual_state(item, true)
	if context.selection_state.prune(store.items):
		selection_changed = true
	return selection_changed

func clear_item_visual_state(item, reset_transform: bool) -> void:
	if not is_instance_valid(item):
		return
	if item is ZoneItemControl:
		(item as ZoneItemControl).apply_zone_visual_state(ZoneItemVisualState.new())
	if reset_transform:
		item.scale = Vector2.ONE
		item.rotation = 0.0
		item.z_index = 0

func reorder_items(items_to_move: Array[ZoneItemControl], placement_target: ZonePlacementTarget) -> bool:
	var moving_items: Array[ZoneItemControl] = []
	var original_indices: Dictionary = {}
	for item in store.items:
		if item in items_to_move:
			original_indices[item] = store.find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var resolved_target = transfer_service.resolve_transfer_target(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(store.find_item_index(moving_items[0]), resolved_target)
	for item in moving_items:
		store.erase_item_reference(item)
	target_index = clampi(target_index, 0, store.items.size())
	for offset in range(moving_items.size()):
		store.items.insert(target_index + offset, moving_items[offset])
	for item in moving_items:
		store.set_item_target(item, _resolve_reordered_target(resolved_target, target_index + moving_items.find(item)))
		item.visible = true
	render_service.sync_container_order()
	for item in moving_items:
		var to_index = store.find_item_index(item)
		var from_index = original_indices[item]
		if from_index != to_index:
			transfer_service.runtime_port.emit_item_reordered(item, from_index, to_index)
	transfer_service.runtime_port.request_refresh()
	transfer_service.runtime_port.emit_layout_changed()
	return true

func transfer_items_to(target_zone: Zone, items_to_move: Array[ZoneItemControl], placement_target: ZonePlacementTarget, drop_position = null, source_zone_override: Zone = null, decision: ZoneTransferDecision = null, anchor_item: ZoneItemControl = null) -> bool:
	if target_zone == null or target_zone.get_items_root() == null:
		return false
	var source_zone = source_zone_override if source_zone_override != null else zone
	var moving_items: Array[ZoneItemControl] = []
	var original_indices: Dictionary = {}
	var removed_indices: Dictionary = {}
	for item in store.items:
		if item in items_to_move:
			original_indices[item] = store.find_item_index(item)
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var transfer_snapshots = transfer_service.build_transfer_snapshots(moving_items, drop_position, anchor_item)
	var selection_changed = false
	var target_transfer = ZoneRuntimePortScript.resolve_transfer_service(target_zone)
	var target_context = ZoneRuntimePortScript.resolve_context(target_zone)
	if target_transfer == null or target_context == null:
		return false
	var resolved_decision = decision if decision != null else ZoneTransferDecision.new(true, "", target_transfer.resolve_transfer_target(moving_items, placement_target))
	var final_target = target_transfer.resolve_transfer_target(moving_items, resolved_decision.resolved_target)
	if final_target == null or not final_target.is_valid():
		final_target = target_transfer.resolve_transfer_target(moving_items, null)
	if final_target == null or not final_target.is_valid():
		target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Invalid drop target.")
		return false
	var original_targets: Dictionary = {}
	for item in moving_items:
		original_targets[item] = store.get_item_target(context, item)
	for item in moving_items:
		selection_changed = remove_item_from_state(item, false, false) or selection_changed
		clear_item_visual_state(item, false)
		var from_index = original_indices.get(item, -1)
		if from_index >= 0:
			removed_indices[item] = from_index
	if resolved_decision.transfer_mode == ZoneTransferDecision.TransferMode.SPAWN_PIECE:
		var spawned_items = _build_spawned_items(target_context, moving_items, resolved_decision, final_target)
		if spawned_items.is_empty():
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "No spawn item could be created.")
			for item in moving_items:
				if is_instance_valid(item):
					item.visible = true
			store.rebuild_items_from_root(context, zone.get_items_root())
			input_service.sync_item_bindings()
			transfer_service.runtime_port.request_refresh()
			target_transfer.rebuild_items_from_root()
			var target_input_service = ZoneRuntimePortScript.resolve_input_service(target_zone)
			if target_input_service != null:
				target_input_service.sync_item_bindings()
			ZoneRuntimePortScript.request_refresh_for(target_zone)
			return false
		var spawned_snapshots: Dictionary = {}
		for index in range(min(spawned_items.size(), moving_items.size())):
			spawned_snapshots[spawned_items[index]] = transfer_snapshots.get(moving_items[index], {})
		var spawned_inserted = target_transfer._insert_transferred_items(spawned_items, final_target, spawned_snapshots)
		if not spawned_inserted:
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Failed to insert spawned items.")
			restore_failed_transfer(moving_items, original_targets)
			return false
		for removed_item in moving_items:
			if removed_indices.has(removed_item):
				transfer_service.runtime_port.emit_item_removed(removed_item, removed_indices[removed_item])
		for source_item in moving_items:
			if is_instance_valid(source_item):
				var items_root = zone.get_items_root()
				if items_root != null and source_item.get_parent() == items_root:
					items_root.remove_child(source_item)
				source_item.queue_free()
		emit_item_transferred(source_zone, target_zone, spawned_items)
	else:
		var inserted = target_transfer._insert_transferred_items(moving_items, final_target, transfer_snapshots)
		if inserted:
			for item in moving_items:
				if not target_context.has_item(item):
					inserted = false
					break
		if not inserted:
			target_transfer.emit_drop_rejected_items(moving_items, source_zone, "Failed to insert items.")
			restore_failed_transfer(moving_items, original_targets)
			return false
		for removed_item in moving_items:
			if removed_indices.has(removed_item):
				transfer_service.runtime_port.emit_item_removed(removed_item, removed_indices[removed_item])
		for item in moving_items:
			item.visible = true
		emit_item_transferred(source_zone, target_zone, moving_items)
	render_service.sync_container_order()
	transfer_service.runtime_port.request_refresh()
	if selection_changed:
		transfer_service.runtime_port.emit_selection_changed()
	transfer_service.runtime_port.emit_layout_changed()
	if source_zone != target_zone:
		ZoneRuntimePortScript.emit_layout_changed_for(target_zone)
		ZoneRuntimePortScript.request_refresh_for(target_zone)
	return true

func insert_transferred_items(moving_items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, transfer_snapshots: Dictionary) -> bool:
	var items_root = zone.get_items_root()
	if items_root == null:
		return false
	var resolved_target = transfer_service.resolve_transfer_target(moving_items, placement_target)
	if resolved_target == null or not resolved_target.is_valid():
		return false
	var target_index = _resolve_linear_insert_index(store.items.size(), resolved_target)
	for offset in range(moving_items.size()):
		var item = moving_items[offset]
		if store.contains_item_reference(item):
			store.erase_item_reference(item)
		if item.get_parent() != items_root:
			if item.get_parent() != null:
				item.reparent(items_root, true)
			else:
				items_root.add_child(item)
		transfer_service.set_transfer_handoff(item, transfer_snapshots.get(item, {}))
		item.visible = true
		input_service.register_item(item)
		store.items.insert(target_index + offset, item)
		store.set_item_target(item, _resolve_reordered_target(resolved_target, target_index + offset))
		transfer_service.runtime_port.emit_item_added(item, target_index + offset)
	render_service.sync_container_order()
	transfer_service.runtime_port.request_refresh()
	return true

func restore_failed_transfer(moving_items: Array[ZoneItemControl], original_targets: Dictionary) -> void:
	var source_root = zone.get_items_root()
	for item in moving_items:
		if not is_instance_valid(item):
			continue
		item.visible = true
		if source_root != null and item.get_parent() != source_root:
			if item.get_parent() != null:
				item.reparent(source_root, true)
			else:
				source_root.add_child(item)
		var original_target = original_targets.get(item, ZonePlacementTarget.invalid())
		if original_target is ZonePlacementTarget and (original_target as ZonePlacementTarget).is_valid():
			store.set_item_target(item, original_target)
	store.rebuild_items_from_root(context, zone.get_items_root())
	input_service.sync_item_bindings()
	transfer_service.runtime_port.request_refresh()

func emit_item_transferred(source_zone: Zone, target_zone: Zone, moving_items: Array[ZoneItemControl]) -> void:
	for item in moving_items:
		var target = target_zone.get_item_target(item)
		ZoneRuntimePortScript.emit_item_transferred_for(target_zone, item, source_zone, target_zone, target)
		if source_zone != target_zone:
			ZoneRuntimePortScript.emit_item_transferred_for(source_zone, item, source_zone, target_zone, target)

func _build_spawned_items(target_context: ZoneContext, source_items: Array[ZoneItemControl], decision: ZoneTransferDecision, placement_target: ZonePlacementTarget) -> Array[ZoneItemControl]:
	var spawned_items: Array[ZoneItemControl] = []
	for source_item in source_items:
		var spawned = _instantiate_spawn_item(target_context, source_item, decision, placement_target)
		if spawned == null:
			continue
		spawned_items.append(spawned)
	return spawned_items

func _instantiate_spawn_item(target_context: ZoneContext, source_item: ZoneItemControl, decision: ZoneTransferDecision, placement_target: ZonePlacementTarget) -> ZoneItemControl:
	if decision.spawn_scene != null:
		var created = decision.spawn_scene.instantiate()
		if created is ZoneItemControl:
			source_item.configure_zone_spawned_item(created as ZoneItemControl, target_context, placement_target)
			return created as ZoneItemControl
	var from_item = source_item.create_zone_spawned_item(target_context, decision, placement_target)
	if from_item != null:
		source_item.configure_zone_spawned_item(from_item, target_context, placement_target)
		return from_item
	return null

func _resolve_linear_insert_index(index_hint: int, target: ZonePlacementTarget) -> int:
	if context.get_space_model() is ZoneLinearSpaceModel:
		if target != null and target.is_linear():
			return clampi(target.linear_index, 0, store.items.size())
		return clampi(index_hint, 0, store.items.size())
	return clampi(index_hint, 0, store.items.size())

func _resolve_reordered_target(base_target: ZonePlacementTarget, linear_index: int) -> ZonePlacementTarget:
	if context.get_space_model() is ZoneLinearSpaceModel:
		return ZonePlacementTarget.linear(linear_index)
	return base_target.duplicate_target() if base_target != null else ZonePlacementTarget.invalid()
