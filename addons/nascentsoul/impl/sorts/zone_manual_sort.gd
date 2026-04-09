@tool
class_name ZoneManualSort extends ZoneSortPolicy

func sort_items(_context: ZoneContext, items: Array[ZoneItemControl]) -> Array[ZoneItemControl]:
	return items.duplicate()
