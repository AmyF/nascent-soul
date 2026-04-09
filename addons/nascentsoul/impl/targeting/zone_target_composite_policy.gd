@tool
class_name ZoneTargetCompositePolicy extends ZoneTargetingPolicy

enum CombineMode {
	ALL,
	ANY
}

@export var combine_mode: CombineMode = CombineMode.ALL
@export var policies: Array[ZoneTargetingPolicy] = []
@export var fallback_reject_reason: String = "This target was rejected."

func evaluate_target(request: ZoneTargetRequest) -> ZoneTargetDecision:
	var valid_policies: Array[ZoneTargetingPolicy] = []
	for policy in policies:
		if policy != null and policy != self:
			valid_policies.append(policy)
	if valid_policies.is_empty():
		return ZoneTargetDecision.new(request != null and request.candidate != null and request.candidate.is_valid(), "", request.candidate if request != null else null)
	if combine_mode == CombineMode.ANY:
		return _evaluate_any(valid_policies, request)
	return _evaluate_all(valid_policies, request)

func _evaluate_all(valid_policies: Array[ZoneTargetingPolicy], request: ZoneTargetRequest) -> ZoneTargetDecision:
	var resolved_candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	var metadata: Dictionary = {}
	for policy in valid_policies:
		var next_request = ZoneTargetRequest.new(request.source_zone, request.source_item, request.intent, resolved_candidate, request.global_position)
		var decision = policy.evaluate_target(next_request)
		if decision == null:
			continue
		metadata.merge(decision.metadata, true)
		if not decision.allowed:
			return ZoneTargetDecision.new(false, _resolve_reason(decision.reason), _resolve_candidate(decision.resolved_candidate, resolved_candidate), metadata)
		resolved_candidate = _resolve_candidate(decision.resolved_candidate, resolved_candidate)
	return ZoneTargetDecision.new(resolved_candidate.is_valid(), "", resolved_candidate, metadata)

func _evaluate_any(valid_policies: Array[ZoneTargetingPolicy], request: ZoneTargetRequest) -> ZoneTargetDecision:
	var fallback_reason = ""
	var resolved_candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	for policy in valid_policies:
		var decision = policy.evaluate_target(ZoneTargetRequest.new(request.source_zone, request.source_item, request.intent, resolved_candidate, request.global_position))
		if decision == null:
			continue
		if decision.allowed:
			return ZoneTargetDecision.new(true, "", _resolve_candidate(decision.resolved_candidate, resolved_candidate), decision.metadata)
		if fallback_reason == "" and decision.reason != "":
			fallback_reason = decision.reason
	return ZoneTargetDecision.new(false, _resolve_reason(fallback_reason), resolved_candidate)

func _resolve_candidate(candidate: ZoneTargetCandidate, fallback: ZoneTargetCandidate) -> ZoneTargetCandidate:
	if candidate != null and candidate.is_valid():
		return candidate.duplicate_candidate()
	return fallback.duplicate_candidate() if fallback != null else ZoneTargetCandidate.invalid()

func _resolve_reason(candidate: String) -> String:
	return candidate if candidate != "" else fallback_reject_reason
