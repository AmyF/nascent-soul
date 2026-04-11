extends RefCounted

# Internal helper for transfer target normalization and policy evaluation.

var context: ZoneContext = null

func _init(p_context: ZoneContext) -> void:
	context = p_context

func cleanup() -> void:
	context = null

func resolve_transfer_target(items: Array[ZoneItemControl], placement_target: ZonePlacementTarget) -> ZonePlacementTarget:
	var space_model = context.get_space_model()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	if placement_target != null and placement_target.is_valid():
		return space_model.normalize_target(context, placement_target, items)
	var reference_item = items[0] if not items.is_empty() else null
	return space_model.resolve_add_target(context, reference_item, null)

func make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	return ZoneTransferRequest.new(target_zone, source_zone, items, placement_target, global_position)

func evaluate_drop_request(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	var space_model = context.get_space_model()
	if space_model == null:
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	if not space_model.is_target_valid(context, target):
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	var decision = ZoneTransferDecision.new(true, "", target)
	var transfer_policy = context.get_transfer_policy()
	if transfer_policy != null:
		decision = transfer_policy.evaluate_transfer(context, request)
	if decision == null:
		return ZoneTransferDecision.new(true, "", target)
	return decision

func resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var decision = evaluate_drop_request(request)
	if decision == null:
		decision = ZoneTransferDecision.new(true, "", request.placement_target)
	if (decision.resolved_target == null or not decision.resolved_target.is_valid()) and request.placement_target != null and request.placement_target.is_valid():
		return ZoneTransferDecision.new(decision.allowed, decision.reason, request.placement_target, decision.transfer_mode, decision.spawn_scene, decision.metadata)
	return decision
