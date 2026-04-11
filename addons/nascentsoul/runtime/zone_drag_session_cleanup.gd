extends RefCounted

# Internal helper for drag-session cleanup across all involved zones.

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")

var transfer_service = null
var zone = null

func _init(p_transfer_service) -> void:
	transfer_service = p_transfer_service
	zone = transfer_service.zone

func cleanup() -> void:
	transfer_service = null
	zone = null

func cleanup_drag_session(session: ZoneDragSession, refresh_involved: bool, emit_layout_changed: bool) -> void:
	session.prune_invalid_items()
	var involved_zones = _collect_involved_drag_zones(session)
	for involved_zone in involved_zones:
		var render_service = ZoneRuntimePortScript.resolve_render_service(involved_zone)
		if render_service != null:
			render_service.clear_preview_for_session(session)
		var input_service = ZoneRuntimePortScript.resolve_input_service(involved_zone)
		if input_service != null:
			input_service.clear_hover_for_items(session.items, false)
			input_service.reset_press_state_for_item()
	for item in session.items:
		if is_instance_valid(item):
			item.visible = true
	var coordinator = _resolve_drag_coordinator(involved_zones)
	if coordinator != null:
		coordinator.clear_session()
	if not refresh_involved:
		return
	for involved_zone in involved_zones:
		ZoneRuntimePortScript.request_refresh_for(involved_zone)
		if emit_layout_changed:
			ZoneRuntimePortScript.emit_layout_changed_for(involved_zone)

func _collect_involved_drag_zones(session: ZoneDragSession) -> Array[Zone]:
	var involved_zones: Array[Zone] = []
	_append_unique_zone(involved_zones, zone)
	if session.source_zone is Zone:
		_append_unique_zone(involved_zones, session.source_zone as Zone)
	if session.hover_zone is Zone:
		_append_unique_zone(involved_zones, session.hover_zone as Zone)
	return involved_zones

func _resolve_drag_coordinator(involved_zones: Array[Zone]) -> ZoneDragCoordinator:
	for involved_zone in involved_zones:
		var coordinator = ZoneRuntimePortScript.resolve_drag_coordinator(involved_zone, false)
		if coordinator != null:
			return coordinator
	return ZoneRuntimePortScript.resolve_drag_coordinator(zone, false)

func _append_unique_zone(zones: Array[Zone], candidate: Zone) -> void:
	if candidate == null or candidate in zones:
		return
	zones.append(candidate)
