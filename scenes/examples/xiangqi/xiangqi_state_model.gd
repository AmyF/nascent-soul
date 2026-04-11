extends RefCounted

const INVALID_COORDS := Vector2i(-1, -1)
const BOARD_COLUMNS := 9
const BOARD_ROWS := 10
const INITIAL_SETUP := [
	{"side": "black", "type": "chariot", "coords": Vector2i(0, 0)},
	{"side": "black", "type": "horse", "coords": Vector2i(1, 0)},
	{"side": "black", "type": "elephant", "coords": Vector2i(2, 0)},
	{"side": "black", "type": "advisor", "coords": Vector2i(3, 0)},
	{"side": "black", "type": "general", "coords": Vector2i(4, 0)},
	{"side": "black", "type": "advisor", "coords": Vector2i(5, 0)},
	{"side": "black", "type": "elephant", "coords": Vector2i(6, 0)},
	{"side": "black", "type": "horse", "coords": Vector2i(7, 0)},
	{"side": "black", "type": "chariot", "coords": Vector2i(8, 0)},
	{"side": "black", "type": "cannon", "coords": Vector2i(1, 2)},
	{"side": "black", "type": "cannon", "coords": Vector2i(7, 2)},
	{"side": "black", "type": "soldier", "coords": Vector2i(0, 3)},
	{"side": "black", "type": "soldier", "coords": Vector2i(2, 3)},
	{"side": "black", "type": "soldier", "coords": Vector2i(4, 3)},
	{"side": "black", "type": "soldier", "coords": Vector2i(6, 3)},
	{"side": "black", "type": "soldier", "coords": Vector2i(8, 3)},
	{"side": "red", "type": "chariot", "coords": Vector2i(0, 9)},
	{"side": "red", "type": "horse", "coords": Vector2i(1, 9)},
	{"side": "red", "type": "elephant", "coords": Vector2i(2, 9)},
	{"side": "red", "type": "advisor", "coords": Vector2i(3, 9)},
	{"side": "red", "type": "general", "coords": Vector2i(4, 9)},
	{"side": "red", "type": "advisor", "coords": Vector2i(5, 9)},
	{"side": "red", "type": "elephant", "coords": Vector2i(6, 9)},
	{"side": "red", "type": "horse", "coords": Vector2i(7, 9)},
	{"side": "red", "type": "chariot", "coords": Vector2i(8, 9)},
	{"side": "red", "type": "cannon", "coords": Vector2i(1, 7)},
	{"side": "red", "type": "cannon", "coords": Vector2i(7, 7)},
	{"side": "red", "type": "soldier", "coords": Vector2i(0, 6)},
	{"side": "red", "type": "soldier", "coords": Vector2i(2, 6)},
	{"side": "red", "type": "soldier", "coords": Vector2i(4, 6)},
	{"side": "red", "type": "soldier", "coords": Vector2i(6, 6)},
	{"side": "red", "type": "soldier", "coords": Vector2i(8, 6)}
]
const PIECE_DEFS := {
	&"general": {"name": "General", "red": "帅", "black": "将"},
	&"advisor": {"name": "Advisor", "red": "仕", "black": "士"},
	&"elephant": {"name": "Elephant", "red": "相", "black": "象"},
	&"horse": {"name": "Horse", "red": "马", "black": "马"},
	&"chariot": {"name": "Chariot", "red": "车", "black": "车"},
	&"cannon": {"name": "Cannon", "red": "炮", "black": "炮"},
	&"soldier": {"name": "Soldier", "red": "兵", "black": "卒"}
}

func build_initial_state() -> Dictionary:
	return normalize_state({
		"current_side": "red",
		"pieces": INITIAL_SETUP.duplicate(true),
		"captured_by_red": [],
		"captured_by_black": []
	})

func normalize_state(state: Dictionary) -> Dictionary:
	return {
		"current_side": str(state.get("current_side", "red")),
		"pieces": _normalize_piece_states(state.get("pieces", [])),
		"captured_by_red": _normalize_glyphs(state.get("captured_by_red", [])),
		"captured_by_black": _normalize_glyphs(state.get("captured_by_black", []))
	}

func serialize_state(
	current_side: StringName,
	pieces: Array,
	piece_coords: Callable,
	captured_by_red: Array[String],
	captured_by_black: Array[String]
) -> Dictionary:
	var serialized_pieces: Array = []
	for piece in pieces:
		if piece == null or not is_instance_valid(piece):
			continue
		if not piece_coords.is_valid():
			continue
		var coords = piece_coords.call(piece)
		if coords is not Vector2i:
			continue
		serialized_pieces.append({
			"side": str(piece.side),
			"type": str(piece.piece_type),
			"coords": coords
		})
	serialized_pieces.sort_custom(Callable(self, "_sort_piece_states"))
	return normalize_state({
		"current_side": str(current_side),
		"pieces": serialized_pieces,
		"captured_by_red": captured_by_red.duplicate(),
		"captured_by_black": captured_by_black.duplicate()
	})

func snapshot_board(pieces: Array, piece_coords: Callable) -> Array:
	var snapshot: Array = []
	for piece in pieces:
		if piece == null or not is_instance_valid(piece):
			continue
		if not piece_coords.is_valid():
			continue
		var coords = piece_coords.call(piece)
		if coords is not Vector2i:
			continue
		snapshot.append({
			"piece": piece,
			"side": piece.side,
			"type": piece.piece_type,
			"coords": coords
		})
	return snapshot

func snapshot_piece_for(piece, snapshot: Array) -> Dictionary:
	for piece_info in snapshot:
		if piece_info.get("piece", null) == piece:
			return piece_info
	return {}

func snapshot_piece_at(coords: Vector2i, snapshot: Array) -> Dictionary:
	for piece_info in snapshot:
		if piece_info.get("coords", INVALID_COORDS) == coords:
			return piece_info
	return {}

func snapshot_after_move(piece, target_coords: Vector2i, captured_piece, snapshot: Array) -> Array:
	var moved_snapshot: Array = []
	for piece_info in snapshot:
		if captured_piece != null and piece_info.get("piece", null) == captured_piece:
			continue
		var cloned = piece_info.duplicate(true)
		if piece_info.get("piece", null) == piece:
			cloned["coords"] = target_coords
		moved_snapshot.append(cloned)
	return moved_snapshot

func state_signature(state: Dictionary) -> String:
	var normalized_state = normalize_state(state)
	var parts: Array[String] = ["turn=%s" % str(normalized_state.get("current_side", "red"))]
	for piece_state in normalized_state.get("pieces", []):
		var coords: Vector2i = piece_state.get("coords", INVALID_COORDS)
		parts.append("%s:%s@%d,%d" % [str(piece_state.get("side", "")), str(piece_state.get("type", "")), coords.x, coords.y])
	parts.append("red=" + ",".join(PackedStringArray(normalized_state.get("captured_by_red", []))))
	parts.append("black=" + ",".join(PackedStringArray(normalized_state.get("captured_by_black", []))))
	return "|".join(parts)

func piece_layout_signature(state: Dictionary) -> String:
	var normalized_state = normalize_state(state)
	var parts: Array[String] = []
	for piece_state in normalized_state.get("pieces", []):
		var coords: Vector2i = piece_state.get("coords", INVALID_COORDS)
		parts.append("%s:%s@%d,%d" % [str(piece_state.get("side", "")), str(piece_state.get("type", "")), coords.x, coords.y])
	return "|".join(parts)

func _normalize_piece_states(pieces: Array) -> Array:
	var normalized: Array = []
	for piece_state in pieces:
		if piece_state is not Dictionary:
			continue
		var coords = piece_state.get("coords", INVALID_COORDS)
		if coords is not Vector2i:
			continue
		normalized.append({
			"side": str(piece_state.get("side", "red")),
			"type": str(piece_state.get("type", "soldier")),
			"coords": coords
		})
	normalized.sort_custom(Callable(self, "_sort_piece_states"))
	return normalized

func _normalize_glyphs(values: Array) -> Array[String]:
	var glyphs: Array[String] = []
	for value in values:
		glyphs.append(str(value))
	return glyphs

func _sort_piece_states(a: Dictionary, b: Dictionary) -> bool:
	var a_coords: Vector2i = a.get("coords", INVALID_COORDS)
	var b_coords: Vector2i = b.get("coords", INVALID_COORDS)
	if a_coords.y != b_coords.y:
		return a_coords.y < b_coords.y
	if a_coords.x != b_coords.x:
		return a_coords.x < b_coords.x
	var a_side = str(a.get("side", ""))
	var b_side = str(b.get("side", ""))
	if a_side != b_side:
		return a_side < b_side
	return str(a.get("type", "")) < str(b.get("type", ""))
