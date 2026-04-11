class_name ZoneDragCoordinator extends Node

# Internal viewport-level helper that owns the active drag session.

const COORDINATOR_NAME := "__NascentSoulDragCoordinator"
const CURSOR_PROXY_Z_INDEX := 2048
const ZoneRuntimeHooksScript = preload("res://addons/nascentsoul/runtime/zone_runtime_hooks.gd")

var active_session: ZoneDragSession = null

func _process(_delta: float) -> void:
	if active_session == null:
		set_process(false)
		return
	if is_instance_valid(active_session.cursor_proxy):
		active_session.cursor_proxy.global_position = get_viewport().get_mouse_position() - active_session.drag_offset
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var source_zone = active_session.source_zone as Zone
	if source_zone != null:
		var runtime_hooks = ZoneRuntimeHooksScript.for_zone(source_zone)
		if runtime_hooks != null:
			runtime_hooks.finalize_drag_session(active_session)
		else:
			clear_session()
	else:
		clear_session()

static func ensure_for(zone_host: Node) -> ZoneDragCoordinator:
	if zone_host == null or not zone_host.is_inside_tree():
		return null
	var viewport = zone_host.get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(COORDINATOR_NAME)
	if existing != null and existing is ZoneDragCoordinator:
		return existing as ZoneDragCoordinator
	var coordinator := ZoneDragCoordinator.new()
	coordinator.name = COORDINATOR_NAME
	viewport.add_child(coordinator)
	return coordinator

func get_session() -> ZoneDragSession:
	return active_session

func start_drag(source_zone: Node, items: Array[ZoneItemControl], anchor_item: ZoneItemControl, drag_offset: Vector2, cursor_proxy: Control) -> ZoneDragSession:
	clear_session()
	active_session = ZoneDragSession.new(source_zone, items, anchor_item, drag_offset, cursor_proxy)
	set_process(true)
	if is_instance_valid(cursor_proxy):
		cursor_proxy.top_level = true
		cursor_proxy.z_as_relative = false
		cursor_proxy.z_index = CURSOR_PROXY_Z_INDEX
		cursor_proxy.visible = true
		cursor_proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if cursor_proxy.get_parent() != self:
			if cursor_proxy.get_parent() != null:
				cursor_proxy.reparent(self, false)
			else:
				add_child(cursor_proxy)
		move_child(cursor_proxy, get_child_count() - 1)
	return active_session

func clear_session() -> void:
	if active_session == null:
		set_process(false)
		return
	active_session.cleanup()
	active_session = null
	set_process(false)
