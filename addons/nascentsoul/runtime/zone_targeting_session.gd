class_name ZoneTargetingSession extends RefCounted

var source_zone: Node = null
var source_item: Control = null
var intent: ZoneTargetingIntent = null
var entry_mode: StringName = &""
var source_anchor_global: Vector2 = Vector2.ZERO
var pointer_global_position: Vector2 = Vector2.ZERO
var candidate: ZoneTargetCandidate = ZoneTargetCandidate.invalid()
var decision: ZoneTargetDecision = ZoneTargetDecision.new()

func _init(
	p_source_zone: Node = null,
	p_source_item: Control = null,
	p_intent: ZoneTargetingIntent = null,
	p_entry_mode: StringName = &"",
	p_source_anchor_global: Vector2 = Vector2.ZERO,
	p_pointer_global_position: Vector2 = Vector2.ZERO
) -> void:
	source_zone = p_source_zone
	source_item = p_source_item
	intent = p_intent.duplicate_intent() if p_intent != null else null
	entry_mode = p_entry_mode
	source_anchor_global = p_source_anchor_global
	pointer_global_position = p_pointer_global_position

func cleanup() -> void:
	source_zone = null
	source_item = null
	intent = null
	candidate = ZoneTargetCandidate.invalid()
	decision = ZoneTargetDecision.new()
