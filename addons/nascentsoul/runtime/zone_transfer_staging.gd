class_name ZoneTransferStaging extends RefCounted

var _transfer_handoffs: Dictionary = {}

func cleanup() -> void:
	_transfer_handoffs.clear()

func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	var snapshots: Dictionary = {}
	if moving_items.is_empty():
		return snapshots
	for item in moving_items:
		if is_instance_valid(item):
			snapshots[item] = _snapshot_item_visual_state(item)
	if drop_position is not Vector2:
		return snapshots
	var resolved_drop_position: Vector2 = drop_position
	var primary_item = anchor_item if is_instance_valid(anchor_item) and anchor_item in moving_items else moving_items[0]
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

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	if not is_instance_valid(item):
		return
	if snapshot.is_empty():
		_transfer_handoffs.erase(item)
		return
	_transfer_handoffs[item] = snapshot.duplicate(true)

func clear_transfer_handoff(item) -> void:
	if item == null:
		return
	_transfer_handoffs.erase(item)

func clear_transfer_handoffs() -> void:
	_transfer_handoffs.clear()

func get_transfer_handoff_count() -> int:
	return _transfer_handoffs.size()

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	if not is_instance_valid(item):
		return false
	return _transfer_handoffs.has(item)

func consume_transfer_handoff(item: ZoneItemControl) -> Dictionary:
	if not is_instance_valid(item) or not _transfer_handoffs.has(item):
		return {}
	var handoff: Dictionary = _transfer_handoffs[item]
	_transfer_handoffs.erase(item)
	return handoff.duplicate(true)

func _snapshot_item_visual_state(item: ZoneItemControl) -> Dictionary:
	if not is_instance_valid(item):
		return {}
	return {
		"global_position": item.global_position,
		"rotation": item.rotation,
		"scale": item.scale
	}
