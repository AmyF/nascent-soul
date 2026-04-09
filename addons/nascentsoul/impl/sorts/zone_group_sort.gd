@tool
class_name ZoneGroupSort extends ZoneSortPolicy

@export_group("Grouping")
@export var group_property_name: String = ""
@export var group_metadata_key: String = ""
@export var group_order: PackedStringArray = []
@export var descending_groups: bool = false

@export_group("Within Group")
@export var item_property_name: String = ""
@export var item_metadata_key: String = ""
@export var descending_items: bool = false

func sort_items(_context: ZoneContext, items: Array[ZoneItemControl]) -> Array[ZoneItemControl]:
	return stable_sort_items(items, Callable(self, "_compare_items"))

func _compare_items(a: ZoneItemControl, b: ZoneItemControl) -> int:
	var a_group = _resolve_group_value(a)
	var b_group = _resolve_group_value(b)
	var group_comparison = _compare_group_values(a_group, b_group)
	if group_comparison != 0:
		return group_comparison
	var item_comparison = compare_values(_resolve_member_value(a), _resolve_member_value(b))
	if descending_items:
		item_comparison *= -1
	return item_comparison

func _compare_group_values(a_group, b_group) -> int:
	var a_rank = _resolve_group_rank(a_group)
	var b_rank = _resolve_group_rank(b_group)
	if a_rank != b_rank:
		return -1 if a_rank < b_rank else 1
	var comparison = compare_values(a_group, b_group)
	if descending_groups:
		comparison *= -1
	return comparison

func _resolve_group_rank(group_value) -> int:
	if group_order.is_empty():
		return 0
	var rank = group_order.find(str(group_value))
	if rank == -1:
		return group_order.size()
	return rank

func _resolve_group_value(item: ZoneItemControl):
	return resolve_item_value(item, group_property_name, group_metadata_key, "default")

func _resolve_member_value(item: ZoneItemControl):
	return resolve_item_value(item, item_property_name, item_metadata_key, item.name)
