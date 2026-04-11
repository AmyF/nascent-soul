@tool
class_name Zone extends Control

const ITEMS_ROOT_NAME := "ItemsRoot"
const PREVIEW_ROOT_NAME := "PreviewRoot"
const TARGETING_ZONE_GROUP := "__NascentSoulZones"

signal item_clicked(item: ZoneItemControl)
signal item_double_clicked(item: ZoneItemControl)
signal item_right_clicked(item: ZoneItemControl)
signal item_long_pressed(item: ZoneItemControl)
signal item_hover_entered(item: ZoneItemControl)
signal item_hover_exited(item: ZoneItemControl)
signal selection_changed(items: Array)
signal drag_started(items: Array, source_zone: Zone)
signal drag_start_rejected(items: Array, source_zone: Zone, reason: String)
signal drop_preview_changed(items: Array, target_zone: Zone, target)
signal drop_hover_state_changed(items: Array, target_zone: Zone, decision)
signal item_added(item: ZoneItemControl, index: int)
signal item_removed(item: ZoneItemControl, from_index: int)
signal item_reordered(item: ZoneItemControl, from_index: int, to_index: int)
signal item_transferred(item: ZoneItemControl, source_zone: Zone, target_zone: Zone, target)
signal drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String)
signal targeting_started(source_item: ZoneItemControl, source_zone: Zone, intent: ZoneTargetingIntent)
signal target_preview_changed(source_item: ZoneItemControl, target_zone: Zone, candidate)
signal target_hover_state_changed(source_item: ZoneItemControl, target_zone: Zone, decision)
signal targeting_resolved(source_item: ZoneItemControl, source_zone: Zone, candidate, decision)
signal targeting_cancelled(source_item: ZoneItemControl, source_zone: Zone)
signal layout_changed()

var _config: ZoneConfig = null
var _items_root: Control = null
var _preview_root: Control = null

var _default_config: ZoneConfig = null

var _store: ZoneStore = null
var _context: ZoneContext = null
var _input_service: ZoneInputService = null
var _render_service: ZoneRenderService = null
var _transfer_service: ZoneTransferService = null
var _targeting_service: ZoneTargetingService = null

@export_group("Zone")
@export var config: ZoneConfig:
	get:
		return _config
	set(value):
		var next_config: ZoneConfig = value.duplicate_config() if value != null else null
		if _config == next_config:
			return
		_config = next_config
		_handle_configuration_changed()

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(TARGETING_ZONE_GROUP)
	_ensure_internal_nodes()
	_ensure_services()
	update_configuration_warnings()
	queue_redraw()
	_bind_items_root_signals()
	_transfer_service.rebuild_items_from_root()
	_input_service.bind()
	call_deferred("refresh")
	set_process(not Engine.is_editor_hint())
	var resized_callable = Callable(self, "_on_zone_resized")
	if not resized.is_connected(resized_callable):
		resized.connect(resized_callable)

func _exit_tree() -> void:
	var drag_coordinator = _get_drag_coordinator(false)
	if drag_coordinator != null and drag_coordinator.get_session() != null:
		var drag_session = drag_coordinator.get_session()
		if drag_session.source_zone == self or drag_session.hover_zone == self:
			drag_coordinator.clear_session()
	var targeting_coordinator = _get_targeting_coordinator(false)
	if targeting_coordinator != null and targeting_coordinator.get_session() != null:
		var session = targeting_coordinator.get_session()
		if session.source_zone == self or session.candidate.target_zone == self:
			targeting_coordinator.clear_session()
	_unbind_items_root_signals(_items_root)
	_cleanup_runtime_services()
	remove_from_group(TARGETING_ZONE_GROUP)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_ensure_services()
	_transfer_service.process(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	var stylebox = get_theme_stylebox("panel", "Panel")
	if stylebox != null:
		draw_style_box(stylebox, Rect2(Vector2.ZERO, size))

func _get_configuration_warnings() -> PackedStringArray:
	if not is_inside_tree():
		return PackedStringArray()
	_ensure_internal_nodes()
	_ensure_services()
	var warnings := PackedStringArray()
	var resolved_layout = _context.get_layout_policy()
	var resolved_display = _context.get_display_style()
	if clip_contents and (resolved_layout is ZoneHandLayout or resolved_layout is ZonePileLayout or resolved_display is ZoneCardDisplay):
		warnings.append("Zone clips its children. Hover lift, drag previews, and pile overlap may be cut off.")
	if size != Vector2.ZERO:
		if resolved_layout is ZoneHandLayout and (resolved_layout as ZoneHandLayout).would_escape_container(size):
			warnings.append("The current hand layout values push cards outside the zone. Reduce arch settings or use a taller zone.")
		if resolved_layout is ZonePileLayout and (resolved_layout as ZonePileLayout).would_escape_container(size):
			warnings.append("The current pile layout values push cards outside the zone. Reduce overlap or increase the zone size.")
	for child in get_children():
		if _is_expected_direct_child(child):
			continue
		if child is Control:
			warnings.append("Direct child '%s' is not managed. Put zone items under ItemsRoot instead of attaching them directly to Zone." % child.name)
			break
	return warnings

func refresh() -> void:
	_ensure_internal_nodes()
	_ensure_services()
	_render_service.refresh()
	queue_redraw()

func get_space_model() -> ZoneSpaceModel:
	_ensure_services()
	return _context.get_space_model()

func get_layout_policy() -> ZoneLayoutPolicy:
	_ensure_services()
	return _context.get_layout_policy()

func get_display_style() -> ZoneDisplayStyle:
	_ensure_services()
	return _context.get_display_style()

func get_interaction() -> ZoneInteraction:
	_ensure_services()
	return _context.get_interaction()

func get_sort_policy() -> ZoneSortPolicy:
	_ensure_services()
	return _context.get_sort_policy()

func get_transfer_policy() -> ZoneTransferPolicy:
	_ensure_services()
	return _context.get_transfer_policy()

func get_drag_visual_factory() -> ZoneDragVisualFactory:
	_ensure_services()
	return _context.get_drag_visual_factory()

func get_targeting_style() -> ZoneTargetingStyle:
	_ensure_services()
	return _context.get_targeting_style()

func get_targeting_policy() -> ZoneTargetingPolicy:
	_ensure_services()
	return _context.get_targeting_policy()

func get_items_root() -> Control:
	_ensure_internal_nodes()
	return _items_root

func get_preview_root() -> Control:
	_ensure_internal_nodes()
	return _preview_root

func get_items() -> Array[ZoneItemControl]:
	_ensure_services()
	return _context.get_items()

func get_sorted_items() -> Array[ZoneItemControl]:
	_ensure_services()
	var items = _context.get_items_ordered()
	var sort_policy = _context.get_sort_policy()
	if sort_policy == null:
		return items
	return sort_policy.sort_items(_context, items)

func get_item_count() -> int:
	_ensure_services()
	return _context.get_item_count()

func get_selected_items() -> Array[ZoneItemControl]:
	_ensure_services()
	return _context.selection_state.get_selected_items()

func get_hovered_item() -> ZoneItemControl:
	_ensure_services()
	return _context.selection_state.hovered_item if _context.selection_state != null else null

func is_hovered(item: ZoneItemControl) -> bool:
	_ensure_services()
	return _context.selection_state.hovered_item == item if _context.selection_state != null else false

func get_item_target(item: ZoneItemControl) -> ZonePlacementTarget:
	_ensure_services()
	return _context.get_item_target(item)

func get_items_at_target(target: ZonePlacementTarget) -> Array[ZoneItemControl]:
	_ensure_services()
	return _context.get_items_at_target(target)

func is_selected(item: ZoneItemControl) -> bool:
	_ensure_services()
	return _context.selection_state.is_selected(item)

func has_item(item: ZoneItemControl) -> bool:
	_ensure_services()
	return _context.has_item(item)

func add_item(item: ZoneItemControl, placement_target: ZonePlacementTarget = null) -> bool:
	_ensure_services()
	return _transfer_service.add_item(item, _coerce_placement_target(placement_target))

func remove_item(item: ZoneItemControl) -> bool:
	_ensure_services()
	return _transfer_service.remove_item(item)

func perform_transfer(command: ZoneTransferCommand) -> bool:
	_ensure_services()
	return _transfer_service.perform_transfer(command)

func clear_selection() -> void:
	_ensure_services()
	_input_service.clear_selection()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	_ensure_services()
	_input_service.select_item(item, additive)

func start_drag(items: Array[ZoneItemControl], anchor_item: ZoneItemControl = null) -> void:
	_ensure_services()
	_transfer_service.start_drag(items, anchor_item)

func begin_targeting(command: ZoneTargetingCommand) -> bool:
	_ensure_services()
	if command == null:
		return false
	if command.source_zone == null:
		command.source_zone = self
	return _targeting_service.begin_targeting(command)

func cancel_targeting() -> void:
	_ensure_services()
	_targeting_service.cancel_targeting()

func cancel_drag(session: ZoneDragSession = null) -> void:
	_ensure_services()
	_transfer_service.cancel_drag(session)

func perform_drop(session: ZoneDragSession) -> bool:
	_ensure_services()
	return _transfer_service.perform_drop(session)

func get_display_state(style: Resource) -> Dictionary:
	_ensure_services()
	return _render_service.get_display_state(style)

func clear_display_state() -> void:
	_ensure_services()
	_render_service.clear_display_state()

func get_transfer_handoff_count() -> int:
	_ensure_services()
	return _store.get_transfer_handoff_count()

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	_ensure_services()
	return _store.has_transfer_handoff(item)

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	_ensure_services()
	_store.set_transfer_handoff(item, snapshot)

func clear_transfer_handoffs() -> void:
	_ensure_services()
	_store.clear_transfer_handoffs()

func capture_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	_ensure_services()
	return _transfer_service.build_transfer_snapshots(moving_items, drop_position, anchor_item)

func resolve_transfer_origin(moving_items: Array[ZoneItemControl]):
	_ensure_services()
	return _transfer_service.resolve_programmatic_transfer_global_position(moving_items)

func preview_transfer(items: Array[ZoneItemControl], source_zone: Node, placement_target: ZonePlacementTarget, global_position: Vector2, preview_source: ZoneItemControl = null) -> ZoneTransferDecision:
	_ensure_services()
	var request = _transfer_service.make_transfer_request(self, source_zone, items, placement_target, global_position)
	var decision = _transfer_service.resolve_drop_decision(request)
	var resolved_preview_source = preview_source
	if resolved_preview_source == null and not items.is_empty():
		resolved_preview_source = items[0]
	if _render_service.apply_hover_feedback(items, decision, decision.resolved_target if decision.allowed else ZonePlacementTarget.invalid(), resolved_preview_source):
		refresh()
	return decision

func is_targeting() -> bool:
	return get_targeting_session() != null

func get_drag_session() -> ZoneDragSession:
	var coordinator = _get_drag_coordinator(false)
	if coordinator == null:
		return null
	var session = coordinator.get_session()
	if session == null:
		return null
	if session.source_zone == self or session.hover_zone == self:
		return session
	return null

func get_targeting_session() -> ZoneTargetingSession:
	var coordinator = _get_targeting_coordinator(false)
	if coordinator == null:
		return null
	var session = coordinator.get_session()
	if session != null and session.source_zone == self:
		return session
	return null

func get_item_at_global_position(global_position: Vector2) -> ZoneItemControl:
	_ensure_services()
	return _context.get_item_at_global_position(global_position)

func get_first_open_target(item: Control) -> ZonePlacementTarget:
	_ensure_services()
	var space_model = _context.get_space_model()
	if space_model == null:
		return ZonePlacementTarget.invalid()
	return space_model.get_first_open_target(_context, item)

func resolve_target_anchor(target: ZonePlacementTarget) -> Vector2:
	_ensure_services()
	return _context.resolve_target_anchor(target)

func update_targeting_session(session: ZoneTargetingSession, global_position: Vector2) -> void:
	_ensure_services()
	_targeting_service.update_targeting_session(session, global_position)

func finalize_targeting_session(session: ZoneTargetingSession) -> void:
	_ensure_services()
	_targeting_service.finalize_targeting_session(session)

func cancel_targeting_session(session: ZoneTargetingSession, emit_signal: bool) -> void:
	_ensure_services()
	_targeting_service.cancel_targeting_session(session, emit_signal)

func clear_targeting_feedback(emit_clear_signals: bool, source_item: ZoneItemControl = null) -> void:
	_ensure_services()
	_targeting_service.clear_targeting_feedback(emit_clear_signals, source_item)

func finalize_drag_session(session: ZoneDragSession = null) -> void:
	_ensure_services()
	_transfer_service.finalize_drag_session(session)

func _get_drag_coordinator(create_if_missing: bool = true) -> ZoneDragCoordinator:
	if not is_inside_tree():
		return null
	if create_if_missing:
		return ZoneDragCoordinator.ensure_for(self)
	var viewport = get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(ZoneDragCoordinator.COORDINATOR_NAME)
	if existing is ZoneDragCoordinator:
		return existing as ZoneDragCoordinator
	return null

func _get_targeting_coordinator(create_if_missing: bool = true) -> ZoneTargetingCoordinator:
	if not is_inside_tree():
		return null
	if create_if_missing:
		return ZoneTargetingCoordinator.ensure_for(self)
	var viewport = get_viewport()
	if viewport == null:
		return null
	var existing = viewport.get_node_or_null(ZoneTargetingCoordinator.COORDINATOR_NAME)
	if existing is ZoneTargetingCoordinator:
		return existing as ZoneTargetingCoordinator
	return null

func _get_context() -> ZoneContext:
	_ensure_services()
	return _context

func _get_store() -> ZoneStore:
	_ensure_services()
	return _store

func _get_input_service() -> ZoneInputService:
	_ensure_services()
	return _input_service

func _get_render_service() -> ZoneRenderService:
	_ensure_services()
	return _render_service

func _get_transfer_service() -> ZoneTransferService:
	_ensure_services()
	return _transfer_service

func _get_targeting_service() -> ZoneTargetingService:
	_ensure_services()
	return _targeting_service

func _make_transfer_request(target_zone: Zone, source_zone: Node, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTransferRequest:
	_ensure_services()
	return _transfer_service.make_transfer_request(target_zone, source_zone, items, placement_target, global_position)

func _resolve_drop_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	_ensure_services()
	return _transfer_service.resolve_drop_decision(request)

func _apply_hover_feedback(items: Array[ZoneItemControl], decision: ZoneTransferDecision, preview_target, preview_source: ZoneItemControl) -> bool:
	_ensure_services()
	return _render_service.apply_hover_feedback(items, decision, preview_target, preview_source)

func _build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	_ensure_services()
	return _transfer_service.build_transfer_snapshots(moving_items, drop_position, anchor_item)

func _resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	_ensure_services()
	return _transfer_service.resolve_programmatic_transfer_global_position(moving_items)

func _ensure_services() -> void:
	if _store != null and _context != null and _input_service != null and _render_service != null and _transfer_service != null and _targeting_service != null:
		_context.update_config(_resolved_config())
		return
	if _store == null:
		_store = ZoneStore.new()
	if _context == null:
		_context = ZoneContext.new(self, _store, _resolved_config())
	else:
		_context.store = _store
		_context.zone = self
		_context.update_config(_resolved_config())
	if _input_service == null:
		_input_service = ZoneInputService.new(_context)
	if _render_service == null:
		_render_service = ZoneRenderService.new(_context)
	if _transfer_service == null:
		_transfer_service = ZoneTransferService.new(_context)
	if _targeting_service == null:
		_targeting_service = ZoneTargetingService.new(_context)
	_context.bind_services(_input_service, _render_service, _transfer_service, _targeting_service)
	_transfer_service.bind_services(_input_service, _render_service, _targeting_service)

func _cleanup_runtime_services() -> void:
	if _input_service != null:
		_input_service.cleanup()
	if _targeting_service != null:
		_targeting_service.cleanup()
	if _transfer_service != null:
		_transfer_service.cleanup()
	if _render_service != null:
		_render_service.cleanup()
	if _context != null:
		_context.cleanup()
	if _store != null:
		_store.cleanup()
	_input_service = null
	_targeting_service = null
	_transfer_service = null
	_render_service = null
	_context = null
	_store = null

func _resolved_config() -> ZoneConfig:
	if _config != null:
		return _config
	return _ensure_default_config()

func _ensure_default_config() -> ZoneConfig:
	if _default_config != null:
		return _default_config
	var resolved := ZoneConfig.new()
	resolved.space_model = ZoneLinearSpaceModel.new()
	var layout := ZoneHBoxLayout.new()
	layout.item_spacing = 14.0
	layout.padding_left = 12.0
	layout.padding_top = 12.0
	resolved.layout_policy = layout
	resolved.display_style = ZoneCardDisplay.new()
	resolved.interaction = ZoneInteraction.new()
	resolved.sort_policy = ZoneManualSort.new()
	resolved.transfer_policy = ZoneAllowAllTransferPolicy.new()
	resolved.drag_visual_factory = ZoneConfigurableDragVisualFactory.new()
	resolved.targeting_style = ZoneArrowTargetingStyle.new()
	resolved.targeting_policy = ZoneTargetAllowAllPolicy.new()
	_default_config = resolved
	return _default_config

func _ensure_internal_nodes() -> void:
	_items_root = _ensure_internal_root(_items_root, ITEMS_ROOT_NAME)
	_preview_root = _ensure_internal_root(_preview_root, PREVIEW_ROOT_NAME)
	if _items_root != null and _preview_root != null and _items_root.get_index() > _preview_root.get_index():
		move_child(_items_root, 0)
	if _preview_root != null:
		move_child(_preview_root, get_child_count() - 1)

func _ensure_internal_root(existing: Control, node_name: String) -> Control:
	var root = existing
	if root == null or not is_instance_valid(root) or root.get_parent() != self:
		root = _find_internal_root(node_name)
	if root == null:
		root = Control.new()
		root.name = node_name
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(root)
	_merge_duplicate_internal_roots(root, node_name)
	_sync_internal_root_owner(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	root.focus_mode = Control.FOCUS_NONE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = false
	return root

func _find_internal_root(node_name: String) -> Control:
	for child in get_children():
		if child is Control and child.name == node_name:
			return child as Control
	return null

func _merge_duplicate_internal_roots(root: Control, node_name: String) -> void:
	if root == null:
		return
	var duplicate_roots: Array[Control] = []
	for child in get_children():
		if child == root:
			continue
		if child is Control and child.name == node_name:
			duplicate_roots.append(child as Control)
	for duplicate_root in duplicate_roots:
		for duplicate_child in duplicate_root.get_children():
			if duplicate_child == null:
				continue
			duplicate_child.reparent(root, true)
		duplicate_root.queue_free()

func _sync_internal_root_owner(root: Node) -> void:
	if root == null:
		return
	if owner != null and root.owner != owner:
		root.owner = owner

func _is_expected_direct_child(child: Node) -> bool:
	return child == _items_root \
		or child == _preview_root \
		or child.name.begins_with("__NascentSoul")

func _handle_configuration_changed() -> void:
	if not is_inside_tree():
		return
	_ensure_internal_nodes()
	_ensure_services()
	_context.update_config(_resolved_config())
	update_configuration_warnings()
	queue_redraw()
	if is_inside_tree():
		call_deferred("_rebind_after_configuration_change")

func _rebind_after_configuration_change() -> void:
	_transfer_service.rebuild_items_from_root()
	_input_service.bind()
	refresh()

func _on_zone_resized() -> void:
	refresh()
	_emit_layout_changed()

func _bind_items_root_signals() -> void:
	if _items_root == null:
		return
	var entered_callable = Callable(self, "_on_items_root_child_entered")
	if not _items_root.child_entered_tree.is_connected(entered_callable):
		_items_root.child_entered_tree.connect(entered_callable)
	var exiting_callable = Callable(self, "_on_items_root_child_exiting")
	if not _items_root.child_exiting_tree.is_connected(exiting_callable):
		_items_root.child_exiting_tree.connect(exiting_callable)

func _unbind_items_root_signals(items_root: Control) -> void:
	if items_root == null:
		return
	var entered_callable = Callable(self, "_on_items_root_child_entered")
	if items_root.child_entered_tree.is_connected(entered_callable):
		items_root.child_entered_tree.disconnect(entered_callable)
	var exiting_callable = Callable(self, "_on_items_root_child_exiting")
	if items_root.child_exiting_tree.is_connected(exiting_callable):
		items_root.child_exiting_tree.disconnect(exiting_callable)

func _on_items_root_child_entered(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _on_items_root_child_exiting(_node: Node) -> void:
	call_deferred("_handle_items_root_structure_changed")

func _handle_items_root_structure_changed() -> void:
	if not is_instance_valid(self):
		return
	_ensure_services()
	_transfer_service.rebuild_items_from_root()
	_input_service.sync_item_bindings()
	var coordinator = _get_drag_coordinator(false)
	if coordinator == null or coordinator.get_session() == null:
		refresh()
		_emit_layout_changed()

func _coerce_placement_target(value):
	if value == null:
		return null
	if value is ZonePlacementTarget:
		return (value as ZonePlacementTarget).duplicate_target()
	return null

func _emit_item_clicked(item: ZoneItemControl) -> void:
	item_clicked.emit(item)

func _emit_item_double_clicked(item: ZoneItemControl) -> void:
	item_double_clicked.emit(item)

func _emit_item_right_clicked(item: ZoneItemControl) -> void:
	item_right_clicked.emit(item)

func _emit_item_long_pressed(item: ZoneItemControl) -> void:
	item_long_pressed.emit(item)

func _emit_item_hover_entered(item: ZoneItemControl) -> void:
	item_hover_entered.emit(item)

func _emit_item_hover_exited(item: ZoneItemControl) -> void:
	item_hover_exited.emit(item)

func _emit_selection_changed() -> void:
	selection_changed.emit(get_selected_items())

func _emit_drag_started(items: Array[ZoneItemControl], source_zone: Zone) -> void:
	drag_started.emit(items, source_zone)

func _emit_drag_start_rejected(items: Array, source_zone: Zone, reason: String) -> void:
	drag_start_rejected.emit(items, source_zone, reason)

func _emit_drop_preview_changed(items: Array, target_zone: Zone, target) -> void:
	drop_preview_changed.emit(items, target_zone, target)

func _emit_drop_hover_state_changed(items: Array, target_zone: Zone, decision) -> void:
	drop_hover_state_changed.emit(items, target_zone, decision)

func _emit_item_added(item: ZoneItemControl, index: int) -> void:
	item_added.emit(item, index)

func _emit_item_removed(item: ZoneItemControl, from_index: int) -> void:
	item_removed.emit(item, from_index)

func _emit_item_reordered(item: ZoneItemControl, from_index: int, to_index: int) -> void:
	item_reordered.emit(item, from_index, to_index)

func _emit_item_transferred(item: ZoneItemControl, source_zone: Zone, target_zone: Zone, target) -> void:
	item_transferred.emit(item, source_zone, target_zone, target)

func _emit_drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String) -> void:
	drop_rejected.emit(items, source_zone, target_zone, reason)

func _emit_targeting_started(source_item: ZoneItemControl, source_zone: Zone, intent: ZoneTargetingIntent) -> void:
	targeting_started.emit(source_item, source_zone, intent)

func _emit_target_preview_changed(source_item: ZoneItemControl, target_zone: Zone, candidate) -> void:
	target_preview_changed.emit(source_item, target_zone, candidate)

func _emit_target_hover_state_changed(source_item: ZoneItemControl, target_zone: Zone, decision) -> void:
	target_hover_state_changed.emit(source_item, target_zone, decision)

func _emit_targeting_resolved(source_item: ZoneItemControl, source_zone: Zone, candidate, decision) -> void:
	targeting_resolved.emit(source_item, source_zone, candidate, decision)

func _emit_targeting_cancelled(source_item: ZoneItemControl, source_zone: Zone) -> void:
	targeting_cancelled.emit(source_item, source_zone)

func _emit_layout_changed() -> void:
	layout_changed.emit()
