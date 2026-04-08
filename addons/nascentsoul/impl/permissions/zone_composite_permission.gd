@tool
class_name ZoneCompositePermission extends ZonePermissionPolicy

enum CombineMode {
	ALL,
	ANY
}

@export var combine_mode: CombineMode = CombineMode.ALL
@export var policies: Array[ZonePermissionPolicy] = []
@export var fallback_reject_reason: String = "This zone rejected the drop."

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	var valid_policies: Array[ZonePermissionPolicy] = []
	for policy in policies:
		if policy != null and policy != self:
			valid_policies.append(policy)
	if valid_policies.is_empty():
		return ZoneDropDecision.new(true, "", request.requested_index)
	if combine_mode == CombineMode.ANY:
		return _evaluate_any(valid_policies, request)
	return _evaluate_all(valid_policies, request)

func _evaluate_all(valid_policies: Array[ZonePermissionPolicy], request: ZoneDropRequest) -> ZoneDropDecision:
	var target_index = request.requested_index
	for policy in valid_policies:
		var decision = _evaluate_policy(policy, request)
		if decision == null:
			continue
		if not decision.allowed:
			return ZoneDropDecision.new(false, _resolve_reason(decision.reason), _resolve_target_index(decision.target_index, target_index))
		target_index = _resolve_target_index(decision.target_index, target_index)
	return ZoneDropDecision.new(true, "", target_index)

func _evaluate_any(valid_policies: Array[ZonePermissionPolicy], request: ZoneDropRequest) -> ZoneDropDecision:
	var fallback_reason = ""
	var target_index = request.requested_index
	for policy in valid_policies:
		var decision = _evaluate_policy(policy, request)
		if decision == null:
			continue
		if decision.allowed:
			return ZoneDropDecision.new(true, "", _resolve_target_index(decision.target_index, target_index))
		if fallback_reason == "" and decision.reason != "":
			fallback_reason = decision.reason
		target_index = _resolve_target_index(decision.target_index, target_index)
	return ZoneDropDecision.new(false, _resolve_reason(fallback_reason), target_index)

func _evaluate_policy(policy: ZonePermissionPolicy, request: ZoneDropRequest) -> ZoneDropDecision:
	if policy == null:
		return null
	return policy.evaluate_drop(request)

func _resolve_target_index(candidate: int, fallback: int) -> int:
	return candidate if candidate >= 0 else fallback

func _resolve_reason(candidate: String) -> String:
	return candidate if candidate != "" else fallback_reject_reason
