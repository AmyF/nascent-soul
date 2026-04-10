class_name ZoneRenderService extends RefCounted

var context: ZoneContext
var zone: Zone

var ghost_instance: Control = null
var display_state: Dictionary = {}
var hover_active: bool = false
var hover_allowed: bool = false
var hover_reason: String = ""
var hover_target: ZonePlacementTarget = null
var hover_preview_target: ZonePlacementTarget = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone

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
	var placements = layout_policy.calculate(context, layout_items, zone.size, ghost_instance, ghost_hint)
	display_style.apply(context, placements)

func clear_preview() -> void:
	clear_preview_internal()
	reset_hover_feedback_tracking()
	zone.queue_redraw()

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
	clear_preview_internal()
	clear_display_state()
	reset_hover_feedback_tracking()
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
	var items_root = zone.get_items_root()
	if items_root == null:
		return
	var global_mouse = zone.get_viewport().get_mouse_position()
	var is_hovering = zone.get_global_rect().has_point(global_mouse)
	if not is_hovering:
		if session.hover_zone == zone:
			session.hover_zone = null
			session.requested_target = ZonePlacementTarget.invalid()
			session.preview_target = ZonePlacementTarget.invalid()
		if clear_hover_feedback(session.items):
			refresh()
		return
	var visible_items = get_layout_items(session)
	var space_model = context.get_space_model()
	if space_model == null:
		if clear_hover_feedback(session.items):
			refresh()
		return
	var requested_target = space_model.resolve_hover_target(context, visible_items, global_mouse, zone.get_local_mouse_position())
	requested_target = space_model.normalize_target(context, requested_target, session.items)
	var request = context.transfer_service.make_transfer_request(zone, session.source_zone, session.items, requested_target, global_mouse)
	var decision = context.transfer_service.resolve_drop_decision(request)
	var preview_target = decision.resolved_target if decision.allowed else ZonePlacementTarget.invalid()
	session.hover_zone = zone
	session.requested_target = requested_target
	session.preview_target = preview_target
	var preview_source = session.items[0] if not session.items.is_empty() and session.items[0] is ZoneItemControl else null
	if apply_hover_feedback(session.items, decision, preview_target, preview_source):
		refresh()

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
	if session == null or session.hover_zone != zone or session.preview_target == null or not session.preview_target.is_valid() or not is_instance_valid(ghost_instance):
		return false
	var items_root = zone.get_items_root()
	for item in session.items:
		if not is_instance_valid(item):
			continue
		if item.visible and item.get_parent() == items_root:
			return false
	return true

func create_ghost(source_item: ZoneItemControl) -> void:
	var preview_root = zone.get_preview_root()
	if preview_root == null or not is_instance_valid(source_item):
		return
	var ghost = create_factory_ghost(source_item)
	if ghost == null:
		ghost = source_item.create_zone_drag_ghost(context)
	if ghost == null:
		var fallback := ColorRect.new()
		fallback.color = Color(1, 1, 1, 0.18)
		fallback.custom_minimum_size = resolve_item_size(source_item)
		fallback.size = resolve_item_size(source_item)
		ghost = fallback
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ghost.get_parent() != preview_root:
		if ghost.get_parent() != null:
			ghost.reparent(preview_root, false)
		else:
			preview_root.add_child(ghost)
	ghost_instance = ghost

func create_cursor_proxy(source_item: ZoneItemControl) -> Control:
	var factory_proxy = create_factory_proxy(source_item)
	if factory_proxy != null:
		return factory_proxy
	return source_item.create_zone_drag_proxy(context)

func create_factory_ghost(source_item: ZoneItemControl) -> Control:
	var factory = context.get_drag_visual_factory()
	if factory == null:
		return null
	var created = factory.create_ghost(context, source_item)
	if created is Control and created != source_item and is_instance_valid(created):
		return created as Control
	return null

func create_factory_proxy(source_item: ZoneItemControl) -> Control:
	var factory = context.get_drag_visual_factory()
	if factory == null:
		return null
	var created = factory.create_drag_proxy(context, source_item)
	if created is Control and created != source_item and is_instance_valid(created):
		return created as Control
	return null

func clear_preview_internal() -> void:
	if is_instance_valid(ghost_instance):
		ghost_instance.queue_free()
	ghost_instance = null

func clear_preview_for_session(session: ZoneDragSession) -> void:
	var items = session.items if session != null else []
	var invalid_target = ZonePlacementTarget.invalid()
	var should_emit_preview_clear = (hover_preview_target != null and hover_preview_target.is_valid()) \
		or (session != null and session.hover_zone == zone and session.preview_target != null and session.preview_target.is_valid())
	if should_emit_preview_clear:
		zone._emit_drop_preview_changed(items, zone, invalid_target)
	if is_instance_valid(ghost_instance):
		clear_preview_internal()
	if hover_active:
		zone._emit_drop_hover_state_changed(items, zone, make_clear_hover_decision())
	reset_hover_feedback_tracking()

func apply_hover_feedback(items: Array[ZoneItemControl], decision: ZoneTransferDecision, preview_target, preview_source: ZoneItemControl) -> bool:
	var resolved_preview_target: ZonePlacementTarget = preview_target if preview_target is ZonePlacementTarget else ZonePlacementTarget.invalid()
	var refresh_needed = false
	var next_active = decision != null
	var next_allowed = decision.allowed if decision != null else false
	var next_reason = decision.reason if decision != null else ""
	var next_target = decision.resolved_target if decision != null else ZonePlacementTarget.invalid()
	if resolved_preview_target is ZonePlacementTarget and (resolved_preview_target as ZonePlacementTarget).is_valid():
		next_target = (resolved_preview_target as ZonePlacementTarget).duplicate_target()
	elif not next_allowed:
		next_target = ZonePlacementTarget.invalid()
	if next_active and next_allowed and next_target != null and next_target.is_valid():
		if not is_instance_valid(ghost_instance) and is_instance_valid(preview_source):
			create_ghost(preview_source)
			refresh_needed = true
	elif is_instance_valid(ghost_instance):
		clear_preview_internal()
		refresh_needed = true
	if hover_preview_target == null or not hover_preview_target.matches(next_target):
		zone._emit_drop_preview_changed(items, zone, next_target)
		refresh_needed = true
	if has_hover_state_changed(next_active, decision):
		zone._emit_drop_hover_state_changed(items, zone, decision if decision != null else make_clear_hover_decision())
		refresh_needed = true
	hover_active = next_active
	hover_allowed = next_allowed
	hover_reason = next_reason
	hover_target = next_target.duplicate_target() if next_target != null else ZonePlacementTarget.invalid()
	hover_preview_target = next_target.duplicate_target() if next_target != null else ZonePlacementTarget.invalid()
	return refresh_needed

func clear_hover_feedback(items: Array[ZoneItemControl]) -> bool:
	var refresh_needed = false
	if is_instance_valid(ghost_instance):
		clear_preview_internal()
		refresh_needed = true
	if hover_preview_target != null and hover_preview_target.is_valid():
		zone._emit_drop_preview_changed(items, zone, ZonePlacementTarget.invalid())
		refresh_needed = true
	if hover_active:
		zone._emit_drop_hover_state_changed(items, zone, make_clear_hover_decision())
		refresh_needed = true
	reset_hover_feedback_tracking()
	return refresh_needed

func has_hover_state_changed(active: bool, decision: ZoneTransferDecision) -> bool:
	if hover_active != active:
		return true
	if not active or decision == null:
		return false
	var next_target = decision.resolved_target if decision.resolved_target != null else ZonePlacementTarget.invalid()
	return hover_allowed != decision.allowed or hover_reason != decision.reason or hover_target == null or not hover_target.matches(next_target)

func make_clear_hover_decision() -> ZoneTransferDecision:
	return ZoneTransferDecision.new(false, "", ZonePlacementTarget.invalid())

func reset_hover_feedback_tracking() -> void:
	hover_active = false
	hover_allowed = false
	hover_reason = ""
	hover_target = ZonePlacementTarget.invalid()
	hover_preview_target = ZonePlacementTarget.invalid()
