class_name ZoneTargetHeadNode extends Node2D

enum HeadShape {
	TRIANGLE,
	CHEVRON,
	SPEAR,
	BOLT
}

var _shape: int = HeadShape.TRIANGLE
var _tip: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.RIGHT
var _color: Color = Color.WHITE
var _head_size: float = 18.0
var _width_scale: float = 0.55

func set_head_state(tip: Vector2, direction: Vector2, color: Color, head_size: float, width_scale: float, head_shape: int, material_override: Material = null) -> void:
	_tip = tip
	_direction = direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_color = color
	_head_size = head_size
	_width_scale = width_scale
	_shape = head_shape
	material = material_override
	visible = true
	queue_redraw()

func clear_state() -> void:
	visible = false
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var direction = _direction
	var normal = Vector2(-direction.y, direction.x)
	var back = _tip - direction * _head_size
	var left = back + normal * (_head_size * _width_scale)
	var right = back - normal * (_head_size * _width_scale)
	match _shape:
		HeadShape.CHEVRON:
			draw_polyline(PackedVector2Array([left, _tip, right]), _color, maxf(2.0, _head_size * 0.18), true)
		HeadShape.SPEAR:
			var inner_back = _tip - direction * (_head_size * 0.45)
			var spear_points := PackedVector2Array([_tip, left, inner_back, right])
			draw_colored_polygon(spear_points, _color)
		HeadShape.BOLT:
			var mid_left = _tip - direction * (_head_size * 0.35) + normal * (_head_size * _width_scale * 0.65)
			var mid_right = _tip - direction * (_head_size * 0.70) - normal * (_head_size * _width_scale * 0.25)
			var bolt_points := PackedVector2Array([_tip, mid_left, back, mid_right])
			draw_colored_polygon(bolt_points, _color)
		_:
			draw_colored_polygon(PackedVector2Array([_tip, left, right]), _color)
