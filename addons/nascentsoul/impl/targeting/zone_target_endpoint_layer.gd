@tool
class_name ZoneTargetEndpointLayer extends ZoneTargetingVisualLayer

@export_enum("Ring", "Reticle", "Rune", "Flare") var endpoint_shape: int = ZoneTargetEndpointNode.EndpointShape.RING
@export_range(8.0, 48.0, 0.5) var radius: float = 22.0
@export_range(1.0, 12.0, 0.5) var line_width: float = 3.0
@export var show_only_with_candidate: bool = true
@export var pulse_enabled: bool = true
@export_range(0.5, 12.0, 0.1) var pulse_speed: float = 4.0
@export_range(3, 12, 1) var rune_spokes: int = 6
@export var material_override: Material

func create_nodes(host: ZoneTargetingOverlayHost) -> void:
	var root = host.get_layer_root(self)
	if root == null or root.get_node_or_null("Endpoint") != null:
		return
	var node := ZoneTargetEndpointNode.new()
	node.name = "Endpoint"
	root.add_child(node)

func update_nodes(host: ZoneTargetingOverlayHost, frame: ZoneTargetingVisualFrame) -> void:
	var node = _get_endpoint_node(host)
	if node == null:
		return
	if frame == null or not frame.active or (show_only_with_candidate and not frame.show_endpoint):
		node.clear_state()
		return
	node.set_endpoint_state(frame.end_anchor, resolve_frame_color(frame), radius, line_width, endpoint_shape, pulse_enabled, pulse_speed, material_override, rune_spokes)

func clear_nodes(host: ZoneTargetingOverlayHost) -> void:
	var node = _get_endpoint_node(host)
	if node != null:
		node.clear_state()

func _get_endpoint_node(host: ZoneTargetingOverlayHost) -> ZoneTargetEndpointNode:
	var root = host.get_layer_root(self)
	if root == null:
		return null
	return root.get_node_or_null("Endpoint") as ZoneTargetEndpointNode
