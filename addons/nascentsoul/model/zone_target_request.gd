class_name ZoneTargetRequest extends RefCounted

# Public request payload passed into ZoneTargetingPolicy implementations.

var source_zone: Node = null
var source_item: Control = null
var intent: ZoneTargetingIntent = null
var candidate: ZoneTargetCandidate = null
var global_position: Vector2 = Vector2.ZERO

func _init(
	p_source_zone: Node = null,
	p_source_item: Control = null,
	p_intent: ZoneTargetingIntent = null,
	p_candidate: ZoneTargetCandidate = null,
	p_global_position: Vector2 = Vector2.ZERO
) -> void:
	source_zone = p_source_zone
	source_item = p_source_item
	intent = p_intent.duplicate_intent() if p_intent != null else null
	candidate = p_candidate.duplicate_candidate() if p_candidate != null else ZoneTargetCandidate.invalid(p_global_position)
	global_position = p_global_position
