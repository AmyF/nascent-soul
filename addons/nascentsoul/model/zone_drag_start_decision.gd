class_name ZoneDragStartDecision extends RefCounted

var allowed: bool = true
var reason: String = ""
var items: Array[ZoneItemControl] = []

func _init(p_allowed: bool = true, p_reason: String = "", p_items: Array = []) -> void:
	allowed = p_allowed
	reason = p_reason
	items = []
	for item in p_items:
		if item is ZoneItemControl:
			items.append(item)

func duplicate_decision():
	var decision = get_script().new()
	decision.allowed = allowed
	decision.reason = reason
	decision.items = items.duplicate()
	return decision
