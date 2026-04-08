class_name ZoneDropDecision extends RefCounted

var allowed: bool = true
var reason: String = ""
var target_index: int = -1

func _init(p_allowed: bool = true, p_reason: String = "", p_target_index: int = -1) -> void:
	allowed = p_allowed
	reason = p_reason
	target_index = p_target_index
