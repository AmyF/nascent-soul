@tool
class_name ZoneHandLayout extends ZoneLayoutPolicy

@export var arch_angle_deg: float = 30.0
@export var arch_height: float = 20.0
@export var card_spacing_angle: float = 5.0
@export var center_offset_y: float = 0.0

func calculate(items: Array[Control], container_size: Vector2, ghost_item: Control = null, ghost_index: int = -1) -> Array[ZonePlacement]:
	var render_items: Array[Control] = items.duplicate()
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	if render_items.is_empty():
		return []
	var placements: Array[ZonePlacement] = []
	var total_items = render_items.size()
	var max_item_size = _resolve_max_item_size(render_items)
	var metrics = _build_metrics(max_item_size, total_items, container_size)
	var half_spread = deg_to_rad(metrics["spread_deg"] * 0.5)
	var step = (half_spread * 2.0) / float(total_items - 1) if total_items > 1 else 0.0
	for i in range(total_items):
		var item = render_items[i]
		var angle = -half_spread + i * step
		var size = resolve_item_size(item)
		var center = Vector2(
			metrics["center_x"] + sin(angle) * metrics["radius_x"],
			metrics["center_y"] - cos(angle) * metrics["radius_y"]
		)
		var pos = center - size / 2.0
		placements.append(ZonePlacement.new(item, pos, angle * 0.55, Vector2.ONE, i, item == ghost_item))
	return placements

func get_insertion_index(items: Array[Control], container_size: Vector2, mouse_pos: Vector2) -> int:
	var count = items.size()
	if count == 0:
		return 0
	var max_item_size = _resolve_max_item_size(items)
	var metrics = _build_metrics(max_item_size, count, container_size)
	var half_spread = deg_to_rad(metrics["spread_deg"] * 0.5)
	var step = (half_spread * 2.0) / float(count - 1) if count > 1 else 0.0
	var centers: Array[float] = []
	for i in range(count):
		var angle = -half_spread + i * step
		centers.append(metrics["center_x"] + sin(angle) * metrics["radius_x"])
	if mouse_pos.x <= centers[0]:
		return 0
	if mouse_pos.x >= centers[count - 1]:
		return count
	for i in range(count - 1):
		var midpoint = (centers[i] + centers[i + 1]) * 0.5
		if mouse_pos.x < midpoint:
			return i + 1
	return count

func would_escape_container(container_size: Vector2, item_count: int = 5, sample_item_size: Vector2 = Vector2(120, 180)) -> bool:
	if container_size == Vector2.ZERO:
		return false
	var metrics = _build_metrics(sample_item_size, item_count, container_size)
	var half_spread = deg_to_rad(metrics["spread_deg"] * 0.5)
	var step = (half_spread * 2.0) / float(item_count - 1) if item_count > 1 else 0.0
	for i in range(item_count):
		var angle = -half_spread + i * step
		var center = Vector2(
			metrics["center_x"] + sin(angle) * metrics["radius_x"],
			metrics["center_y"] - cos(angle) * metrics["radius_y"]
		)
		var pos = center - sample_item_size / 2.0
		if pos.x < 0.0 or pos.y < 0.0:
			return true
		if pos.x + sample_item_size.x > container_size.x or pos.y + sample_item_size.y > container_size.y:
			return true
	return false

func _resolve_max_item_size(items: Array[Control]) -> Vector2:
	var max_size = Vector2(120, 180)
	for item in items:
		var size = resolve_item_size(item)
		max_size.x = max(max_size.x, size.x)
		max_size.y = max(max_size.y, size.y)
	return max_size

func _build_metrics(item_size: Vector2, item_count: int, container_size: Vector2) -> Dictionary:
	var safe_count = max(1, item_count)
	var spread_deg = min(float(safe_count - 1) * max(card_spacing_angle, 0.0), max(arch_angle_deg, 0.0) * 2.0)
	var available_width = max(0.0, container_size.x - item_size.x)
	var radius_x = item_size.x * 0.55 * max(1.0, float(safe_count - 1))
	radius_x += max(card_spacing_angle, 0.0) * 3.0 * max(1.0, float(safe_count - 1))
	radius_x = min(radius_x, max(item_size.x * 0.5, available_width * 0.5))
	var radius_y = max(18.0, item_size.y * 0.22 + max(arch_height, 0.0))
	var vertical_bias = clampf(center_offset_y, -item_size.y * 0.35, item_size.y * 0.35)
	var baseline_y = container_size.y - item_size.y * 0.55 - max(12.0, arch_height * 0.25) + vertical_bias
	baseline_y = clampf(baseline_y, item_size.y * 0.5 + 8.0, max(item_size.y * 0.5 + 8.0, container_size.y - item_size.y * 0.5 - 8.0))
	return {
		"spread_deg": spread_deg,
		"radius_x": radius_x,
		"radius_y": radius_y,
		"center_x": container_size.x * 0.5,
		"center_y": baseline_y + radius_y
	}
