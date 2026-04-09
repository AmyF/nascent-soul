@tool
class_name ZoneTargetRuleTablePolicy extends ZoneTargetingPolicy

@export var rules: Array[ZoneTargetRule] = []

func evaluate_target(request: ZoneTargetRequest) -> ZoneTargetDecision:
	var fallback_candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	for rule in rules:
		if rule == null or not rule.matches(request):
			continue
		return rule.build_decision(request)
	return ZoneTargetDecision.new(fallback_candidate.is_valid(), "", fallback_candidate)
