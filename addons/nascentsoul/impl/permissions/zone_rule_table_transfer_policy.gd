@tool
class_name ZoneRuleTableTransferPolicy extends ZoneTransferPolicy

@export var rules: Array[ZoneTransferRule] = []

func evaluate_transfer(_context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	var fallback_target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	for rule in rules:
		if rule == null or not rule.matches(request):
			continue
		return rule.build_decision(request)
	return ZoneTransferDecision.new(true, "", fallback_target)
