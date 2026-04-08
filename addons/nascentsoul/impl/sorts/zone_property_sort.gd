@tool
class_name ZonePropertySort extends ZoneSortPolicy

@export var property_name: String = ""
@export var metadata_key: String = ""
@export var descending: bool = false

func sort_items(items: Array[Control]) -> Array[Control]:
	var result = items.duplicate()
	result.sort_custom(_compare_items)
	if descending:
		result.reverse()
	return result

func _compare_items(a: Control, b: Control) -> bool:
	var a_value = _resolve_value(a)
	var b_value = _resolve_value(b)
	if a_value is String or b_value is String:
		return str(a_value).naturalnocasecmp_to(str(b_value)) < 0
	return a_value < b_value

func _resolve_value(item: Control):
	if metadata_key != "" and item.has_meta(metadata_key):
		return item.get_meta(metadata_key)
	if property_name != "" and item.get(property_name) != null:
		return item.get(property_name)
	return item.name
