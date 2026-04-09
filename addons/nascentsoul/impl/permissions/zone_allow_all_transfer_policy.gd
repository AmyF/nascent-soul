@tool
class_name ZoneAllowAllTransferPolicy extends ZoneTransferPolicy

func evaluate_transfer(_context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	return ZoneTransferDecision.new(true, "", target)
