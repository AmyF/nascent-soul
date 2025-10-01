extends Node
class_name ZoneVisibilityStrategy

func get_visible_objs(objs: Array[Control], zone: Zone) -> Array[Control]:
	return objs


func should_be_visible(obj: Control, index: int, filtered_objs: Array[Control], zone: Zone) -> bool:
	return true
