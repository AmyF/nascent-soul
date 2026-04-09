@tool
class_name Zone extends Control

const ITEMS_ROOT_NAME := "ItemsRoot"
const PREVIEW_ROOT_NAME := "PreviewRoot"

# Drag lifecycle contract:
# `drag_started` fires on the source zone.
# `drop_preview_changed(..., target)` fires on the hovered target zone, and an invalid target means the preview was cleared.
# `drop_hover_state_changed(..., decision)` reports whether the current hovered zone would accept the drop.
# A hover clear is represented by `decision.resolved_target` being invalid; rejected hovers keep their computed target but do not show a preview slot.
# Successful drops emit `item_reordered` for same-zone moves or `item_transferred` on the target first and then the source.
# Rejected drops emit `drop_rejected` on the target and mirrored source zone.
signal item_clicked(item: Control)
signal item_double_clicked(item: Control)
signal item_right_clicked(item: Control)
signal item_long_pressed(item: Control)
signal item_hover_entered(item: Control)
signal item_hover_exited(item: Control)
signal selection_changed(items: Array)
signal drag_started(items: Array, source_zone: Zone)
signal drop_preview_changed(items: Array, target_zone: Zone, target)
signal drop_hover_state_changed(items: Array, target_zone: Zone, decision)
signal item_added(item: Control, index: int)
signal item_removed(item: Control, from_index: int)
signal item_reordered(item: Control, from_index: int, to_index: int)
signal item_transferred(item: Control, source_zone: Zone, target_zone: Zone, target)
signal drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String)
signal layout_changed()

var _preset: ZonePreset = null
var _space_model: ZoneSpaceModel = null
var _layout_policy: ZoneLayoutPolicy = null
var _display_style: ZoneDisplayStyle = null
var _interaction: ZoneInteraction = null
var _sort_policy: ZoneSortPolicy = null
var _transfer_policy: ZoneTransferPolicy = null
var _drag_visual_factory: ZoneDragVisualFactory = null

var _runtime: ZoneRuntime
var _items_root: Control = null
var _preview_root: Control = null

var _default_space_model: ZoneSpaceModel = null
var _default_layout_policy: ZoneLayoutPolicy = null
var _default_display_style: ZoneDisplayStyle = null
var _default_interaction: ZoneInteraction = null
var _default_sort_policy: ZoneSortPolicy = null
var _default_transfer_policy: ZoneTransferPolicy = null
var _default_drag_visual_factory: ZoneDragVisualFactory = null

@export_group("Preset")
@export var preset: ZonePreset:
	get:
		return _preset
	set(value):
		if _preset == value:
			return
		_preset = value
		_handle_configuration_changed()

@export_group("Advanced Overrides")
@export var space_model: ZoneSpaceModel:
	get:
		return _space_model
	set(value):
		if _space_model == value:
			return
		_space_model = value
		_handle_configuration_changed()

@export var layout_policy: ZoneLayoutPolicy:
	get:
		return _layout_policy
	set(value):
		if _layout_policy == value:
			return
		_layout_policy = value
		_handle_configuration_changed()

@export var display_style: ZoneDisplayStyle:
	get:
		return _display_style
	set(value):
		if _display_style == value:
			return
		_display_style = value
		_handle_configuration_changed()

@export var interaction: ZoneInteraction:
	get:
		return _interaction
	set(value):
		if _interaction == value:
			return
		_interaction = value
		_handle_configuration_changed()

@export var sort_policy: ZoneSortPolicy:
	get:
		return _sort_policy
	set(value):
		if _sort_policy == value:
			return
		_sort_policy = value
		_handle_configuration_changed()

@export var transfer_policy: ZoneTransferPolicy:
	get:
		return _transfer_policy
	set(value):
		if _transfer_policy == value:
			return
		_transfer_policy = value
		_handle_configuration_changed()

@export var permission_policy: ZoneTransferPolicy:
	get:
		return _transfer_policy
	set(value):
		transfer_policy = value

@export var drag_visual_factory: ZoneDragVisualFactory:
	get:
		return _drag_visual_factory
	set(value):
		if _drag_visual_factory == value:
			return
		_drag_visual_factory = value
		_handle_configuration_changed()

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_internal_nodes()
	update_configuration_warnings()
	queue_redraw()
	_ensure_runtime()
	_runtime.bind()
	var resized_callable = Callable(self, "_on_zone_resized")
	if not resized.is_connected(resized_callable):
		resized.connect(resized_callable)
	call_deferred("refresh")
	set_process(not Engine.is_editor_hint())

func _exit_tree() -> void:
	if _runtime != null:
		_runtime.unbind()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _runtime != null:
		_runtime.process(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	var stylebox = get_theme_stylebox("panel", "Panel")
	if stylebox != null:
		draw_style_box(stylebox, Rect2(Vector2.ZERO, size))

func _get_configuration_warnings() -> PackedStringArray:
	_ensure_internal_nodes()
	_ensure_default_resources()
	var warnings := PackedStringArray()
	var resolved_layout = get_layout_policy_resource()
	var resolved_display = get_display_style_resource()
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
			warnings.append("Direct child '%s' is not managed. Put card items under ItemsRoot instead of attaching them directly to Zone." % child.name)
			break
	return warnings

func refresh() -> void:
	_ensure_internal_nodes()
	_ensure_runtime()
	if _runtime != null:
		_runtime.refresh()
	queue_redraw()

func get_items_root() -> Control:
	_ensure_internal_nodes()
	return _items_root

func get_preview_root() -> Control:
	_ensure_internal_nodes()
	return _preview_root

func get_items() -> Array[Control]:
	_ensure_runtime()
	return _runtime.get_items()

func get_item_count() -> int:
	_ensure_runtime()
	return _runtime.get_item_count()

func get_selected_items() -> Array[Control]:
	_ensure_runtime()
	return _runtime.selection_state.get_selected_items()

func get_item_target(item: Control) -> ZonePlacementTarget:
	_ensure_runtime()
	return _runtime.get_item_target(item)

func get_items_at_target(target: ZonePlacementTarget) -> Array[Control]:
	_ensure_runtime()
	return _runtime.get_items_at_target(target)

func is_selected(item: Control) -> bool:
	_ensure_runtime()
	return _runtime.selection_state.is_selected(item)

func has_item(item: Control) -> bool:
	_ensure_runtime()
	return _runtime != null and _runtime.has_item(item)

func add_item(item: Control, placement_target = null) -> bool:
	_ensure_runtime()
	return _runtime.add_item(item, _coerce_placement_target(placement_target))

func insert_item(item: Control, index: int) -> bool:
	_ensure_runtime()
	return _runtime.insert_item(item, index)

func place_item(item: Control, placement_target: ZonePlacementTarget) -> bool:
	return add_item(item, placement_target)

func remove_item(item: Control) -> bool:
	_ensure_runtime()
	return _runtime.remove_item(item)

func move_item_to(item: Control, target_zone: Zone, placement_target = null) -> bool:
	_ensure_runtime()
	return _runtime.move_item_to(item, target_zone, _coerce_placement_target(placement_target))

func transfer_items(items: Array[Control], target_zone: Zone, placement_target = null) -> bool:
	_ensure_runtime()
	return _runtime.transfer_items(items, target_zone, _coerce_placement_target(placement_target))

func reorder_item(item: Control, placement_target = null) -> bool:
	_ensure_runtime()
	return _runtime.reorder_item(item, _coerce_placement_target(placement_target))

func clear_selection() -> void:
	_ensure_runtime()
	if _runtime != null:
		_runtime.clear_selection()

func select_item(item: Control, additive: bool = false) -> void:
	_ensure_runtime()
	if _runtime != null:
		_runtime.select_item(item, additive)

func start_drag(items: Array[Control]) -> void:
	_ensure_runtime()
	if _runtime != null:
		_runtime.start_drag(items)

func get_runtime() -> ZoneRuntime:
	_ensure_runtime()
	return _runtime

func get_space_model_resource() -> ZoneSpaceModel:
	_ensure_default_resources()
	if _space_model != null:
		return _space_model
	if _preset != null:
		return _preset.resolve_space_model(_default_space_model)
	return _default_space_model

func get_layout_policy_resource() -> ZoneLayoutPolicy:
	_ensure_default_resources()
	if _layout_policy != null:
		return _layout_policy
	if _preset != null:
		return _preset.resolve_layout_policy(_default_layout_policy)
	return _default_layout_policy

func get_display_style_resource() -> ZoneDisplayStyle:
	_ensure_default_resources()
	if _display_style != null:
		return _display_style
	if _preset != null:
		return _preset.resolve_display_style(_default_display_style)
	return _default_display_style

func get_interaction_config() -> ZoneInteraction:
	_ensure_default_resources()
	if _interaction != null:
		return _interaction
	if _preset != null:
		return _preset.resolve_interaction(_default_interaction)
	return _default_interaction

func get_sort_policy_resource() -> ZoneSortPolicy:
	_ensure_default_resources()
	if _sort_policy != null:
		return _sort_policy
	if _preset != null:
		return _preset.resolve_sort_policy(_default_sort_policy)
	return _default_sort_policy

func get_transfer_policy_resource() -> ZoneTransferPolicy:
	_ensure_default_resources()
	if _transfer_policy != null:
		return _transfer_policy
	if _preset != null:
		return _preset.resolve_transfer_policy(_default_transfer_policy)
	return _default_transfer_policy

func get_permission_policy_resource() -> ZoneTransferPolicy:
	return get_transfer_policy_resource()

func get_drag_visual_factory_resource() -> ZoneDragVisualFactory:
	_ensure_default_resources()
	if _drag_visual_factory != null:
		return _drag_visual_factory
	if _preset != null:
		return _preset.resolve_drag_visual_factory(_default_drag_visual_factory)
	return _default_drag_visual_factory

func get_drag_coordinator(create_if_missing: bool = true) -> ZoneDragCoordinator:
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

func _ensure_runtime() -> void:
	if _runtime == null:
		_runtime = ZoneRuntime.new(self)

func _ensure_default_resources() -> void:
	if _default_space_model == null:
		_default_space_model = ZoneLinearSpaceModel.new()
	if _default_layout_policy == null:
		var layout := ZoneHBoxLayout.new()
		layout.item_spacing = 14.0
		layout.padding_left = 12.0
		layout.padding_top = 12.0
		_default_layout_policy = layout
	if _default_display_style == null:
		_default_display_style = ZoneCardDisplay.new()
	if _default_interaction == null:
		_default_interaction = ZoneInteraction.new()
	if _default_sort_policy == null:
		_default_sort_policy = ZoneManualSort.new()
	if _default_transfer_policy == null:
		_default_transfer_policy = ZoneAllowAllPermission.new()
	if _default_drag_visual_factory == null:
		_default_drag_visual_factory = ZoneConfigurableDragVisualFactory.new()

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
		root = get_node_or_null(node_name) as Control
	if root == null:
		root = Control.new()
		root.name = node_name
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(root)
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
	_ensure_internal_nodes()
	update_configuration_warnings()
	queue_redraw()
	if _runtime == null:
		return
	_runtime.bind()
	if is_inside_tree():
		call_deferred("refresh")

func _on_zone_resized() -> void:
	refresh()
	layout_changed.emit()

func _coerce_placement_target(value):
	if value == null:
		return null
	if value is ZonePlacementTarget:
		return (value as ZonePlacementTarget).duplicate_target()
	if value is int:
		return ZonePlacementTarget.linear(value as int)
	return null
