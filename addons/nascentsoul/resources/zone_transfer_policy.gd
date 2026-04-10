@tool
class_name ZoneTransferPolicy extends Resource

const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

func evaluate_drag_start(context: ZoneContext, anchor_item: ZoneItemControl, selected_items: Array[ZoneItemControl]):
	if context == null or not is_instance_valid(anchor_item) or not context.has_item(anchor_item):
		return ZoneDragStartDecisionScript.new(false, "This item can no longer start a drag.", [])
	if selected_items.is_empty() or anchor_item not in selected_items:
		return ZoneDragStartDecisionScript.new(true, "", [anchor_item])
	var ordered_items: Array[ZoneItemControl] = []
	for candidate in context.get_items_ordered():
		if is_instance_valid(candidate) and candidate in selected_items:
			ordered_items.append(candidate)
	if ordered_items.is_empty():
		ordered_items.append(anchor_item)
	return ZoneDragStartDecisionScript.new(true, "", ordered_items)

func evaluate_transfer(_context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	return ZoneTransferDecision.new(true, "", target)
