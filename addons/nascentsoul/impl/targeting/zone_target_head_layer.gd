@tool
class_name ZoneTargetHeadLayer extends ZoneTargetingVisualLayer

@export_enum("Triangle", "Chevron", "Spear", "Bolt") var head_shape: int = ZoneTargetHeadNode.HeadShape.TRIANGLE
@export_enum("Curve", "Straight", "Segmented") var path_mode: int = ZoneTargetingGeometry.PathMode.CURVE
@export_range(4.0, 48.0, 0.5) var head_size: float = 18.0
@export_range(0.20, 1.20, 0.05) var width_scale: float = 0.55
@export_range(0.02, 0.40, 0.01) var curvature: float = 0.16
@export_range(8, 48, 1) var smoothness: int = 24
@export var material_override: Material

func create_nodes(host: ZoneTargetingOverlayHost) -> void:
	var root = host.get_layer_root(self)
	if root == null or root.get_node_or_null("Head") != null:
		return
	var node := ZoneTargetHeadNode.new()
	node.name = "Head"
	root.add_child(node)

func update_nodes(host: ZoneTargetingOverlayHost, frame: ZoneTargetingVisualFrame) -> void:
	var node = _get_head_node(host)
	if node == null:
		return
	if frame == null or not frame.active:
		node.clear_state()
		return
	var points = ZoneTargetingGeometry.build_path_points(path_mode, frame.source_anchor, frame.end_anchor, curvature, smoothness)
	if points.size() < 2:
		node.clear_state()
		return
	var tip = points[points.size() - 1]
	var tail = points[points.size() - 2]
	node.set_head_state(tip, tip - tail, resolve_frame_color(frame), head_size, width_scale, head_shape, material_override)

func clear_nodes(host: ZoneTargetingOverlayHost) -> void:
	var node = _get_head_node(host)
	if node != null:
		node.clear_state()

func _get_head_node(host: ZoneTargetingOverlayHost) -> ZoneTargetHeadNode:
	var root = host.get_layer_root(self)
	if root == null:
		return null
	return root.get_node_or_null("Head") as ZoneTargetHeadNode
