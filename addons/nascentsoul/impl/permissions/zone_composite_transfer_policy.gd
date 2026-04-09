@tool
class_name ZoneCompositeTransferPolicy extends ZoneTransferPolicy

enum CombineMode {
	ALL,
	ANY
}

@export var combine_mode: CombineMode = CombineMode.ALL
@export var policies: Array[ZoneTransferPolicy] = []
@export var fallback_reject_reason: String = "This zone rejected the drop."

func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	var valid_policies: Array[ZoneTransferPolicy] = []
	for policy in policies:
		if policy != null and policy != self:
			valid_policies.append(policy)
	if valid_policies.is_empty():
		return ZoneTransferDecision.new(true, "", request.placement_target)
	if combine_mode == CombineMode.ANY:
		return _evaluate_any(context, valid_policies, request)
	return _evaluate_all(context, valid_policies, request)

func _evaluate_all(context: ZoneContext, valid_policies: Array[ZoneTransferPolicy], request: ZoneTransferRequest) -> ZoneTransferDecision:
	var resolved_target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	var transfer_mode = ZoneTransferDecision.TransferMode.DIRECT_PLACE
	var spawn_scene: PackedScene = null
	for policy in valid_policies:
		var decision = _evaluate_policy(context, policy, request)
		if decision == null:
			continue
		if not decision.allowed:
			return ZoneTransferDecision.new(false, _resolve_reason(decision.reason), _resolve_target(decision.resolved_target, resolved_target), decision.transfer_mode, decision.spawn_scene, decision.metadata)
		resolved_target = _resolve_target(decision.resolved_target, resolved_target)
		transfer_mode = decision.transfer_mode
		if decision.spawn_scene != null:
			spawn_scene = decision.spawn_scene
	return ZoneTransferDecision.new(true, "", resolved_target, transfer_mode, spawn_scene)

func _evaluate_any(context: ZoneContext, valid_policies: Array[ZoneTransferPolicy], request: ZoneTransferRequest) -> ZoneTransferDecision:
	var fallback_reason = ""
	var resolved_target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	for policy in valid_policies:
		var decision = _evaluate_policy(context, policy, request)
		if decision == null:
			continue
		if decision.allowed:
			return ZoneTransferDecision.new(true, "", _resolve_target(decision.resolved_target, resolved_target), decision.transfer_mode, decision.spawn_scene, decision.metadata)
		if fallback_reason == "" and decision.reason != "":
			fallback_reason = decision.reason
		resolved_target = _resolve_target(decision.resolved_target, resolved_target)
	return ZoneTransferDecision.new(false, _resolve_reason(fallback_reason), resolved_target)

func _evaluate_policy(context: ZoneContext, policy: ZoneTransferPolicy, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if policy == null:
		return null
	return policy.evaluate_transfer(context, request)

func _resolve_target(candidate: ZonePlacementTarget, fallback: ZonePlacementTarget) -> ZonePlacementTarget:
	if candidate != null and candidate.is_valid():
		return candidate.duplicate_target()
	return fallback.duplicate_target() if fallback != null else ZonePlacementTarget.invalid()

func _resolve_reason(candidate: String) -> String:
	return candidate if candidate != "" else fallback_reject_reason
