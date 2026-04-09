@tool
class_name ZoneLayeredTargetingStyle extends ZoneTargetingStyle

@export var layers: Array[ZoneTargetingVisualLayer] = []

func create_overlay(_context: ZoneContext, _coordinator: Node) -> Control:
	return ZoneTargetingOverlayHost.new()

func update_overlay(_context: ZoneContext, overlay: Control, _session, source_anchor: Vector2, candidate: ZoneTargetCandidate, decision: ZoneTargetDecision, pointer_global_position: Vector2) -> void:
	if overlay == null or not is_instance_valid(overlay) or overlay is not ZoneTargetingOverlayHost:
		return
	var host := overlay as ZoneTargetingOverlayHost
	host.set_layers(resolve_layers())
	host.apply_frame(build_visual_frame(source_anchor, candidate, decision, pointer_global_position))

func clear_overlay(overlay: Control) -> void:
	if overlay != null and is_instance_valid(overlay) and overlay is ZoneTargetingOverlayHost:
		(overlay as ZoneTargetingOverlayHost).clear_overlay()
		return
	super.clear_overlay(overlay)

func resolve_layers() -> Array[ZoneTargetingVisualLayer]:
	var resolved: Array[ZoneTargetingVisualLayer] = []
	for layer in layers:
		if layer != null:
			resolved.append(layer)
	return resolved

func build_visual_frame(source_anchor: Vector2, candidate: ZoneTargetCandidate, decision: ZoneTargetDecision, pointer_global_position: Vector2) -> ZoneTargetingVisualFrame:
	var frame := ZoneTargetingVisualFrame.new()
	frame.active = true
	frame.source_anchor = source_anchor
	frame.pointer_global_position = pointer_global_position
	frame.candidate = candidate.duplicate_candidate() if candidate != null else ZoneTargetCandidate.invalid(pointer_global_position)
	frame.decision = decision.duplicate_decision() if decision != null else ZoneTargetDecision.new()
	var resolved_candidate = frame.get_resolved_candidate()
	frame.end_anchor = pointer_global_position
	if resolved_candidate != null and resolved_candidate.is_valid():
		frame.end_anchor = resolved_candidate.global_position
		frame.show_endpoint = true
		frame.is_item_target = resolved_candidate.is_item()
		frame.is_placement_target = resolved_candidate.is_placement()
		if frame.decision != null and frame.decision.allowed:
			frame.visual_state = ZoneTargetingVisualFrame.VisualState.VALID
		elif frame.decision != null:
			frame.visual_state = ZoneTargetingVisualFrame.VisualState.INVALID
	else:
		frame.show_endpoint = false
		frame.is_item_target = false
		frame.is_placement_target = false
		frame.visual_state = ZoneTargetingVisualFrame.VisualState.NEUTRAL
	var metadata: Dictionary = {}
	if frame.candidate != null:
		metadata.merge(frame.candidate.metadata, true)
	if frame.decision != null:
		metadata.merge(frame.decision.metadata, true)
	metadata["visual_state"] = frame.visual_state
	metadata["show_endpoint"] = frame.show_endpoint
	metadata["is_item_target"] = frame.is_item_target
	metadata["is_placement_target"] = frame.is_placement_target
	frame.metadata = metadata
	return frame
