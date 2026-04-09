@tool
class_name ZoneTargetingStyle extends Resource

func create_overlay(_context: ZoneContext, _coordinator: Node) -> Control:
	return null

func update_overlay(_context: ZoneContext, _overlay: Control, _session, _source_anchor: Vector2, _candidate: ZoneTargetCandidate, _decision: ZoneTargetDecision, _pointer_global_position: Vector2) -> void:
	pass

func clear_overlay(overlay: Control) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	if overlay.has_method("clear_overlay"):
		overlay.call("clear_overlay")
		return
	if overlay.has_method("clear_state"):
		overlay.call("clear_state")
