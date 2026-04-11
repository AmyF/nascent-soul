extends Control

const ExampleZoneSupport = preload("res://scenes/examples/shared/example_zone_support.gd")
const ZoneRuntimeHooksScript = preload("res://addons/nascentsoul/runtime/zone_runtime_hooks.gd")
const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")
const XiangqiBoardOverlayScript = preload("res://scenes/examples/xiangqi/xiangqi_board_overlay.gd")
const XiangqiBoardRegistryScript = preload("res://scenes/examples/xiangqi/xiangqi_board_registry.gd")
const XiangqiHistoryScript = preload("res://scenes/examples/xiangqi/xiangqi_history.gd")
const XiangqiMoveRulesScript = preload("res://scenes/examples/xiangqi/xiangqi_move_rules.gd")
const XiangqiPieceScript = preload("res://scenes/examples/xiangqi/xiangqi_piece.gd")
const XiangqiStateModelScript = preload("res://scenes/examples/xiangqi/xiangqi_state_model.gd")
const XiangqiTargetPolicyScript = preload("res://scenes/examples/xiangqi/xiangqi_target_policy.gd")

const NORMAL_STATUS_COLOR := Color(0.97, 0.98, 1.0)
const REJECT_STATUS_COLOR := Color(0.96, 0.60, 0.56)
const WIN_STATUS_COLOR := Color(0.93, 0.88, 0.62)
const HISTORY_LIMIT := 256
const UNDO_ANIMATION_PADDING := 0.08

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var toolbar: Control = $RootMargin/RootVBox/Toolbar
@onready var new_game_button: Button = $RootMargin/RootVBox/Toolbar/NewGameButton
@onready var undo_button: Button = $RootMargin/RootVBox/Toolbar/UndoButton
@onready var content_row: Control = $RootMargin/RootVBox/ContentRow
@onready var board_column: VBoxContainer = $RootMargin/RootVBox/ContentRow/BoardColumn
@onready var board_panel: Panel = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel
@onready var board_host: Control = $RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost

var _board_zone: BattlefieldZone = null
var _board_overlay: Control = null
var _space_model: ZoneSquareGridSpaceModel = null
var _current_side: StringName = &"red"
var _game_over: bool = false
var _winner_side: StringName = &""
var _captured_by_red: Array[String] = []
var _captured_by_black: Array[String] = []
var _last_status_message: String = ""
var _last_status_color: Color = NORMAL_STATUS_COLOR
var _board = XiangqiBoardRegistryScript.new()
var _history = XiangqiHistoryScript.new(HISTORY_LIMIT)
var _move_rules = XiangqiMoveRulesScript.new()
var _state_model = XiangqiStateModelScript.new()

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

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if _history.is_undo_animation_active():
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_ESCAPE:
		_cancel_targeting()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F2:
		start_new_game()
		get_viewport().set_input_as_handled()
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_Z:
		if undo_last_move():
			get_viewport().set_input_as_handled()

func start_new_game() -> void:
	load_debug_state(_state_model.build_initial_state())
	_set_status("Red moves first. Click a red piece to begin targeting.", NORMAL_STATUS_COLOR)

func load_debug_state(state: Dictionary) -> void:
	_apply_serialized_state(state, true)

func get_current_side() -> StringName:
	return _current_side

func can_undo() -> bool:
	return _history.can_undo()

func get_last_status_message() -> String:
	return _last_status_message

func get_captured_glyphs(side: StringName) -> Array[String]:
	return _captured_by_red.duplicate() if side == &"red" else _captured_by_black.duplicate()

func undo_last_move() -> bool:
	if _history.is_undo_animation_active():
		_set_status("The undo animation is still playing.", REJECT_STATUS_COLOR)
		return false
	if not can_undo():
		_update_undo_button_state()
		_set_status("There is no move to undo.", REJECT_STATUS_COLOR)
		return false
	var undo_step = _history.pop_undo()
	if undo_step.is_empty():
		_update_undo_button_state()
		_set_status("There is no move to undo.", REJECT_STATUS_COLOR)
		return false
	var snapshot = undo_step.get("snapshot", {})
	var transition = undo_step.get("transition", {})
	if _restore_state_from_undo_transition(snapshot, transition):
		_set_status("Undoing the last move...")
	else:
		_set_status("Undid the last move.")
	return true

func _apply_serialized_state(state: Dictionary, reset_history: bool) -> void:
	var resolved_state = _state_model.normalize_state(state)
	_history.finish_undo_animation()
	_clear_board()
	_captured_by_red = []
	_captured_by_black = []
	for glyph in resolved_state.get("captured_by_red", []):
		_captured_by_red.append(str(glyph))
	for glyph in resolved_state.get("captured_by_black", []):
		_captured_by_black.append(str(glyph))
	_current_side = StringName(str(resolved_state.get("current_side", "red")))
	_game_over = false
	_winner_side = &""
	var pieces: Array = resolved_state.get("pieces", [])
	for piece_state in pieces:
		var side = StringName(str(piece_state.get("side", "red")))
		var piece_type = StringName(str(piece_state.get("type", "soldier")))
		var coords = piece_state.get("coords", XiangqiStateModelScript.INVALID_COORDS)
		if coords is not Vector2i:
			continue
		var piece = _board.spawn_piece(side, piece_type)
		_board_zone.add_item(piece, ZonePlacementTarget.square(coords.x, coords.y))
	_refresh_side_panels()
	_refresh_turn_label()
	_update_terminal_state_after_move()
	if reset_history:
		_history.reset_to_snapshot(_serialize_state())
	else:
		_update_undo_button_state()

func get_piece_at_coords(coords: Vector2i) -> Control:
	return _board.get_piece_at(coords)

func try_move_at(from_coords: Vector2i, to_coords: Vector2i) -> bool:
	if _history.is_undo_animation_active():
		return false
	var piece = get_piece_at_coords(from_coords)
	if piece is not XiangqiPieceScript:
		return false
	return _attempt_piece_move(piece as XiangqiPieceScript, to_coords, true)

func is_side_in_check(side: StringName) -> bool:
	return _move_rules.is_side_in_check(side, _snapshot_board())

func get_winner() -> StringName:
	return _winner_side

func evaluate_xiangqi_target(request: ZoneTargetRequest) -> ZoneTargetDecision:
	if _history.is_undo_animation_active():
		return ZoneTargetDecision.new(false, "Finish the undo animation before moving again.", ZoneTargetCandidate.invalid())
	if request == null or request.source_item is not XiangqiPieceScript:
		return ZoneTargetDecision.new(false, "Only Xiangqi pieces can target the board.", ZoneTargetCandidate.invalid())
	var piece := request.source_item as XiangqiPieceScript
	if _game_over:
		return ZoneTargetDecision.new(false, "The game is over. Start a new board to continue.", request.candidate)
	if piece.side != _current_side:
		return ZoneTargetDecision.new(false, "It is %s's turn." % _side_name(_current_side), request.candidate)
	var resolution = _board.resolve_target_candidate(request.candidate)
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
	_space_model.columns = XiangqiStateModelScript.BOARD_COLUMNS
	_space_model.rows = XiangqiStateModelScript.BOARD_ROWS
	_space_model.cell_size = Vector2(72, 72)
	_space_model.cell_spacing = Vector2.ZERO
	_space_model.padding = Vector2(20, 20)
	_board_overlay = XiangqiBoardOverlayScript.new()
	_board_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_overlay.columns = XiangqiStateModelScript.BOARD_COLUMNS
	_board_overlay.rows = XiangqiStateModelScript.BOARD_ROWS
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
	_board_zone = ExampleZoneSupport.make_battlefield_zone(board_host, "XiangqiBoardZone", _space_model, transfer_policy, display_style, interaction)
	_board.attach(_board_zone)
	ExampleZoneSupport.set_zone_targeting_style(_board_zone, TargetingSupport.builtin_targeting_style(&"tactical"))
	_board_zone.item_clicked.connect(_on_board_item_clicked)
	_board_zone.targeting_started.connect(_on_targeting_started)
	_board_zone.target_hover_state_changed.connect(_on_target_hover_state_changed)
	_board_zone.targeting_resolved.connect(_on_targeting_resolved)
	_board_zone.targeting_cancelled.connect(_on_targeting_cancelled)

func _wire_controls() -> void:
	new_game_button.pressed.connect(start_new_game)
	undo_button.pressed.connect(undo_last_move)
	_update_undo_button_state()

func _clear_board() -> void:
	_board.clear_pieces()

func _on_board_item_clicked(item: Control) -> void:
	if _history.is_undo_animation_active():
		return
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
	if ExampleZoneSupport.begin_item_targeting(_board_zone, piece, intent):
		_set_status("%s selected. Choose a legal destination." % piece.display_name())

func _on_targeting_started(source_item: Control, _source_zone: Zone, _intent: ZoneTargetingIntent) -> void:
	if source_item is XiangqiPieceScript:
		_set_status("%s selected. Choose a legal destination." % (source_item as XiangqiPieceScript).display_name())

func _on_target_hover_state_changed(source_item: Control, _target_zone: Zone, decision: ZoneTargetDecision) -> void:
	if source_item is not XiangqiPieceScript or decision == null:
		return
	var piece := source_item as XiangqiPieceScript
	if decision.allowed and decision.resolved_candidate != null and decision.resolved_candidate.is_valid():
		var resolution = _board.resolve_target_candidate(decision.resolved_candidate)
		if resolution.valid:
			_set_status("%s can move to %s." % [piece.display_name(), _coords_label(resolution.coords)], NORMAL_STATUS_COLOR)
	elif decision.reason != "":
		_set_status(decision.reason, REJECT_STATUS_COLOR)

func _on_targeting_resolved(source_item: Control, _source_zone: Zone, candidate: ZoneTargetCandidate, _decision: ZoneTargetDecision) -> void:
	if source_item is not XiangqiPieceScript:
		return
	var piece := source_item as XiangqiPieceScript
	var resolution = _board.resolve_target_candidate(candidate)
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
	var from_coords = _board.get_piece_coords(piece)
	var captured_piece = target_piece as XiangqiPieceScript if target_piece is XiangqiPieceScript else null
	var captured_transition: Dictionary = {}
	if captured_piece != null:
		captured_transition = {
			"side": String(captured_piece.side),
			"type": String(captured_piece.piece_type),
			"coords": target_coords
		}
	if captured_piece != null:
		_record_capture(piece.side, captured_piece)
		if _board_zone.remove_item(captured_piece):
			captured_piece.queue_free()
	var moved = ExampleZoneSupport.move_item(_board_zone, piece, _board_zone, ZonePlacementTarget.square(target_coords.x, target_coords.y))
	if not moved:
		if announce:
			_set_status("The battlefield could not apply that move.", REJECT_STATUS_COLOR)
		return false
	_current_side = _move_rules.other_side(piece.side)
	_refresh_side_panels()
	_refresh_turn_label()
	if announce:
		if captured_piece != null:
			_set_status("%s captured %s at %s." % [piece.display_name(), captured_piece.display_name(), _coords_label(target_coords)])
		else:
			_set_status("%s moved from %s to %s." % [piece.display_name(), _coords_label(from_coords), _coords_label(target_coords)])
	_update_terminal_state_after_move()
	_history.commit_checkpoint(_serialize_state(), {
		"moving": {
			"side": String(piece.side),
			"type": String(piece.piece_type),
			"from": from_coords,
			"to": target_coords
		},
		"captured": captured_transition
	})
	_update_undo_button_state()
	return true

func _update_terminal_state_after_move() -> void:
	var snapshot = _snapshot_board()
	if _move_rules.is_general_missing(&"red", snapshot):
		_game_over = true
		_winner_side = &"black"
		_refresh_turn_label()
		_set_status("Black wins. The red general has fallen.", WIN_STATUS_COLOR)
		return
	if _move_rules.is_general_missing(&"black", snapshot):
		_game_over = true
		_winner_side = &"red"
		_refresh_turn_label()
		_set_status("Red wins. The black general has fallen.", WIN_STATUS_COLOR)
		return
	if not _move_rules.has_legal_move(_current_side, snapshot):
		_game_over = true
		_winner_side = _move_rules.other_side(_current_side)
		_refresh_turn_label()
		if _move_rules.is_side_in_check(_current_side, snapshot):
			_set_status("%s wins by checkmate." % _side_name(_winner_side), WIN_STATUS_COLOR)
		else:
			_set_status("%s wins. %s has no legal moves." % [_side_name(_winner_side), _side_name(_current_side)], WIN_STATUS_COLOR)
		return
	_game_over = false
	_winner_side = &""
	if _move_rules.is_side_in_check(_current_side, snapshot):
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
	return _move_rules.evaluate_move(piece, target_coords, target_piece, _current_side, _snapshot_board(), enforce_turn)

func _record_capture(capturing_side: StringName, captured_piece: XiangqiPieceScript) -> void:
	if capturing_side == &"red":
		_captured_by_red.append(captured_piece.glyph)
	else:
		_captured_by_black.append(captured_piece.glyph)

func _refresh_side_panels() -> void:
	pass

func _refresh_turn_label() -> void:
	pass

func _coords_label(coords: Vector2i) -> String:
	return "(%d, %d)" % [coords.x, coords.y]

func _side_name(side: StringName) -> String:
	return "Red" if side == &"red" else "Black"

func _set_status(message: String, color: Color = NORMAL_STATUS_COLOR) -> void:
	_last_status_message = message
	_last_status_color = color

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	var board_padding := Vector2(12.0, 12.0)
	var root_spacing = float(root_vbox.get_theme_constant("separation"))
	var available_width = max(420.0, root_vbox.size.x - 40.0)
	var available_height = max(420.0, root_vbox.size.y - _control_height(toolbar) - root_spacing * 2.0)
	var cell_from_width = floor((available_width - board_padding.x * 2.0) / float(XiangqiStateModelScript.BOARD_COLUMNS))
	var cell_from_height = floor((available_height - board_padding.y * 2.0) / float(XiangqiStateModelScript.BOARD_ROWS))
	var resolved_cell = clamp(min(cell_from_width, cell_from_height), 40.0, 72.0)
	var cell_size := Vector2(resolved_cell, resolved_cell)
	var board_size = Vector2(
		board_padding.x * 2.0 + cell_size.x * XiangqiStateModelScript.BOARD_COLUMNS,
		board_padding.y * 2.0 + cell_size.y * XiangqiStateModelScript.BOARD_ROWS
	)
	board_column.custom_minimum_size = board_size
	board_panel.custom_minimum_size = board_size
	if _space_model != null:
		_space_model.cell_size = cell_size
		_space_model.padding = board_padding
	if _board_overlay != null:
		_board_overlay.cell_size = cell_size
		_board_overlay.padding = board_padding
		_board_overlay.queue_redraw()
	if _board_zone != null:
		_board_zone.refresh()

func _control_height(control: Control) -> float:
	if control == null:
		return 0.0
	return control.size.y if control.size.y > 0.0 else control.get_combined_minimum_size().y

func _serialize_state() -> Dictionary:
	return _state_model.serialize_state(
		_current_side,
		_board.get_pieces(),
		Callable(_board, "get_piece_coords"),
		_captured_by_red,
		_captured_by_black
	)

func _update_undo_button_state() -> void:
	if is_instance_valid(new_game_button):
		new_game_button.disabled = _history.is_undo_animation_active()
	if not is_instance_valid(undo_button):
		return
	undo_button.disabled = _history.is_undo_animation_active() or not can_undo()

func _restore_state_from_undo_transition(state: Dictionary, transition: Dictionary) -> bool:
	var resolved_state = _state_model.normalize_state(state)
	var should_animate = _xiangqi_animation_duration() > 0.0 and DisplayServer.get_name() != "headless"
	if should_animate:
		_history.mark_undo_animation_started()
		_update_undo_button_state()
	var restored = _apply_undo_transition(resolved_state, transition)
	if not restored:
		_history.finish_undo_animation()
		_apply_serialized_state(resolved_state, false)
		return false
	_current_side = StringName(str(resolved_state.get("current_side", "red")))
	_captured_by_red = []
	_captured_by_black = []
	for glyph in resolved_state.get("captured_by_red", []):
		_captured_by_red.append(str(glyph))
	for glyph in resolved_state.get("captured_by_black", []):
		_captured_by_black.append(str(glyph))
	_game_over = false
	_winner_side = &""
	_refresh_side_panels()
	_refresh_turn_label()
	_update_terminal_state_after_move()
	if not should_animate:
		_history.finish_undo_animation()
		_update_undo_button_state()
		return false
	var timer = get_tree().create_timer(_xiangqi_animation_duration() + UNDO_ANIMATION_PADDING)
	timer.timeout.connect(_finish_undo_animation, CONNECT_ONE_SHOT)
	return true

func _apply_undo_transition(state: Dictionary, transition: Dictionary) -> bool:
	if transition.is_empty() or _board_zone == null:
		return false
	_cancel_targeting()
	var moving = transition.get("moving", {})
	if moving.is_empty():
		return false
	var from_coords = moving.get("from", XiangqiStateModelScript.INVALID_COORDS)
	var to_coords = moving.get("to", XiangqiStateModelScript.INVALID_COORDS)
	if from_coords is not Vector2i or to_coords is not Vector2i:
		return false
	var moving_piece = get_piece_at_coords(to_coords)
	if moving_piece is not XiangqiPieceScript:
		return false
	var moved_piece := moving_piece as XiangqiPieceScript
	if String(moved_piece.side) != str(moving.get("side", "")) or String(moved_piece.piece_type) != str(moving.get("type", "")):
		return false
	var restore_snapshot = _piece_restore_snapshot(moved_piece)
	if not ExampleZoneSupport.move_item(_board_zone, moved_piece, _board_zone, ZonePlacementTarget.square(from_coords.x, from_coords.y)):
		return false
	var captured = transition.get("captured", {})
	if not captured.is_empty():
		var captured_side = StringName(str(captured.get("side", "")))
		var captured_type = StringName(str(captured.get("type", "")))
		var captured_coords = captured.get("coords", XiangqiStateModelScript.INVALID_COORDS)
		if captured_coords is not Vector2i:
			return false
		var restored_piece = _board.spawn_piece(captured_side, captured_type)
		var runtime_hooks = ZoneRuntimeHooksScript.for_zone(_board_zone)
		if runtime_hooks == null:
			restored_piece.queue_free()
			return false
		runtime_hooks.set_transfer_handoff(restored_piece, restore_snapshot)
		if not _board_zone.add_item(restored_piece, ZonePlacementTarget.square(captured_coords.x, captured_coords.y)):
			restored_piece.queue_free()
			return false
	_board_zone.refresh()
	return _state_matches_board(state)

func _piece_restore_snapshot(piece: XiangqiPieceScript) -> Dictionary:
	if not is_instance_valid(piece):
		return {}
	return {
		"global_position": piece.global_position,
		"rotation": piece.rotation,
		"scale": Vector2(0.55, 0.55)
	}

func _xiangqi_animation_duration() -> float:
	if _board_zone == null:
		return 0.0
	var display_style = ExampleZoneSupport.get_zone_display_style(_board_zone)
	if display_style is ZoneTweenDisplay:
		return max(0.0, (display_style as ZoneTweenDisplay).duration)
	return 0.0

func _finish_undo_animation() -> void:
	_history.finish_undo_animation()
	_update_undo_button_state()
	_set_status("Undid the last move.")

func _state_matches_board(state: Dictionary) -> bool:
	return _state_model.piece_layout_signature(state) == _state_model.piece_layout_signature(_serialize_state())

func _snapshot_board() -> Array:
	return _state_model.snapshot_board(_board.get_pieces(), Callable(_board, "get_piece_coords"))
