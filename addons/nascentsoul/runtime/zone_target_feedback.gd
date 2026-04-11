extends RefCounted

# Internal helper for targeting hover state, highlighting, and signal emission.

var zone = null

var candidate: ZoneTargetCandidate = ZoneTargetCandidate.invalid()
var decision: ZoneTargetDecision = ZoneTargetDecision.new()
var highlight_item: ZoneItemControl = null

func _init(p_zone) -> void:
	zone = p_zone

func cleanup() -> void:
	clear_targeting_feedback(false)
	highlight_item = null
	candidate = ZoneTargetCandidate.invalid()
	decision = ZoneTargetDecision.new()
	zone = null

func apply_targeting_feedback(session: ZoneTargetingSession, next_candidate: ZoneTargetCandidate, next_decision: ZoneTargetDecision) -> void:
	var previous_candidate = candidate.duplicate_candidate()
	var previous_decision = decision.duplicate_decision()
	session.candidate = next_candidate.duplicate_candidate() if next_candidate != null else ZoneTargetCandidate.invalid()
	session.decision = next_decision.duplicate_decision() if next_decision != null else ZoneTargetDecision.new()
	candidate = session.candidate.duplicate_candidate()
	decision = session.decision.duplicate_decision()
	var next_item = session.decision.resolved_candidate.target_item if session.decision != null and session.decision.resolved_candidate != null and session.decision.resolved_candidate.is_valid() and is_instance_valid(session.decision.resolved_candidate.target_item) else session.candidate.target_item if session.candidate != null and is_instance_valid(session.candidate.target_item) else null
	var next_allowed = session.decision != null and session.decision.allowed
	if highlight_item != next_item or (next_item != null and previous_decision.allowed != next_allowed):
		_set_target_candidate_visual(highlight_item, false, previous_decision.allowed)
		highlight_item = next_item
		_set_target_candidate_visual(highlight_item, highlight_item != null, next_allowed)
	if not _target_candidates_match(previous_candidate, session.candidate):
		zone._emit_target_preview_changed(session.source_item, session.candidate.target_zone, session.candidate)
	if not _target_decisions_match(previous_decision, session.decision):
		zone._emit_target_hover_state_changed(session.source_item, session.candidate.target_zone, session.decision)

func clear_targeting_feedback(emit_clear_signals: bool, source_item: ZoneItemControl = null) -> void:
	var had_candidate = candidate != null and candidate.is_valid()
	if is_instance_valid(highlight_item):
		_set_target_candidate_visual(highlight_item, false, decision.allowed if decision != null else false)
	highlight_item = null
	if emit_clear_signals and had_candidate:
		zone._emit_target_preview_changed(source_item, null, ZoneTargetCandidate.invalid())
		zone._emit_target_hover_state_changed(source_item, null, ZoneTargetDecision.new())
	candidate = ZoneTargetCandidate.invalid()
	decision = ZoneTargetDecision.new()

func _set_target_candidate_visual(item: ZoneItemControl, active: bool, allowed: bool) -> void:
	if not is_instance_valid(item):
		return
	item.set_zone_target_candidate_visual(active, allowed)

func _target_candidates_match(a: ZoneTargetCandidate, b: ZoneTargetCandidate) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.matches(b)

func _target_decisions_match(a: ZoneTargetDecision, b: ZoneTargetDecision) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.allowed == b.allowed and a.reason == b.reason and _target_candidates_match(a.resolved_candidate, b.resolved_candidate)
