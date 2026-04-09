@tool
class_name ZoneArrowTargetingStyle extends ZoneTargetingStyle

var _neutral_color: Color = Color(0.84, 0.88, 0.96, 0.85)
var _valid_color: Color = Color(0.42, 0.90, 0.62, 0.92)
var _invalid_color: Color = Color(1.0, 0.42, 0.42, 0.92)
var _line_width: float = 6.0
var _arrow_head_size: float = 18.0
var _curvature: float = 0.16
var _target_ring_radius: float = 24.0
var _pulse_enabled: bool = true
var _pulse_speed: float = 4.0
var _layers_dirty: bool = true
var _delegate_style: ZoneLayeredTargetingStyle = null

@export_group("Colors")
@export var neutral_color: Color:
	get:
		return _neutral_color
	set(value):
		_neutral_color = value
		_layers_dirty = true

@export var valid_color: Color:
	get:
		return _valid_color
	set(value):
		_valid_color = value
		_layers_dirty = true

@export var invalid_color: Color:
	get:
		return _invalid_color
	set(value):
		_invalid_color = value
		_layers_dirty = true

@export_group("Geometry")
@export_range(1.0, 18.0, 0.5) var line_width: float:
	get:
		return _line_width
	set(value):
		_line_width = value
		_layers_dirty = true

@export_range(4.0, 48.0, 0.5) var arrow_head_size: float:
	get:
		return _arrow_head_size
	set(value):
		_arrow_head_size = value
		_layers_dirty = true

@export_range(0.02, 0.40, 0.01) var curvature: float:
	get:
		return _curvature
	set(value):
		_curvature = value
		_layers_dirty = true

@export_range(8.0, 48.0, 0.5) var target_ring_radius: float:
	get:
		return _target_ring_radius
	set(value):
		_target_ring_radius = value
		_layers_dirty = true

@export_group("Motion")
@export var pulse_enabled: bool:
	get:
		return _pulse_enabled
	set(value):
		_pulse_enabled = value
		_layers_dirty = true

@export_range(0.5, 12.0, 0.1) var pulse_speed: float:
	get:
		return _pulse_speed
	set(value):
		_pulse_speed = value
		_layers_dirty = true

func create_overlay(context: ZoneContext, coordinator: Node) -> Control:
	return _ensure_delegate().create_overlay(context, coordinator)

func update_overlay(context: ZoneContext, overlay: Control, session, source_anchor: Vector2, candidate: ZoneTargetCandidate, decision: ZoneTargetDecision, pointer_global_position: Vector2) -> void:
	_ensure_delegate().update_overlay(context, overlay, session, source_anchor, candidate, decision, pointer_global_position)

func clear_overlay(overlay: Control) -> void:
	_ensure_delegate().clear_overlay(overlay)

func _ensure_delegate() -> ZoneLayeredTargetingStyle:
	if _delegate_style == null:
		_delegate_style = ZoneLayeredTargetingStyle.new()
		_delegate_style.resource_name = "Classic Arrow"
	if _layers_dirty:
		_delegate_style.layers = _build_layers()
		_layers_dirty = false
	return _delegate_style

func _build_layers() -> Array[ZoneTargetingVisualLayer]:
	var trail := ZoneTargetTrailLayer.new()
	trail.resource_name = "classic_trail"
	trail.neutral_color = Color(_neutral_color.r, _neutral_color.g, _neutral_color.b, _neutral_color.a * 0.38)
	trail.valid_color = Color(_valid_color.r, _valid_color.g, _valid_color.b, _valid_color.a * 0.40)
	trail.invalid_color = Color(_invalid_color.r, _invalid_color.g, _invalid_color.b, _invalid_color.a * 0.40)
	trail.path_mode = ZoneTargetingGeometry.PathMode.CURVE
	trail.line_width = _line_width * 1.85
	trail.curvature = _curvature
	trail.pulse_enabled = _pulse_enabled
	trail.pulse_speed = _pulse_speed
	var path := ZoneTargetPathLayer.new()
	path.resource_name = "classic_path"
	path.neutral_color = _neutral_color
	path.valid_color = _valid_color
	path.invalid_color = _invalid_color
	path.path_mode = ZoneTargetingGeometry.PathMode.CURVE
	path.pattern_mode = ZoneTargetPathLayer.PatternMode.SOLID
	path.line_width = _line_width
	path.curvature = _curvature
	var head := ZoneTargetHeadLayer.new()
	head.resource_name = "classic_head"
	head.neutral_color = _neutral_color
	head.valid_color = _valid_color
	head.invalid_color = _invalid_color
	head.head_shape = ZoneTargetHeadNode.HeadShape.TRIANGLE
	head.path_mode = ZoneTargetingGeometry.PathMode.CURVE
	head.head_size = _arrow_head_size
	head.curvature = _curvature
	var endpoint := ZoneTargetEndpointLayer.new()
	endpoint.resource_name = "classic_endpoint"
	endpoint.neutral_color = _neutral_color
	endpoint.valid_color = _valid_color
	endpoint.invalid_color = _invalid_color
	endpoint.endpoint_shape = ZoneTargetEndpointNode.EndpointShape.RING
	endpoint.radius = _target_ring_radius
	endpoint.line_width = maxf(2.0, _line_width * 0.45)
	endpoint.pulse_enabled = _pulse_enabled
	endpoint.pulse_speed = _pulse_speed
	return [trail, path, head, endpoint]
