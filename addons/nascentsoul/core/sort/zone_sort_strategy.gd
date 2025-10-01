extends Node
class_name ZoneSortStrategy

enum SortMode { NONE, ASCENDING, DESCENDING }

@export var sort_mode: SortMode = SortMode.NONE

func sort(objs: Array) -> Array:
	var result = objs.duplicate()

	match sort_mode:
		SortMode.ASCENDING:
			pass
		SortMode.DESCENDING:
			result.reverse()
		SortMode.NONE:
			pass

	return result
