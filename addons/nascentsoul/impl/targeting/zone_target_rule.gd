@tool
class_name ZoneTargetRule extends Resource

@export var source_item_script: Script
@export var target_item_script: Script
@export var target_zone_name: String = ""
@export var target_candidate_kind: ZoneTargetCandidate.CandidateKind = ZoneTargetCandidate.CandidateKind.NONE
@export var placement_target_kind: ZonePlacementTarget.TargetKind = ZonePlacementTarget.TargetKind.NONE
@export var required_source_meta_key: String = ""
@export var required_source_meta_value: String = ""
@export var required_candidate_meta_key: String = ""
@export var required_candidate_meta_value: String = ""
@export var reject_reason: String = ""
@export var allowed: bool = true

func matches(request: ZoneTargetRequest) -> bool:
	if request == null or request.candidate == null or not request.candidate.is_valid() or not is_instance_valid(request.source_item):
		return false
	if source_item_script != null and request.source_item.get_script() != source_item_script:
		return false
	if target_item_script != null:
		if not is_instance_valid(request.candidate.target_item) or request.candidate.target_item.get_script() != target_item_script:
			return false
	if target_zone_name != "":
		var target_zone = request.candidate.target_zone as Zone
		if target_zone == null or target_zone.name != target_zone_name:
			return false
	if target_candidate_kind != ZoneTargetCandidate.CandidateKind.NONE and request.candidate.kind != target_candidate_kind:
		return false
	if placement_target_kind != ZonePlacementTarget.TargetKind.NONE:
		if request.candidate.placement_target == null or request.candidate.placement_target.kind != placement_target_kind:
			return false
	if not _matches_source_meta(request.source_item):
		return false
	if not _matches_candidate_meta(request.candidate):
		return false
	return true

func build_decision(request: ZoneTargetRequest) -> ZoneTargetDecision:
	var candidate = request.candidate.duplicate_candidate() if request != null and request.candidate != null else ZoneTargetCandidate.invalid()
	return ZoneTargetDecision.new(allowed, reject_reason if not allowed else "", candidate)

func _matches_source_meta(source_item: Control) -> bool:
	if required_source_meta_key == "":
		return true
	if not source_item.has_meta(required_source_meta_key):
		return false
	if required_source_meta_value == "":
		return true
	return str(source_item.get_meta(required_source_meta_key)) == required_source_meta_value

func _matches_candidate_meta(candidate: ZoneTargetCandidate) -> bool:
	if required_candidate_meta_key == "":
		return true
	if not candidate.metadata.has(required_candidate_meta_key):
		return false
	if required_candidate_meta_value == "":
		return true
	return str(candidate.metadata.get(required_candidate_meta_key)) == required_candidate_meta_value
