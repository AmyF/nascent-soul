class_name ZoneDropRequest extends ZoneTransferRequest

func _init(
	p_target_zone: Node = null,
	p_source_zone: Node = null,
	p_items: Array[Control] = [],
	p_requested_index: int = -1,
	p_global_position: Vector2 = Vector2.ZERO
) -> void:
	var target = ZonePlacementTarget.linear(p_requested_index, p_global_position) if p_requested_index >= 0 else ZonePlacementTarget.invalid()
	super(p_target_zone, p_source_zone, p_items, target, p_global_position)
