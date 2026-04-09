class_name ZoneTargetEndpointNode extends Node2D

enum EndpointShape {
	RING,
	RETICLE,
	RUNE,
	FLARE
}

var _shape: int = EndpointShape.RING
var _center: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _radius: float = 20.0
var _line_width: float = 3.0
var _pulse_enabled: bool = false
var _pulse_speed: float = 4.0
var _rune_spokes: int = 6

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	queue_redraw()

func set_endpoint_state(center: Vector2, color: Color, radius: float, line_width: float, endpoint_shape: int, pulse_enabled: bool = false, pulse_speed: float = 4.0, material_override: Material = null, rune_spokes: int = 6) -> void:
	_center = center
	_color = color
	_radius = radius
	_line_width = line_width
	_pulse_enabled = pulse_enabled
	_pulse_speed = pulse_speed
	_rune_spokes = rune_spokes
	_shape = endpoint_shape
	material = material_override
	visible = true
	set_process(_pulse_enabled)
	queue_redraw()

func clear_state() -> void:
	visible = false
	set_process(false)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var color = _resolved_color()
	match _shape:
		EndpointShape.RETICLE:
			_draw_reticle(color)
		EndpointShape.RUNE:
			_draw_rune(color)
		EndpointShape.FLARE:
			_draw_flare(color)
		_:
			draw_arc(_center, _radius, 0.0, TAU, 32, color, _line_width, true)

func _draw_reticle(color: Color) -> void:
	draw_arc(_center, _radius, 0.0, TAU, 32, color, _line_width, true)
	var inner = _radius * 0.45
	draw_line(_center + Vector2(-_radius, 0.0), _center + Vector2(-inner, 0.0), color, _line_width, true)
	draw_line(_center + Vector2(_radius, 0.0), _center + Vector2(inner, 0.0), color, _line_width, true)
	draw_line(_center + Vector2(0.0, -_radius), _center + Vector2(0.0, -inner), color, _line_width, true)
	draw_line(_center + Vector2(0.0, _radius), _center + Vector2(0.0, inner), color, _line_width, true)

func _draw_rune(color: Color) -> void:
	draw_arc(_center, _radius, 0.0, TAU, 32, color, _line_width, true)
	draw_arc(_center, _radius * 0.55, 0.0, TAU, 24, Color(color.r, color.g, color.b, color.a * 0.8), maxf(1.5, _line_width * 0.75), true)
	var spokes = maxi(3, _rune_spokes)
	for index in range(spokes):
		var angle = TAU * float(index) / float(spokes)
		var direction = Vector2.RIGHT.rotated(angle)
		draw_line(_center + direction * (_radius * 0.65), _center + direction * (_radius * 1.05), color, maxf(1.5, _line_width * 0.75), true)

func _draw_flare(color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(8):
		var angle = TAU * float(index) / 8.0
		var radius = _radius if index % 2 == 0 else _radius * 0.42
		points.push_back(_center + Vector2.RIGHT.rotated(angle) * radius)
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.22))
	draw_polyline(points + PackedVector2Array([points[0]]), color, maxf(1.5, _line_width), true)

func _resolved_color() -> Color:
	if not _pulse_enabled:
		return _color
	var alpha_scale = 0.84 + (sin(Time.get_ticks_msec() * 0.001 * _pulse_speed) + 1.0) * 0.10
	return Color(_color.r, _color.g, _color.b, clampf(_color.a * alpha_scale, 0.0, 1.0))
