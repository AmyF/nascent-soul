class_name ZoneTargetingGeometry extends RefCounted

enum PathMode {
	CURVE,
	STRAIGHT,
	SEGMENTED
}

static func build_path_points(path_mode: int, start: Vector2, finish: Vector2, curvature: float = 0.16, samples: int = 24) -> PackedVector2Array:
	match path_mode:
		PathMode.STRAIGHT:
			return PackedVector2Array([start, finish])
		PathMode.SEGMENTED:
			return _build_segmented_points(start, finish)
		_:
			return _build_curve_points(start, finish, curvature, samples)

static func build_dashed_segments(points: PackedVector2Array, dash_length: float, gap_length: float) -> Array:
	var segments: Array = []
	var total_length = get_polyline_length(points)
	if points.size() < 2 or total_length <= 0.01:
		return segments
	var dash = maxf(2.0, dash_length)
	var gap = maxf(0.0, gap_length)
	var cursor = 0.0
	while cursor < total_length:
		var dash_end = minf(total_length, cursor + dash)
		var segment = _slice_polyline(points, cursor, dash_end)
		if segment.size() >= 2:
			segments.append(segment)
		cursor = dash_end + gap
	return segments

static func get_polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for index in range(points.size() - 1):
		total += points[index].distance_to(points[index + 1])
	return total

static func sample_polyline(points: PackedVector2Array, distance_along: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var remaining = clampf(distance_along, 0.0, get_polyline_length(points))
	for index in range(points.size() - 1):
		var start = points[index]
		var finish = points[index + 1]
		var segment_length = start.distance_to(finish)
		if segment_length <= 0.001:
			continue
		if remaining <= segment_length:
			return start.lerp(finish, remaining / segment_length)
		remaining -= segment_length
	return points[points.size() - 1]

static func sample_polyline_points(points: PackedVector2Array, count: int, include_endpoints: bool = false) -> PackedVector2Array:
	var sampled := PackedVector2Array()
	var total_length = get_polyline_length(points)
	if count <= 0 or total_length <= 0.01:
		return sampled
	var start_offset = 0 if include_endpoints else 1
	var divisor = max(1, count - 1) if include_endpoints else count + 1
	for index in range(count):
		var t = float(index + start_offset) / float(divisor)
		sampled.push_back(sample_polyline(points, total_length * t))
	return sampled

static func _build_curve_points(start: Vector2, finish: Vector2, curvature: float, samples: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance = start.distance_to(finish)
	if distance <= 1.0:
		points.push_back(start)
		points.push_back(finish)
		return points
	var lift = maxf(24.0, distance * clampf(curvature, 0.02, 0.45))
	var direction = (finish - start).normalized()
	var normal = Vector2(-direction.y, direction.x)
	if normal == Vector2.ZERO:
		normal = Vector2.UP
	var control = (start + finish) * 0.5 + normal * -lift
	for index in range(samples + 1):
		var t = float(index) / float(samples)
		var a = start.lerp(control, t)
		var b = control.lerp(finish, t)
		points.push_back(a.lerp(b, t))
	return points

static func _build_segmented_points(start: Vector2, finish: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var delta = finish - start
	if delta.length() <= 1.0:
		points.push_back(start)
		points.push_back(finish)
		return points
	var horizontal_first = absf(delta.x) >= absf(delta.y)
	if horizontal_first:
		var bend_x = start.x + delta.x * 0.5
		points.push_back(start)
		points.push_back(Vector2(bend_x, start.y))
		points.push_back(Vector2(bend_x, finish.y))
		points.push_back(finish)
	else:
		var bend_y = start.y + delta.y * 0.5
		points.push_back(start)
		points.push_back(Vector2(start.x, bend_y))
		points.push_back(Vector2(finish.x, bend_y))
		points.push_back(finish)
	return points

static func _slice_polyline(points: PackedVector2Array, start_distance: float, end_distance: float) -> PackedVector2Array:
	var sliced := PackedVector2Array()
	if points.size() < 2 or end_distance <= start_distance:
		return sliced
	var total = 0.0
	sliced.push_back(sample_polyline(points, start_distance))
	for index in range(points.size() - 1):
		var segment_length = points[index].distance_to(points[index + 1])
		var next_total = total + segment_length
		if next_total > start_distance and next_total < end_distance:
			sliced.push_back(points[index + 1])
		total = next_total
	sliced.push_back(sample_polyline(points, end_distance))
	return _dedupe_points(sliced)

static func _dedupe_points(points: PackedVector2Array) -> PackedVector2Array:
	var deduped := PackedVector2Array()
	for point in points:
		if deduped.is_empty() or deduped[deduped.size() - 1].distance_to(point) > 0.01:
			deduped.push_back(point)
	return deduped
