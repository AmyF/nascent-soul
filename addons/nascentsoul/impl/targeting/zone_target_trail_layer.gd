@tool
class_name ZoneTargetTrailLayer extends ZoneTargetingVisualLayer

@export_enum("Curve", "Straight", "Segmented") var path_mode: int = ZoneTargetingGeometry.PathMode.CURVE
@export_range(2.0, 32.0, 0.5) var line_width: float = 10.0
@export_range(0.02, 0.40, 0.01) var curvature: float = 0.16
@export var pulse_enabled: bool = true
@export_range(0.5, 12.0, 0.1) var pulse_speed: float = 3.0
@export var scroll_enabled: bool = false
@export_range(0.0, 120.0, 1.0) var scroll_speed: float = 26.0
@export var afterimage_enabled: bool = false
@export_range(1, 12, 1) var afterimage_count: int = 4
@export_range(2.0, 24.0, 0.5) var afterimage_radius: float = 6.0
@export var texture: Texture2D
@export var material_override: Material
@export_range(8, 48, 1) var smoothness: int = 24

func create_nodes(host: ZoneTargetingOverlayHost) -> void:
	var root = host.get_layer_root(self)
	if root == null or root.get_node_or_null("Trail") != null:
		return
	var node := ZoneTargetTrailNode.new()
	node.name = "Trail"
	root.add_child(node)

func update_nodes(host: ZoneTargetingOverlayHost, frame: ZoneTargetingVisualFrame) -> void:
	var node = _get_trail_node(host)
	if node == null:
		return
	if frame == null or not frame.active:
		node.clear_state()
		return
	var points = ZoneTargetingGeometry.build_path_points(path_mode, frame.source_anchor, frame.end_anchor, curvature, smoothness)
	node.set_trail_state(points, resolve_frame_color(frame), line_width, pulse_enabled, pulse_speed, scroll_enabled, scroll_speed, texture, material_override, afterimage_enabled, afterimage_count, afterimage_radius)

func clear_nodes(host: ZoneTargetingOverlayHost) -> void:
	var node = _get_trail_node(host)
	if node != null:
		node.clear_state()

func _get_trail_node(host: ZoneTargetingOverlayHost) -> ZoneTargetTrailNode:
	var root = host.get_layer_root(self)
	if root == null:
		return null
	return root.get_node_or_null("Trail") as ZoneTargetTrailNode
