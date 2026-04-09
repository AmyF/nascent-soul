@tool
class_name ZoneSourceTransferPolicy extends ZoneTransferPolicy

@export var allowed_source_zone_names: PackedStringArray = []
@export var allow_same_zone: bool = true
@export var allow_external_source: bool = true
@export var reject_reason: String = "This zone does not accept cards from that source."

func evaluate_transfer(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	var source_zone = request.source_zone as Zone
	if source_zone == null:
		return ZoneTransferDecision.new(allow_external_source, reject_reason, target)
	if source_zone == request.target_zone:
		return ZoneTransferDecision.new(allow_same_zone, reject_reason, target)
	if allowed_source_zone_names.is_empty() or source_zone.name in allowed_source_zone_names:
		return ZoneTransferDecision.new(true, "", target)
	return ZoneTransferDecision.new(false, reject_reason, target)
