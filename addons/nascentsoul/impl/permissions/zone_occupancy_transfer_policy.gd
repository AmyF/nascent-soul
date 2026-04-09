@tool
class_name ZoneOccupancyTransferPolicy extends ZoneTransferPolicy

@export var allow_multiple_items_per_target: bool = false
@export var reject_reason: String = "This cell is occupied."

func evaluate_transfer(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	if allow_multiple_items_per_target or target == null or not target.is_valid():
		return ZoneTransferDecision.new(true, "", target)
	var target_zone = request.target_zone as Zone
	if target_zone == null:
		return ZoneTransferDecision.new(true, "", target)
	var occupants = target_zone.get_items_at_target(target)
	var moving_ids: Dictionary = {}
	for item in request.items:
		if is_instance_valid(item):
			moving_ids[item.get_instance_id()] = true
	var blocking_items: Array[Control] = []
	for occupant in occupants:
		if is_instance_valid(occupant) and not moving_ids.has(occupant.get_instance_id()):
			blocking_items.append(occupant)
	if blocking_items.is_empty():
		return ZoneTransferDecision.new(true, "", target)
	return ZoneTransferDecision.new(false, reject_reason, target)
