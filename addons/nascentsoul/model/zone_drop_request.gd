class_name ZoneDropRequest extends RefCounted

var target_zone: Node = null
var source_zone: Node = null
var items: Array[Control] = []
var requested_index: int = -1
var global_position: Vector2 = Vector2.ZERO

func _init(p_target_zone: Node = null, p_source_zone: Node = null, p_items: Array[Control] = [], p_requested_index: int = -1, p_global_position: Vector2 = Vector2.ZERO) -> void:
	target_zone = p_target_zone
	source_zone = p_source_zone
	items = p_items.duplicate()
	requested_index = p_requested_index
	global_position = p_global_position

func is_reorder() -> bool:
	return target_zone != null and target_zone == source_zone
