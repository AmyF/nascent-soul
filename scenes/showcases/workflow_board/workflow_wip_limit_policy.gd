@tool
extends ZoneTransferPolicy

@export var wip_limit: int = 3
@export var lane_label: String = "In Progress"

func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if request == null:
		return ZoneTransferDecision.new(false, "Invalid transfer.", ZonePlacementTarget.invalid())
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	if request.is_reorder() or wip_limit < 0:
		return ZoneTransferDecision.new(true, "", target)
	if context != null and context.get_item_count() + request.items.size() > wip_limit:
		return ZoneTransferDecision.new(false, "Keep %s at %d tasks or fewer." % [lane_label, wip_limit], target)
	return ZoneTransferDecision.new(true, "", target)
