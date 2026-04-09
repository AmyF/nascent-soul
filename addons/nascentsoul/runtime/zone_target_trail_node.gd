class_name ZoneTargetTrailNode extends Node2D

var _points: PackedVector2Array = PackedVector2Array()
var _base_color: Color = Color.WHITE
var _line_width: float = 10.0
var _pulse_enabled: bool = true
var _pulse_speed: float = 3.0
var _scroll_enabled: bool = false
var _scroll_speed: float = 26.0
var _afterimage_enabled: bool = false
var _afterimage_count: int = 4
var _afterimage_radius: float = 6.0
var _texture: Texture2D = null
var _material_override: Material = null
var _line: Line2D = null

func _ready() -> void:
	_line = Line2D.new()
	_line.name = "TrailLine"
	_line.antialiased = true
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_line)
	set_process(false)

func _process(delta: float) -> void:
	_apply_visuals(delta)
	queue_redraw()

func set_trail_state(points: PackedVector2Array, color: Color, line_width: float, pulse_enabled: bool, pulse_speed: float, scroll_enabled: bool, scroll_speed: float, texture: Texture2D = null, material_override: Material = null, afterimage_enabled: bool = false, afterimage_count: int = 4, afterimage_radius: float = 6.0) -> void:
	_points = points
	_base_color = color
	_line_width = line_width
	_pulse_enabled = pulse_enabled
	_pulse_speed = pulse_speed
	_scroll_enabled = scroll_enabled
	_scroll_speed = scroll_speed
	_texture = texture
	_material_override = material_override
	_afterimage_enabled = afterimage_enabled
	_afterimage_count = afterimage_count
	_afterimage_radius = afterimage_radius
	_apply_visuals()
	visible = _points.size() >= 2
	set_process(_pulse_enabled or (_scroll_enabled and _texture != null))
	queue_redraw()

func clear_state() -> void:
	_points = PackedVector2Array()
	if _line != null:
		_line.points = PackedVector2Array()
	visible = false
	set_process(false)
	queue_redraw()

func _draw() -> void:
	if not visible or not _afterimage_enabled or _points.size() < 2:
		return
	var sample_points = ZoneTargetingGeometry.sample_polyline_points(_points, _afterimage_count)
	var color = _resolved_color()
	for index in range(sample_points.size()):
		var alpha_scale = 1.0 - (float(index) / float(max(1, sample_points.size())))
		draw_circle(sample_points[index], _afterimage_radius * alpha_scale, Color(color.r, color.g, color.b, color.a * 0.35 * alpha_scale))

func _apply_visuals(delta: float = 0.0) -> void:
	if _line == null:
		return
	_line.points = _points
	_line.width = _line_width
	_line.default_color = _resolved_color()
	_line.texture = _texture
	_line.texture_mode = Line2D.LINE_TEXTURE_TILE if _texture != null else Line2D.LINE_TEXTURE_NONE
	_line.material = _material_override
	if _scroll_enabled and _texture != null:
		_line.texture_offset += _scroll_speed * delta

func _resolved_color() -> Color:
	if not _pulse_enabled:
		return _base_color
	var alpha_scale = 0.76 + (sin(Time.get_ticks_msec() * 0.001 * _pulse_speed) + 1.0) * 0.12
	return Color(_base_color.r, _base_color.g, _base_color.b, clampf(_base_color.a * alpha_scale, 0.0, 1.0))
