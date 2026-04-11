class_name ZoneTargetDecision extends RefCounted

# Public decision contract returned by targeting policies and hover feedback.

var allowed: bool = false
var reason: String = ""
var resolved_candidate: ZoneTargetCandidate = null
var metadata: Dictionary = {}

func _init(
	p_allowed: bool = false,
	p_reason: String = "",
	p_resolved_candidate: ZoneTargetCandidate = null,
	p_metadata: Dictionary = {}
) -> void:
	allowed = p_allowed
	reason = p_reason
	resolved_candidate = p_resolved_candidate.duplicate_candidate() if p_resolved_candidate != null else ZoneTargetCandidate.invalid()
	metadata = p_metadata.duplicate(true)

func duplicate_decision() -> ZoneTargetDecision:
	return ZoneTargetDecision.new(allowed, reason, resolved_candidate, metadata)
