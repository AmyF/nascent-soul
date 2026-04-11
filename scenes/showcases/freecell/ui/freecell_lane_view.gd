extends Panel

@export var lane_role: StringName = &"tableau"
@export var lane_index: int = 0
@export var zone_path: NodePath = NodePath("ZoneHost")

func resolve_zone() -> Zone:
	return get_node_or_null(zone_path) as Zone

func get_lane_role() -> StringName:
	return lane_role

func get_lane_index() -> int:
	return lane_index
