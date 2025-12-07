class_name ZoneAllowAllPermission extends ZonePermission

func can_drop(target_zone: Node, items: Array[Control], source_zone: Node) -> bool:
	return true