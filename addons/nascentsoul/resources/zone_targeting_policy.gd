@tool
class_name ZoneTargetingPolicy extends Resource

# Public extension point for targeting rules used from ZoneConfig.

## Returns whether request.candidate is allowed and may replace it with a normalized resolved_candidate.
func evaluate_target(_context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision:
	var candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	return ZoneTargetDecision.new(candidate.is_valid(), "", candidate)
