@tool
class_name ZoneTweenDisplay extends ZoneDisplayStyle

@export var duration: float = 0.2
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

func apply(zone: Node, runtime, placements: Array[ZonePlacement]) -> void:
	var state = runtime.get_display_state(self)
	var active_tweens: Dictionary = state["active_tweens"]
	var target_cache: Dictionary = state["target_cache"]
	var should_animate = duration > 0.0 and DisplayServer.get_name() != "headless"
	_prune_inactive_tweens(active_tweens)
	var placed_lookup: Dictionary = {}
	for placement in placements:
		if is_instance_valid(placement.item):
			placed_lookup[placement.item] = true
	var stale_lookup: Dictionary = {}
	for item in active_tweens.keys():
		if not is_instance_valid(item) or not placed_lookup.has(item):
			stale_lookup[item] = true
	for item in target_cache.keys():
		if not is_instance_valid(item) or not placed_lookup.has(item):
			stale_lookup[item] = true
	for item in runtime.get_items():
		if is_instance_valid(item) and not placed_lookup.has(item):
			stale_lookup[item] = true
	for item in stale_lookup.keys():
		if not is_instance_valid(item):
			active_tweens.erase(item)
			target_cache.erase(item)
			continue
		_kill_tween(active_tweens, item)
		target_cache.erase(item)
		_reset_transform(item)
	for placement in placements:
		if not is_instance_valid(placement.item):
			continue
		var item: Control = placement.item
		var handoff = runtime.consume_transfer_handoff(item)
		item.pivot_offset = runtime.resolve_item_size(item) / 2.0
		item.z_index = placement.z_index
		if not handoff.is_empty():
			_apply_handoff_transform(item, handoff, placement.z_index)
		if placement.instant or not should_animate:
			_kill_tween(active_tweens, item)
			_apply_transform(item, placement)
			target_cache[item] = _cache_transform(placement)
			continue
		if handoff.is_empty() and _is_target_same(active_tweens, target_cache, item, placement):
			continue
		_kill_tween(active_tweens, item)
		var tween = item.create_tween()
		tween.set_parallel(true)
		tween.set_trans(trans_type)
		tween.set_ease(ease_type)
		tween.tween_property(item, "position", placement.position, duration)
		tween.tween_property(item, "rotation", placement.rotation, duration)
		tween.tween_property(item, "scale", placement.scale, duration)
		active_tweens[item] = tween
		target_cache[item] = _cache_transform(placement)

func _apply_transform(item: Control, placement: ZonePlacement) -> void:
	item.position = placement.position
	item.rotation = placement.rotation
	item.scale = placement.scale
	item.z_index = placement.z_index

func _cache_transform(placement: ZonePlacement) -> Dictionary:
	return {
		"position": placement.position,
		"rotation": placement.rotation,
		"scale": placement.scale
	}

func _kill_tween(active_tweens: Dictionary, item: Control) -> void:
	if active_tweens.has(item):
		active_tweens[item].kill()
		active_tweens.erase(item)

func _prune_inactive_tweens(active_tweens: Dictionary) -> void:
	var stale_items: Array = []
	for item in active_tweens.keys():
		var tween = active_tweens[item]
		if not is_instance_valid(item):
			stale_items.append(item)
			continue
		if tween == null or not tween.is_valid() or not tween.is_running():
			stale_items.append(item)
	for item in stale_items:
		active_tweens.erase(item)

func _apply_handoff_transform(item: Control, handoff: Dictionary, z_index: int) -> void:
	if handoff.has("global_position"):
		item.position = _global_to_parent_local(item, handoff["global_position"])
	if handoff.has("rotation"):
		item.rotation = handoff["rotation"]
	if handoff.has("scale"):
		item.scale = handoff["scale"]
	item.z_index = z_index

func _global_to_parent_local(item: Control, global_position: Vector2) -> Vector2:
	var parent = item.get_parent()
	if parent is CanvasItem:
		return (parent as CanvasItem).get_global_transform().affine_inverse() * global_position
	return global_position

func _is_target_same(active_tweens: Dictionary, target_cache: Dictionary, item: Control, placement: ZonePlacement) -> bool:
	if not target_cache.has(item):
		return false
	var cached: Dictionary = target_cache[item]
	if cached["position"].distance_squared_to(placement.position) > 0.1:
		return false
	if abs(cached["rotation"] - placement.rotation) > 0.001:
		return false
	if cached["scale"].distance_squared_to(placement.scale) > 0.001:
		return false
	if active_tweens.has(item):
		var tween = active_tweens[item]
		return tween != null and tween.is_valid() and tween.is_running()
	return _is_transform_at_target(item, cached)

func _is_transform_at_target(item: Control, target: Dictionary) -> bool:
	if item.position.distance_squared_to(target["position"]) > 0.1:
		return false
	if abs(item.rotation - target["rotation"]) > 0.001:
		return false
	if item.scale.distance_squared_to(target["scale"]) > 0.001:
		return false
	return true

func _reset_transform(item: Control) -> void:
	item.scale = Vector2.ONE
	item.rotation = 0.0
	item.z_index = 0
