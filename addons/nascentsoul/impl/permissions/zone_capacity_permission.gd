@tool
class_name ZoneCapacityPermission extends ZoneTransferPolicy

@export var max_items: int = 7
@export var reject_reason: String = "This zone is full."

func evaluate_transfer(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	if max_items < 0:
		return ZoneTransferDecision.new(true, "", target)
	var target_zone = request.target_zone as Zone
	if target_zone == null:
		return ZoneTransferDecision.new(true, "", target)
	if request.is_reorder():
		return ZoneTransferDecision.new(true, "", target)
	if target_zone.get_item_count() + request.items.size() > max_items:
		return ZoneTransferDecision.new(false, reject_reason, target)
	return ZoneTransferDecision.new(true, "", target)
