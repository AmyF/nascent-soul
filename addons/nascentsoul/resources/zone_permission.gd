@tool
class_name ZonePermissionPolicy extends Resource

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	return ZoneDropDecision.new(true, "", request.requested_index)
