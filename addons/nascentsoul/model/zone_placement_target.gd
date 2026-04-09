class_name ZonePlacementTarget extends RefCounted

enum TargetKind {
	NONE,
	LINEAR,
	SQUARE,
	HEX
}

var kind: TargetKind = TargetKind.NONE
var slot: int = -1
var coordinates: Vector2i = Vector2i(-1, -1)
var cell_id: StringName = &""
var global_position: Vector2 = Vector2.ZERO
var local_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}

func _init(
	p_kind: TargetKind = TargetKind.NONE,
	p_slot: int = -1,
	p_coordinates: Vector2i = Vector2i(-1, -1),
	p_cell_id: StringName = &"",
	p_global_position: Vector2 = Vector2.ZERO,
	p_local_position: Vector2 = Vector2.ZERO,
	p_metadata: Dictionary = {}
) -> void:
	kind = p_kind
	slot = p_slot
	coordinates = p_coordinates
	cell_id = p_cell_id
	global_position = p_global_position
	local_position = p_local_position
	metadata = p_metadata.duplicate(true)

static func invalid() -> ZonePlacementTarget:
	return ZonePlacementTarget.new()

static func linear(index: int, p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.LINEAR, index, Vector2i(index, 0), &"", p_global_position, p_local_position)

static func square(column: int, row: int, p_cell_id: StringName = &"", p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.SQUARE, -1, Vector2i(column, row), p_cell_id, p_global_position, p_local_position, p_metadata)

static func hex(column: int, row: int, p_cell_id: StringName = &"", p_global_position: Vector2 = Vector2.ZERO, p_local_position: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}) -> ZonePlacementTarget:
	return ZonePlacementTarget.new(TargetKind.HEX, -1, Vector2i(column, row), p_cell_id, p_global_position, p_local_position, p_metadata)

func is_valid() -> bool:
	match kind:
		TargetKind.LINEAR:
			return slot >= 0
		TargetKind.SQUARE, TargetKind.HEX:
			return coordinates.x >= 0 and coordinates.y >= 0
		_:
			return false

func is_linear() -> bool:
	return kind == TargetKind.LINEAR and slot >= 0

func duplicate_target() -> ZonePlacementTarget:
	return ZonePlacementTarget.new(kind, slot, coordinates, cell_id, global_position, local_position, metadata)

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
			return slot == other.slot
		TargetKind.SQUARE, TargetKind.HEX:
			if coordinates != other.coordinates:
				return false
			if cell_id == &"" or other.cell_id == &"":
				return true
			return cell_id == other.cell_id
		_:
			return not is_valid() and not other.is_valid()

func describe() -> String:
	match kind:
		TargetKind.LINEAR:
			return "slot:%d" % slot
		TargetKind.SQUARE:
			return "square:%d,%d" % [coordinates.x, coordinates.y]
		TargetKind.HEX:
			return "hex:%d,%d" % [coordinates.x, coordinates.y]
		_:
			return "invalid"
