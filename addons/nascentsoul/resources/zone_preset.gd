@tool
class_name ZonePreset extends Resource

@export_group("Policies")
@export var layout_policy: ZoneLayoutPolicy
@export var display_style: ZoneDisplayStyle
@export var interaction: ZoneInteraction
@export var sort_policy: ZoneSortPolicy
@export var permission_policy: ZonePermissionPolicy

@export_group("Drag Visuals")
@export var drag_visual_factory: ZoneDragVisualFactory

func resolve_layout_policy(default_value: ZoneLayoutPolicy = null) -> ZoneLayoutPolicy:
	return layout_policy if layout_policy != null else default_value

func resolve_display_style(default_value: ZoneDisplayStyle = null) -> ZoneDisplayStyle:
	return display_style if display_style != null else default_value

func resolve_interaction(default_value: ZoneInteraction = null) -> ZoneInteraction:
	return interaction if interaction != null else default_value

func resolve_sort_policy(default_value: ZoneSortPolicy = null) -> ZoneSortPolicy:
	return sort_policy if sort_policy != null else default_value

func resolve_permission_policy(default_value: ZonePermissionPolicy = null) -> ZonePermissionPolicy:
	return permission_policy if permission_policy != null else default_value

func resolve_drag_visual_factory(default_value: ZoneDragVisualFactory = null) -> ZoneDragVisualFactory:
	return drag_visual_factory if drag_visual_factory != null else default_value
