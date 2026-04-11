@tool
class_name Zone extends Control

# Public facade for NascentSoul zone behavior. Game code should prefer Zone,
# ZoneConfig, commands, and signals over runtime/* helpers or private _get_* APIs.

const ITEMS_ROOT_NAME := "ItemsRoot"
const PREVIEW_ROOT_NAME := "PreviewRoot"
const TARGETING_ZONE_GROUP := "__NascentSoulZones"
const ZoneConfigurationWarningsScript := preload("res://addons/nascentsoul/runtime/zone_configuration_warnings.gd")
const ZoneInternalRootsScript := preload("res://addons/nascentsoul/runtime/zone_internal_roots.gd")
const ZoneRuntimeBootstrapScript := preload("res://addons/nascentsoul/runtime/zone_runtime_bootstrap.gd")
const ZoneRuntimePortScript := preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")

# Public interaction surface.
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

var _internal_roots = null
var _runtime_bootstrap = null

var _store: ZoneStore = null
var _context: ZoneContext = null
var _input_service: ZoneInputService = null
var _render_service: ZoneRenderService = null
var _transfer_service: ZoneTransferService = null
var _targeting_service: ZoneTargetingService = null

# Public configuration.
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
	var drag_coordinator = ZoneRuntimePortScript.resolve_drag_coordinator(self, false)
	if drag_coordinator != null and drag_coordinator.get_session() != null:
		var drag_session = drag_coordinator.get_session()
		if drag_session.source_zone == self or drag_session.hover_zone == self:
			drag_coordinator.clear_session()
	var targeting_coordinator = ZoneRuntimePortScript.resolve_targeting_coordinator(self, false)
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
	return ZoneConfigurationWarningsScript.build(self, _context, Callable(self, "_is_expected_direct_child"))

# Public gameplay API.
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

func is_targeting() -> bool:
	return get_targeting_session() != null

func get_drag_session() -> ZoneDragSession:
	var coordinator = ZoneRuntimePortScript.resolve_drag_coordinator(self, false)
	if coordinator == null:
		return null
	var session = coordinator.get_session()
	if session == null:
		return null
	if session.source_zone == self or session.hover_zone == self:
		return session
	return null

func get_targeting_session() -> ZoneTargetingSession:
	var coordinator = ZoneRuntimePortScript.resolve_targeting_coordinator(self, false)
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

func _ensure_services() -> void:
	if _runtime_bootstrap == null:
		_runtime_bootstrap = ZoneRuntimeBootstrapScript.new()
	_runtime_bootstrap.ensure(self, _resolved_config())
	_sync_runtime_service_references()

func _cleanup_runtime_services() -> void:
	if _runtime_bootstrap != null:
		_runtime_bootstrap.cleanup()
		_runtime_bootstrap = null
	_sync_runtime_service_references()

func _sync_runtime_service_references() -> void:
	if _runtime_bootstrap == null:
		_store = null
		_context = null
		_input_service = null
		_render_service = null
		_transfer_service = null
		_targeting_service = null
		return
	_store = _runtime_bootstrap.store
	_context = _runtime_bootstrap.context
	_input_service = _runtime_bootstrap.input_service
	_render_service = _runtime_bootstrap.render_service
	_transfer_service = _runtime_bootstrap.transfer_service
	_targeting_service = _runtime_bootstrap.targeting_service

func _resolved_config() -> ZoneConfig:
	if _config != null:
		return _config
	return _ensure_default_config()

func _ensure_default_config() -> ZoneConfig:
	if _default_config != null:
		return _default_config
	_default_config = ZoneConfig.make_zone_defaults()
	return _default_config

func _ensure_internal_nodes() -> void:
	if _internal_roots == null:
		_internal_roots = ZoneInternalRootsScript.new(self, ITEMS_ROOT_NAME, PREVIEW_ROOT_NAME)
	_internal_roots.ensure_nodes()
	_items_root = _internal_roots.items_root
	_preview_root = _internal_roots.preview_root

func _is_expected_direct_child(child: Node) -> bool:
	_ensure_internal_nodes()
	return _internal_roots.is_expected_direct_child(child)

func _handle_configuration_changed() -> void:
	if not is_inside_tree():
		return
	_ensure_internal_nodes()
	_ensure_services()
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
	layout_changed.emit()

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
	var coordinator = ZoneRuntimePortScript.resolve_drag_coordinator(self, false)
	if coordinator == null or coordinator.get_session() == null:
		refresh()
		layout_changed.emit()

func _coerce_placement_target(value):
	if value == null:
		return null
	if value is ZonePlacementTarget:
		return (value as ZonePlacementTarget).duplicate_target()
	return null
