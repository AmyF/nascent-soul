@tool
class_name ZoneSourcePermission extends ZonePermissionPolicy

@export var allowed_source_zone_names: PackedStringArray = []
@export var allow_same_zone: bool = true
@export var allow_external_source: bool = true
@export var reject_reason: String = "This zone does not accept cards from that source."

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	var source_zone = request.source_zone as Zone
	if source_zone == null:
		return ZoneDropDecision.new(allow_external_source, reject_reason, request.requested_index)
	if source_zone == request.target_zone:
		return ZoneDropDecision.new(allow_same_zone, reject_reason, request.requested_index)
	if allowed_source_zone_names.is_empty() or source_zone.name in allowed_source_zone_names:
		return ZoneDropDecision.new(true, "", request.requested_index)
	return ZoneDropDecision.new(false, reject_reason, request.requested_index)
