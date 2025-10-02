extends ZoneVisibilityStrategy
class_name MaxVisibleZoneVisibilityStrategy

@export var max_visible: int = 5

func get_visible_objs(objs: Array[Control], zone: Zone) -> Array[Control]:
	if objs.size() <= max_visible:
		return objs
	else:
		return objs.slice(0, max_visible)
