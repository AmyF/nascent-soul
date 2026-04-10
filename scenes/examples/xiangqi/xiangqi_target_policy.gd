extends ZoneTargetingPolicy

var controller = null

func evaluate_target(_context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision:
	if controller == null or not controller.has_method("evaluate_xiangqi_target"):
		return ZoneTargetDecision.new(false, "Xiangqi controller unavailable.", ZoneTargetCandidate.invalid())
	return controller.evaluate_xiangqi_target(request)
