@tool
class_name ZonePropertySort extends ZoneSortPolicy

@export var property_name: String = ""
@export var metadata_key: String = ""
@export var descending: bool = false

func sort_items(_context: ZoneContext, items: Array[ZoneItemControl]) -> Array[ZoneItemControl]:
	var result = stable_sort_items(items, Callable(self, "_compare_items"))
	if descending:
		result.reverse()
	return result

func _compare_items(a: ZoneItemControl, b: ZoneItemControl) -> int:
	var a_value = _resolve_value(a)
	var b_value = _resolve_value(b)
	return compare_values(a_value, b_value)

func _resolve_value(item: ZoneItemControl):
	return resolve_item_value(item, property_name, metadata_key, item.name)
