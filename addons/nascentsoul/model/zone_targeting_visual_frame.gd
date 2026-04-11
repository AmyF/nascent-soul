class_name ZoneTargetingVisualFrame extends RefCounted

# Public overlay-frame payload used by layered targeting styles and layers.

enum VisualState {
	NEUTRAL,
	VALID,
	INVALID
}

var active: bool = false
var source_anchor: Vector2 = Vector2.ZERO
var end_anchor: Vector2 = Vector2.ZERO
var pointer_global_position: Vector2 = Vector2.ZERO
var candidate: ZoneTargetCandidate = ZoneTargetCandidate.invalid()
var decision: ZoneTargetDecision = ZoneTargetDecision.new()
var visual_state: VisualState = VisualState.NEUTRAL
var show_endpoint: bool = false
var is_item_target: bool = false
var is_placement_target: bool = false
var metadata: Dictionary = {}

func get_resolved_candidate() -> ZoneTargetCandidate:
	if decision != null and decision.resolved_candidate != null and decision.resolved_candidate.is_valid():
		return decision.resolved_candidate
	return candidate

func duplicate_frame() -> ZoneTargetingVisualFrame:
	var duplicated := ZoneTargetingVisualFrame.new()
	duplicated.active = active
	duplicated.source_anchor = source_anchor
	duplicated.end_anchor = end_anchor
	duplicated.pointer_global_position = pointer_global_position
	duplicated.candidate = candidate.duplicate_candidate() if candidate != null else ZoneTargetCandidate.invalid()
	duplicated.decision = decision.duplicate_decision() if decision != null else ZoneTargetDecision.new()
	duplicated.visual_state = visual_state
	duplicated.show_endpoint = show_endpoint
	duplicated.is_item_target = is_item_target
	duplicated.is_placement_target = is_placement_target
	duplicated.metadata = metadata.duplicate(true)
	return duplicated
