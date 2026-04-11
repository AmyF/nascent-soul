class_name ZoneRenderService extends RefCounted

# Internal runtime helper for layout application, preview ghosts, and hover state.

const ZoneDragPreviewFeedbackScript = preload("res://addons/nascentsoul/runtime/zone_drag_preview_feedback.gd")

var context: ZoneContext
var zone: Zone

var display_state: Dictionary = {}
var _preview_feedback = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone
	_preview_feedback = ZoneDragPreviewFeedbackScript.new(context)

func refresh() -> void:
	var layout_policy = context.get_layout_policy()
	var display_style = context.get_display_style()
	if zone.get_items_root() == null or layout_policy == null or display_style == null:
		return
	var coordinator = zone._get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	var layout_items := get_layout_items(session)
	var sort_policy = context.get_sort_policy()
	if sort_policy != null and session == null and context.get_space_model() is ZoneLinearSpaceModel:
		layout_items = sort_policy.sort_items(context, layout_items)
	var ghost_hint = null
	if should_render_ghost_for_session(session):
		ghost_hint = context.get_space_model().resolve_layout_hint(session.preview_target)
	var placements = layout_policy.calculate(context, layout_items, zone.size, _preview_feedback.ghost_instance, ghost_hint)
	display_style.apply(context, placements)

func clear_preview() -> void:
	_preview_feedback.clear_preview()

func clear_display_state() -> void:
	for state in display_state.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		for item in active_tweens.keys():
			if active_tweens[item] != null:
				active_tweens[item].kill()
	display_state.clear()
	if context != null:
		context.clear_transfer_handoffs()

func cleanup() -> void:
	if _preview_feedback != null:
		_preview_feedback.cleanup()
	clear_display_state()
	_preview_feedback = null
	context = null
	zone = null

func get_display_state(style: Resource) -> Dictionary:
	var key = style.get_instance_id()
	if not display_state.has(key):
		display_state[key] = {
			"active_tweens": {},
			"target_cache": {}
		}
	return display_state[key]

func prune_display_state() -> void:
	for state in display_state.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		var target_cache: Dictionary = state.get("target_cache", {})
		var stale_items: Array = []
		for item in active_tweens.keys():
			var tween = active_tweens[item]
			if not is_instance_valid(item) or tween == null or not tween.is_valid() or not tween.is_running():
				stale_items.append(item)
		for item in target_cache.keys():
			if not is_instance_valid(item) and item not in stale_items:
				stale_items.append(item)
		for item in stale_items:
			active_tweens.erase(item)
			if not is_instance_valid(item):
				target_cache.erase(item)

func resolve_item_size(item: ZoneItemControl) -> Vector2:
	var layout_policy = context.get_layout_policy()
	if layout_policy != null:
		return layout_policy.resolve_item_size(item)
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)

func update_hover_preview(session: ZoneDragSession) -> void:
	_preview_feedback.update_hover_preview(session, get_layout_items(session))

func get_layout_items(session: ZoneDragSession) -> Array[ZoneItemControl]:
	var layout_items: Array[ZoneItemControl] = []
	var ordered_items = context.get_items_ordered()
	for item in ordered_items:
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			continue
		if session != null and item in session.items and not item.visible:
			continue
		if item.visible:
			layout_items.append(item)
	return layout_items

func should_render_ghost_for_session(session: ZoneDragSession) -> bool:
	return _preview_feedback.should_render_ghost_for_session(session)

func create_cursor_proxy(source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	return _preview_feedback.create_cursor_proxy(source_items, anchor_item)

func get_preview_ghost() -> Control:
	return _preview_feedback.ghost_instance if _preview_feedback != null else null

func clear_preview_for_session(session: ZoneDragSession) -> void:
	_preview_feedback.clear_preview_for_session(session)

func apply_hover_feedback(items: Array[ZoneItemControl], decision: ZoneTransferDecision, preview_target, preview_source: ZoneItemControl) -> bool:
	return _preview_feedback.apply_hover_feedback(items, decision, preview_target, preview_source)

func clear_hover_feedback(items: Array[ZoneItemControl]) -> bool:
	return _preview_feedback.clear_hover_feedback(items)
