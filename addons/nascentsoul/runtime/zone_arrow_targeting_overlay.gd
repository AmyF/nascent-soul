class_name ZoneArrowTargetingOverlay extends Control

enum VisualState {
	NEUTRAL,
	VALID,
	INVALID
}

var _active: bool = false
var _source_anchor: Vector2 = Vector2.ZERO
var _end_anchor: Vector2 = Vector2.ZERO
var _state: VisualState = VisualState.NEUTRAL
var _line_width: float = 6.0
var _arrow_head_size: float = 18.0
var _curve_height: float = 72.0
var _ring_radius: float = 26.0
var _show_ring: bool = false
var _neutral_color: Color = Color(0.85, 0.87, 0.95, 0.85)
var _valid_color: Color = Color(0.48, 0.90, 0.66, 0.92)
var _invalid_color: Color = Color(1.0, 0.45, 0.45, 0.92)
var _pulse_enabled: bool = true
var _pulse_speed: float = 4.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	set_process(false)

func _process(_delta: float) -> void:
	size = get_viewport_rect().size
	if _active and _pulse_enabled:
		queue_redraw()

func set_arrow_state(
	source_anchor: Vector2,
	end_anchor: Vector2,
	state: VisualState,
	line_width: float,
	arrow_head_size: float,
	curve_height: float,
	ring_radius: float,
	show_ring: bool,
	neutral_color: Color,
	valid_color: Color,
	invalid_color: Color,
	pulse_enabled: bool,
	pulse_speed: float
) -> void:
	_active = true
	_source_anchor = source_anchor
	_end_anchor = end_anchor
	_state = state
	_line_width = line_width
	_arrow_head_size = arrow_head_size
	_curve_height = curve_height
	_ring_radius = ring_radius
	_show_ring = show_ring
	_neutral_color = neutral_color
	_valid_color = valid_color
	_invalid_color = invalid_color
	_pulse_enabled = pulse_enabled
	_pulse_speed = pulse_speed
	visible = true
	set_process(_pulse_enabled)
	queue_redraw()

func clear_state() -> void:
	_active = false
	_show_ring = false
	visible = false
	set_process(false)
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	var color = _resolve_color()
	var points = _build_curve_points(_source_anchor, _end_anchor)
	if points.size() < 2:
		return
	draw_polyline(points, color, _line_width, true)
	_draw_arrow_head(points, color)
	if _show_ring:
		draw_arc(_end_anchor, _ring_radius, 0.0, TAU, 28, color, maxf(2.0, _line_width * 0.45), true)

func _resolve_color() -> Color:
	var base_color = _neutral_color
	match _state:
		VisualState.VALID:
			base_color = _valid_color
		VisualState.INVALID:
			base_color = _invalid_color
	if not _pulse_enabled:
		return base_color
	var pulse = 0.88 + (sin(Time.get_ticks_msec() * 0.001 * _pulse_speed) + 1.0) * 0.08
	return Color(base_color.r, base_color.g, base_color.b, clampf(base_color.a * pulse, 0.0, 1.0))

func _build_curve_points(start: Vector2, finish: Vector2, samples: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance = start.distance_to(finish)
	if distance <= 1.0:
		points.push_back(start)
		points.push_back(finish)
		return points
	var control = (start + finish) * 0.5 + Vector2(0.0, -maxf(24.0, distance * _curve_height))
	for index in range(samples + 1):
		var t = float(index) / float(samples)
		var a = start.lerp(control, t)
		var b = control.lerp(finish, t)
		points.push_back(a.lerp(b, t))
	return points

func _draw_arrow_head(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 2:
		return
	var tip = points[points.size() - 1]
	var tail = points[points.size() - 2]
	var direction = (tip - tail).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var normal = Vector2(-direction.y, direction.x)
	var back = tip - direction * _arrow_head_size
	var left = back + normal * (_arrow_head_size * 0.55)
	var right = back - normal * (_arrow_head_size * 0.55)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
