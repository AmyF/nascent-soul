class_name DemoLayoutSupport extends RefCounted

const DESKTOP := &"desktop"
const COMPACT := &"compact"
const NARROW := &"narrow"
const RESPONSIVE_FRAME_ALLOWANCE := 48.0

static func mode_for_width(width: float) -> StringName:
	if width >= 1280.0:
		return DESKTOP
	if width >= 960.0:
		return COMPACT
	return NARROW

static func resolved_width(control: Control) -> float:
	if control == null:
		return 0.0
	var width := control.size.x
	if width <= 1.0 and control.get_parent() is Control:
		width = (control.get_parent() as Control).size.x
	if width <= 1.0:
		width = control.get_viewport_rect().size.x
	return width

static func mode_for(control: Control) -> StringName:
	return mode_for_width(resolved_width(control) + RESPONSIVE_FRAME_ALLOWANCE)

static func set_grid_columns(grid: GridContainer, mode: StringName, desktop_columns: int, compact_columns: int, narrow_columns: int) -> void:
	if grid == null:
		return
	grid.columns = pick_int(mode, desktop_columns, compact_columns, narrow_columns)

static func set_minimum_width(control: Control, mode: StringName, desktop_width: float, compact_width: float, narrow_width: float) -> void:
	if control == null:
		return
	var min_size := control.custom_minimum_size
	min_size.x = pick_float(mode, desktop_width, compact_width, narrow_width)
	control.custom_minimum_size = min_size

static func set_minimum_height(control: Control, mode: StringName, desktop_height: float, compact_height: float, narrow_height: float) -> void:
	if control == null:
		return
	var min_size := control.custom_minimum_size
	min_size.y = pick_float(mode, desktop_height, compact_height, narrow_height)
	control.custom_minimum_size = min_size

static func set_minimum_size(control: Control, width: float, height: float) -> void:
	if control == null:
		return
	control.custom_minimum_size = Vector2(width, height)

static func pick_float(mode: StringName, desktop_value: float, compact_value: float, narrow_value: float) -> float:
	match mode:
		COMPACT:
			return compact_value
		NARROW:
			return narrow_value
		_:
			return desktop_value

static func pick_int(mode: StringName, desktop_value: int, compact_value: int, narrow_value: int) -> int:
	match mode:
		COMPACT:
			return compact_value
		NARROW:
			return narrow_value
		_:
			return desktop_value

static func ensure_child_order(parent: Node, ordered_children: Array) -> void:
	if parent == null:
		return
	for index in range(ordered_children.size()):
		var child = ordered_children[index]
		if child is Node and (child as Node).get_parent() == parent:
			parent.move_child(child, index)
