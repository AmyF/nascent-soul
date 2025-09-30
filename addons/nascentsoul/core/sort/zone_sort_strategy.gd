extends Node
class_name ZoneSortStrategy

enum SortOrder {
    ASCENDING,
    DESCENDING
}

@export var sort_order: SortOrder = SortOrder.ASCENDING

func sort(objs: Array) -> Array:
    return objs