@tool
class_name ZoneSortPolicy extends Resource

func sort_items(items: Array[Control]) -> Array[Control]:
	return items.duplicate()
