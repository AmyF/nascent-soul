extends Control

const DemoLayoutSupport = preload("res://scenes/examples/shared/demo_layout_support.gd")
const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")
const XiangqiPieceScript = preload("res://scenes/examples/xiangqi/xiangqi_piece.gd")
const XiangqiTargetPolicyScript = preload("res://scenes/examples/xiangqi/xiangqi_target_policy.gd")
const XiangqiBoardOverlayScript = preload("res://scenes/examples/xiangqi/xiangqi_board_overlay.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_STATUS_COLOR := Color(0.96, 0.60, 0.56)
const WIN_STATUS_COLOR := Color(0.93, 0.88, 0.62)
const INVALID_COORDS := Vector2i(-1, -1)
const BOARD_COLUMNS := 9
const BOARD_ROWS := 10
const INITIAL_SETUP := [
	{"side": &"black", "type": &"chariot", "coords": Vector2i(0, 0)},
	{"side": &"black", "type": &"horse", "coords": Vector2i(1, 0)},
	{"side": &"black", "type": &"elephant", "coords": Vector2i(2, 0)},
	{"side": &"black", "type": &"advisor", "coords": Vector2i(3, 0)},
	{"side": &"black", "type": &"general", "coords": Vector2i(4, 0)},
	{"side": &"black", "type": &"advisor", "coords": Vector2i(5, 0)},
	{"side": &"black", "type": &"elephant", "coords": Vector2i(6, 0)},
	{"side": &"black", "type": &"horse", "coords": Vector2i(7, 0)},
	{"side": &"black", "type": &"chariot", "coords": Vector2i(8, 0)},
	{"side": &"black", "type": &"cannon", "coords": Vector2i(1, 2)},
	{"side": &"black", "type": &"cannon", "coords": Vector2i(7, 2)},
	{"side": &"black", "type": &"soldier", "coords": Vector2i(0, 3)},
	{"side": &"black", "type": &"soldier", "coords": Vector2i(2, 3)},
	{"side": &"black", "type": &"soldier", "coords": Vector2i(4, 3)},
	{"side": &"black", "type": &"soldier", "coords": Vector2i(6, 3)},
	{"side": &"black", "type": &"soldier", "coords": Vector2i(8, 3)},
	{"side": &"red", "type": &"chariot", "coords": Vector2i(0, 9)},
	{"side": &"red", "type": &"horse", "coords": Vector2i(1, 9)},
	{"side": &"red", "type": &"elephant", "coords": Vector2i(2, 9)},
	{"side": &"red", "type": &"advisor", "coords": Vector2i(3, 9)},
	{"side": &"red", "type": &"general", "coords": Vector2i(4, 9)},
	{"side": &"red", "type": &"advisor", "coords": Vector2i(5, 9)},
	{"side": &"red", "type": &"elephant", "coords": Vector2i(6, 9)},
	{"side": &"red", "type": &"horse", "coords": Vector2i(7, 9)},
	{"side": &"red", "type": &"chariot", "coords": Vector2i(8, 9)},
	{"side": &"red", "type": &"cannon", "coords": Vector2i(1, 7)},
	{"side": &"red", "type": &"cannon", "coords": Vector2i(7, 7)},
	{"side": &"red", "type": &"soldier", "coords": Vector2i(0, 6)},
	{"side": &"red", "type": &"soldier", "coords": Vector2i(2, 6)},
	{"side": &"red", "type": &"soldier", "coords": Vector2i(4, 6)},
	{"side": &"red", "type": &"soldier", "coords": Vector2i(6, 6)},
	{"side": &"red", "type": &"soldier", "coords": Vector2i(8, 6)}
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

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var toolbar: Control = $RootMargin/RootVBox/Toolbar
@onready var new_game_button: Button = $RootMargin/RootVBox/Toolbar/NewGameButton
@onready var cancel_button: Button = $RootMargin/RootVBox/Toolbar/CancelMoveButton
@onready var state_row: Control = $RootMargin/RootVBox/StateRow
@onready var turn_label: Label = $RootMargin/RootVBox/StateRow/TurnLabel
@onready var status_label: Label = $RootMargin/RootVBox/StateRow/StatusLabel
@onready var content_row: HFlowContainer = $RootMargin/RootVBox/ContentRow
@onready var left_panel: Panel = $RootMargin/RootVBox/ContentRow/LeftPanel
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/BoardColumn
@onready var board_label: Label = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardLabel
@onready var board_caption: Label = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardCaption
@onready var board_panel: Panel = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel
@onready var right_panel: Panel = $RootMargin/RootVBox/ContentRow/RightPanel
@onready var red_capture_label: Label = $RootMargin/RootVBox/ContentRow/LeftPanel/LeftVBox/RedCaptureLabel
@onready var black_capture_label: Label = $RootMargin/RootVBox/ContentRow/RightPanel/RightVBox/BlackCaptureLabel
@onready var board_host: Control = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost

var _board_zone: BattlefieldZone = null
var _board_overlay: Control = null
var _space_model: ZoneSquareGridSpaceModel = null
var _current_side: StringName = &"red"
var _game_over: bool = false
var _winner_side: StringName = &""
var _captured_by_red: Array[String] = []
var _captured_by_black: Array[String] = []

func _ready() -> void:
	_build_board()
	_wire_controls()
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	start_new_game()

func _exit_tree() -> void:
	if _board_zone != null and _board_zone.is_targeting():
		_board_zone.cancel_targeting()

func start_new_game() -> void:
	load_debug_state({
		"current_side": "red",
		"pieces": INITIAL_SETUP
	})
	_set_status("Red moves first. Click a red piece to begin targeting.", NORMAL_STATUS_COLOR)

func load_debug_state(state: Dictionary) -> void:
	_clear_board()
	_captured_by_red.clear()
	_captured_by_black.clear()
	_current_side = StringName(str(state.get("current_side", "red")))
	_game_over = false
	_winner_side = &""
	var pieces: Array = state.get("pieces", [])
	for piece_state in pieces:
		var side = StringName(str(piece_state.get("side", "red")))
		var piece_type = StringName(str(piece_state.get("type", "soldier")))
		var coords = piece_state.get("coords", INVALID_COORDS)
		if coords is not Vector2i:
			continue
		var piece = _create_piece(side, piece_type)
		_board_zone.add_item(piece, ZonePlacementTarget.square(coords.x, coords.y))
	_refresh_side_panels()
	_refresh_turn_label()
	_update_terminal_state_after_move()

func get_piece_at_coords(coords: Vector2i) -> Control:
	for piece in _typed_pieces():
		if _piece_coords(piece) == coords:
			return piece
	return null

func try_move_at(from_coords: Vector2i, to_coords: Vector2i) -> bool:
	var piece = get_piece_at_coords(from_coords)
	if piece is not XiangqiPieceScript:
		return false
	return _attempt_piece_move(piece as XiangqiPieceScript, to_coords, true)

func is_side_in_check(side: StringName) -> bool:
	return _is_side_in_check(side, _snapshot_board())

func get_winner() -> StringName:
	return _winner_side

func evaluate_xiangqi_target(request: ZoneTargetRequest) -> ZoneTargetDecision:
	if request == null or request.source_item is not XiangqiPieceScript:
		return ZoneTargetDecision.new(false, "Only Xiangqi pieces can target the board.", ZoneTargetCandidate.invalid())
	var piece := request.source_item as XiangqiPieceScript
	if _game_over:
		return ZoneTargetDecision.new(false, "The game is over. Start a new board to continue.", request.candidate)
	if piece.side != _current_side:
		return ZoneTargetDecision.new(false, "It is %s's turn." % _side_name(_current_side), request.candidate)
	var resolution = _resolve_candidate(request.candidate)
	if not resolution.valid:
		return ZoneTargetDecision.new(false, "Choose a legal board intersection or an enemy piece.", request.candidate)
	var evaluation = _evaluate_move(piece, resolution.coords, resolution.target_piece, true)
	if not evaluation.allowed:
		return ZoneTargetDecision.new(false, evaluation.reason, request.candidate)
	return ZoneTargetDecision.new(true, "", request.candidate)

func _build_board() -> void:
	if _board_zone != null:
		return
	_space_model = ZoneSquareGridSpaceModel.new()
	_space_model.columns = BOARD_COLUMNS
	_space_model.rows = BOARD_ROWS
	_space_model.cell_size = Vector2(72, 72)
	_space_model.cell_spacing = Vector2.ZERO
	_space_model.padding = Vector2(20, 20)
	_board_overlay = XiangqiBoardOverlayScript.new()
	_board_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_overlay.columns = BOARD_COLUMNS
	_board_overlay.rows = BOARD_ROWS
	_board_overlay.cell_size = _space_model.cell_size
	_board_overlay.cell_spacing = _space_model.cell_spacing
	_board_overlay.padding = _space_model.padding
	board_host.add_child(_board_overlay)
	var display_style := ZoneCardDisplay.new()
	display_style.hovered_scale = 1.03
	display_style.selected_scale = 1.02
	display_style.hovered_lift = 0.0
	display_style.selected_lift = 0.0
	var interaction := ZoneInteraction.new()
	interaction.drag_enabled = false
	interaction.multi_select_enabled = false
	interaction.keyboard_navigation_enabled = false
	var transfer_policy := ZoneOccupancyTransferPolicy.new()
	_board_zone = ExampleSupport.make_battlefield_zone(board_host, "XiangqiBoardZone", _space_model, transfer_policy, display_style, interaction)
	ExampleSupport.set_zone_targeting_style(_board_zone, TargetingSupport.builtin_targeting_style(&"tactical"))
	_board_zone.item_clicked.connect(_on_board_item_clicked)
	_board_zone.targeting_started.connect(_on_targeting_started)
	_board_zone.target_hover_state_changed.connect(_on_target_hover_state_changed)
	_board_zone.targeting_resolved.connect(_on_targeting_resolved)
	_board_zone.targeting_cancelled.connect(_on_targeting_cancelled)

func _wire_controls() -> void:
	new_game_button.pressed.connect(start_new_game)
	cancel_button.pressed.connect(_cancel_targeting)

func _clear_board() -> void:
	if _board_zone != null and _board_zone.is_targeting():
		_board_zone.cancel_targeting()
	for item in _board_zone.get_items():
		if _board_zone.remove_item(item):
			item.queue_free()

func _create_piece(side: StringName, piece_type: StringName) -> Control:
	var definition = PIECE_DEFS.get(piece_type, PIECE_DEFS[&"soldier"])
	var piece = XiangqiPieceScript.new()
	var glyph = definition.get("red", "兵") if side == &"red" else definition.get("black", "卒")
	piece.configure(side, piece_type, glyph, definition.get("name", "Piece"))
	return piece

func _on_board_item_clicked(item: Control) -> void:
	if item is not XiangqiPieceScript:
		return
	var piece := item as XiangqiPieceScript
	if _game_over:
		_set_status("The game is over. Start a new board to keep playing.", REJECT_STATUS_COLOR)
		return
	if piece.side != _current_side:
		_set_status("It is %s's turn." % _side_name(_current_side), REJECT_STATUS_COLOR)
		return
	var intent = _make_targeting_intent()
	if ExampleSupport.begin_item_targeting(_board_zone, piece, intent):
		_set_status("%s selected. Choose a legal destination." % piece.display_name())

func _on_targeting_started(source_item: Control, _source_zone: Zone, _intent: ZoneTargetingIntent) -> void:
	if source_item is XiangqiPieceScript:
		_set_status("%s selected. Choose a legal destination." % (source_item as XiangqiPieceScript).display_name())

func _on_target_hover_state_changed(source_item: Control, _target_zone: Zone, decision: ZoneTargetDecision) -> void:
	if source_item is not XiangqiPieceScript or decision == null:
		return
	var piece := source_item as XiangqiPieceScript
	if decision.allowed and decision.resolved_candidate != null and decision.resolved_candidate.is_valid():
		var resolution = _resolve_candidate(decision.resolved_candidate)
		if resolution.valid:
			_set_status("%s can move to %s." % [piece.display_name(), _coords_label(resolution.coords)], NORMAL_STATUS_COLOR)
	elif decision.reason != "":
		_set_status(decision.reason, REJECT_STATUS_COLOR)

func _on_targeting_resolved(source_item: Control, _source_zone: Zone, candidate: ZoneTargetCandidate, _decision: ZoneTargetDecision) -> void:
	if source_item is not XiangqiPieceScript:
		return
	var piece := source_item as XiangqiPieceScript
	var resolution = _resolve_candidate(candidate)
	if not resolution.valid:
		_set_status("Choose a legal destination on the board.", REJECT_STATUS_COLOR)
		return
	_attempt_piece_move(piece, resolution.coords, true)

func _on_targeting_cancelled(source_item: Control, _source_zone: Zone) -> void:
	if source_item is XiangqiPieceScript:
		_set_status("%s targeting cancelled." % (source_item as XiangqiPieceScript).display_name(), REJECT_STATUS_COLOR)

func _cancel_targeting() -> void:
	if _board_zone != null and _board_zone.is_targeting():
		_board_zone.cancel_targeting()

func _attempt_piece_move(piece: XiangqiPieceScript, target_coords: Vector2i, announce: bool) -> bool:
	var target_piece = get_piece_at_coords(target_coords)
	var evaluation = _evaluate_move(piece, target_coords, target_piece, true)
	if not evaluation.allowed:
		if announce:
			_set_status(evaluation.reason, REJECT_STATUS_COLOR)
		return false
	var from_coords = _piece_coords(piece)
	var captured_piece = target_piece as XiangqiPieceScript if target_piece is XiangqiPieceScript else null
	if captured_piece != null:
		_record_capture(piece.side, captured_piece)
		if _board_zone.remove_item(captured_piece):
			captured_piece.queue_free()
	var moved = ExampleSupport.move_item(_board_zone, piece, _board_zone, ZonePlacementTarget.square(target_coords.x, target_coords.y))
	if not moved:
		if announce:
			_set_status("The battlefield could not apply that move.", REJECT_STATUS_COLOR)
		return false
	_current_side = _other_side(piece.side)
	_refresh_side_panels()
	_refresh_turn_label()
	if announce:
		if captured_piece != null:
			_set_status("%s captured %s at %s." % [piece.display_name(), captured_piece.display_name(), _coords_label(target_coords)])
		else:
			_set_status("%s moved from %s to %s." % [piece.display_name(), _coords_label(from_coords), _coords_label(target_coords)])
	_update_terminal_state_after_move()
	return true

func _update_terminal_state_after_move() -> void:
	if _general_missing(&"red"):
		_game_over = true
		_winner_side = &"black"
		_refresh_turn_label()
		_set_status("Black wins. The red general has fallen.", WIN_STATUS_COLOR)
		return
	if _general_missing(&"black"):
		_game_over = true
		_winner_side = &"red"
		_refresh_turn_label()
		_set_status("Red wins. The black general has fallen.", WIN_STATUS_COLOR)
		return
	if not _has_legal_move(_current_side):
		_game_over = true
		_winner_side = _other_side(_current_side)
		_refresh_turn_label()
		if _is_side_in_check(_current_side, _snapshot_board()):
			_set_status("%s wins by checkmate." % _side_name(_winner_side), WIN_STATUS_COLOR)
		else:
			_set_status("%s wins. %s has no legal moves." % [_side_name(_winner_side), _side_name(_current_side)], WIN_STATUS_COLOR)
		return
	_game_over = false
	_winner_side = &""
	if _is_side_in_check(_current_side, _snapshot_board()):
		_set_status("%s is in check. Choose a legal reply." % _side_name(_current_side), REJECT_STATUS_COLOR)

func _make_targeting_intent() -> ZoneTargetingIntent:
	var policy = XiangqiTargetPolicyScript.new()
	policy.controller = self
	var intent := ZoneTargetingIntent.new()
	intent.policy = policy
	intent.style_override = TargetingSupport.builtin_targeting_style(&"tactical")
	intent.allowed_candidate_kinds = PackedInt32Array([
		ZoneTargetCandidate.CandidateKind.ITEM,
		ZoneTargetCandidate.CandidateKind.PLACEMENT
	])
	return intent

func _evaluate_move(piece: XiangqiPieceScript, target_coords: Vector2i, target_piece: Control, enforce_turn: bool) -> Dictionary:
	if not is_instance_valid(piece):
		return {"allowed": false, "reason": "That piece is no longer on the board."}
	if not _is_inside_board(target_coords):
		return {"allowed": false, "reason": "That destination is outside the board."}
	if enforce_turn and piece.side != _current_side:
		return {"allowed": false, "reason": "It is %s's turn." % _side_name(_current_side)}
	var from_coords = _piece_coords(piece)
	if from_coords == INVALID_COORDS:
		return {"allowed": false, "reason": "That piece is not on a legal board intersection."}
	if from_coords == target_coords:
		return {"allowed": false, "reason": "Choose a different destination."}
	var occupied_target = target_piece
	if occupied_target == null:
		occupied_target = get_piece_at_coords(target_coords)
	if occupied_target is XiangqiPieceScript and (occupied_target as XiangqiPieceScript).side == piece.side:
		return {"allowed": false, "reason": "You cannot capture your own piece."}
	var snapshot = _snapshot_board()
	var piece_info = _snapshot_piece_for(piece, snapshot)
	var target_info = _snapshot_piece_at(target_coords, snapshot)
	var raw_reason = _raw_move_reason(piece_info, target_coords, target_info, snapshot)
	if raw_reason != "":
		return {"allowed": false, "reason": raw_reason}
	var moved_snapshot = _snapshot_after_move(piece, target_coords, occupied_target as XiangqiPieceScript, snapshot)
	if _is_side_in_check(piece.side, moved_snapshot):
		return {"allowed": false, "reason": "That move leaves your general in check."}
	return {"allowed": true, "reason": ""}

func _resolve_candidate(candidate: ZoneTargetCandidate) -> Dictionary:
	if candidate == null or not candidate.is_valid():
		return {"valid": false, "coords": INVALID_COORDS, "target_piece": null}
	if candidate.is_item():
		if candidate.target_item is not XiangqiPieceScript:
			return {"valid": false, "coords": INVALID_COORDS, "target_piece": null}
		var piece = candidate.target_item as XiangqiPieceScript
		return {"valid": true, "coords": _piece_coords(piece), "target_piece": piece}
	if candidate.is_placement():
		var coords = candidate.placement_target.coordinates
		return {"valid": true, "coords": coords, "target_piece": get_piece_at_coords(coords)}
	return {"valid": false, "coords": INVALID_COORDS, "target_piece": null}

func _typed_pieces() -> Array:
	var pieces: Array = []
	for item in _board_zone.get_items():
		if item is XiangqiPieceScript and is_instance_valid(item):
			pieces.append(item)
	return pieces

func _piece_coords(piece: Control) -> Vector2i:
	if _board_zone == null or piece == null:
		return INVALID_COORDS
	var target = _board_zone.get_item_target(piece)
	if target == null or not target.is_valid():
		return INVALID_COORDS
	return target.coordinates

func _snapshot_board() -> Array:
	var snapshot: Array = []
	for piece in _typed_pieces():
		snapshot.append({
			"piece": piece,
			"side": piece.side,
			"type": piece.piece_type,
			"coords": _piece_coords(piece)
		})
	return snapshot

func _snapshot_piece_for(piece: XiangqiPieceScript, snapshot: Array) -> Dictionary:
	for piece_info in snapshot:
		if piece_info["piece"] == piece:
			return piece_info
	return {}

func _snapshot_piece_at(coords: Vector2i, snapshot: Array) -> Dictionary:
	for piece_info in snapshot:
		if piece_info["coords"] == coords:
			return piece_info
	return {}

func _snapshot_after_move(piece: XiangqiPieceScript, target_coords: Vector2i, captured_piece: XiangqiPieceScript, snapshot: Array) -> Array:
	var moved_snapshot: Array = []
	for piece_info in snapshot:
		if captured_piece != null and piece_info["piece"] == captured_piece:
			continue
		var cloned = piece_info.duplicate(true)
		if piece_info["piece"] == piece:
			cloned["coords"] = target_coords
		moved_snapshot.append(cloned)
	return moved_snapshot

func _is_side_in_check(side: StringName, snapshot: Array) -> bool:
	var general_coords = _general_coords(side, snapshot)
	if general_coords == INVALID_COORDS:
		return true
	for piece_info in snapshot:
		if piece_info["side"] == side:
			continue
		if _piece_attacks_square(piece_info, general_coords, snapshot):
			return true
	return false

func _general_coords(side: StringName, snapshot: Array) -> Vector2i:
	for piece_info in snapshot:
		if piece_info["side"] == side and piece_info["type"] == &"general":
			return piece_info["coords"]
	return INVALID_COORDS

func _general_missing(side: StringName) -> bool:
	return _general_coords(side, _snapshot_board()) == INVALID_COORDS

func _has_legal_move(side: StringName) -> bool:
	var snapshot = _snapshot_board()
	for piece_info in snapshot:
		if piece_info["side"] != side:
			continue
		for row in range(BOARD_ROWS):
			for column in range(BOARD_COLUMNS):
				var coords = Vector2i(column, row)
				if coords == piece_info["coords"]:
					continue
				var target_info = _snapshot_piece_at(coords, snapshot)
				if not target_info.is_empty() and target_info["side"] == side:
					continue
				if _raw_move_reason(piece_info, coords, target_info, snapshot) != "":
					continue
				var moved_snapshot = _snapshot_after_move(piece_info["piece"], coords, target_info["piece"] if not target_info.is_empty() else null, snapshot)
				if not _is_side_in_check(side, moved_snapshot):
					return true
	return false

func _raw_move_reason(piece_info: Dictionary, target_coords: Vector2i, target_info: Dictionary, snapshot: Array) -> String:
	if piece_info.is_empty():
		return "That piece is unavailable."
	var from_coords: Vector2i = piece_info["coords"]
	var dx = target_coords.x - from_coords.x
	var dy = target_coords.y - from_coords.y
	var abs_dx = absi(dx)
	var abs_dy = absi(dy)
	var has_capture = not target_info.is_empty()
	match piece_info["type"]:
		&"general":
			if abs_dx + abs_dy != 1:
				return "Generals move one step orthogonally."
			if not _inside_palace(piece_info["side"], target_coords):
				return "Generals must stay inside the palace."
		&"advisor":
			if abs_dx != 1 or abs_dy != 1:
				return "Advisors move one step diagonally."
			if not _inside_palace(piece_info["side"], target_coords):
				return "Advisors must stay inside the palace."
		&"elephant":
			if abs_dx != 2 or abs_dy != 2:
				return "Elephants move exactly two points diagonally."
			if _crosses_river(piece_info["side"], target_coords):
				return "Elephants cannot cross the river."
			var elephant_eye = from_coords + Vector2i(_step(dx), _step(dy))
			if not _snapshot_piece_at(elephant_eye, snapshot).is_empty():
				return "An elephant cannot jump over the eye point."
		&"horse":
			if not ((abs_dx == 2 and abs_dy == 1) or (abs_dx == 1 and abs_dy == 2)):
				return "Horses move in an L shape."
			var horse_leg = from_coords + (Vector2i(_step(dx), 0) if abs_dx == 2 else Vector2i(0, _step(dy)))
			if not _snapshot_piece_at(horse_leg, snapshot).is_empty():
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
			if not _soldier_move_allowed(piece_info["side"], from_coords, target_coords):
				return "Soldiers move one step forward, or sideways only after crossing the river."
		_:
			return "Unknown Xiangqi piece."
	return ""

func _piece_attacks_square(piece_info: Dictionary, target_coords: Vector2i, snapshot: Array) -> bool:
	var from_coords: Vector2i = piece_info["coords"]
	var dx = target_coords.x - from_coords.x
	var dy = target_coords.y - from_coords.y
	var abs_dx = absi(dx)
	var abs_dy = absi(dy)
	match piece_info["type"]:
		&"general":
			if abs_dx + abs_dy == 1:
				return true
			return dx == 0 and _count_between(from_coords, target_coords, snapshot) == 0
		&"advisor":
			return abs_dx == 1 and abs_dy == 1
		&"elephant":
			if abs_dx != 2 or abs_dy != 2:
				return false
			if _crosses_river(piece_info["side"], target_coords):
				return false
			var elephant_eye = from_coords + Vector2i(_step(dx), _step(dy))
			return _snapshot_piece_at(elephant_eye, snapshot).is_empty()
		&"horse":
			if not ((abs_dx == 2 and abs_dy == 1) or (abs_dx == 1 and abs_dy == 2)):
				return false
			var horse_leg = from_coords + (Vector2i(_step(dx), 0) if abs_dx == 2 else Vector2i(0, _step(dy)))
			return _snapshot_piece_at(horse_leg, snapshot).is_empty()
		&"chariot":
			return (dx == 0 or dy == 0) and _count_between(from_coords, target_coords, snapshot) == 0
		&"cannon":
			return (dx == 0 or dy == 0) and _count_between(from_coords, target_coords, snapshot) == 1
		&"soldier":
			return _soldier_move_allowed(piece_info["side"], from_coords, target_coords)
		_:
			return false

func _count_between(from_coords: Vector2i, to_coords: Vector2i, snapshot: Array) -> int:
	if from_coords.x != to_coords.x and from_coords.y != to_coords.y:
		return 0
	var count := 0
	if from_coords.x == to_coords.x:
		var step = _step(to_coords.y - from_coords.y)
		for row in range(from_coords.y + step, to_coords.y, step):
			if not _snapshot_piece_at(Vector2i(from_coords.x, row), snapshot).is_empty():
				count += 1
	else:
		var step = _step(to_coords.x - from_coords.x)
		for column in range(from_coords.x + step, to_coords.x, step):
			if not _snapshot_piece_at(Vector2i(column, from_coords.y), snapshot).is_empty():
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
	return coords.x >= 0 and coords.y >= 0 and coords.x < BOARD_COLUMNS and coords.y < BOARD_ROWS

func _other_side(side: StringName) -> StringName:
	return &"black" if side == &"red" else &"red"

func _record_capture(capturing_side: StringName, captured_piece: XiangqiPieceScript) -> void:
	if capturing_side == &"red":
		_captured_by_red.append(captured_piece.glyph)
	else:
		_captured_by_black.append(captured_piece.glyph)

func _refresh_side_panels() -> void:
	red_capture_label.text = "Red captures: %s" % (" ".join(_captured_by_red) if not _captured_by_red.is_empty() else "None")
	black_capture_label.text = "Black captures: %s" % (" ".join(_captured_by_black) if not _captured_by_black.is_empty() else "None")

func _refresh_turn_label() -> void:
	if _game_over:
		turn_label.text = "Winner: %s" % _side_name(_winner_side)
		return
	turn_label.text = "Side to move: %s" % _side_name(_current_side)

func _coords_label(coords: Vector2i) -> String:
	return "(%d, %d)" % [coords.x, coords.y]

func _side_name(side: StringName) -> String:
	return "Red" if side == &"red" else "Black"

func _set_status(message: String, color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var mode = DemoLayoutSupport.mode_for(self)
	var content_width = max(root_vbox.size.x, DemoLayoutSupport.resolved_width(self) - 40.0)
	var row_spacing = float(content_row.get_theme_constant("h_separation"))
	var board_padding := Vector2(12.0, 12.0)
	var root_spacing = float(root_vbox.get_theme_constant("separation"))
	var board_spacing = float(board_column.get_theme_constant("separation"))
	var side_panel_height = 0.0
	if mode == DemoLayoutSupport.COMPACT:
		side_panel_height = 220.0 + row_spacing
	elif mode == DemoLayoutSupport.NARROW:
		side_panel_height = 180.0 * 2.0 + row_spacing * 2.0
	var available_content_height = max(420.0, root_vbox.size.y - _control_height(toolbar) - _control_height(state_row) - root_spacing * 2.0)
	var board_chrome_height = _control_height(board_label) + _control_height(board_caption) + board_spacing * 2.0
	var max_board_panel_height = max(400.0, available_content_height - side_panel_height - board_chrome_height)
	var cell_from_width = floor((content_width - board_padding.x * 2.0) / float(BOARD_COLUMNS))
	var cell_from_height = floor((max_board_panel_height - board_padding.y * 2.0) / float(BOARD_ROWS))
	var min_cell = 48.0 if mode == DemoLayoutSupport.DESKTOP else 40.0
	var resolved_cell = clamp(min(cell_from_width, cell_from_height), min_cell, 72.0)
	var cell_size := Vector2(resolved_cell, resolved_cell)
	var board_size = Vector2(
		board_padding.x * 2.0 + cell_size.x * BOARD_COLUMNS,
		board_padding.y * 2.0 + cell_size.y * BOARD_ROWS
	)
	if mode == DemoLayoutSupport.DESKTOP:
		DemoLayoutSupport.ensure_child_order(content_row, [left_panel, board_column, right_panel])
		DemoLayoutSupport.set_minimum_size(left_panel, 180.0, board_size.y)
		DemoLayoutSupport.set_minimum_size(right_panel, 180.0, board_size.y)
		DemoLayoutSupport.set_minimum_width(board_column, mode, board_size.x, board_size.x, board_size.x)
	else:
		DemoLayoutSupport.ensure_child_order(content_row, [board_column, left_panel, right_panel])
		var compact_panel_width = max(220.0, floor((content_width - row_spacing) * 0.5))
		var narrow_panel_width = max(0.0, content_width)
		var panel_width = compact_panel_width if mode == DemoLayoutSupport.COMPACT else narrow_panel_width
		var panel_height = 220.0 if mode == DemoLayoutSupport.COMPACT else 180.0
		DemoLayoutSupport.set_minimum_size(left_panel, panel_width, panel_height)
		DemoLayoutSupport.set_minimum_size(right_panel, panel_width, panel_height)
		DemoLayoutSupport.set_minimum_width(board_column, mode, board_size.x, content_width, content_width)
	DemoLayoutSupport.set_minimum_size(board_panel, board_size.x, board_size.y)
	if _space_model != null:
		_space_model.cell_size = cell_size
		_space_model.padding = board_padding
	if _board_overlay != null:
		_board_overlay.cell_size = cell_size
		_board_overlay.padding = board_padding
		_board_overlay.queue_redraw()
	if _board_zone != null:
		_board_zone.refresh()

func _step(value: int) -> int:
	if value == 0:
		return 0
	return 1 if value > 0 else -1

func _control_height(control: Control) -> float:
	if control == null:
		return 0.0
	return control.size.y if control.size.y > 0.0 else control.get_combined_minimum_size().y
