class_name ZoneTransferDecisionResolver extends RefCounted

var context: ZoneContext = null

func _init(p_context: ZoneContext) -> void:
	context = p_context

func cleanup() -> void:
	context = null

func make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	return ZoneTransferRequest.new(target_zone, source_zone, items, placement_target, global_position)

func resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var decision = _evaluate_drop_request(request)
	if decision == null:
		decision = ZoneTransferDecision.new(true, "", request.placement_target)
	# Policies may allow/reject without rewriting geometry. Preserve the requested
	# target so preview and execution keep talking about the same slot or cell.
	if (decision.resolved_target == null or not decision.resolved_target.is_valid()) and request.placement_target != null and request.placement_target.is_valid():
		return ZoneTransferDecision.new(decision.allowed, decision.reason, request.placement_target, decision.transfer_mode, decision.spawn_scene, decision.metadata)
	return decision

func update_hover_preview_session(target_zone: Zone, session: ZoneDragSession, visible_items: Array[ZoneItemControl], global_position: Vector2, local_position: Vector2) -> ZoneTransferDecision:
	var space_model = context.get_space_model()
	if space_model == null:
		return null
	# Hover preview always resolves through the target zone's space model first,
	# then lets the transfer policy accept or reject that normalized geometry.
	var requested_target = space_model.resolve_hover_target(context, visible_items, global_position, local_position)
	requested_target = space_model.normalize_target(context, requested_target, session.items)
	var request = make_transfer_request(target_zone, session.source_zone, session.items, requested_target, global_position)
	var decision = resolve_drop_decision(request)
	session.hover_zone = target_zone
	session.requested_target = requested_target
	session.preview_target = decision.resolved_target if decision.allowed else ZonePlacementTarget.invalid()
	return decision

func _evaluate_drop_request(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	var space_model = context.get_space_model()
	if space_model == null:
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	# Invalid geometry is a hard gate; policies only evaluate targets that the
	# zone's space model already considers meaningful.
	if not space_model.is_target_valid(context, target):
		return ZoneTransferDecision.new(false, "This zone rejected the drop target.", ZonePlacementTarget.invalid())
	var decision = ZoneTransferDecision.new(true, "", target)
	var transfer_policy = context.get_transfer_policy()
	if transfer_policy != null:
		decision = transfer_policy.evaluate_transfer(context, request)
	if decision == null:
		return ZoneTransferDecision.new(true, "", target)
	return decision
