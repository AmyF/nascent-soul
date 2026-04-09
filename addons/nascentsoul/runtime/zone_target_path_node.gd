class_name ZoneTargetPathNode extends Node2D

var _segments: Array = []
var _base_color: Color = Color.WHITE
var _line_width: float = 6.0
var _texture: Texture2D = null
var _material_override: Material = null
var _antialiased: bool = true
var _taper_enabled: bool = false
var _taper_end_scale: float = 0.25

func set_path_state(segments: Array, color: Color, line_width: float, texture: Texture2D = null, material_override: Material = null, antialiased: bool = true, taper_enabled: bool = false, taper_end_scale: float = 0.25) -> void:
	_segments = segments.duplicate(true)
	_base_color = color
	_line_width = line_width
	_texture = texture
	_material_override = material_override
	_antialiased = antialiased
	_taper_enabled = taper_enabled
	_taper_end_scale = taper_end_scale
	_sync_lines()
	visible = not _segments.is_empty()

func clear_state() -> void:
	_segments.clear()
	for child in get_children():
		if child is Line2D:
			(child as Line2D).points = PackedVector2Array()
	visible = false

func _sync_lines() -> void:
	while get_child_count() < _segments.size():
		var line := Line2D.new()
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(line)
	while get_child_count() > _segments.size():
		var child = get_child(get_child_count() - 1)
		remove_child(child)
		child.queue_free()
	for index in range(_segments.size()):
		var line = get_child(index) as Line2D
		line.points = _segments[index]
		line.default_color = _base_color
		line.width = _line_width
		line.antialiased = _antialiased
		line.texture = _texture
		line.texture_mode = Line2D.LINE_TEXTURE_TILE if _texture != null else Line2D.LINE_TEXTURE_NONE
		line.material = _material_override
		line.width_curve = _make_taper_curve(_taper_end_scale) if _taper_enabled else null

func _make_taper_curve(end_scale: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, clampf(end_scale, 0.05, 1.0)))
	return curve
