@tool
class_name ZonePermissionPolicy extends ZoneTransferPolicy

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	var decision = evaluate_transfer(request)
	if decision == null:
		return ZoneDropDecision.new(true, "", request.requested_index)
	return ZoneDropDecision.new(decision.allowed, decision.reason, decision.target_index)

func evaluate_transfer(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	return ZoneTransferDecision.new(true, "", target)
