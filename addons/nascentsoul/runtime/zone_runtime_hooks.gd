class_name ZoneRuntimeHooks extends RefCounted

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")

var zone = null
var bootstrap = null
var runtime_port = null

func _init(p_zone = null, p_bootstrap = null, p_runtime_port = null) -> void:
	attach(p_zone, p_bootstrap, p_runtime_port)

func attach(p_zone, p_bootstrap, p_runtime_port) -> void:
	zone = p_zone
	bootstrap = p_bootstrap
	runtime_port = p_runtime_port

func cleanup() -> void:
	runtime_port = null
	bootstrap = null
	zone = null

func get_transfer_handoff_count() -> int:
	var context = _context()
	return context.get_transfer_handoff_count() if context != null else 0

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	var context = _context()
	return context.has_transfer_handoff(item) if context != null else false

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	var context = _context()
	if context != null:
		context.set_transfer_handoff(item, snapshot)

func clear_transfer_handoffs() -> void:
	var context = _context()
	if context != null:
		context.clear_transfer_handoffs()

func capture_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	var transfer_service = _transfer_service()
	return transfer_service.build_transfer_snapshots(moving_items, drop_position, anchor_item) if transfer_service != null else {}

func resolve_transfer_origin(moving_items: Array[ZoneItemControl]):
	var transfer_service = _transfer_service()
	return transfer_service.resolve_programmatic_transfer_global_position(moving_items) if transfer_service != null else Vector2.ZERO

func preview_transfer(items: Array[ZoneItemControl], source_zone: Node, placement_target: ZonePlacementTarget, global_position: Vector2, preview_source: ZoneItemControl = null) -> ZoneTransferDecision:
	var transfer_service = _transfer_service()
	var render_service = _render_service()
	if transfer_service == null or render_service == null:
		return ZoneTransferDecision.new()
	var request = transfer_service.make_transfer_request(zone, source_zone, items, placement_target, global_position)
	var decision = transfer_service.resolve_drop_decision(request)
	var resolved_preview_source = preview_source
	if resolved_preview_source == null and not items.is_empty():
		resolved_preview_source = items[0]
	if render_service.apply_hover_feedback(items, decision, decision.resolved_target if decision.allowed else ZonePlacementTarget.invalid(), resolved_preview_source):
		_request_refresh()
	return decision

func update_targeting_session(session: ZoneTargetingSession, global_position: Vector2) -> void:
	var targeting_service = _targeting_service()
	if targeting_service != null:
		targeting_service.update_targeting_session(session, global_position)

func finalize_targeting_session(session: ZoneTargetingSession) -> void:
	var targeting_service = _targeting_service()
	if targeting_service != null:
		targeting_service.finalize_targeting_session(session)

func cancel_targeting_session(session: ZoneTargetingSession, emit_signal: bool) -> void:
	var targeting_service = _targeting_service()
	if targeting_service != null:
		targeting_service.cancel_targeting_session(session, emit_signal)

func clear_targeting_feedback(emit_clear_signals: bool, source_item: ZoneItemControl = null) -> void:
	var targeting_service = _targeting_service()
	if targeting_service != null:
		targeting_service.clear_targeting_feedback(emit_clear_signals, source_item)

func finalize_drag_session(session: ZoneDragSession = null) -> void:
	var transfer_service = _transfer_service()
	if transfer_service != null:
		transfer_service.finalize_drag_session(session)

static func for_zone(target_zone):
	var port = ZoneRuntimePortScript.for_zone(target_zone)
	if port == null or port.bootstrap == null:
		return null
	return port.bootstrap.runtime_hooks if port.bootstrap.runtime_hooks is ZoneRuntimeHooks else null

func _context():
	return bootstrap.context if bootstrap != null else null

func _render_service():
	return bootstrap.render_service if bootstrap != null else null

func _transfer_service():
	return bootstrap.transfer_service if bootstrap != null else null

func _targeting_service():
	return bootstrap.targeting_service if bootstrap != null else null

func _request_refresh() -> void:
	if runtime_port != null:
		runtime_port.request_refresh()
	elif is_instance_valid(zone):
		zone.refresh()
