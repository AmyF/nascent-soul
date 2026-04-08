@tool
class_name ZoneManualSort extends ZoneSortPolicy

func sort_items(items: Array[Control]) -> Array[Control]:
	return items.duplicate()
