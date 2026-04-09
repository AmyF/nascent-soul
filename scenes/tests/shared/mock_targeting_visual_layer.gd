@tool
class_name MockTargetingVisualLayer extends ZoneTargetingVisualLayer

func create_nodes(host: ZoneTargetingOverlayHost) -> void:
	var root = host.get_layer_root(self)
	if root == null or root.get_node_or_null("Probe") != null:
		return
	var probe := ColorRect.new()
	probe.name = "Probe"
	probe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	probe.custom_minimum_size = Vector2(14, 14)
	probe.size = probe.custom_minimum_size
	root.add_child(probe)

func update_nodes(host: ZoneTargetingOverlayHost, frame: ZoneTargetingVisualFrame) -> void:
	var probe = _get_probe(host)
	if probe == null:
		return
	if frame == null or not frame.active:
		clear_nodes(host)
		return
	var resolved_candidate = frame.get_resolved_candidate()
	probe.visible = true
	probe.color = resolve_frame_color(frame)
	probe.position = frame.end_anchor - probe.size * 0.5
	probe.set_meta("visual_state", frame.visual_state)
	probe.set_meta("show_endpoint", frame.show_endpoint)
	probe.set_meta("is_item_target", frame.is_item_target)
	probe.set_meta("is_placement_target", frame.is_placement_target)
	probe.set_meta("candidate", frame.candidate.describe() if frame.candidate != null else "invalid")
	probe.set_meta("resolved_candidate", resolved_candidate.describe() if resolved_candidate != null else "invalid")
	probe.set_meta("metadata_keys", frame.metadata.keys())
	probe.set_meta("cleared", false)

func clear_nodes(host: ZoneTargetingOverlayHost) -> void:
	var probe = _get_probe(host)
	if probe == null:
		return
	probe.visible = false
	probe.set_meta("cleared", true)

func _get_probe(host: ZoneTargetingOverlayHost) -> ColorRect:
	var root = host.get_layer_root(self)
	if root == null:
		return null
	return root.get_node_or_null("Probe") as ColorRect
