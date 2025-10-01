extends ZoneVisibilityStrategy
class_name ZoneCompositeVisibilityStrategy

enum LogicMode { AND, OR }

@export var filters: Array[ZoneFilterStrategy] = []
@export var logic_mode: LogicMode = LogicMode.AND

func filter(objs: Array[Control], zone: Zone) -> Array[Control]:
	if filters.is_empty():
		return objs

	var result: Array[Control] = []
	
	for obj in objs:
		var should_include = false

		if logic_mode == LogicMode.AND:
			should_include = true
			for filter in filters:
				if not filter.should_be_visible(obj, zone):
					should_include = false
					break
		elif logic_mode == LogicMode.OR:
			should_include = false
			for filter in filters:
				if filter.should_be_visible(obj, zone):
					should_include = true
					break

		if should_include:
			result.append(obj)
	
	return result
