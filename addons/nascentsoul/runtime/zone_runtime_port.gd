class_name ZoneRuntimePort extends RefCounted

# Internal zone-facing port for runtime services. It keeps signal emission,
# refresh, coordinator access, and cross-zone runtime lookup out of service code.

static var _ports: Dictionary = {}

var zone = null
var bootstrap = null
var _zone_instance_id: int = 0

func _init(p_zone = null, p_bootstrap = null) -> void:
	attach(p_zone, p_bootstrap)

func attach(p_zone, p_bootstrap) -> void:
	_unregister()
	zone = p_zone
	bootstrap = p_bootstrap
	_zone_instance_id = zone.get_instance_id() if is_instance_valid(zone) else 0
	_register()

func cleanup() -> void:
	_unregister()
	bootstrap = null
	zone = null
	_zone_instance_id = 0

func get_context():
	return bootstrap.context if bootstrap != null else null

func get_input_service():
	return bootstrap.input_service if bootstrap != null else null

func get_render_service():
	return bootstrap.render_service if bootstrap != null else null

func get_transfer_service():
	return bootstrap.transfer_service if bootstrap != null else null

func get_targeting_service():
	return bootstrap.targeting_service if bootstrap != null else null

func request_refresh() -> void:
	if is_instance_valid(zone):
		zone.refresh()

func get_drag_coordinator(create_if_missing: bool = true):
	if not is_instance_valid(zone) or not zone.is_inside_tree():
		return null
	if create_if_missing:
		return ZoneDragCoordinator.ensure_for(zone)
	var viewport = zone.get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(ZoneDragCoordinator.COORDINATOR_NAME)
	if existing is ZoneDragCoordinator:
		return existing as ZoneDragCoordinator
	return null

func get_targeting_coordinator(create_if_missing: bool = true):
	if not is_instance_valid(zone) or not zone.is_inside_tree():
		return null
	if create_if_missing:
		return ZoneTargetingCoordinator.ensure_for(zone)
	var viewport = zone.get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(ZoneTargetingCoordinator.COORDINATOR_NAME)
	if existing is ZoneTargetingCoordinator:
		return existing as ZoneTargetingCoordinator
	return null

func emit_item_clicked(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_clicked.emit(item)

func emit_item_double_clicked(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_double_clicked.emit(item)

func emit_item_right_clicked(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_right_clicked.emit(item)

func emit_item_long_pressed(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_long_pressed.emit(item)

func emit_item_hover_entered(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_hover_entered.emit(item)

func emit_item_hover_exited(item: ZoneItemControl) -> void:
	if is_instance_valid(zone):
		zone.item_hover_exited.emit(item)

func emit_selection_changed() -> void:
	if not is_instance_valid(zone):
		return
	var selected_items: Array = []
	var context = get_context()
	if context != null and context.selection_state != null:
		selected_items = context.selection_state.get_selected_items()
	zone.selection_changed.emit(selected_items)

func emit_drag_started(items: Array, source_zone) -> void:
	if is_instance_valid(zone):
		zone.drag_started.emit(items, source_zone)

func emit_drag_start_rejected(items: Array, source_zone, reason: String) -> void:
	if is_instance_valid(zone):
		zone.drag_start_rejected.emit(items, source_zone, reason)

func emit_drop_preview_changed(items: Array, target_zone, target) -> void:
	if is_instance_valid(zone):
		zone.drop_preview_changed.emit(items, target_zone, target)

func emit_drop_hover_state_changed(items: Array, target_zone, decision) -> void:
	if is_instance_valid(zone):
		zone.drop_hover_state_changed.emit(items, target_zone, decision)

func emit_item_added(item: ZoneItemControl, index: int) -> void:
	if is_instance_valid(zone):
		zone.item_added.emit(item, index)

func emit_item_removed(item: ZoneItemControl, from_index: int) -> void:
	if is_instance_valid(zone):
		zone.item_removed.emit(item, from_index)

func emit_item_reordered(item: ZoneItemControl, from_index: int, to_index: int) -> void:
	if is_instance_valid(zone):
		zone.item_reordered.emit(item, from_index, to_index)

func emit_item_transferred(item: ZoneItemControl, source_zone, target_zone, target) -> void:
	if is_instance_valid(zone):
		zone.item_transferred.emit(item, source_zone, target_zone, target)

func emit_drop_rejected(items: Array, source_zone, target_zone, reason: String) -> void:
	if is_instance_valid(zone):
		zone.drop_rejected.emit(items, source_zone, target_zone, reason)

func emit_targeting_started(source_item: ZoneItemControl, source_zone, intent: ZoneTargetingIntent) -> void:
	if is_instance_valid(zone):
		zone.targeting_started.emit(source_item, source_zone, intent)

func emit_target_preview_changed(source_item: ZoneItemControl, target_zone, candidate) -> void:
	if is_instance_valid(zone):
		zone.target_preview_changed.emit(source_item, target_zone, candidate)

func emit_target_hover_state_changed(source_item: ZoneItemControl, target_zone, decision) -> void:
	if is_instance_valid(zone):
		zone.target_hover_state_changed.emit(source_item, target_zone, decision)

func emit_targeting_resolved(source_item: ZoneItemControl, source_zone, candidate, decision) -> void:
	if is_instance_valid(zone):
		zone.targeting_resolved.emit(source_item, source_zone, candidate, decision)

func emit_targeting_cancelled(source_item: ZoneItemControl, source_zone) -> void:
	if is_instance_valid(zone):
		zone.targeting_cancelled.emit(source_item, source_zone)

func emit_layout_changed() -> void:
	if is_instance_valid(zone):
		zone.layout_changed.emit()

static func for_zone(target_zone):
	if not is_instance_valid(target_zone):
		return null
	var existing = _ports.get(target_zone.get_instance_id(), null)
	if existing != null and existing.zone == target_zone:
		return existing
	if target_zone.has_method("_ensure_services"):
		target_zone._ensure_services()
		existing = _ports.get(target_zone.get_instance_id(), null)
		if existing != null and existing.zone == target_zone:
			return existing
	return null

static func resolve_context(target_zone):
	var port = for_zone(target_zone)
	return port.get_context() if port != null else null

static func resolve_input_service(target_zone):
	var port = for_zone(target_zone)
	return port.get_input_service() if port != null else null

static func resolve_render_service(target_zone):
	var port = for_zone(target_zone)
	return port.get_render_service() if port != null else null

static func resolve_transfer_service(target_zone):
	var port = for_zone(target_zone)
	return port.get_transfer_service() if port != null else null

static func resolve_drag_coordinator(target_zone, create_if_missing: bool = false):
	var port = for_zone(target_zone)
	return port.get_drag_coordinator(create_if_missing) if port != null else null

static func request_refresh_for(target_zone) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.request_refresh()

static func emit_item_hover_exited_for(target_zone, item: ZoneItemControl) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_item_hover_exited(item)

static func emit_selection_changed_for(target_zone) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_selection_changed()

static func emit_item_added_for(target_zone, item: ZoneItemControl, index: int) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_item_added(item, index)

static func emit_item_removed_for(target_zone, item: ZoneItemControl, from_index: int) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_item_removed(item, from_index)

static func emit_item_reordered_for(target_zone, item: ZoneItemControl, from_index: int, to_index: int) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_item_reordered(item, from_index, to_index)

static func emit_layout_changed_for(target_zone) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_layout_changed()

static func emit_drop_rejected_for(target_zone, items: Array, source_zone, emitter_target_zone, reason: String) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_drop_rejected(items, source_zone, emitter_target_zone, reason)

static func emit_item_transferred_for(target_zone, item: ZoneItemControl, source_zone, emitter_target_zone, target) -> void:
	var port = for_zone(target_zone)
	if port != null:
		port.emit_item_transferred(item, source_zone, emitter_target_zone, target)

func _register() -> void:
	if _zone_instance_id != 0:
		_ports[_zone_instance_id] = self

func _unregister() -> void:
	if _zone_instance_id != 0:
		var existing = _ports.get(_zone_instance_id, null)
		if existing == self:
			_ports.erase(_zone_instance_id)
