class_name ZoneDropDecision extends ZoneTransferDecision

func _init(
	p_allowed: bool = true,
	p_reason: String = "",
	p_target_index: int = -1
) -> void:
	var target = ZonePlacementTarget.linear(p_target_index) if p_target_index >= 0 else ZonePlacementTarget.invalid()
	super(p_allowed, p_reason, target)
