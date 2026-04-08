@tool
class_name ZoneAllowAllPermission extends ZonePermissionPolicy

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	return ZoneDropDecision.new(true, "", request.requested_index)
