class_name ZoneTargetingCoordinator extends Node

const COORDINATOR_NAME := "__NascentSoulTargetingCoordinator"
const ZONE_GROUP := "__NascentSoulZones"
const OVERLAY_LAYER_NAME := "__NascentSoulTargetingLayer"

var active_session: ZoneTargetingSession = null
var _overlay: Control = null
var _overlay_layer: CanvasLayer = null

func _ready() -> void:
	set_process(false)
	set_process_input(false)

func _process(_delta: float) -> void:
	if active_session == null:
		set_process(false)
		return
	var source_zone = active_session.source_zone as Zone
	if source_zone == null or not is_instance_valid(source_zone) or not source_zone.is_inside_tree() or not is_instance_valid(active_session.source_item):
		clear_session(false)
		return
	active_session.pointer_global_position = get_viewport().get_mouse_position()
	source_zone.update_targeting_session(active_session, active_session.pointer_global_position)
	_update_overlay(source_zone)

func _input(event: InputEvent) -> void:
	if active_session == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			var source_zone = active_session.source_zone as Zone
			if source_zone != null:
				source_zone.finalize_targeting_session(active_session)
			else:
				clear_session(false)
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			var cancel_zone = active_session.source_zone as Zone
			if cancel_zone != null:
				cancel_zone.cancel_targeting_session(active_session, true)
			else:
				clear_session(false)
			return
	if event is InputEventAction:
		var action_event := event as InputEventAction
		if action_event.pressed and action_event.action == &"ui_cancel":
			var cancel_zone = active_session.source_zone as Zone
			if cancel_zone != null:
				cancel_zone.cancel_targeting_session(active_session, true)
			else:
				clear_session(false)

static func ensure_for(zone_host: Node) -> ZoneTargetingCoordinator:
	if zone_host == null or not zone_host.is_inside_tree():
		return null
	var viewport = zone_host.get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(COORDINATOR_NAME)
	if existing != null and existing is ZoneTargetingCoordinator:
		return existing as ZoneTargetingCoordinator
	var coordinator := ZoneTargetingCoordinator.new()
	coordinator.name = COORDINATOR_NAME
	viewport.add_child(coordinator)
	return coordinator

func get_session() -> ZoneTargetingSession:
	return active_session

func refresh_overlay() -> void:
	if active_session == null:
		_clear_overlay()
		return
	var source_zone = active_session.source_zone as Zone
	if source_zone == null or not is_instance_valid(source_zone):
		_clear_overlay()
		return
	_update_overlay(source_zone)

func start_targeting(
	source_zone: Zone,
	source_item: Control,
	intent: ZoneTargetingIntent,
	entry_mode: StringName,
	source_anchor_global: Vector2,
	pointer_global_position: Vector2
) -> ZoneTargetingSession:
	clear_session(false)
	active_session = ZoneTargetingSession.new(source_zone, source_item, intent, entry_mode, source_anchor_global, pointer_global_position)
	set_process(true)
	set_process_input(true)
	if source_zone != null:
		source_zone.update_targeting_session(active_session, pointer_global_position)
		refresh_overlay()
	return active_session

func clear_session(keep_process_input: bool = false) -> void:
	if active_session == null:
		set_process(false)
		if not keep_process_input:
			set_process_input(false)
		_clear_overlay()
		return
	var source_zone = active_session.source_zone as Zone
	if source_zone != null and is_instance_valid(source_zone):
		source_zone.clear_targeting_feedback(false, active_session.source_item)
	active_session.cleanup()
	active_session = null
	set_process(false)
	if not keep_process_input:
		set_process_input(false)
	_clear_overlay()

func _update_overlay(source_zone: Zone) -> void:
	if source_zone == null:
		_clear_overlay()
		return
	var context = source_zone._get_context()
	var style = _resolve_style(source_zone)
	if style == null:
		_clear_overlay()
		return
	var viewport = get_viewport()
	if viewport == null:
		return
	_ensure_overlay_layer(viewport)
	if _overlay_layer != null and _overlay_layer.get_parent() == viewport:
		viewport.move_child(_overlay_layer, viewport.get_child_count() - 1)
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = style.create_overlay(context, self)
		if _overlay == null:
			return
		_overlay.name = "__NascentSoulTargetingOverlay"
		_overlay.visible = false
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.top_level = _overlay_layer == null
		if _overlay_layer != null:
			_overlay_layer.add_child(_overlay)
		else:
			viewport.add_child(_overlay)
	elif _overlay_layer != null and _overlay.top_level:
		_overlay.top_level = false
	if _overlay_layer == null and _overlay.get_parent() == viewport:
		viewport.move_child(_overlay, viewport.get_child_count() - 1)
	style.update_overlay(context, _overlay, active_session, active_session.source_anchor_global, active_session.candidate, active_session.decision, active_session.pointer_global_position)

func _resolve_style(source_zone: Zone) -> ZoneTargetingStyle:
	if active_session == null:
		return null
	if active_session.intent != null and active_session.intent.style_override != null:
		return active_session.intent.style_override
	return source_zone.get_targeting_style()

func _clear_overlay() -> void:
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = null
		_clear_overlay_layer()
		return
	var source_zone: Zone = null
	if active_session != null and active_session.source_zone is Zone:
		source_zone = active_session.source_zone as Zone
	if source_zone != null:
		var style = _resolve_style(source_zone)
		if style != null:
			style.clear_overlay(_overlay)
	if _overlay.get_parent() != null:
		_overlay.get_parent().remove_child(_overlay)
	_overlay.free()
	_overlay = null
	_clear_overlay_layer()

func _ensure_overlay_layer(viewport: Viewport) -> void:
	if _overlay_layer != null and is_instance_valid(_overlay_layer) and _overlay_layer.get_parent() == viewport:
		return
	_overlay_layer = viewport.get_node_or_null(OVERLAY_LAYER_NAME) as CanvasLayer
	if _overlay_layer == null:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.name = OVERLAY_LAYER_NAME
		_overlay_layer.layer = 120
		viewport.add_child(_overlay_layer)
	_overlay_layer.visible = true

func _clear_overlay_layer() -> void:
	if _overlay_layer == null or not is_instance_valid(_overlay_layer):
		_overlay_layer = null
		return
	if _overlay_layer.get_parent() != null:
		_overlay_layer.get_parent().remove_child(_overlay_layer)
	_overlay_layer.free()
	_overlay_layer = null
