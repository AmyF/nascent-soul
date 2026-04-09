class_name ZoneTransferRequest extends RefCounted

var target_zone: Node = null
var source_zone: Node = null
var items: Array[Control] = []
var placement_target: ZonePlacementTarget = null
var global_position: Vector2 = Vector2.ZERO

var requested_index: int:
	get:
		if placement_target == null or not placement_target.is_linear():
			return -1
		return placement_target.slot
	set(value):
		if value < 0:
			placement_target = ZonePlacementTarget.invalid()
			return
		var existing_global = placement_target.global_position if placement_target != null else Vector2.ZERO
		var existing_local = placement_target.local_position if placement_target != null else Vector2.ZERO
		placement_target = ZonePlacementTarget.linear(value, existing_global, existing_local)

func _init(
	p_target_zone: Node = null,
	p_source_zone: Node = null,
	p_items: Array[Control] = [],
	p_placement_target: ZonePlacementTarget = null,
	p_global_position: Vector2 = Vector2.ZERO
) -> void:
	target_zone = p_target_zone
	source_zone = p_source_zone
	items = p_items.duplicate()
	placement_target = p_placement_target.duplicate_target() if p_placement_target != null else ZonePlacementTarget.invalid()
	global_position = p_global_position

func is_reorder() -> bool:
	return target_zone != null and target_zone == source_zone
