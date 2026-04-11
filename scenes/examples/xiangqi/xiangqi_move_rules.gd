extends RefCounted

const XiangqiStateModelScript = preload("res://scenes/examples/xiangqi/xiangqi_state_model.gd")

var _state_model = XiangqiStateModelScript.new()

func evaluate_move(
	piece,
	target_coords: Vector2i,
	target_piece: Control,
	current_side: StringName,
	snapshot: Array,
	enforce_turn: bool
) -> Dictionary:
	if not is_instance_valid(piece):
		return {"allowed": false, "reason": "That piece is no longer on the board."}
	if not _is_inside_board(target_coords):
		return {"allowed": false, "reason": "That destination is outside the board."}
	if enforce_turn and piece.side != current_side:
		return {"allowed": false, "reason": "It is %s's turn." % side_name(current_side)}
	var piece_info = _state_model.snapshot_piece_for(piece, snapshot)
	if piece_info.is_empty():
		return {"allowed": false, "reason": "That piece is not on a legal board intersection."}
	var from_coords: Vector2i = piece_info.get("coords", XiangqiStateModelScript.INVALID_COORDS)
	if from_coords == XiangqiStateModelScript.INVALID_COORDS:
		return {"allowed": false, "reason": "That piece is not on a legal board intersection."}
	if from_coords == target_coords:
		return {"allowed": false, "reason": "Choose a different destination."}
	var target_info = _state_model.snapshot_piece_at(target_coords, snapshot)
	var occupied_target = target_piece
	if occupied_target == null and not target_info.is_empty():
		occupied_target = target_info.get("piece", null)
	if occupied_target != null and occupied_target.side == piece.side:
		return {"allowed": false, "reason": "You cannot capture your own piece."}
	var raw_reason = _raw_move_reason(piece_info, target_coords, target_info, snapshot)
	if raw_reason != "":
		return {"allowed": false, "reason": raw_reason}
	var moved_snapshot = _state_model.snapshot_after_move(piece, target_coords, occupied_target, snapshot)
	if is_side_in_check(piece.side, moved_snapshot):
		return {"allowed": false, "reason": "That move leaves your general in check."}
	return {"allowed": true, "reason": ""}

func is_side_in_check(side: StringName, snapshot: Array) -> bool:
	var general_coords = general_position(side, snapshot)
	if general_coords == XiangqiStateModelScript.INVALID_COORDS:
		return true
	for piece_info in snapshot:
		if piece_info.get("side", &"") == side:
			continue
		if _piece_attacks_square(piece_info, general_coords, snapshot):
			return true
	return false

func is_general_missing(side: StringName, snapshot: Array) -> bool:
	return general_position(side, snapshot) == XiangqiStateModelScript.INVALID_COORDS

func general_position(side: StringName, snapshot: Array) -> Vector2i:
	for piece_info in snapshot:
		if piece_info.get("side", &"") == side and piece_info.get("type", &"") == &"general":
			return piece_info.get("coords", XiangqiStateModelScript.INVALID_COORDS)
	return XiangqiStateModelScript.INVALID_COORDS

func has_legal_move(side: StringName, snapshot: Array) -> bool:
	for piece_info in snapshot:
		if piece_info.get("side", &"") != side:
			continue
		for row in range(XiangqiStateModelScript.BOARD_ROWS):
			for column in range(XiangqiStateModelScript.BOARD_COLUMNS):
				var coords = Vector2i(column, row)
				if coords == piece_info.get("coords", XiangqiStateModelScript.INVALID_COORDS):
					continue
				var target_info = _state_model.snapshot_piece_at(coords, snapshot)
				if not target_info.is_empty() and target_info.get("side", &"") == side:
					continue
				if _raw_move_reason(piece_info, coords, target_info, snapshot) != "":
					continue
				var captured_piece = target_info.get("piece", null) if not target_info.is_empty() else null
				var moved_snapshot = _state_model.snapshot_after_move(piece_info.get("piece", null), coords, captured_piece, snapshot)
				if not is_side_in_check(side, moved_snapshot):
					return true
	return false

func other_side(side: StringName) -> StringName:
	return &"black" if side == &"red" else &"red"

func side_name(side: StringName) -> String:
	return "Red" if side == &"red" else "Black"

func _raw_move_reason(piece_info: Dictionary, target_coords: Vector2i, target_info: Dictionary, snapshot: Array) -> String:
	if piece_info.is_empty():
		return "That piece is unavailable."
	var from_coords: Vector2i = piece_info.get("coords", XiangqiStateModelScript.INVALID_COORDS)
	var dx = target_coords.x - from_coords.x
	var dy = target_coords.y - from_coords.y
	var abs_dx = absi(dx)
	var abs_dy = absi(dy)
	var has_capture = not target_info.is_empty()
	match piece_info.get("type", &""):
		&"general":
			if abs_dx + abs_dy != 1:
				return "Generals move one step orthogonally."
			if not _inside_palace(piece_info.get("side", &""), target_coords):
				return "Generals must stay inside the palace."
		&"advisor":
			if abs_dx != 1 or abs_dy != 1:
				return "Advisors move one step diagonally."
			if not _inside_palace(piece_info.get("side", &""), target_coords):
				return "Advisors must stay inside the palace."
		&"elephant":
			if abs_dx != 2 or abs_dy != 2:
				return "Elephants move exactly two points diagonally."
			if _crosses_river(piece_info.get("side", &""), target_coords):
				return "Elephants cannot cross the river."
			var elephant_eye = from_coords + Vector2i(_step(dx), _step(dy))
			if not _state_model.snapshot_piece_at(elephant_eye, snapshot).is_empty():
				return "An elephant cannot jump over the eye point."
		&"horse":
			if not ((abs_dx == 2 and abs_dy == 1) or (abs_dx == 1 and abs_dy == 2)):
				return "Horses move in an L shape."
			var horse_leg = from_coords + (Vector2i(_step(dx), 0) if abs_dx == 2 else Vector2i(0, _step(dy)))
			if not _state_model.snapshot_piece_at(horse_leg, snapshot).is_empty():
				return "The horse leg is blocked."
		&"chariot":
			if dx != 0 and dy != 0:
				return "Chariots move in straight lines."
			if _count_between(from_coords, target_coords, snapshot) != 0:
				return "Chariots cannot jump over intervening pieces."
		&"cannon":
			if dx != 0 and dy != 0:
				return "Cannons move in straight lines."
			var screens = _count_between(from_coords, target_coords, snapshot)
			if has_capture and screens != 1:
				return "Cannons need exactly one screen to capture."
			if not has_capture and screens != 0:
				return "Cannons cannot jump when not capturing."
		&"soldier":
			if not _soldier_move_allowed(piece_info.get("side", &""), from_coords, target_coords):
				return "Soldiers move one step forward, or sideways only after crossing the river."
		_:
			return "Unknown Xiangqi piece."
	return ""

func _piece_attacks_square(piece_info: Dictionary, target_coords: Vector2i, snapshot: Array) -> bool:
	var from_coords: Vector2i = piece_info.get("coords", XiangqiStateModelScript.INVALID_COORDS)
	var dx = target_coords.x - from_coords.x
	var dy = target_coords.y - from_coords.y
	var abs_dx = absi(dx)
	var abs_dy = absi(dy)
	match piece_info.get("type", &""):
		&"general":
			if abs_dx + abs_dy == 1:
				return true
			return dx == 0 and _count_between(from_coords, target_coords, snapshot) == 0
		&"advisor":
			return abs_dx == 1 and abs_dy == 1
		&"elephant":
			if abs_dx != 2 or abs_dy != 2:
				return false
			if _crosses_river(piece_info.get("side", &""), target_coords):
				return false
			var elephant_eye = from_coords + Vector2i(_step(dx), _step(dy))
			return _state_model.snapshot_piece_at(elephant_eye, snapshot).is_empty()
		&"horse":
			if not ((abs_dx == 2 and abs_dy == 1) or (abs_dx == 1 and abs_dy == 2)):
				return false
			var horse_leg = from_coords + (Vector2i(_step(dx), 0) if abs_dx == 2 else Vector2i(0, _step(dy)))
			return _state_model.snapshot_piece_at(horse_leg, snapshot).is_empty()
		&"chariot":
			return (dx == 0 or dy == 0) and _count_between(from_coords, target_coords, snapshot) == 0
		&"cannon":
			return (dx == 0 or dy == 0) and _count_between(from_coords, target_coords, snapshot) == 1
		&"soldier":
			return _soldier_move_allowed(piece_info.get("side", &""), from_coords, target_coords)
		_:
			return false

func _count_between(from_coords: Vector2i, to_coords: Vector2i, snapshot: Array) -> int:
	if from_coords.x != to_coords.x and from_coords.y != to_coords.y:
		return 0
	var count = 0
	if from_coords.x == to_coords.x:
		var step = _step(to_coords.y - from_coords.y)
		for row in range(from_coords.y + step, to_coords.y, step):
			if not _state_model.snapshot_piece_at(Vector2i(from_coords.x, row), snapshot).is_empty():
				count += 1
	else:
		var step = _step(to_coords.x - from_coords.x)
		for column in range(from_coords.x + step, to_coords.x, step):
			if not _state_model.snapshot_piece_at(Vector2i(column, from_coords.y), snapshot).is_empty():
				count += 1
	return count

func _soldier_move_allowed(side: StringName, from_coords: Vector2i, target_coords: Vector2i) -> bool:
	var dx = target_coords.x - from_coords.x
	var dy = target_coords.y - from_coords.y
	var forward = -1 if side == &"red" else 1
	if dx == 0 and dy == forward:
		return true
	if _has_crossed_river(side, from_coords) and dy == 0 and absi(dx) == 1:
		return true
	return false

func _has_crossed_river(side: StringName, coords: Vector2i) -> bool:
	return coords.y <= 4 if side == &"red" else coords.y >= 5

func _crosses_river(side: StringName, coords: Vector2i) -> bool:
	return coords.y >= 5 if side == &"black" else coords.y <= 4

func _inside_palace(side: StringName, coords: Vector2i) -> bool:
	if coords.x < 3 or coords.x > 5:
		return false
	return coords.y >= 7 and coords.y <= 9 if side == &"red" else coords.y >= 0 and coords.y <= 2

func _is_inside_board(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.y >= 0 and coords.x < XiangqiStateModelScript.BOARD_COLUMNS and coords.y < XiangqiStateModelScript.BOARD_ROWS

func _step(value: int) -> int:
	if value == 0:
		return 0
	return 1 if value > 0 else -1
