class_name ZonePlacementTarget extends RefCounted

# Public target descriptor shared by transfer APIs, spaces, and layouts.

enum TargetKind {
	NONE,
	LINEAR,
	SQUARE,
	HEX
}

var kind: TargetKind = TargetKind.NONE
var linear_index: int = -1
var grid_coordinates: Vector2i = Vector2i(-1, -1)
var grid_cell_id: StringName = &""
var global_position: Vector2 = Vector2.ZERO
var local_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}

func _init(
	p_kind: TargetKind = TargetKind.NONE,
	p_linear_index: int = -1,
	p_grid_coordinates: Vector2i = Vector2i(-1, -1),
	p_grid_cell_id: StringName = &"",
	p_global_position: Vector2 = Vector2.ZERO,
	p_local_position: Vector2 = Vector2.ZERO,
	p_metadata: Dictionary = {}
) -> void:
	kind = p_kind
	linear_index = p_linear_index
	grid_coordinates = p_grid_coordinates
	grid_cell_id = p_grid_cell_id
	global_position = p_global_position
	local_position = p_local_position
	metadata = p_metadata.duplicate(true)

static func invalid() -> ZonePlacementTarget:
	return ZonePlacementTarget.new()

static func linear(index: int, p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.LINEAR, index, Vector2i(-1, -1), &"", p_global_position, p_local_position)

static func square(column: int, row: int, p_cell_id: StringName = &"", p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.SQUARE, -1, Vector2i(column, row), p_cell_id, p_global_position, p_local_position, p_metadata)

static func hex(column: int, row: int, p_cell_id: StringName = &"", p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.HEX, -1, Vector2i(column, row), p_cell_id, p_global_position, p_local_position, p_metadata)

func is_valid() -> bool:
	match kind:
		TargetKind.LINEAR:
			return linear_index >= 0
		TargetKind.SQUARE, TargetKind.HEX:
			return grid_coordinates.x >= 0 and grid_coordinates.y >= 0
		_:
			return false

func is_linear() -> bool:
	return kind == TargetKind.LINEAR and linear_index >= 0

func is_grid() -> bool:
	return is_square() or is_hex()

func is_square() -> bool:
	return kind == TargetKind.SQUARE and is_valid()

func is_hex() -> bool:
	return kind == TargetKind.HEX and is_valid()

func matches_kind(target_kind: TargetKind) -> bool:
	if target_kind == TargetKind.NONE:
		return kind == TargetKind.NONE
	return kind == target_kind and is_valid()

func get_linear_index(default_value: int = -1) -> int:
	return linear_index if is_linear() else default_value

func get_grid_coordinates(default_value: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	return grid_coordinates if is_grid() else default_value

func get_grid_column(default_value: int = -1) -> int:
	var resolved_coordinates = get_grid_coordinates()
	return resolved_coordinates.x if resolved_coordinates.x >= 0 else default_value

func get_grid_row(default_value: int = -1) -> int:
	var resolved_coordinates = get_grid_coordinates()
	return resolved_coordinates.y if resolved_coordinates.y >= 0 else default_value

func has_grid_cell_id() -> bool:
	return grid_cell_id != &""

func duplicate_target() -> ZonePlacementTarget:
	return ZonePlacementTarget.new(kind, linear_index, grid_coordinates, grid_cell_id, global_position, local_position, metadata)

func with_positions(p_global_position: Vector2, p_local_position: Vector2) -> ZonePlacementTarget:
	var duplicated = duplicate_target()
	duplicated.global_position = p_global_position
	duplicated.local_position = p_local_position
	return duplicated

func matches(other: ZonePlacementTarget) -> bool:
	if other == null:
		return false
	if kind != other.kind:
		return false
	match kind:
		TargetKind.LINEAR:
			return linear_index == other.linear_index
		TargetKind.SQUARE, TargetKind.HEX:
			if grid_coordinates != other.grid_coordinates:
				return false
			if grid_cell_id == &"" or other.grid_cell_id == &"":
				return true
			return grid_cell_id == other.grid_cell_id
		_:
			return not is_valid() and not other.is_valid()

func describe() -> String:
	match kind:
		TargetKind.LINEAR:
			return "linear:%d" % linear_index
		TargetKind.SQUARE:
			return "square:%d,%d" % [grid_coordinates.x, grid_coordinates.y]
		TargetKind.HEX:
			return "hex:%d,%d" % [grid_coordinates.x, grid_coordinates.y]
		_:
			return "invalid"
