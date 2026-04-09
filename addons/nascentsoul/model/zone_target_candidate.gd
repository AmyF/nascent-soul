class_name ZoneTargetCandidate extends RefCounted

enum CandidateKind {
	NONE,
	ITEM,
	PLACEMENT
}

var kind: CandidateKind = CandidateKind.NONE
var target_zone: Node = null
var target_item: Control = null
var placement_target: ZonePlacementTarget = null
var global_position: Vector2 = Vector2.ZERO
var local_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}

func _init(
	p_kind: CandidateKind = CandidateKind.NONE,
	p_target_zone: Node = null,
	p_target_item: Control = null,
	p_placement_target: ZonePlacementTarget = null,
	p_global_position: Vector2 = Vector2.ZERO,
	p_local_position: Vector2 = Vector2.ZERO,
	p_metadata: Dictionary = {}
) -> void:
	kind = p_kind
	target_zone = p_target_zone
	target_item = p_target_item
	placement_target = p_placement_target.duplicate_target() if p_placement_target != null else ZonePlacementTarget.invalid()
	global_position = p_global_position
	local_position = p_local_position
	metadata = p_metadata.duplicate(true)

static func invalid(p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}) -> ZoneTargetCandidate:
	return ZoneTargetCandidate.new(CandidateKind.NONE, null, null, ZonePlacementTarget.invalid(), p_global_position, p_local_position, p_metadata)

static func item(
	p_target_zone: Node,
	p_target_item: Control,
	p_placement_target: ZonePlacementTarget = null,
	p_global_position: Vector2 = Vector2.ZERO,
	p_local_position: Vector2 = Vector2.ZERO,
	p_metadata: Dictionary = {}
) -> ZoneTargetCandidate:
	return ZoneTargetCandidate.new(CandidateKind.ITEM, p_target_zone, p_target_item, p_placement_target, p_global_position, p_local_position, p_metadata)

static func placement(
	p_target_zone: Node,
	p_placement_target: ZonePlacementTarget,
	p_global_position: Vector2 = Vector2.ZERO,
	p_local_position: Vector2 = Vector2.ZERO,
	p_metadata: Dictionary = {}
) -> ZoneTargetCandidate:
	return ZoneTargetCandidate.new(CandidateKind.PLACEMENT, p_target_zone, null, p_placement_target, p_global_position, p_local_position, p_metadata)

func is_valid() -> bool:
	match kind:
		CandidateKind.ITEM:
			return target_zone != null and is_instance_valid(target_item)
		CandidateKind.PLACEMENT:
			return target_zone != null and placement_target != null and placement_target.is_valid()
		_:
			return false

func is_item() -> bool:
	return kind == CandidateKind.ITEM and is_valid()

func is_placement() -> bool:
	return kind == CandidateKind.PLACEMENT and is_valid()

func duplicate_candidate() -> ZoneTargetCandidate:
	return ZoneTargetCandidate.new(kind, target_zone, target_item, placement_target, global_position, local_position, metadata)

func matches(other: ZoneTargetCandidate) -> bool:
	if other == null:
		return false
	if kind != other.kind:
		return false
	match kind:
		CandidateKind.ITEM:
			return target_zone == other.target_zone and target_item == other.target_item
		CandidateKind.PLACEMENT:
			if target_zone != other.target_zone:
				return false
			if placement_target == null or other.placement_target == null:
				return placement_target == other.placement_target
			return placement_target.matches(other.placement_target)
		_:
			return not is_valid() and not other.is_valid()

func describe() -> String:
	match kind:
		CandidateKind.ITEM:
			return "item:%s" % [target_item.name if is_instance_valid(target_item) else "invalid"]
		CandidateKind.PLACEMENT:
			return "placement:%s" % [placement_target.describe() if placement_target != null else "invalid"]
		_:
			return "invalid"
