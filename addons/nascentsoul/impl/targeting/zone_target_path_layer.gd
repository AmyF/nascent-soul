@tool
class_name ZoneTargetPathLayer extends ZoneTargetingVisualLayer

enum PatternMode {
	SOLID,
	DASHED
}

@export_enum("Curve", "Straight", "Segmented") var path_mode: int = ZoneTargetingGeometry.PathMode.CURVE
@export_enum("Solid", "Dashed") var pattern_mode: int = PatternMode.SOLID
@export_range(1.0, 24.0, 0.5) var line_width: float = 6.0
@export_range(0.02, 0.40, 0.01) var curvature: float = 0.16
@export_range(4.0, 64.0, 0.5) var dash_length: float = 16.0
@export_range(0.0, 48.0, 0.5) var gap_length: float = 10.0
@export var taper_enabled: bool = false
@export_range(0.05, 1.0, 0.05) var taper_end_scale: float = 0.25
@export var texture: Texture2D
@export var material_override: Material
@export var antialiased: bool = true
@export_range(8, 48, 1) var smoothness: int = 24

func create_nodes(host: ZoneTargetingOverlayHost) -> void:
	var root = host.get_layer_root(self)
	if root == null or root.get_node_or_null("Path") != null:
		return
	var node := ZoneTargetPathNode.new()
	node.name = "Path"
	root.add_child(node)

func update_nodes(host: ZoneTargetingOverlayHost, frame: ZoneTargetingVisualFrame) -> void:
	var node = _get_path_node(host)
	if node == null:
		return
	if frame == null or not frame.active:
		node.clear_state()
		return
	var points = ZoneTargetingGeometry.build_path_points(path_mode, frame.source_anchor, frame.end_anchor, curvature, smoothness)
	var segments = [points]
	if pattern_mode == PatternMode.DASHED:
		segments = ZoneTargetingGeometry.build_dashed_segments(points, dash_length, gap_length)
	node.set_path_state(segments, resolve_frame_color(frame), line_width, texture, material_override, antialiased, taper_enabled, taper_end_scale)

func clear_nodes(host: ZoneTargetingOverlayHost) -> void:
	var node = _get_path_node(host)
	if node != null:
		node.clear_state()

func _get_path_node(host: ZoneTargetingOverlayHost) -> ZoneTargetPathNode:
	var root = host.get_layer_root(self)
	if root == null:
		return null
	return root.get_node_or_null("Path") as ZoneTargetPathNode
