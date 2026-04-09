@tool
class_name ZoneTargetAllowAllPolicy extends ZoneTargetingPolicy

func evaluate_target(_context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision:
	var candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	return ZoneTargetDecision.new(candidate.is_valid(), "", candidate)
