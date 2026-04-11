extends RefCounted

const XiangqiPieceScript = preload("res://scenes/showcases/xiangqi/pieces/xiangqi_piece.gd")
const XiangqiStateModelScript = preload("res://scenes/showcases/xiangqi/state/xiangqi_state_model.gd")

var _board_zone: BattlefieldZone = null

func attach(board_zone: BattlefieldZone) -> void:
	_board_zone = board_zone

func board_zone_ref() -> BattlefieldZone:
	return _board_zone

func get_pieces() -> Array:
	var pieces: Array = []
	if _board_zone == null:
		return pieces
	for item in _board_zone.get_items():
		if item is XiangqiPieceScript and is_instance_valid(item):
			pieces.append(item)
	return pieces

func get_piece_at(coords: Vector2i) -> Control:
	for piece in get_pieces():
		if get_piece_coords(piece) == coords:
			return piece
	return null

func get_piece_coords(piece: Control) -> Vector2i:
	if _board_zone == null or piece == null:
		return XiangqiStateModelScript.INVALID_COORDS
	var target = _board_zone.get_item_target(piece)
	if target == null or not target.is_valid():
		return XiangqiStateModelScript.INVALID_COORDS
	return target.grid_coordinates

func spawn_piece(side: StringName, piece_type: StringName) -> Control:
	var definition = XiangqiStateModelScript.PIECE_DEFS.get(piece_type, XiangqiStateModelScript.PIECE_DEFS[&"soldier"])
	var piece = XiangqiPieceScript.new()
	var glyph = definition.get("red", "兵") if side == &"red" else definition.get("black", "卒")
	piece.configure(side, piece_type, glyph, definition.get("name", "Piece"))
	return piece

func clear_pieces() -> void:
	if _board_zone == null:
		return
	if _board_zone.is_targeting():
		_board_zone.cancel_targeting()
	for item in _board_zone.get_items():
		if _board_zone.remove_item(item):
			item.queue_free()

func resolve_target_candidate(candidate: ZoneTargetCandidate) -> Dictionary:
	if candidate == null or not candidate.is_valid():
		return {"valid": false, "coords": XiangqiStateModelScript.INVALID_COORDS, "target_piece": null}
	if candidate.is_item():
		if candidate.target_item is not XiangqiPieceScript:
			return {"valid": false, "coords": XiangqiStateModelScript.INVALID_COORDS, "target_piece": null}
		var piece = candidate.target_item as XiangqiPieceScript
		return {"valid": true, "coords": get_piece_coords(piece), "target_piece": piece}
	if candidate.is_placement():
		var coords = candidate.placement_target.grid_coordinates
		return {"valid": true, "coords": coords, "target_piece": get_piece_at(coords)}
	return {"valid": false, "coords": XiangqiStateModelScript.INVALID_COORDS, "target_piece": null}
