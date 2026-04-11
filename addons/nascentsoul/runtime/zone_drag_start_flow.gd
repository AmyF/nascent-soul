class_name ZoneDragStartFlow extends RefCounted

const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

var transfer_service = null
var context: ZoneContext = null
var zone = null
var store: ZoneStore = null
var runtime_port = null

func _init(p_transfer_service, p_context: ZoneContext, p_store: ZoneStore, p_runtime_port) -> void:
	transfer_service = p_transfer_service
	context = p_context
	zone = context.zone
	store = p_store
	runtime_port = p_runtime_port

func cleanup() -> void:
	runtime_port = null
	store = null
	zone = null
	context = null
	transfer_service = null

func start_drag(items: Array[ZoneItemControl], pointer_global_position = null, requested_anchor_item: ZoneItemControl = null) -> void:
	if zone.get_items_root() == null or items.is_empty():
		return
	var candidate_items = _sanitize_drag_items(items)
	var anchor_item = _resolve_drag_anchor(requested_anchor_item, candidate_items)
	if not is_instance_valid(anchor_item):
		return
	var drag_start = _evaluate_drag_start(anchor_item, candidate_items)
	if not drag_start.allowed:
		if runtime_port != null:
			runtime_port.emit_drag_start_rejected(drag_start.items, zone, drag_start.reason)
		return
	var valid_items = _sanitize_drag_items(drag_start.items, anchor_item)
	if valid_items.is_empty():
		if runtime_port != null:
			runtime_port.emit_drag_start_rejected([anchor_item], zone, "No draggable items remain.")
		return
	anchor_item = _resolve_drag_anchor(anchor_item, valid_items)
	if not is_instance_valid(anchor_item):
		if runtime_port != null:
			runtime_port.emit_drag_start_rejected(valid_items, zone, "The drag anchor is no longer available.")
		return
	var coordinator = transfer_service.get_drag_coordinator()
	var input_service = transfer_service.input_service
	var render_service = transfer_service.render_service
	if coordinator == null or input_service == null or render_service == null:
		return
	input_service.clear_hover_for_items(valid_items, true)
	var pointer_position = anchor_item.global_position + anchor_item.size * 0.5
	if anchor_item.get_viewport() != null:
		pointer_position = anchor_item.get_global_mouse_position()
	if pointer_global_position is Vector2:
		pointer_position = pointer_global_position as Vector2
	var drag_offset = pointer_position - anchor_item.global_position
	var cursor_proxy = render_service.create_cursor_proxy(valid_items, anchor_item)
	coordinator.start_drag(zone, valid_items, anchor_item, drag_offset, cursor_proxy)
	for item in valid_items:
		item.visible = false
	if runtime_port != null:
		runtime_port.emit_drag_started(valid_items, zone)
	transfer_service.refresh()

func _sanitize_drag_items(items: Array[ZoneItemControl], anchor_item: ZoneItemControl = null) -> Array[ZoneItemControl]:
	var valid_items: Array[ZoneItemControl] = []
	var requested: Dictionary = {}
	for item in items:
		if is_instance_valid(item):
			requested[item.get_instance_id()] = item
	if is_instance_valid(anchor_item):
		requested[anchor_item.get_instance_id()] = anchor_item
	if requested.is_empty():
		return valid_items
	for item in store.items:
		if is_instance_valid(item) and requested.has(item.get_instance_id()):
			valid_items.append(item)
	return valid_items

func _resolve_drag_anchor(requested_anchor_item: ZoneItemControl, items: Array[ZoneItemControl]) -> ZoneItemControl:
	if is_instance_valid(requested_anchor_item) and requested_anchor_item in items:
		return requested_anchor_item
	for item in items:
		if is_instance_valid(item):
			return item
	return null

func _evaluate_drag_start(anchor_item: ZoneItemControl, candidate_items: Array[ZoneItemControl]):
	var policy = context.get_transfer_policy()
	var selected_items = candidate_items.duplicate()
	var decision = policy.evaluate_drag_start(context, anchor_item, selected_items) if policy != null else ZoneDragStartDecisionScript.new(true, "", selected_items)
	if decision == null:
		decision = ZoneDragStartDecisionScript.new(true, "", selected_items)
	var resolved_items = _sanitize_drag_items(decision.items, anchor_item)
	if decision.allowed and resolved_items.is_empty():
		return ZoneDragStartDecisionScript.new(false, "No draggable items remain.", [anchor_item])
	var reported_items = resolved_items
	if not decision.allowed and reported_items.is_empty():
		reported_items = [anchor_item]
	return ZoneDragStartDecisionScript.new(decision.allowed, decision.reason, reported_items)
