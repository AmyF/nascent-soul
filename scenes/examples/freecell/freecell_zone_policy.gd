extends ZoneTransferPolicy

var controller = null
var zone_role: StringName = &""
var zone_index: int = -1

func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if controller == null or not controller.has_method("evaluate_freecell_transfer"):
		return ZoneTransferDecision.new(false, "FreeCell controller unavailable.", ZonePlacementTarget.invalid())
	return controller.evaluate_freecell_transfer(zone_role, zone_index, context, request)
