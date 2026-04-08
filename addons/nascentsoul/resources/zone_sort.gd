@tool
class_name ZoneSortPolicy extends Resource

func sort_items(items: Array[Control]) -> Array[Control]:
	return items.duplicate()

func stable_sort_items(items: Array[Control], comparator: Callable) -> Array[Control]:
	var result = items.duplicate()
	for index in range(1, result.size()):
		var current_item = result[index]
		var compare_index = index - 1
		while compare_index >= 0 and comparator.call(current_item, result[compare_index]) < 0:
			result[compare_index + 1] = result[compare_index]
			compare_index -= 1
		result[compare_index + 1] = current_item
	return result

func resolve_item_value(item: Control, property_name: String = "", metadata_key: String = "", fallback = null):
	if not is_instance_valid(item):
		return fallback
	if metadata_key != "" and item.has_meta(metadata_key):
		return item.get_meta(metadata_key)
	if property_name != "":
		var property_value = item.get(property_name)
		if property_value != null:
			return property_value
	if fallback != null:
		return fallback
	return item.name

func compare_values(a, b) -> int:
	if a == b:
		return 0
	var a_type = typeof(a)
	var b_type = typeof(b)
	if a_type != b_type:
		return str(a).naturalnocasecmp_to(str(b))
	match a_type:
		TYPE_STRING, TYPE_STRING_NAME:
			return str(a).naturalnocasecmp_to(str(b))
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return -1 if a < b else 1
		_:
			return str(a).naturalnocasecmp_to(str(b))
