@tool
class_name ZoneTargetingPolicy extends Resource

func evaluate_target(request: ZoneTargetRequest) -> ZoneTargetDecision:
	var candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	return ZoneTargetDecision.new(candidate.is_valid(), "", candidate)
