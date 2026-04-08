@tool
class_name Zone extends Node

# Drag lifecycle contract:
# `drag_started` fires on the source zone.
# `drop_preview_changed(..., index)` fires on the hovered target zone, and `index = -1` means the preview was cleared.
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
signal drop_preview_changed(items: Array, target_zone: Zone, target_index: int)
signal item_reordered(item: Control, from_index: int, to_index: int)
signal item_transferred(item: Control, source_zone: Zone, target_zone: Zone, to_index: int)
signal drop_rejected(items: Array, source_zone: Zone, target_zone: Zone, reason: String)
signal layout_changed()

var _container: Control = null
var _layout_policy: ZoneLayoutPolicy = null
var _display_style: ZoneDisplayStyle = null
var _interaction: ZoneInteraction = ZoneInteraction.new()
var _sort_policy: ZoneSortPolicy = null
var _permission_policy: ZonePermissionPolicy = null

@export var container: Control:
	get:
		return _container
	set(value):
		if _container == value:
			return
		_container = value
		_handle_configuration_changed(true)

@export_group("Policies")
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
@export var interaction: ZoneInteraction = ZoneInteraction.new():
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
@export var permission_policy: ZonePermissionPolicy:
	get:
		return _permission_policy
	set(value):
		if _permission_policy == value:
			return
		_permission_policy = value
		_handle_configuration_changed()

var _runtime: ZoneRuntime

func _ready() -> void:
	update_configuration_warnings()
	_ensure_runtime()
	_runtime.bind()
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

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var container_size = _resolve_container_size()
	if container == null:
		warnings.append("Zone requires a container Control.")
	else:
		if container is Container:
			warnings.append("Container-derived nodes also manage child layout. Prefer Panel or plain Control as a Zone container.")
		if container.mouse_filter == Control.MOUSE_FILTER_IGNORE and interaction != null and interaction.clear_selection_on_background_click:
			warnings.append("The container ignores mouse input, so background-click deselection will not trigger. Use Stop or Pass on the container mouse_filter.")
		if container.clip_contents and (layout_policy is ZoneHandLayout or layout_policy is ZonePileLayout or display_style is ZoneCardDisplay):
			warnings.append("The container clips its children. Hover lift, drag previews, and pile overlap may be cut off.")
		var sibling_zones := 0
		for child in container.get_children():
			if child is Zone:
				sibling_zones += 1
		if sibling_zones > 1 or (sibling_zones == 1 and not is_ancestor_of(container) and get_parent() != container):
			warnings.append("More than one Zone appears to manage this container. Use one Zone per container to avoid conflicting refreshes.")
		if container_size != Vector2.ZERO:
			if layout_policy is ZoneHandLayout and (layout_policy as ZoneHandLayout).would_escape_container(container_size):
				warnings.append("The current hand layout values push cards outside the container. Reduce arch settings or use a taller panel.")
			if layout_policy is ZonePileLayout and (layout_policy as ZonePileLayout).would_escape_container(container_size):
				warnings.append("The current pile layout values push cards outside the container. Reduce overlap or increase the container size.")
	if layout_policy == null:
		warnings.append("Zone requires a layout_policy to calculate placements.")
	if display_style == null:
		warnings.append("Zone requires a display_style to present placements.")
	if interaction == null:
		warnings.append("Zone has no interaction resource. Click, drag, hover, and long-press signals will not be emitted.")
	if sort_policy == null:
		warnings.append("Zone has no sort_policy. Items will stay in container child order until you reorder them explicitly.")
	if permission_policy == null:
		warnings.append("Zone has no permission_policy. Drops will be accepted by default.")
	return warnings

func refresh() -> void:
	_ensure_runtime()
	if _runtime != null:
		_runtime.refresh()

func get_items() -> Array[Control]:
	_ensure_runtime()
	return _runtime.get_items()

func get_item_count() -> int:
	_ensure_runtime()
	return _runtime.get_item_count()

func has_item(item: Control) -> bool:
	_ensure_runtime()
	return _runtime != null and _runtime.has_item(item)

func add_item(item: Control) -> bool:
	_ensure_runtime()
	return _runtime.add_item(item)

func insert_item(item: Control, index: int) -> bool:
	_ensure_runtime()
	return _runtime.insert_item(item, index)

func remove_item(item: Control) -> bool:
	_ensure_runtime()
	return _runtime.remove_item(item)

func move_item_to(item: Control, target_zone: Zone, index: int = -1) -> bool:
	_ensure_runtime()
	return _runtime.move_item_to(item, target_zone, index)

func reorder_item(item: Control, index: int) -> bool:
	_ensure_runtime()
	return _runtime.reorder_item(item, index)

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

func _handle_configuration_changed(rebind_runtime: bool = false) -> void:
	update_configuration_warnings()
	if _runtime == null:
		return
	if rebind_runtime:
		_runtime.bind()
	if is_inside_tree():
		call_deferred("refresh")

func _resolve_container_size() -> Vector2:
	if container == null:
		return Vector2.ZERO
	if container.size != Vector2.ZERO:
		return container.size
	if container.custom_minimum_size != Vector2.ZERO:
		return container.custom_minimum_size
	return Vector2.ZERO
