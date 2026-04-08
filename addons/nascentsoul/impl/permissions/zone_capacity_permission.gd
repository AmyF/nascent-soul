@tool
class_name ZoneCapacityPermission extends ZonePermissionPolicy

@export var max_items: int = 7
@export var reject_reason: String = "This zone is full."

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	if max_items < 0:
		return ZoneDropDecision.new(true, "", request.requested_index)
	var target_zone = request.target_zone as Zone
	if target_zone == null:
		return ZoneDropDecision.new(true, "", request.requested_index)
	if request.is_reorder():
		return ZoneDropDecision.new(true, "", request.requested_index)
	if target_zone.get_item_count() + request.items.size() > max_items:
		return ZoneDropDecision.new(false, reject_reason, request.requested_index)
	return ZoneDropDecision.new(true, "", request.requested_index)
