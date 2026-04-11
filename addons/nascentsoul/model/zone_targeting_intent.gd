@tool
class_name ZoneTargetingIntent extends Resource

# Public targeting intent resource attached to items and targeting commands.

@export var policy: ZoneTargetingPolicy
@export var style_override: ZoneTargetingStyle
@export var allowed_candidate_kinds: PackedInt32Array = PackedInt32Array([
	ZoneTargetCandidate.CandidateKind.ITEM,
	ZoneTargetCandidate.CandidateKind.PLACEMENT
])
@export var metadata: Dictionary = {}

func duplicate_intent() -> ZoneTargetingIntent:
	var duplicated := ZoneTargetingIntent.new()
	duplicated.policy = policy
	duplicated.style_override = style_override
	duplicated.allowed_candidate_kinds = allowed_candidate_kinds.duplicate()
	duplicated.metadata = metadata.duplicate(true)
	return duplicated

func allows_candidate_kind(kind: int) -> bool:
	if allowed_candidate_kinds.is_empty():
		return true
	return kind in allowed_candidate_kinds
